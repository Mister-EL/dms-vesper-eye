
void main() {
    vec2 p = (vUv - vec2(0.5)) * uSize;
    // У самого края холста рисунок сходит на нет: прямоугольник виджета не должен быть виден.
    vec2 edge = 0.5 * uSize - abs(p);
    float fade = smoothstep(0.0, 0.05 * max(uUnit, 1.0), min(edge.x, edge.y));
    fragColor = eye(p / max(uUnit, 1.0)) * fade;
}
