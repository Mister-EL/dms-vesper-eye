import QtQuick
import QtTest
import "../core"
import "../core/Coverage.js" as Geo
import "../core/Acts.js" as Acts

// Логика движка без оболочки: время тест двигает сам и сам вызывает кадры.
Item {
    width: 10; height: 10

    Component { id: lifeC; Life { testClock: 1000000; unit: 200; eco: true; userIdle: false; hasTarget: false } }

    TestCase {
        name: "Life"
        property var life: null
        // Случайное моргание по расписанию в тестах отключено: оно мешает сверять положение век.
        function init() { life = createTemporaryObject(lifeC, this); life.s.nextBlink = life.testClock + 1e9; }
        function run(seconds) { const n = Math.round(seconds * 60); for (let i = 0; i < n; i++) { life.testClock += 1000 / 60; life.frame(1 / 60); } }

        function test_opens_and_rests() {
            compare(life.lidTop, 1);
            run(2.5);
            verify(life.lidTop < 0.35, "веко открылось: " + life.lidTop);
            verify(life.lidTop > 0.15);
            verify(life.dim > 0.98);
        }
        function test_follows_pointer_without_overshoot() {
            run(2); life.hasTarget = true; life.targetDx = 600; life.targetDy = 0; life.cursorMoved();
            let peak = 0; for (let i = 0; i < 120; i++) { run(1 / 60); peak = Math.max(peak, life.gazeX); }
            const want = 600 / Math.hypot(600, 0, 2.2 * 200);
            verify(Math.abs(life.gazeX - want) < 0.03, "дошёл до цели: " + life.gazeX + " из " + want);
            verify(peak < want + 0.03, "без перелёта: " + peak);
        }
        function test_quiet_when_settled() {
            run(4);
            verify(life.quiet, "в покое кадры не нужны");
            const x = life.gazeX, lid = life.lidTop; run(0.5);
            compare(life.gazeX, x); compare(life.lidTop, lid);
        }
        function test_boredom_starts_an_act() {
            run(2); life.userIdle = true;
            let seen = ""; for (let i = 0; i < 60 * 8 && !seen; i++) { run(1 / 60); seen = life.actName; }
            verify(seen !== "", "через несколько секунд без дела начинается номер");
            verify(Acts.ACTS[seen].e[1] >= 0.9, "бодрому — бодрые номера: " + seen);
        }
        function test_falls_asleep_and_wakes() {
            run(2); life.userIdle = true; life.timeScale = 200; run(4);
            verify(life.asleep); run(4);
            verify(life.lidTop > 0.97, "веки сомкнуты: " + life.lidTop);
            verify(life.quiet, "спящий глаз кадров не просит");
            life.timeScale = 1; life.userIdle = false;
            compare(life.bored, 0); compare(life.actName, "wake");
            run(2.5);
            verify(life.lidTop < 0.4, "проснулся: " + life.lidTop);
        }
        function test_battery_shortens_show() {
            compare(life.showSeconds, 600); life.onBattery = true; compare(life.showSeconds, 180);
            life.lowBattery = true; compare(life.showSeconds, 240); verify(life.energy <= 0.42);
            life.showEnabled = false; compare(life.showSeconds, 70);
        }
        function test_notification_glance() {
            run(2); life.notify(0.8, -0.45); run(0.4);
            verify(life.gazeX > 0.5, "посмотрел в сторону уведомления: " + life.gazeX);
            verify(life.pulse > 0); run(3);
            verify(Math.abs(life.gazeX) < 0.1, "вернулся");
        }
        function test_hold_closes_release_opens() {
            run(2); life.press(); run(0.5); verify(life.lidTop > 0.95); verify(life.lidBot > 0.95);
            life.release(); run(1); verify(life.lidTop < 0.4);
        }
        function test_peeks_from_behind_a_window() {
            run(2); life.visFrac = 0.5; life.visX = 1.2; life.visY = 0; run(1.5);
            verify(life.gazeX > 0.6, "зрачок ушёл в видимую половину: " + life.gazeX);
            life.visFrac = 1; run(1.5); verify(Math.abs(life.gazeX) < 0.1);
        }
        function test_reduced_motion() {
            life.reducedMotion = true; life.userIdle = true; run(6);
            compare(life.actName, ""); compare(life.wake, 0);
        }
        function test_every_act_plays_to_the_end() {
            run(2);
            for (const id in Acts.ACTS) {
                life.play(id, true);
                let guard = 0; while (life.actName === id && guard++ < 60 * 20) run(1 / 60);
                verify(life.actName !== id, "номер доигран: " + id);
                verify(isFinite(life.gazeX) && isFinite(life.lidTop) && isFinite(life.pupil) && isFinite(life.bobY), "числа в порядке: " + id);
                run(1.5);
                verify(Math.abs(life.face.x) < 0.05 && life.face.y < 0.05 && life.face.z < 0.05 && life.mood.w < 0.02, "мимика вернулась в покой: " + id);
                compare(life.bobX, 0); compare(life.bobY, 0);
            }
        }
        function test_plain_character_dozes_instead_of_sleeping() {
            life.character = { plain: true, dozeAfter: 60, drowsyLid: 0.95, actGap: [9000, 20000], acts: { sweep: 1 } };
            life.restLid = 0.02; run(2);
            verify(life.lidTop < 0.12, "глаз открыт: " + life.lidTop);
            life.notify(0.8, 0); run(0.5);
            verify(Math.abs(life.gazeX) < 0.1 && life.pulse === 0, "на уведомление не оглядывается");
            life.userIdle = true; life.timeScale = 30; run(4);
            verify(!life.asleep, "не засыпает"); verify(life.dozing, "дремлет");
            life.timeScale = 1; if (life.actName) life.stop(life.testClock); life.s.nextAt = life.testClock + 1e9; run(4);
            verify(life.lidTop > 0.9, "верхнее веко опущено до середины: " + life.lidTop);
            verify(life.lidBot < 0.05, "нижнее веко открыто: " + life.lidBot);
            verify(life.dim > 0.98, "не гаснет");
            verify(life.quiet, "в дремоте кадры не идут");
            life.userIdle = false; run(3);
            verify(life.lidTop < 0.12, "проснулся: " + life.lidTop); compare(life.actName, "");
        }
        function test_plain_character_looks_around_again_and_again() {
            life.character = { plain: true, acts: { sweep: 1 }, actGap: [600, 900] };
            run(2); life.userIdle = true;
            let starts = 0, was = "", peak = 0;
            for (let i = 0; i < 60 * 60; i++) { run(1 / 60); if (life.actName === "sweep" && was !== "sweep") starts++; was = life.actName; peak = Math.max(peak, Math.abs(life.gazeX)); }
            verify(starts >= 3, "осмотр повторяется: " + starts);
            verify(peak > 0.3, "взгляд уходит в сторону: " + peak);
        }
        function test_acts_do_not_repeat() {
            const seen = [];
            for (let i = 0; i < 40; i++) { const id = Acts.pick(1, seen.slice(-5)); verify(seen.slice(-5).indexOf(id) < 0, "повтор: " + id); seen.push(id); }
            verify(Acts.pick(0.05, []) !== "");
        }
    }

    TestCase {
        name: "Coverage"
        function test_lens() {
            verify(Geo.inLens(0, 0)); verify(Geo.inLens(2.4, 0)); verify(!Geo.inLens(2.6, 0));
            verify(!Geo.inLens(0, -1.05)); verify(Geo.inLens(0, 0.85)); verify(!Geo.inLens(2.0, 0.6));
        }
        function test_unit() { compare(Geo.unitFor(570, 270), 100); compare(Geo.unitFor(1400, 737), 1400 / 5.7); }
        function test_coverage() {
            const eye = { x: 100, y: 100, width: 570, height: 270 };
            compare(Geo.coverage(eye, []), 0);
            compare(Geo.coverage(eye, [{ x: 0, y: 0, width: 2000, height: 2000 }]), 1);
            const half = Geo.coverage(eye, [{ x: 0, y: 0, width: 385, height: 2000 }]);
            verify(half > 0.35 && half < 0.65, "половина: " + half);
            verify(Geo.covered(eye, [{ x: 0, y: 0, width: 385, height: 2000 }, { x: 385, y: 0, width: 2000, height: 2000 }]));
        }
        function test_visible_part() {
            const eye = { x: 100, y: 100, width: 570, height: 270 };
            const all = Geo.visible(eye, []); compare(all.f, 1); compare(all.x, 0);
            const right = Geo.visible(eye, [{ x: 0, y: 0, width: 385, height: 2000 }]);
            verify(right.f > 0.35 && right.f < 0.65); verify(right.x > 0.8, "видна правая половина: " + right.x);
            compare(Geo.visible(eye, [{ x: 0, y: 0, width: 2000, height: 2000 }]).f, 0);
        }
    }
}
