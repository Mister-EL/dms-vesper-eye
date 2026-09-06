import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Modules.DesktopWidgets
import qs.Services.System
import qs.Services.UI
import qs.Widgets
import qs.Services.Media

DraggableDesktopWidget {
  id: root

  readonly property real eyeAspect: 1.9
  readonly property real targetAreaRatio: 0.25
  readonly property real targetArea: screen ? (screen.width * screen.height * targetAreaRatio) : 180000
  readonly property real targetWidth: screen ? Math.sqrt(targetArea * eyeAspect) : 520
  readonly property real targetHeight: screen ? (targetWidth / eyeAspect) : 280

  showBackground: false
  roundedCorners: false

  implicitWidth: Math.round(targetWidth * widgetScale)
  implicitHeight: Math.round(targetHeight * widgetScale)
  width: implicitWidth
  height: implicitHeight
  maxScale: 1.6

  defaultX: screen ? Math.round((screen.width - width) / 2) : 100
  defaultY: screen ? Math.round((screen.height - height) / 2) : 100

  property real cursorX: 0
  property real cursorY: 0
  property real cursorSpeed: 0
  property real cursorSpeedSmoothed: 0
  property real eyeOffsetX: 0
  property real eyeOffsetY: 0
  property real ambientEyeOffsetX: 0
  property real ambientEyeOffsetY: 0
  property real ambientEyePhaseX: 0
  property real ambientEyePhaseY: 0
  property real ambientEyeStrength: 0
  property real irisOffsetX: 0
  property real irisOffsetY: 0
  property real pupilOffsetX: 0
  property real pupilOffsetY: 0
  property real targetEyeOffsetX: 0
  property real targetEyeOffsetY: 0
  property real targetIrisOffsetX: 0
  property real targetIrisOffsetY: 0
  property real targetPupilOffsetX: 0
  property real targetPupilOffsetY: 0
  property real lastCursorX: 0
  property real lastCursorY: 0
  property real lastCursorSampleMs: 0
  property real lastSmoothTimestamp: 0
  property bool hasCursorSample: false
  property bool cursorStreamRetryEnabled: true
  property bool isIdle: false
  property real idleLidProgress: 0
  property bool isClickHeld: false
  property real clickLidProgress: 0
  property int clickLidAnimDuration: 120
  property int clickLidAnimEasing: Easing.OutQuad
  property bool autoBlinkActive: false
  property real autoBlinkProgress: 0
  property int autoBlinkAnimDuration: 160
  property int autoBlinkAnimEasing: Easing.OutQuad
  property real microSaccadeOffsetX: 0
  property real microSaccadeOffsetY: 0
  property bool microSaccadeReturning: true
  property bool isSurprised: false
  property real surpriseLidOffset: 0
  property bool surpriseCooldown: false
  property real clickPupilScale: 1
  property bool wakeBlinking: false
  property bool cavaEnabled: false
  property real cavaAmplitude: 0
  readonly property real cavaIrisScale: 1 + cavaAmplitude * 0.06
  property bool notificationFocusActive: false
  property string lastNotificationId: ""
  property real idleBreathPhase: 0
  property real idleDriftPhase: 0
  property real idleBreathStrength: 0
  property real idleDriftStrength: 0
  property real idlePulsePhase: 0
  property real idlePulseStrength: 0
  property real idlePatrolStrength: 0
  property real idlePatrolAngle: 0
  property real idlePatrolTarget1: 1
  property real idlePatrolTarget2: -0.5
  property int idlePatrolDuration1: 380
  property int idlePatrolPause1Duration: 180
  property int idlePatrolDuration2: 350
  property int idlePatrolPause2Duration: 140
  property int idlePatrolDuration3: 500
  property real notificationScanX: 0
  property real notificationScanY: 0

  readonly property real eyeWidth: width * 0.96
  readonly property real eyeHeight: height * 0.95
  readonly property real eyeShaderPadding: Math.max(4, 3 * widgetScale)
  readonly property real eyeShaderHeight: Math.ceil(eyeHeight * 0.44 + eyeShaderPadding * 2)
  readonly property real apertureHalfHeight: eyeHeight * 0.22
  readonly property bool motionEffectsEnabled: !Settings.data.general.animationDisabled
  readonly property real ambientEyeMaxX: Math.max(16, Math.min(24, width * 0.016))
  readonly property real ambientEyeMaxY: Math.max(6, Math.min(10, height * 0.025))
  readonly property real activeEyeMaxX: Math.max(14, Math.min(20, width * 0.012))
  readonly property real activeEyeMaxY: Math.max(6, Math.min(9, height * 0.022))
  readonly property real irisSize: height * 0.5412 * cavaIrisScale
  readonly property real cursorSpeedMax: Math.max(900, height * 1.8)
  readonly property real cursorSpeedNorm: Math.min(1, cursorSpeedSmoothed / cursorSpeedMax)
  readonly property real basePupilRatio: 0.66
  readonly property real minPupilRatio: 0.61
  readonly property real dynamicPupilScale: {
    if (isSurprised) return 1.3;
    if (!isIdle && !isClickHeld && !notificationFocusActive)
      return 1 - ((basePupilRatio - minPupilRatio) / basePupilRatio) * cursorSpeedNorm;
    return 1;
  }
  readonly property real pupilSize: irisSize * basePupilRatio * dynamicPupilScale * clickPupilScale
  readonly property real irisMaxOffset: Math.max(2, height * 0.1056)
  readonly property real outlineWidth: Math.max(1, 1.5 * widgetScale)
  readonly property real idlePulseAmount: (isIdle && !isClickHeld && blinkProgress <= 0.01)
                                      ? (Math.sin(idlePulsePhase) * 0.5 + 0.5)
                                      : 0
  readonly property real idleEyeScaleY: {
    const amp = 0.015 * idlePulseStrength;
    return 1 - amp + (idlePulseAmount * amp);
  }
  readonly property real idleBreathAmplitude: 0.022
  readonly property real idleBreathOffset: (isIdle && !isClickHeld && blinkProgress <= 0.01)
                                       ? (Math.sin(idleBreathPhase) * idleBreathAmplitude * idleBreathStrength)
                                       : 0
  readonly property real idleLidEffective: Math.max(0, Math.min(1, idleLidProgress - (idleBreathAmplitude * idleBreathStrength) + idleBreathOffset))
  readonly property real blinkProgress: Math.max(clickLidProgress, autoBlinkProgress)
  readonly property real topLidProgress: Math.max(idleLidEffective, blinkProgress) - surpriseLidOffset
  readonly property color scleraTone: Settings.data.colorSchemes.darkMode
                                         ? Qt.lighter(Color.mSurfaceVariant, 1.8)
                                         : Qt.darker(Color.mSurfaceVariant, 1.05)
  readonly property color irisInnerTone: Qt.lighter(Color.mPrimary, 1.12)
  readonly property color irisMiddleTone: Color.mPrimary
  readonly property color irisOuterTone: Qt.darker(Color.mPrimary, 1.18)
  readonly property color pupilTone: Color.mShadow
  readonly property color accentTone: Color.mOutline
  readonly property color lidTone: Color.mSurface
  readonly property bool needsSmoothing:
    Math.abs(targetEyeOffsetX - eyeOffsetX) > 0.04
    || Math.abs(targetEyeOffsetY - eyeOffsetY) > 0.04
    || Math.abs(targetIrisOffsetX - irisOffsetX) > 0.04
    || Math.abs(targetIrisOffsetY - irisOffsetY) > 0.04
    || Math.abs(targetPupilOffsetX - pupilOffsetX) > 0.025
    || Math.abs(targetPupilOffsetY - pupilOffsetY) > 0.025
    || Math.abs(cursorSpeed - cursorSpeedSmoothed) > 0.15

  function colorVector(colorValue) {
    return Qt.vector4d(colorValue.r, colorValue.g, colorValue.b, colorValue.a);
  }

  function notificationFocusPoint() {
    const location = Settings.data.notifications.location || "top_right";
    const xFactor = location.indexOf("left") >= 0 ? 0.12
                  : location.indexOf("right") >= 0 ? 0.88 : 0.5;
    const yFactor = location.indexOf("bottom") >= 0 ? 0.88 : 0.12;
    return Qt.point((screen.x || 0) + screen.width * xFactor,
                    (screen.y || 0) + screen.height * yFactor);
  }

  function updateIris() {
    if (!screen || width <= 0 || height <= 0) {
      return;
    }
    if (isIdle) {
      var driftX = Math.sin(idleDriftPhase);
      var driftY = Math.cos(idleDriftPhase * 0.8);
      var patrolX = Math.cos(idlePatrolAngle) * idlePatrolStrength;
      var patrolY = Math.sin(idlePatrolAngle) * idlePatrolStrength;
      var irisX = (driftX * (irisMaxOffset * 0.26) * idleDriftStrength)
                + (patrolX * irisMaxOffset * 0.95);
      var irisY = (driftY * (irisMaxOffset * 0.18) * idleDriftStrength)
                + (patrolY * irisMaxOffset * 0.75);
      var irisDist = Math.sqrt(irisX * irisX + irisY * irisY);
      if (irisDist > irisMaxOffset && irisDist > 0) {
        irisX = irisX / irisDist * irisMaxOffset;
        irisY = irisY / irisDist * irisMaxOffset;
      }
      targetEyeOffsetX = 0;
      targetEyeOffsetY = 0;
      targetIrisOffsetX = irisX;
      targetIrisOffsetY = irisY;
      targetPupilOffsetX = 0;
      targetPupilOffsetY = 0;
      return;
    }

    var targetX = cursorX;
    var targetY = cursorY;
    if (notificationFocusActive && screen) {
      const focusPoint = notificationFocusPoint();
      targetX = focusPoint.x;
      targetY = focusPoint.y;
    }

    var localX = targetX - (screen.x || 0) - root.x;
    var localY = targetY - (screen.y || 0) - root.y;

    var centerX = width / 2;
    var centerY = height / 2;

    var dx = localX - centerX;
    var dy = localY - centerY;
    var dist = Math.sqrt(dx * dx + dy * dy);

    var eyeRangeX = Math.max(1, screen.width * 0.42);
    var eyeRangeY = Math.max(1, screen.height * 0.42);
    var ex = Math.max(-activeEyeMaxX, Math.min(activeEyeMaxX, dx / eyeRangeX * activeEyeMaxX));
    var ey = Math.max(-activeEyeMaxY, Math.min(activeEyeMaxY, dy / eyeRangeY * activeEyeMaxY));
    var ix = dx;
    var iy = dy;

    if (dist > irisMaxOffset && dist > 0) {
      ix = ix / dist * irisMaxOffset;
      iy = iy / dist * irisMaxOffset;
    }

    ix += microSaccadeOffsetX;
    iy += microSaccadeOffsetY;
    if (notificationFocusActive) {
      ix += notificationScanX;
      iy += notificationScanY;
    }
    var idist = Math.sqrt(ix * ix + iy * iy);
    if (idist > irisMaxOffset && idist > 0) {
      ix = ix / idist * irisMaxOffset;
      iy = iy / idist * irisMaxOffset;
    }

    var pMax = Math.max(0, Math.min((irisSize - pupilSize) / 2, (irisSize / 2) * 0.1));
    var pScale = dist > 0 ? Math.min(1, dist / (irisMaxOffset * 1.1)) : 0;
    var px = dist > 0 ? (dx / dist) * pMax * pScale : 0;
    var py = dist > 0 ? (dy / dist) * pMax * pScale : 0;

    targetEyeOffsetX = ex;
    targetEyeOffsetY = ey;
    targetIrisOffsetX = ix;
    targetIrisOffsetY = iy;
    targetPupilOffsetX = px;
    targetPupilOffsetY = py;
  }

  function resetMicroSaccade() {
    microSaccadeReturning = true;
    microSaccadeOffsetX = 0;
    microSaccadeOffsetY = 0;
  }

  function cancelBlinkSequence() {
    autoBlinkHoldTimer.stop();
    doubleBlinkPause.stop();
    doubleBlinkHold.stop();
    wakeBlinkAnim.stop();
    autoBlinkTimer.doDoubleBlink = false;
    autoBlinkActive = false;
  }

  function checkNotificationHead() {
    if (!NotificationService || !NotificationService.activeList) {
      return;
    }
    if (NotificationService.activeList.count <= 0) {
      return;
    }
    var head = NotificationService.activeList.get(0);
    if (head && head.id && head.id !== lastNotificationId) {
      lastNotificationId = head.id;
      if (!motionEffectsEnabled) {
        return;
      }
      cancelBlinkSequence();
      notificationFocusActive = true;
      idleTimer.stop();
      idleTimer.start();
      if (isIdle) {
        isIdle = false;
      }
      resetMicroSaccade();
      notificationScanX = 0;
      notificationScanY = 0;
      notificationReadAnim.restart();
      notificationFocusTimer.restart();
      updateIris();
    }
  }

  function approach(current, target, factor, epsilon) {
    const delta = target - current;
    if (Math.abs(delta) <= epsilon) {
      return target;
    }
    return current + delta * factor;
  }

  function smoothingFactor(deltaMs, timeConstantMs) {
    return 1 - Math.exp(-deltaMs / Math.max(1, timeConstantMs));
  }

  Timer {
    id: smoothTimer
    interval: root.isIdle ? 33 : 16
    running: root.visible && root.motionEffectsEnabled && !root.isIdle && root.needsSmoothing
    repeat: true
    onRunningChanged: if (!running) root.lastSmoothTimestamp = 0
    onTriggered: {
      const now = Date.now();
      const deltaMs = root.lastSmoothTimestamp > 0
                    ? Math.max(1, Math.min(80, now - root.lastSmoothTimestamp))
                    : interval;
      root.lastSmoothTimestamp = now;
      const eyeFactor = root.smoothingFactor(deltaMs, root.isIdle ? 440 : 310);
      const irisFactor = root.smoothingFactor(deltaMs, root.isIdle ? 260 : 80);
      const pupilFactor = root.smoothingFactor(deltaMs, root.isIdle ? 200 : 65);
      const speedFactor = root.smoothingFactor(deltaMs, 110);
      eyeOffsetX = root.approach(eyeOffsetX, targetEyeOffsetX, eyeFactor, 0.04);
      eyeOffsetY = root.approach(eyeOffsetY, targetEyeOffsetY, eyeFactor, 0.04);
      irisOffsetX = root.approach(irisOffsetX, targetIrisOffsetX, irisFactor, 0.04);
      irisOffsetY = root.approach(irisOffsetY, targetIrisOffsetY, irisFactor, 0.04);
      pupilOffsetX = root.approach(pupilOffsetX, targetPupilOffsetX, pupilFactor, 0.025);
      pupilOffsetY = root.approach(pupilOffsetY, targetPupilOffsetY, pupilFactor, 0.025);
      cursorSpeedSmoothed = root.approach(cursorSpeedSmoothed, cursorSpeed, speedFactor, 0.15);
    }
  }

  Timer {
    id: idleTimer
    interval: 10000
    repeat: false
    running: root.visible && !root.isIdle
    onTriggered: {
      if (!root.isIdle) {
        root.isIdle = true;
      }
    }
  }

  function scheduleIdlePatrol() {
    idlePatrolTimer.interval = 12000 + Math.floor(Math.random() * 10000);
    idlePatrolTimer.restart();
  }

  function prepareIdlePatrolAnimation() {
    idlePatrolTarget1 = (Math.random() * 2 - 1);
    idlePatrolTarget2 = (Math.random() * 2 - 1) * 0.55;
    idlePatrolDuration1 = 900 + Math.floor(Math.random() * 550);
    idlePatrolPause1Duration = 240 + Math.floor(Math.random() * 260);
    idlePatrolDuration2 = 850 + Math.floor(Math.random() * 600);
    idlePatrolPause2Duration = 220 + Math.floor(Math.random() * 260);
    idlePatrolDuration3 = 1100 + Math.floor(Math.random() * 600);
    idlePatrolAngle = (Math.random() * Math.PI * 2) - Math.PI;
  }

  Timer {
    id: idlePatrolTimer
    interval: 20000
    repeat: false
    onTriggered: {
      if (!root.isIdle || !root.motionEffectsEnabled) {
        return;
      }
      if (root.isClickHeld || root.blinkProgress > 0.01) {
        root.scheduleIdlePatrol();
        return;
      }
      root.prepareIdlePatrolAnimation();
      idlePatrolAnim.restart();
    }
  }

  Timer {
    id: notificationFocusTimer
    interval: 2000
    repeat: false
    onTriggered: {
      notificationFocusActive = false;
      updateIris();
    }
  }

  Timer {
    id: autoBlinkTimer
    interval: 4000
    repeat: true
    running: root.visible && root.motionEffectsEnabled
    property bool doDoubleBlink: false
    onTriggered: {
      autoBlinkTimer.interval = 4000 + Math.floor(Math.random() * 5000);
      if (root.isClickHeld || root.notificationFocusActive || root.wakeBlinking) {
        return;
      }
      doDoubleBlink = Math.random() < 0.2;
      root.autoBlinkActive = true;
      autoBlinkHoldTimer.restart();
    }
  }

  Timer {
    id: autoBlinkHoldTimer
    interval: 125
    repeat: false
    onTriggered: {
      root.autoBlinkActive = false;
      if (autoBlinkTimer.doDoubleBlink) {
        autoBlinkTimer.doDoubleBlink = false;
        doubleBlinkPause.restart();
      }
    }
  }

  Timer {
    id: doubleBlinkPause
    interval: 145
    repeat: false
    onTriggered: {
      root.autoBlinkActive = true;
      doubleBlinkHold.restart();
    }
  }

  Timer {
    id: doubleBlinkHold
    interval: 110
    repeat: false
    onTriggered: root.autoBlinkActive = false
  }

  Timer {
    id: microSaccadeTimer
    interval: 2000
    repeat: true
    running: root.visible && root.motionEffectsEnabled
    onTriggered: {
      microSaccadeTimer.interval = 2000 + Math.floor(Math.random() * 4000);
      if (root.isIdle || root.isClickHeld || root.notificationFocusActive) {
        return;
      }
      root.microSaccadeReturning = false;
      var max = Math.max(1, Math.round(root.irisMaxOffset * 0.16));
      root.microSaccadeOffsetX = (Math.random() * 2 - 1) * max;
      root.microSaccadeOffsetY = (Math.random() * 2 - 1) * (max * 0.6);
      microSaccadeResetTimer.restart();
    }
  }

  Timer {
    id: microSaccadeResetTimer
    interval: 120
    repeat: false
    onTriggered: root.resetMicroSaccade()
  }

  Timer {
    id: clickPupilResetTimer
    interval: 250
    repeat: false
    onTriggered: root.clickPupilScale = 1
  }

  Timer {
    id: idleMotionTimer
    interval: 33
    repeat: true
    running: root.isIdle && root.visible && root.motionEffectsEnabled
    onTriggered: {
      const fullTurn = Math.PI * 2;
      root.idleBreathPhase = (root.idleBreathPhase + fullTurn * interval / 7600) % fullTurn;
      root.idlePulsePhase = (root.idlePulsePhase + fullTurn * interval / 5900) % fullTurn;
      root.idleDriftPhase = (root.idleDriftPhase + fullTurn * interval / 15000) % fullTurn;
      root.ambientEyePhaseX = (root.ambientEyePhaseX + fullTurn * interval / 18000) % fullTurn;
      root.ambientEyePhaseY = (root.ambientEyePhaseY + fullTurn * interval / 22000) % fullTurn;
      root.ambientEyeOffsetX = Math.sin(root.ambientEyePhaseX);
      root.ambientEyeOffsetY = Math.sin(root.ambientEyePhaseY) * 0.82;

      const eyeFactor = root.smoothingFactor(interval, 440);
      const irisFactor = root.smoothingFactor(interval, 260);
      const pupilFactor = root.smoothingFactor(interval, 200);
      root.eyeOffsetX = root.approach(root.eyeOffsetX, root.targetEyeOffsetX, eyeFactor, 0.04);
      root.eyeOffsetY = root.approach(root.eyeOffsetY, root.targetEyeOffsetY, eyeFactor, 0.04);
      root.irisOffsetX = root.approach(root.irisOffsetX, root.targetIrisOffsetX, irisFactor, 0.04);
      root.irisOffsetY = root.approach(root.irisOffsetY, root.targetIrisOffsetY, irisFactor, 0.04);
      root.pupilOffsetX = root.approach(root.pupilOffsetX, root.targetPupilOffsetX, pupilFactor, 0.025);
      root.pupilOffsetY = root.approach(root.pupilOffsetY, root.targetPupilOffsetY, pupilFactor, 0.025);
    }
  }

  // Cursor positions are streamed by a persistent helper that talks to the
  // Hyprland socket directly — no fork/exec per sample. The helper only
  // prints when the cursor actually moved and adapts its own polling rate.
  Timer {
    id: cursorSpeedDecay
    interval: 250
    repeat: false
    onTriggered: root.cursorSpeed = 0
  }

  Timer {
    id: cursorStreamRestart
    interval: 3000
    repeat: false
    onTriggered: {
      if (root.visible) {
        root.cursorStreamRetryEnabled = true;
      }
    }
  }

  Process {
    id: cursorStream
    running: root.visible && root.cursorStreamRetryEnabled
    command: ["python3", Quickshell.shellDir + "/Bin/eye-cursor-poller.py"]

    stdout: SplitParser {
      onRead: function (line) {
        var parts = line.split(" ");
        if (parts.length < 2) {
          return;
        }
        var x = parseInt(parts[0]);
        var y = parseInt(parts[1]);
        if (isNaN(x) || isNaN(y)) {
          return;
        }
        const now = Date.now();
        var dx = 0;
        var dy = 0;
        var deltaMs = 0;
        if (root.hasCursorSample) {
          dx = x - root.lastCursorX;
          dy = y - root.lastCursorY;
          deltaMs = Math.max(16, Math.min(250, now - root.lastCursorSampleMs));
        }
        root.hasCursorSample = true;
        root.lastCursorX = x;
        root.lastCursorY = y;
        root.lastCursorSampleMs = now;
        // surprise disabled — fast mouse movement no longer triggers it
        root.cursorSpeed = deltaMs > 0 ? Math.sqrt(dx * dx + dy * dy) * 1000 / deltaMs : 0;
        root.cursorX = x;
        root.cursorY = y;
        if (root.isIdle) {
          root.isIdle = false;
        }
        idleTimer.stop();
        idleTimer.start();
        cursorSpeedDecay.restart();
        root.updateIris();
      }
    }

    onExited: {
      root.hasCursorSample = false;
      root.lastCursorSampleMs = 0;
      root.cursorStreamRetryEnabled = false;
      cursorStreamRestart.restart();
    }
  }

  Component.onCompleted: {
    if (cavaEnabled) CavaService.registerComponent("desktopEye");
  }
  Component.onDestruction: {
    CavaService.unregisterComponent("desktopEye");
  }
  onCavaEnabledChanged: {
    if (cavaEnabled) CavaService.registerComponent("desktopEye");
    else CavaService.unregisterComponent("desktopEye");
  }

  Timer {
    id: cavaPoller
    interval: 33
    running: root.cavaEnabled && root.motionEffectsEnabled
    repeat: true
    onTriggered: {
      var vals = CavaService.values;
      if (!vals || vals.length === 0) { root.cavaAmplitude = 0; return; }
      var sum = 0;
      var count = Math.min(vals.length, 8);
      for (var i = 0; i < count; i++) sum += (vals[i] || 0);
      var avg = sum / count;
      root.cavaAmplitude += (avg - root.cavaAmplitude) * 0.3;
    }
  }

  Connections {
    target: NotificationService.activeList
    function onCountChanged() {
      root.checkNotificationHead();
    }
    function onRowsInserted() {
      root.checkNotificationHead();
    }
  }

  onWidthChanged: updateIris()
  onHeightChanged: updateIris()
  onMicroSaccadeOffsetXChanged: updateIris()
  onMicroSaccadeOffsetYChanged: updateIris()
  onIdleDriftPhaseChanged: updateIris()
  onNotificationScanXChanged: updateIris()
  onNotificationScanYChanged: updateIris()
  onIsIdleChanged: {
    idleSleepAnim.stop();
    idleWakeAnim.stop();
    if (!motionEffectsEnabled) {
      idleLidProgress = isIdle ? 1 : 0;
    } else if (isIdle) {
      idleSleepAnim.restart();
    } else {
      idleWakeAnim.restart();
    }
    idleBreathPhase = 0;
    idleDriftPhase = 0;
    idlePulsePhase = 0;
    idleBreathStrength = isIdle && motionEffectsEnabled ? 1 : 0;
    idleDriftStrength = isIdle && motionEffectsEnabled ? 1 : 0;
    idlePulseStrength = isIdle && motionEffectsEnabled ? 1 : 0;
    ambientEyeStrength = isIdle && motionEffectsEnabled ? 1 : 0;
    idlePatrolStrength = 0;
    cursorSpeed = 0;
    cursorSpeedSmoothed = 0;
    idlePatrolTimer.stop();
    idlePatrolAnim.stop();
    if (isIdle && motionEffectsEnabled) {
      scheduleIdlePatrol();
    } else if (!isIdle && !notificationFocusActive && motionEffectsEnabled) {
      wakeBlinkAnim.restart();
    }
    resetMicroSaccade();
    if (isIdle) {
      targetEyeOffsetX = 0;
      targetEyeOffsetY = 0;
      targetIrisOffsetX = 0;
      targetIrisOffsetY = 0;
    } else {
      updateIris();
    }
  }

  onMotionEffectsEnabledChanged: {
    if (!motionEffectsEnabled) {
      cancelBlinkSequence();
      idleSleepAnim.stop();
      idleWakeAnim.stop();
      idlePatrolTimer.stop();
      idlePatrolAnim.stop();
      surpriseAnim.stop();
      surpriseCooldownTimer.stop();
      notificationFocusTimer.stop();
      notificationReadAnim.stop();
      notificationFocusActive = false;
      isSurprised = false;
      surpriseCooldown = false;
      surpriseLidOffset = 0;
      idleBreathStrength = 0;
      idleDriftStrength = 0;
      idlePulseStrength = 0;
      idlePatrolStrength = 0;
      ambientEyeStrength = 0;
      ambientEyeOffsetX = 0;
      ambientEyeOffsetY = 0;
      resetMicroSaccade();
      eyeOffsetX = 0;
      eyeOffsetY = 0;
      irisOffsetX = 0;
      irisOffsetY = 0;
      pupilOffsetX = 0;
      pupilOffsetY = 0;
      targetEyeOffsetX = 0;
      targetEyeOffsetY = 0;
      targetIrisOffsetX = 0;
      targetIrisOffsetY = 0;
      targetPupilOffsetX = 0;
      targetPupilOffsetY = 0;
      cursorSpeed = 0;
      cursorSpeedSmoothed = 0;
      idleLidProgress = isIdle ? 1 : 0;
    } else if (isIdle) {
      idleBreathStrength = 1;
      idleDriftStrength = 1;
      idlePulseStrength = 1;
      ambientEyeStrength = 1;
      idleSleepAnim.restart();
      scheduleIdlePatrol();
    }
  }

  onVisibleChanged: {
    if (visible) {
      cursorStreamRetryEnabled = true;
    }
  }

  onWidgetScaleChanged: {
    const clampedScale = Math.max(minScale, Math.min(maxScale, widgetScale));
    if (Math.abs(clampedScale - widgetScale) > 0.001) {
      widgetScale = clampedScale;
    }
  }

  onIsClickHeldChanged: {
    clickLidAnimDuration = isClickHeld ? 190 : 210;
    clickLidAnimEasing = Easing.OutCubic;
    clickLidProgress = isClickHeld ? 1 : 0;
    if (isClickHeld && autoBlinkActive) {
      autoBlinkActive = false;
    }
  }

  onAutoBlinkActiveChanged: {
    autoBlinkAnimDuration = autoBlinkActive ? 95 : 175;
    autoBlinkAnimEasing = Easing.OutCubic;
    autoBlinkProgress = autoBlinkActive ? 1 : 0;
  }

  onNotificationFocusActiveChanged: {
    resetMicroSaccade();
    if (notificationFocusActive) {
      notificationScanX = 0;
      notificationScanY = 0;
    } else {
      notificationReadAnim.stop();
      notificationScanX = 0;
      notificationScanY = 0;
    }
    updateIris();
  }

  SequentialAnimation {
    id: wakeBlinkAnim
    running: false
    onStarted: root.wakeBlinking = true
    onStopped: root.wakeBlinking = false
    PauseAnimation { duration: 360 }
    ScriptAction { script: { root.autoBlinkActive = true; } }
    PauseAnimation { duration: 125 }
    ScriptAction { script: { root.autoBlinkActive = false; } }
    PauseAnimation { duration: 150 }
    ScriptAction { script: { root.autoBlinkActive = true; } }
    PauseAnimation { duration: 110 }
    ScriptAction { script: { root.autoBlinkActive = false; } }
  }

  SequentialAnimation {
    id: surpriseAnim
    running: false
    onStarted: root.surpriseCooldown = true
    onStopped: surpriseCooldownTimer.restart()
    ScriptAction { script: { root.isSurprised = true; } }
    NumberAnimation {
      target: root; property: "surpriseLidOffset"
      to: 0.12; duration: 150; easing.type: Easing.OutCubic
    }
    PauseAnimation { duration: 400 }
    NumberAnimation {
      target: root; property: "surpriseLidOffset"
      to: 0; duration: 350; easing.type: Easing.InOutCubic
    }
    ScriptAction { script: { root.isSurprised = false; } }
  }

  Timer {
    id: surpriseCooldownTimer
    interval: 2000
    repeat: false
    onTriggered: root.surpriseCooldown = false
  }

  Behavior on clickPupilScale {
    enabled: root.motionEffectsEnabled
    NumberAnimation { duration: 220; easing.type: Easing.InOutCubic }
  }

  Behavior on surpriseLidOffset {
    enabled: false
  }

  SequentialAnimation {
    id: notificationReadAnim
    running: false
    ParallelAnimation {
      NumberAnimation {
        target: root
        property: "notificationScanX"
        to: -root.irisMaxOffset * 0.28
        duration: 190
        easing.type: Easing.InOutCubic
      }
      NumberAnimation {
        target: root
        property: "notificationScanY"
        to: -root.irisMaxOffset * 0.03
        duration: 190
        easing.type: Easing.InOutCubic
      }
    }
    PauseAnimation { duration: 360 }
    ParallelAnimation {
      NumberAnimation {
        target: root
        property: "notificationScanX"
        to: 0
        duration: 170
        easing.type: Easing.InOutCubic
      }
      NumberAnimation {
        target: root
        property: "notificationScanY"
        to: 0
        duration: 170
        easing.type: Easing.InOutCubic
      }
    }
    PauseAnimation { duration: 320 }
    ParallelAnimation {
      NumberAnimation {
        target: root
        property: "notificationScanX"
        to: root.irisMaxOffset * 0.3
        duration: 180
        easing.type: Easing.InOutCubic
      }
      NumberAnimation {
        target: root
        property: "notificationScanY"
        to: root.irisMaxOffset * 0.03
        duration: 180
        easing.type: Easing.InOutCubic
      }
    }
    PauseAnimation { duration: 360 }
    ParallelAnimation {
      NumberAnimation {
        target: root
        property: "notificationScanX"
        to: 0
        duration: 210
        easing.type: Easing.InOutCubic
      }
      NumberAnimation {
        target: root
        property: "notificationScanY"
        to: 0
        duration: 210
        easing.type: Easing.InOutCubic
      }
    }
  }


  SequentialAnimation {
    id: idleSleepAnim
    NumberAnimation {
      target: root; property: "idleLidProgress"
      to: 1; duration: 1100; easing.type: Easing.InOutSine
    }
  }

  SequentialAnimation {
    id: idleWakeAnim
    NumberAnimation {
      target: root; property: "idleLidProgress"
      to: 0; duration: 420; easing.type: Easing.OutCubic
    }
  }

  Behavior on clickLidProgress {
    enabled: root.motionEffectsEnabled
    NumberAnimation {
      duration: root.clickLidAnimDuration
      easing.type: root.clickLidAnimEasing
    }
  }

  Behavior on autoBlinkProgress {
    enabled: root.motionEffectsEnabled
    NumberAnimation {
      duration: root.autoBlinkAnimDuration
      easing.type: root.autoBlinkAnimEasing
    }
  }

  Behavior on idleBreathStrength {
    enabled: root.motionEffectsEnabled
    NumberAnimation {
      duration: 1400
      easing.type: Easing.InOutSine
    }
  }

  Behavior on idleDriftStrength {
    enabled: root.motionEffectsEnabled
    NumberAnimation {
      duration: 1700
      easing.type: Easing.InOutSine
    }
  }

  Behavior on idlePulseStrength {
    enabled: root.motionEffectsEnabled
    NumberAnimation {
      duration: 1600
      easing.type: Easing.InOutSine
    }
  }

  Behavior on ambientEyeStrength {
    enabled: root.motionEffectsEnabled
    NumberAnimation {
      duration: 1600
      easing.type: Easing.InOutSine
    }
  }

  Behavior on idlePatrolStrength {
    enabled: root.motionEffectsEnabled && !idlePatrolAnim.running
    NumberAnimation {
      duration: 1200
      easing.type: Easing.InOutSine
    }
  }

  SequentialAnimation {
    id: idlePatrolAnim
    running: false
    NumberAnimation {
      id: patrolSeg1
      target: root; property: "idlePatrolStrength"
      to: root.idlePatrolTarget1; duration: root.idlePatrolDuration1; easing.type: Easing.InOutSine
    }
    PauseAnimation { id: patrolPause1; duration: root.idlePatrolPause1Duration }
    ScriptAction {
      script: root.idlePatrolAngle += (Math.random() * 0.8 - 0.4);
    }
    NumberAnimation {
      id: patrolSeg2
      target: root; property: "idlePatrolStrength"
      to: root.idlePatrolTarget2; duration: root.idlePatrolDuration2; easing.type: Easing.InOutSine
    }
    PauseAnimation { id: patrolPause2; duration: root.idlePatrolPause2Duration }
    NumberAnimation {
      id: patrolSeg3
      target: root; property: "idlePatrolStrength"
      to: 0; duration: root.idlePatrolDuration3; easing.type: Easing.InOutSine
    }
    onStopped: {
      if (root.isIdle && root.motionEffectsEnabled) {
        root.scheduleIdlePatrol();
      }
    }
  }

  Behavior on microSaccadeOffsetX {
    enabled: root.motionEffectsEnabled
    NumberAnimation {
      duration: root.microSaccadeReturning ? 160 : 90
      easing.type: Easing.OutCubic
    }
  }

  Behavior on microSaccadeOffsetY {
    enabled: root.motionEffectsEnabled
    NumberAnimation {
      duration: root.microSaccadeReturning ? 160 : 90
      easing.type: Easing.OutCubic
    }
  }

  Item {
    id: eyeGroup
    width: root.eyeWidth
    height: root.eyeShaderHeight
    x: (parent.width - width) / 2 + root.eyeOffsetX
       + root.ambientEyeOffsetX * root.ambientEyeMaxX * root.ambientEyeStrength
    y: (parent.height - height) / 2 + root.eyeOffsetY
       + root.ambientEyeOffsetY * root.ambientEyeMaxY * root.ambientEyeStrength
    transform: Scale {
      xScale: 1
      yScale: root.idleEyeScaleY
      origin.x: eyeGroup.width / 2
      origin.y: eyeGroup.height / 2
    }

    ShaderEffect {
      anchors.fill: parent
      property vector2d itemSize: Qt.vector2d(width, height)
      property real logicalEyeHeight: root.eyeHeight
      property vector2d irisOffset: Qt.vector2d(root.irisOffsetX, root.irisOffsetY)
      property vector2d pupilOffset: Qt.vector2d(root.pupilOffsetX, root.pupilOffsetY)
      property real irisRadius: root.irisSize / 2
      property real pupilRadius: root.pupilSize / 2
      property real topLidProgress: Math.max(0, Math.min(1, root.topLidProgress))
      property real bottomLidProgress: Math.max(0, Math.min(1, root.blinkProgress))
      property real outlineWidth: root.outlineWidth
      property vector4d scleraColor: root.colorVector(root.scleraTone)
      property vector4d irisInnerColor: root.colorVector(root.irisInnerTone)
      property vector4d irisMiddleColor: root.colorVector(root.irisMiddleTone)
      property vector4d irisOuterColor: root.colorVector(root.irisOuterTone)
      property vector4d pupilColor: root.colorVector(root.pupilTone)
      property vector4d accentColor: root.colorVector(root.accentTone)
      property vector4d highlightColor: Qt.vector4d(Color.mOnSurface.r, Color.mOnSurface.g, Color.mOnSurface.b, 0.72)
      property vector4d lidColor: root.colorVector(root.lidTone)

      fragmentShader: Qt.resolvedUrl(Quickshell.shellDir + "/Shaders/qsb/desktop_eye.frag.qsb")
      blending: true
    }
  }

  Item {
    id: eyeHitMask
    anchors.fill: parent

    function contains(point) {
      const mapped = eyeHitMask.mapToItem(eyeGroup, point.x, point.y);
      const px = mapped.x - eyeGroup.width / 2;
      const py = mapped.y - eyeGroup.height / 2;
      const halfWidth = eyeGroup.width * 0.496;
      const nx = Math.abs(px) / Math.max(1, halfWidth);
      if (nx > 1) {
        return false;
      }
      const curve = root.apertureHalfHeight
                  * Math.pow(Math.max(0, 1 - nx * nx), 1.08);
      return Math.abs(py) <= curve + Math.max(6, root.outlineWidth * 2);
    }
  }

  MouseArea {
    anchors.fill: parent
    containmentMask: eyeHitMask
    acceptedButtons: Qt.LeftButton
    hoverEnabled: false
    preventStealing: true
    onPressed: mouse => {
                 root.cancelBlinkSequence();
                 if (root.isIdle) {
                   root.isIdle = false;
                 }
                 idleTimer.restart();
                 root.isClickHeld = true;
                 root.clickPupilScale = 0.95;
               }
    onReleased: mouse => {
                  root.isClickHeld = false;
                  root.clickPupilScale = 1.02;
                  clickPupilResetTimer.restart();
                }
    onDoubleClicked: mouse => {
                       if (!root.surpriseCooldown && root.motionEffectsEnabled) {
                         root.cancelBlinkSequence();
                         surpriseAnim.restart();
                       }
                     }
    onCanceled: {
      root.isClickHeld = false;
      root.clickPupilScale = 1;
    }
  }
}
