import QtQuick 2.0
import QtQuick.Controls 1.1

import com.offloadbuddy.style 1.0

Item {
    id: actionButtonItem
    height: 24
    width: parent.width - 4

    property string button_text;
    property bool clicked;
    property int index;
    property string target;
    property bool enable: true;

    signal buttonClicked;

    function viewButtonHovered() {
        viewButton.state = "hovered"
    }

    function viewButtonExited() {
        if(clicked == false) {
            viewButton.state = ""
        } else {
            viewButton.state = "clicked"
        }
    }

    Rectangle {
        id: viewButton;
        height: vButton.height + 4
        width: parent.width

        Text {
            id: vButton
            text: qsTr(button_text)
            width: parent.width
            anchors { verticalCenter: parent.verticalCenter; left: parent.left; leftMargin: 10 }
            font.bold: true
            font.pixelSize: ThemeEngine.fontSizeContentText
            color: "#3d3d3d"
        }
        MouseArea {
            hoverEnabled: enable
            anchors.fill: parent
            enabled: enable
            onClicked: buttonClicked()
            onEntered: viewButtonHovered()
            onExited: viewButtonExited()
        }
        states: [
            State {
                name: "clicked";
                PropertyChanges { target: vButton; color: "#286E1E"; }
            },
            State {
                name: "hovered";
                PropertyChanges { target: vButton; color: { if (vButton.text === qsTr("DELETE")) ThemeEngine.colorDangerZone; else ThemeEngine.colorApproved; } }
            },
            State {
                name: "normal";
                PropertyChanges { target: vButton; color: "#3d3d3d"; }
            }
        ]
    }
}
