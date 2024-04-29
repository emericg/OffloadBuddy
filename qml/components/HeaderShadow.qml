import QtQuick
import ThemeEngine

Rectangle { // fake shadow
    anchors.top: parent.bottom
    anchors.left: parent.left
    anchors.right: parent.right

    height: 8
    opacity: 0.5

    gradient: Gradient {
        orientation: Gradient.Vertical
        GradientStop { position: 0.0; color: Theme.colorHeaderHighlight; }
        GradientStop { position: 1.0; color: Theme.colorBackground; }
    }
}
