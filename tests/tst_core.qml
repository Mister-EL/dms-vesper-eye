import QtQuick
import QtTest
import "../core"
import "../core/Coverage.js" as Geo

Item {
    width: 570; height: 270

    Gaze { id: gaze; active: false; unit: 200 }
    Manner { id: behavior; active: false; restLid: 0.1; drowsyAfter: 400; sleepAfter: 1500 }
    SignalSpy { id: glanceSpy; target: behavior; signalName: "glance" }
    SignalSpy { id: resumeSpy; target: behavior; signalName: "resume" }

    TestCase {
        name: "Gaze"
        function init() {
            gaze.active = false; gaze.reducedMotion = false; gaze.glancing = false; gaze.fpsCap = 0;
            gaze.hasTarget = false; gaze.targetDx = 0; gaze.targetDy = 0;
            gaze.active = true; gaze.snap(); gaze.frames = 0;
        }
        function cleanup() { gaze.active = false; }
        function test_settles_on_target() {
            gaze.targetDx = 400; gaze.hasTarget = true;
            verify(gaze.moving);
            tryVerify(function() { return !gaze.moving; }, 3000);
            const expected = 400 / Math.hypot(400, 2.2 * 200);
            verify(Math.abs(gaze.gazeX - expected) < gaze.quantum, "взгляд должен прийти в цель");
            compare(gaze.gazeY, 0);
            verify(Math.abs(gaze.lagX - gaze.gazeX) < gaze.quantum * 2, "запаздывающий слой должен догнать");
        }
        function test_never_overshoots() {
            gaze.targetDx = 900; gaze.hasTarget = true;
            const limit = 900 / Math.hypot(900, 440) + gaze.quantum;
            let worst = 0;
            for (let i = 0; i < 60 && gaze.moving; i++) { wait(10); worst = Math.max(worst, gaze.gazeX); }
            verify(worst <= limit, "пружина без перерегулирования: " + worst + " > " + limit);
        }
        function test_invisible_change_requests_no_frame() {
            gaze.hasTarget = true; gaze.targetDx = 300;
            tryVerify(function() { return !gaze.moving; }, 3000);
            const before = gaze.frames;
            gaze.targetDx = 300.02;      // сотые доли пикселя указателя вдали
            wait(120);
            verify(!gaze.moving); compare(gaze.frames, before);
        }
        function test_frame_cap_reduces_updates() {
            gaze.fpsCap = 0; gaze.hasTarget = true; gaze.targetDx = 2000;
            tryVerify(function() { return !gaze.moving; }, 3000);
            const free = gaze.frames;
            gaze.snap(); gaze.hasTarget = false; gaze.targetDx = 0; gaze.snap(); gaze.frames = 0;
            gaze.fpsCap = 20; gaze.hasTarget = true; gaze.targetDx = 2000;
            tryVerify(function() { return !gaze.moving; }, 3000);
            verify(gaze.frames < free, "с пределом кадров обновлений меньше: " + gaze.frames + " против " + free);
        }
        function test_reduced_motion_snaps() {
            gaze.reducedMotion = true; gaze.hasTarget = true; gaze.targetDy = -500;
            verify(!gaze.moving);
            verify(Math.abs(gaze.gazeY - (-500 / Math.hypot(500, 440))) < 1e-6);
        }
        function test_glance_overrides_pointer() {
            gaze.hasTarget = true; gaze.targetDx = 500;
            gaze.glanceX = -0.5; gaze.glanceY = 0.2; gaze.glancing = true;
            tryVerify(function() { return !gaze.moving; }, 3000);
            verify(Math.abs(gaze.gazeX + 0.5) < gaze.quantum);
            gaze.glancing = false;
            tryVerify(function() { return !gaze.moving && gaze.gazeX > 0.5; }, 3000);
        }
    }

    TestCase {
        name: "Behavior"
        function init() {
            behavior.active = false; behavior.reducedMotion = false; behavior.tired = false;
            behavior.lastNotification = 0; behavior.lastSurprise = 0;
            behavior.active = true; glanceSpy.clear(); resumeSpy.clear();
        }
        function cleanup() { behavior.active = false; }
        function test_rest_lid_and_blink() {
            compare(behavior.lidTop, 0.1); compare(behavior.lidBot, 0);
            behavior.blinkNow(false);
            tryVerify(function() { return behavior.blinkLid > 0.95; }, 600);
            verify(behavior.lidTop > 0.95); verify(behavior.lidBot > 0.8);
            tryCompare(behavior, "blinkLid", 0, 800);
        }
        function test_hold_closes_and_release_resumes() {
            behavior.press(); tryCompare(behavior, "clickLid", 1, 400);
            compare(behavior.lidTop, 1); compare(behavior.lidBot, 1); compare(behavior.stateName, "held");
            behavior.release(); tryCompare(behavior, "clickLid", 0, 400);
            verify(!behavior.held); verify(resumeSpy.count >= 1);
        }
        function test_drowsy_then_asleep_then_wake() {
            tryVerify(function() { return behavior.drowsy; }, 900);
            tryCompare(behavior, "idleLid", 1, 1600);
            verify(behavior.lidTop > 0.7 && behavior.lidTop < 0.8, "в дремоте тяжелеет только верхнее веко");
            compare(behavior.lidBot, 0);
            tryVerify(function() { return behavior.asleep; }, 2500);
            tryCompare(behavior, "sleepLid", 1, 2200);
            compare(behavior.lidTop, 1); compare(behavior.lidBot, 1);
            tryCompare(behavior, "dim", 0.5, 1500);
            behavior.activity();
            verify(!behavior.asleep); verify(!behavior.drowsy); compare(behavior.wake, 1);
            tryCompare(behavior, "sleepLid", 0, 700); tryCompare(behavior, "wake", 0, 900);
            tryCompare(behavior, "dim", 1, 1500);
        }
        function test_notification_glance_and_pulse() {
            behavior.notify(1, -0.45);
            verify(behavior.reading); compare(behavior.stateName, "notification");
            verify(behavior.pulse > 0); verify(Math.abs(Math.hypot(behavior.pulseX, behavior.pulseY) - 1) < 1e-6);
            verify(glanceSpy.count >= 1);
            behavior.notify(-1, 0);                 // второе подряд не принимается
            verify(behavior.pulseX > 0);
            tryVerify(function() { return !behavior.reading; }, 2500);
            tryCompare(behavior, "pulse", 0, 600);
            verify(resumeSpy.count >= 1);
        }
        function test_surprise_and_tired() {
            behavior.surprise(); tryVerify(function() { return behavior.pupilScale > 1.25; }, 500);
            tryVerify(function() { return !behavior.surprised; }, 1500);
            behavior.tired = true; verify(behavior.lidTop > 0.3);
        }
        function test_reveal_and_reduced_motion() {
            behavior.reveal(); compare(behavior.wake, 1); tryCompare(behavior, "wake", 0, 900);
            behavior.reducedMotion = true;
            behavior.blinkNow(false); compare(behavior.blinkLid, 0);
            behavior.press(); compare(behavior.clickLid, 1); behavior.release(); compare(behavior.clickLid, 0);
        }
        function test_suspend_stops_everything() {
            behavior.press(); behavior.active = false;
            compare(behavior.stateName, "suspended"); verify(!behavior.held); compare(behavior.clickLid, 0); compare(behavior.pulse, 0);
        }
    }

    TestCase {
        name: "Geometry"
        function test_lens() {
            verify(Geo.inLens(0, 0)); verify(Geo.inLens(0, -0.99)); verify(!Geo.inLens(0, -1.01));
            verify(Geo.inLens(0, 0.87)); verify(!Geo.inLens(0, 0.89));
            verify(Geo.inLens(2.45, 0)); verify(!Geo.inLens(2.55, 0)); verify(!Geo.inLens(2.3, 0.5));
        }
        function test_unit() { compare(Geo.unitFor(570, 270), 100); compare(Geo.unitFor(1400, 737), 1400 / 5.7); }
        function test_coverage() {
            const eye = { x: 740, y: 532, width: 1400, height: 737 };
            verify(!Geo.covered(eye, []));
            verify(Geo.covered(eye, [{ x: 0, y: 0, width: 2880, height: 1800 }]));
            verify(!Geo.covered(eye, [{ x: 0, y: 0, width: 1400, height: 1800 }]), "закрыта только левая половина");
            verify(Geo.covered(eye, [{ x: 0, y: 0, width: 1450, height: 1800 }, { x: 1440, y: 0, width: 1440, height: 1800 }]), "два окна вместе закрывают глаз");
            verify(!Geo.covered(eye, [{ x: 900, y: 700, width: 300, height: 200 }]), "маленькое окно глаз не закрывает");
            // Два окна бок о бок с зазором 10 px посередине: виден только зазор — глаз считается закрытым.
            verify(Geo.covered(eye, [{ x: 20, y: 60, width: 1415, height: 1720 }, { x: 1445, y: 60, width: 1415, height: 1720 }]), "щель между окнами не в счёт");
            const half = Geo.coverage(eye, [{ x: 0, y: 0, width: 1440, height: 1800 }]);
            verify(half > 0.4 && half < 0.6, "половина экрана закрывает около половины глаза: " + half);
        }
    }
}
