import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Controls 2.12

import ThemeEngine 1.0

Row {
    id: csdWindows

    anchors.top: parent.top
    anchors.topMargin: 0
    anchors.right: parent.right
    anchors.rightMargin: 0

    height: 28
    spacing: 0

    visible: (settingsManager.appThemeCSD && Qt.platform.os === "windows")

    Rectangle { // button minimize
        width: 46; height: 28;
        color: h ? "#33aaaaaa" : "transparent"

        property bool h: false

        Rectangle {
            width: 10; height: 1;
            anchors.centerIn: parent
            color: "transparent"
            border.width: 1
            border.color: parent.h ? Theme.colorHighContrast : Theme.colorIcon
        }

        MouseArea {
            anchors.fill: parent

            hoverEnabled: true
            onEntered: parent.h = true
            onExited: parent.h = false
            onClicked: appWindow.showMinimized()
        }
    }
    ////////

    Rectangle { // button maximize
        width: 46; height: 28;
        color: h ? "#33aaaaaa" : "transparent"

        property bool h: false

        Rectangle {
            width: 10; height: 10;
            anchors.centerIn: parent
            color: "transparent"
            border.width: 1
            border.color: parent.h ? Theme.colorHighContrast : Theme.colorIcon
        }

        MouseArea {
            anchors.fill: parent

            hoverEnabled: true
            onEntered: parent.h = true
            onExited: parent.h = false
            onClicked: {
                if (appWindow.visibility === ApplicationWindow.Maximized)
                    appWindow.showNormal()
                else
                    appWindow.showMaximized()
            }
        }
    }

    ////////

    Rectangle { // button close
        width: 46; height: 28;
        color: h ? "red" : "transparent"

        property bool h: false

        ImageSvg {
            width: 16; height: 16;
            anchors.centerIn: parent

            source: "qrc:/assets/icons_material/baseline-close-24px.svg"
            color: parent.h ? "white" : Theme.colorIcon
        }
/*
        Rectangle {
            width: 12; height: 1;
            anchors.centerIn: parent
            rotation: 45
            color: parent.h ? "white" : Theme.colorIcon
        }
        Rectangle {
            width: 12; height: 1;
            anchors.centerIn: parent
            rotation: -45
            color: parent.h ? "white" : Theme.colorIcon
        }
*/
        MouseArea {
            anchors.fill: parent

            hoverEnabled: true
            onEntered: parent.h = true
            onExited: parent.h = false
            onClicked: appWindow.close()
        }
    }
}
