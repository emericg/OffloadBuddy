import QtQuick 2.12
import QtQuick.Controls 2.12

import ThemeEngine 1.0
import com.offloadbuddy.shared 1.0
import "qrc:/js/UtilsString.js" as UtilsString

Item {
    id: contentDetails
    anchors.fill: parent

    // Left panel //////////////////////////////////////////////////////////////

    Item {
        id: infosDetails
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: infosFiles.left
        anchors.bottom: parent.bottom

        Column {
            anchors.top: parent.top
            anchors.topMargin: 24
            anchors.left: parent.left
            anchors.leftMargin: 24
            anchors.right: parent.right
            anchors.rightMargin: 24
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 24

            visible: shot.hasGoProMetadata

            Row {
                height: 40

                Text {
                    width: 128
                    text: qsTr("Protune")
                    font.bold: true
                    font.pixelSize: Theme.fontSizeContent
                }
                Text {
                    width: 128
                    text: shot.protune
                    font.pixelSize: Theme.fontSizeContent
                }
            }

            Row {
                height: 40

                Text {
                    width: 128
                    text: qsTr("lowlight")
                    font.bold: true
                    font.pixelSize: Theme.fontSizeContent
                }
                Text {
                    width: 128
                    text: shot.lowlight
                    font.pixelSize: Theme.fontSizeContent
                }
            }

            Row {
                height: 40

                Text {
                    width: 128
                    text: qsTr("superview")
                    font.bold: true
                    font.pixelSize: Theme.fontSizeContent
                }
                Text {
                    width: 128
                    text: shot.superview
                    font.pixelSize: Theme.fontSizeContent
                }
            }

            Row {
                height: 40

                Text {
                    width: 128
                    text: qsTr("media_type")
                    font.bold: true
                    font.pixelSize: Theme.fontSizeContent
                }
                Text {
                    width: 128
                    text: shot.media_type
                    font.pixelSize: Theme.fontSizeContent
                }
            }

            Row {
                height: 40

                Text {
                    width: 128
                    text: qsTr("EIS")
                    font.bold: true
                    font.pixelSize: Theme.fontSizeContent
                }
                Text {
                    width: 128
                    text: shot.eis
                    font.pixelSize: Theme.fontSizeContent
                }
            }
        }
    }

    // Right panel /////////////////////////////////////////////////////////////

    Rectangle {
        id: infosFiles
        width: 640
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.bottom: parent.bottom

        color: Theme.colorForeground

        Column {
            anchors.top: parent.top
            anchors.topMargin: 24
            anchors.left: parent.left
            anchors.leftMargin: 24
            anchors.right: parent.right
            anchors.rightMargin: 24
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 24

            Text {
                height: 32
                anchors.left: parent.left
                anchors.right: parent.right

                text: qsTr("Folder:")
                color: Theme.colorText
                font.bold: true
                font.pixelSize: Theme.fontSizeContent
                verticalAlignment: Text.AlignVCenter
            }
            Text {
                height: 32
                anchors.left: parent.left
                anchors.right: parent.right

                text: shot.folder
                color: Theme.colorText
                font.pixelSize: Theme.fontSizeContent
                verticalAlignment: Text.AlignVCenter
            }

            Text {
                height: 32
                anchors.left: parent.left
                anchors.right: parent.right

                text: qsTr("File(s):")
                color: Theme.colorText
                font.bold: true
                font.pixelSize: Theme.fontSizeContent
                verticalAlignment: Text.AlignVCenter
            }

            ListView {
                height: shot.filesList.length * 32
                anchors.left: parent.left
                anchors.right: parent.right

                interactive: false
                model: shot.filesList
                delegate: Item {
                    height: 32
                    anchors.left: parent.left
                    anchors.right: parent.right

                    Row { // row left
                        height: 32
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 8

                        // icon
                        ImageSvg {
                            width: 24; height: 24;
                            anchors.verticalCenter: parent.verticalCenter
                            source: "qrc:/assets/icons_material/baseline-aspect_ratio-24px.svg"
                        }

                        // filesize
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "1 MB"
                            color: Theme.colorText
                            font.pixelSize: Theme.fontSizeContentSmall
                        }

                        // filepath
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData
                            color: Theme.colorText
                            font.pixelSize: Theme.fontSizeContentSmall
                        }
                    }

                    Row { // row right
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 8

                        // controls
                        ItemImageButton {
                            width: 32; height: 32;
                            source: "qrc:/assets/icons_material/outline-folder-24px.svg"
                            onClicked: utilsApp.openWith(modelData)
                        }
                        ItemImageButton {
                            width: 32; height: 32;
                            source: "qrc:/assets/icons_material/baseline-delete-24px.svg"
                        }
                    }
                }
            }
        }
    }
}
