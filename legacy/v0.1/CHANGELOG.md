# 0.1.1 — responsive gaze

- Frame-synchronized gaze interpolation instead of the 33 ms Eco timer.
- 60 Hz cursor sampling during motion; 80–100 ms idle detection, unchanged DPMS suspension.
- Eye size is a per-instance desktop setting, independent of eyelid geometry.

# Changelog

## 0.1.0 — 2026-09-06 (preview)

- First native DMS 1.6.0 desktop plugin; archived Noctalia snapshot remains intact.
- Separate eyelid masking; no whole-eye vertical scaling during blink or drowsiness.
- Bounded, time-based iris/pupil tracking with layer-shell position correction.
- Hold/release, double-click, drowsiness/wake and rate-limited notification reactions.
- Eco default, adaptive read-only cursor bridge, DPMS/visibility shutdown, bounded retries.
- QSB with cross-backend variants; Qt 6 behavior tests and Python IPC tests.
- See docs/VALIDATION.md for measurements and unverified real-session scenarios.
