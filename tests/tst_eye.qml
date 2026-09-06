import QtQuick
import QtTest
import "../components"

Item {
    width: 1000; height: 526
    BehaviorController { id: behavior; active: false }
    GazeController { id: gaze; active: false }
    EyeRenderer {
        id: eye
        anchors.fill: parent
        topLid: behavior.topLid; bottomLid: behavior.bottomLid
        pupilScale: behavior.pupilScale
        irisX: gaze.irisX; irisY: gaze.irisY
    }
    TestCase {
        name: "VesperEye"
        when: windowShown
        function init() {
            behavior.active = false; behavior.reducedMotion = false; behavior.idle = false;
            behavior.lastNotification = 0; behavior.lastSurprise = 0;
            behavior.active = true; behavior.eco = true;
            gaze.active = false; gaze.reducedMotion = false; gaze.active = true;
        }
        function cleanup() { behavior.active = false; gaze.active = false; }
        function test_hold_and_release() {
            const size = Qt.size(eye.width, eye.height), radius = eye.radius;
            behavior.press(); tryCompare(behavior, "clickLid", 1, 350);
            compare(behavior.topLid, 1); compare(behavior.bottomLid, 1);
            compare(Qt.size(eye.width, eye.height), size); compare(eye.radius, radius);
            behavior.release(); tryCompare(behavior, "clickLid", 0, 350); verify(!behavior.held);
        }
        function test_drowsiness_only_upper_lid() {
            behavior.idleNow(); tryCompare(behavior, "idleLid", 1, 1500);
            compare(behavior.topLid, 1); compare(behavior.bottomLid, 0);
        }
        function test_wake_finishes_double_blink() {
            behavior.idleNow(); wait(1150); behavior.activity();
            tryCompare(behavior, "idleLid", 0, 650); wait(1000);
            verify(!behavior.idle); compare(behavior.blinkLid, 0);
        }
        function test_suspend_cancels_hold_and_events() {
            behavior.press(); wait(210); behavior.active = false;
            verify(!behavior.held); compare(behavior.topLid, 0); compare(behavior.bottomLid, 0);
            behavior.notify(1, -0.4); behavior.blinkNow(true); wait(400);
            verify(!behavior.reading); compare(behavior.blinkLid, 0);
        }
        function test_manual_has_priority_over_notification() {
            behavior.press(); behavior.notify(1,-0.4); wait(200);
            verify(behavior.held); verify(!behavior.reading);
        }
        function test_surprise_and_cooldown() {
            behavior.surprise(); verify(behavior.surprised); wait(270);
            compare(behavior.pupilScale,1.3); const stamp=behavior.lastSurprise;
            behavior.surprise(); compare(behavior.lastSurprise,stamp);
            wait(950); verify(!behavior.surprised); compare(behavior.pupilScale,1);
        }
        function test_reduced_motion_hold_still_works() {
            behavior.reducedMotion=true; behavior.press(); wait(30);
            compare(behavior.topLid,1); compare(behavior.bottomLid,1);
            behavior.release(); wait(30); compare(behavior.topLid,0);
            behavior.blinkNow(true); wait(100); compare(behavior.blinkLid,0);
        }
        function test_notification_returns() {
            behavior.notify(1,-0.4); verify(behavior.reading);
            tryCompare(behavior,'reading',false,2200);
        }
        function test_gaze_bounded_and_settles() {
            gaze.limit=40;gaze.point(2000,2000);
            verify(Math.hypot(gaze.targetX,gaze.targetY)<=40.001);
            tryCompare(gaze,'moving',false,1600);
            verify(Math.abs(gaze.irisX-gaze.targetX)<0.025);
            gaze.active=false;compare(gaze.irisX,0);compare(gaze.pupilX,0);
        }
        function test_eye_hit_area() {
            verify(eye.containsPoint(500,263));verify(!eye.containsPoint(500,20));verify(!eye.containsPoint(5,100));
        }
    }
}
