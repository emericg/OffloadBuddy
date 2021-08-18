import QtQuick 2.12

import ThemeEngine 1.0

Item {
    id: tag
    implicitWidth: 80
    implicitHeight: 28
    width: rowTag.width + 20

    property string text: "TAG"
    property string color: Theme.colorSecondary
    property string colorText: "white"

    signal clicked()

    Rectangle {
        id: tagBackground
        width: parent.width
        height: parent.height
        opacity: 1
        radius: Theme.componentRadius
        color: tag.color

        Row {
            id: rowTag
            anchors.centerIn: parent
            height: tag.height
            spacing: 0

            Text {
                id: tagText
                anchors.top: parent.top
                anchors.bottom: parent.bottom

                text: tag.text
                textFormat: Text.PlainText
                color: tag.colorText
                elide: Text.ElideMiddle
                font.capitalization: Font.AllUppercase
                font.pixelSize: Theme.fontSizeComponentVerySmall
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            Item {
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: 20
                Rectangle {
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.right: parent.right
                    anchors.rightMargin: 6
                    width: 2
                    color: tag.colorText
                    opacity: 0.5
                }
            }

            ImageSvg {
                anchors.verticalCenter: parent.verticalCenter
                width: 20
                color: tag.colorText
                source: "qrc:/assets/icons_material/baseline-add-24px.svg"
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        onClicked: tag.clicked()
    }
}
