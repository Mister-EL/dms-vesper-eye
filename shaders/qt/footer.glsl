
void main() {
    vec2 p = (qt_TexCoord0 - vec2(0.5)) * uSize;
    fragColor = eye(p / max(uUnit, 1.0)) * ubuf.qt_Opacity;
}
