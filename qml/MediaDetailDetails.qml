import QtQuick
import QtQuick.Controls

import ThemeEngine
import "qrc:/utils/UtilsString.js" as UtilsString

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

        property int legendWidth: 240

        Column {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: Theme.componentMarginXL

            visible: shot.hasGoProMetadata
            spacing: Theme.componentMargin

            Row {
                height: 32
                spacing: Theme.componentMargin

                visible: shot.camera

                IconSvg {
                    width: 32
                    height: 32
                    color: Theme.colorText
                    source: "qrc:/assets/icons/material-symbols/media/camera.svg"
                }
                Text {
                    height: 32
                    text: shot.camera
                    textFormat: Text.PlainText
                    color: Theme.colorText
                    font.bold: true
                    font.pixelSize: Theme.fontSizeContentBig
                    verticalAlignment: Text.AlignVCenter
                }
            }

            Row {
                Text {
                    width: infosDetails.legendWidth
                    text: qsTr("Protune")
                    textFormat: Text.PlainText
                    color: Theme.colorText
                    font.bold: true
                    font.pixelSize: Theme.fontSizeContentSmall
                }
                Text {
                    text: shot.protune
                    textFormat: Text.PlainText
                    color: Theme.colorText
                    font.pixelSize: Theme.fontSizeContent
                }
            }

            Row {
                Text {
                    width: infosDetails.legendWidth
                    text: qsTr("Cam RAW")
                    textFormat: Text.PlainText
                    color: Theme.colorText
                    font.bold: true
                    font.pixelSize: Theme.fontSizeContentSmall
                }
                Text {
                    text: shot.cam_raw
                    textFormat: Text.PlainText
                    color: Theme.colorText
                    font.pixelSize: Theme.fontSizeContent
                }
            }

            Row {
                Text {
                    width: infosDetails.legendWidth
                    text: qsTr("Broadcast range")
                    textFormat: Text.PlainText
                    color: Theme.colorText
                    font.bold: true
                    font.pixelSize: Theme.fontSizeContentSmall
                }
                Text {
                    text: shot.broadcast_range
                    textFormat: Text.PlainText
                    color: Theme.colorText
                    font.pixelSize: Theme.fontSizeContent
                }
            }

            Row {
                Text {
                    width: infosDetails.legendWidth
                    text: qsTr("Lens type")
                    textFormat: Text.PlainText
                    color: Theme.colorText
                    font.bold: true
                    font.pixelSize: Theme.fontSizeContentSmall
                }
                Text {
                    text: shot.lens_type
                    textFormat: Text.PlainText
                    color: Theme.colorText
                    font.pixelSize: Theme.fontSizeContent
                }
            }

            Row {
                Text {
                    width: infosDetails.legendWidth
                    text: qsTr("video_mode_fov")
                    textFormat: Text.PlainText
                    color: Theme.colorText
                    font.bold: true
                    font.pixelSize: Theme.fontSizeContentSmall
                }
                Text {
                    text: shot.video_mode_fov
                    textFormat: Text.PlainText
                    color: Theme.colorText
                    font.pixelSize: Theme.fontSizeContent
                }
            }

            Row {
                Text {
                    width: infosDetails.legendWidth
                    text: qsTr("Low light")
                    textFormat: Text.PlainText
                    color: Theme.colorText
                    font.bold: true
                    font.pixelSize: Theme.fontSizeContentSmall
                }
                Text {
                    text: shot.lowlight
                    textFormat: Text.PlainText
                    color: Theme.colorText
                    font.pixelSize: Theme.fontSizeContent
                }
            }

            Row {
                Text {
                    width: infosDetails.legendWidth
                    text: qsTr("Superview")
                    textFormat: Text.PlainText
                    color: Theme.colorText
                    font.bold: true
                    font.pixelSize: Theme.fontSizeContentSmall
                }
                Text {
                    text: shot.superview
                    textFormat: Text.PlainText
                    color: Theme.colorText
                    font.pixelSize: Theme.fontSizeContent
                }
            }

            Row {
                Text {
                    width: infosDetails.legendWidth
                    text: qsTr("Sharpening")
                    textFormat: Text.PlainText
                    color: Theme.colorText
                    font.bold: true
                    font.pixelSize: Theme.fontSizeContentSmall
                }
                Text {
                    text: shot.sharpening
                    textFormat: Text.PlainText
                    color: Theme.colorText
                    font.pixelSize: Theme.fontSizeContent
                }
            }

            Row {
                Text {
                    width: infosDetails.legendWidth
                    text: qsTr("Media type")
                    textFormat: Text.PlainText
                    color: Theme.colorText
                    font.bold: true
                    font.pixelSize: Theme.fontSizeContentSmall
                }
                Text {
                    text: shot.media_type_str
                    textFormat: Text.PlainText
                    color: Theme.colorText
                    font.pixelSize: Theme.fontSizeContent
                }
            }

            Row {
                height: 32

                Text {
                    width: infosDetails.legendWidth
                    text: qsTr("EIS")
                    textFormat: Text.PlainText
                    color: Theme.colorText
                    font.bold: true
                    font.pixelSize: Theme.fontSizeContentSmall
                }
                Text {
                    text: shot.eis
                    textFormat: Text.PlainText
                    color: Theme.colorText
                    font.pixelSize: Theme.fontSizeContent
                }
            }
        }
    }

    // Right panel /////////////////////////////////////////////////////////////

    Rectangle {
        id: infosFiles
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.bottom: parent.bottom

        width: parent.width * 0.40
        color: Theme.colorForeground

        Rectangle { // fake shadow
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right

            height: 8
            opacity: 0.5

            gradient: Gradient {
                orientation: Gradient.Vertical
                GradientStop { position: 0.0; color: Theme.colorHeaderHighlight; }
                GradientStop { position: 1.0; color: Theme.colorForeground; }
            }
        }

        Column {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom

            topPadding: Theme.componentMarginXL
            bottomPadding: Theme.componentMarginXL

            Item {
                height: 64
                anchors.left: parent.left
                anchors.leftMargin: Theme.componentMarginXL
                anchors.right: parent.right
                anchors.rightMargin: Theme.componentMarginXL/2

                Text {
                    height: 32
                    anchors.top: parent.top

                    text: qsTr("Folder:")
                    textFormat: Text.PlainText
                    color: Theme.colorText
                    font.bold: true
                    font.pixelSize: Theme.fontSizeContent
                    verticalAlignment: Text.AlignVCenter
                }
                Text {
                    height: 32
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.rightMargin: 48
                    anchors.bottom: parent.bottom

                    text: shot.folder
                    textFormat: Text.PlainText
                    color: Theme.colorText
                    elide: Text.ElideLeft
                    font.pixelSize: Theme.fontSizeContent
                    verticalAlignment: Text.AlignVCenter
                }

                RoundButtonIcon {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter

                    backgroundColor: Theme.colorBackground
                    width: 40; height: 40;
                    source: "qrc:/assets/icons/material-symbols/folder_open.svg"
                    onClicked: utilsApp.openWith(shot.folder)
                }
            }

            Text {
                height: 40
                anchors.left: parent.left
                anchors.leftMargin: Theme.componentMarginXL
                anchors.right: parent.right
                anchors.rightMargin: Theme.componentMargin

                text: (shot.fileCount > 1) ? qsTr("Files:") : qsTr("File:")
                textFormat: Text.PlainText
                color: Theme.colorText
                font.bold: true
                font.pixelSize: Theme.fontSizeContent
                verticalAlignment: Text.AlignVCenter
            }

            ListView {
                height: infosFiles.height - 40 - 64 - Theme.componentMarginXL
                anchors.left: parent.left
                anchors.leftMargin: Theme.componentMarginXL
                anchors.right: parent.right

                clip: true
                interactive: true
                ScrollBar.vertical: ScrollBar { z: 1 }

                model: shot.filesShot
                delegate: Item {
                    id: dlv
                    width: ListView.view.width
                    height: 32

                    ////////

                    Row { // row left
                        id: rowLeft
                        height: 24
                        anchors.left: parent.left
                        anchors.right: rowRight.left
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 12

                        // icon
                        IconSvg {
                            width: 20; height: 20;
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.verticalCenterOffset: -1
                            color: Theme.colorText

                            source: {
                                if (modelData.type === 1)
                                    return "qrc:/assets/icons/material-icons/duotone/aspect_ratio.svg"
                                else if (modelData.type === 2)
                                    return "qrc:/assets/icons/material-symbols/media/image.svg"
                                else if (modelData.type === 3)
                                    return "qrc:/assets/icons/material-icons/duotone/list.svg"
                                else
                                    return "qrc:/assets/icons/material-symbols/media/broken_image.svg"
                            }
                        }
/*
                        // geometry
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData.width + "x" + modelData.height
                            textFormat: Text.PlainText
                            color: Theme.colorText
                            font.pixelSize: Theme.fontSizeContentSmall
                        }
*/
                        // filesize
                        Text {
                            id: fileSize
                            anchors.verticalCenter: parent.verticalCenter
                            text: UtilsString.bytesToString(modelData.size)
                            textFormat: Text.PlainText
                            color: Theme.colorSubText
                            font.pixelSize: Theme.fontSizeContentSmall
                        }

                        // filepath
                        Row {
                            anchors.verticalCenter: parent.verticalCenter

                            Text {
                                id: filePath
                                text: modelData.directory
                                textFormat: Text.PlainText
                                color: Theme.colorText
                                font.pixelSize: Theme.fontSizeContentSmall
                                visible: ((filePath.contentWidth + fileName.contentWidth) < (dlv.width - 48 - fileSize.width - rowRight.width))
                            }
                            Text {
                                id: fileName
                                text: modelData.name + "." + modelData.ext
                                textFormat: Text.PlainText
                                color: Theme.colorText
                                font.pixelSize: Theme.fontSizeContentSmall
                            }
                        }
                    }

                    ////////

                    Row { // row right
                        id: rowRight
                        anchors.right: parent.right
                        anchors.rightMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 8

                        // controls
                        RoundButtonIcon {
                            width: 32; height: 32;
                            backgroundColor: Theme.colorBackground
                            source: "qrc:/assets/icons/material-icons/duotone/launch.svg"
                            onClicked: utilsApp.openWith(modelData.path)
                        }
/*
                        RoundButtonIcon {
                            width: 32; height: 32;
                            visible: false
                            backgroundColor: Theme.colorBackground
                            source: "qrc:/assets/icons/material-symbols/delete.svg"
                        }
*/
                    }
                }
            }
        }
    }
}
