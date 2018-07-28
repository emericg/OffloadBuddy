pragma Singleton
import QtQuick 2.0

Item {
    // Colors
    readonly property string colorRed: "red"
    readonly property string colorGreen: "green"
    readonly property string colorBlue: "blue"

    readonly property string colorSidebar: "#4E596E"

    readonly property string colorHeaderBackground: "#eef0f1"
    readonly property string colorHeaderTitle: "#353637"

    readonly property string colorContentBackground: "#ffffff"
    readonly property string colorContentBox: "#f9f9f9"
    readonly property string colorContentTitle: "#353637"
    readonly property string colorContentText: "#000000"

    readonly property string colorDoIt: "#46b0f4"
    readonly property string colorDangerZone: "#FF5F5F"
    readonly property string colorWarning: "#FFDB63"
    readonly property string colorButtonText: "#ffffff"
    readonly property string colorProgressbar: "#00000000"

    // Fonts (sizes in pixel)
    readonly property int fontSizeHeaderTitle: 30
    readonly property int fontSizeContentTitle: 24
    readonly property int fontSizeContentText: 20
}
