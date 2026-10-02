import QtQuick
import QtQuick.Effects

// Drop shadow shared by every pill, used as
// `layer.enabled: true; layer.effect: PillShadow {}` on the pill's background.
// Styled after Zen browser's content shadow (`--zen-big-shadow` in its
// zen-theme.css: `rgba(0, 0, 0, 0.24) 0px 3px 8px`, same in light and dark),
// but centred rather than offset down so it reads evenly all around. The
// numbers aren't the CSS ones: MultiEffect's blur is tighter than a CSS 8px
// blur, so alpha/blurMax were tuned by eye against a Zen screenshot until the
// edge darkening (~12%) and falloff (~8px) matched.
MultiEffect {
    shadowEnabled: true
    shadowColor: Qt.rgba(0, 0, 0, 0.35)
    shadowBlur: 1.0
    blurMax: 16
}
