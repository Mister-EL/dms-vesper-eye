
void main() {
    vec2 p = (vUv - vec2(0.5)) * uSize;
    fragColor = eye(p / max(uUnit, 1.0));
}
