pragma Singleton
import QtQuick 2.0

Item { // PLAIN AND BORING
    // Colors
    readonly property string colorSidebar: "#4E596E"
    readonly property string colorSidebarText: "#ffffff"

    readonly property string colorHeaderBackground: "#eef0f1"
    readonly property string colorHeaderTitle: "#353637"
    readonly property string colorHeaderSubText: "#000000"

    readonly property string colorContentBackground: "#ffffff"
    readonly property string colorContentBox: "#f9f9f9"
    readonly property string colorContentTitle: "#353637"
    readonly property string colorContentSubBox: "#eef0f1"
    readonly property string colorContentSubTitle: "#000000"
    readonly property string colorContentText: "#000000"

    readonly property string colorApproved: "#46b0f4"
    readonly property string colorDangerZone: "#FF5F5F"
    readonly property string colorSomethingsWrong: "#FFDB63"

    readonly property string colorButtonText: "#ffffff"
    readonly property string colorProgressbar: "#00000000"

    readonly property string colorText: "#000000"

    // Fonts (sizes in pixel)
    readonly property int fontSizeHeaderTitle: 30
    readonly property int fontSizeContentTitle: 24
    readonly property int fontSizeContentText: 16
}
