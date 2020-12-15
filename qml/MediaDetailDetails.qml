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

        property int legendWidth: 240

        Column {
            anchors.top: parent.top
            anchors.topMargin: 24
            anchors.left: parent.left
            anchors.leftMargin: 32
            anchors.right: parent.right
            anchors.rightMargin: 32
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 24

            visible: shot.hasGoProMetadata
            spacing: 16

            Row {
                height: 32
                spacing: 16

                visible: shot.camera

                ImageSvg {
                    width: 32
                    height: 32
                    color: Theme.colorText
                    source: "qrc:/assets/icons_material/baseline-camera-24px.svg"
                }
                Text {
                    height: 32
                    text: shot.camera
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
                    color: Theme.colorText
                    font.bold: true
                    font.pixelSize: Theme.fontSizeContentSmall
                }
                Text {
                    text: shot.protune
                    color: Theme.colorText
                    font.pixelSize: Theme.fontSizeContent
                }
            }

            Row {
                Text {
                    width: infosDetails.legendWidth
                    text: qsTr("Cam RAW")
                    color: Theme.colorText
                    font.bold: true
                    font.pixelSize: Theme.fontSizeContentSmall
                }
                Text {
                    text: shot.cam_raw
                    color: Theme.colorText
                    font.pixelSize: Theme.fontSizeContent
                }
            }

            Row {
                Text {
                    width: infosDetails.legendWidth
                    text: qsTr("Broadcast range")
                    color: Theme.colorText
                    font.bold: true
                    font.pixelSize: Theme.fontSizeContentSmall
                }
                Text {
                    text: shot.broadcast_range
                    color: Theme.colorText
                    font.pixelSize: Theme.fontSizeContent
                }
            }

            Row {
                Text {
                    width: infosDetails.legendWidth
                    text: qsTr("Lens type")
                    color: Theme.colorText
                    font.bold: true
                    font.pixelSize: Theme.fontSizeContentSmall
                }
                Text {
                    text: shot.lens_type
                    color: Theme.colorText
                    font.pixelSize: Theme.fontSizeContent
                }
            }

            Row {
                Text {
                    width: infosDetails.legendWidth
                    text: qsTr("video_mode_fov")
                    color: Theme.colorText
                    font.bold: true
                    font.pixelSize: Theme.fontSizeContentSmall
                }
                Text {
                    text: shot.video_mode_fov
                    color: Theme.colorText
                    font.pixelSize: Theme.fontSizeContent
                }
            }

            Row {
                Text {
                    width: infosDetails.legendWidth
                    text: qsTr("Low light")
                    color: Theme.colorText
                    font.bold: true
                    font.pixelSize: Theme.fontSizeContentSmall
                }
                Text {
                    text: shot.lowlight
                    color: Theme.colorText
                    font.pixelSize: Theme.fontSizeContent
                }
            }

            Row {
                Text {
                    width: infosDetails.legendWidth
                    text: qsTr("Superview")
                    color: Theme.colorText
                    font.bold: true
                    font.pixelSize: Theme.fontSizeContentSmall
                }
                Text {
                    text: shot.superview
                    color: Theme.colorText
                    font.pixelSize: Theme.fontSizeContent
                }
            }

            Row {
                Text {
                    width: infosDetails.legendWidth
                    text: qsTr("Sharpening")
                    color: Theme.colorText
                    font.bold: true
                    font.pixelSize: Theme.fontSizeContentSmall
                }
                Text {
                    text: shot.sharpening
                    color: Theme.colorText
                    font.pixelSize: Theme.fontSizeContent
                }
            }

            Row {
                Text {
                    width: infosDetails.legendWidth
                    text: qsTr("Media type")
                    color: Theme.colorText
                    font.bold: true
                    font.pixelSize: Theme.fontSizeContentSmall
                }
                Text {
                    text: shot.media_type_str
                    color: Theme.colorText
                    font.pixelSize: Theme.fontSizeContent
                }
            }

            Row {
                height: 32

                Text {
                    width: infosDetails.legendWidth
                    text: qsTr("EIS")
                    color: Theme.colorText
                    font.bold: true
                    font.pixelSize: Theme.fontSizeContentSmall
                }
                Text {
                    text: shot.eis
                    color: Theme.colorText
                    font.pixelSize: Theme.fontSizeContent
                }
            }
        }
    }

    // Right panel /////////////////////////////////////////////////////////////

    Rectangle {
        id: infosFiles
        width: parent.width * 0.40
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

            Item {
                height: 64
                anchors.left: parent.left
                anchors.right: parent.right

                Text {
                    height: 32
                    anchors.top: parent.top

                    text: qsTr("Folder:")
                    color: Theme.colorText
                    font.bold: true
                    font.pixelSize: Theme.fontSizeContent
                    verticalAlignment: Text.AlignVCenter
                }
                Text {
                    height: 32
                    anchors.bottom: parent.bottom

                    text: shot.folder
                    color: Theme.colorText
                    font.pixelSize: Theme.fontSizeContent
                    verticalAlignment: Text.AlignVCenter
                }

                ItemImageButton {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter

                    backgroundColor: Theme.colorBackground
                    width: 40; height: 40;
                    source: "qrc:/assets/icons_material/outline-folder-24px.svg"
                    onClicked: utilsApp.openWith(shot.folder)
                }
            }

            Text {
                height: 40
                anchors.left: parent.left
                anchors.right: parent.right

                text: qsTr("File(s):")
                color: Theme.colorText
                font.bold: true
                font.pixelSize: Theme.fontSizeContent
                verticalAlignment: Text.AlignVCenter
            }

            ListView {
                height: shot.filesList.length * 24
                anchors.left: parent.left
                anchors.right: parent.right

                interactive: false
                model: shot.filesShot
                delegate: Item {
                    height: 32
                    anchors.left: parent.left
                    anchors.right: parent.right

                    Row { // row left
                        height: 24
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 12

                        // icon
                        ImageSvg {
                            width: 20; height: 20;
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.verticalCenterOffset: -1

                            source: {
                                if (modelData.type === 1)
                                    return "qrc:/assets/icons_material/baseline-aspect_ratio-24px.svg"
                                else if (modelData.type === 2)
                                    return "qrc:/assets/icons_material/baseline-photo-24px.svg"
                                else if (modelData.type === 3)
                                    return "qrc:/assets/icons_material/baseline-list-24px.svg"
                                else
                                    return "qrc:/assets/icons_material/baseline-broken_image-24px.svg"
                            }
                        }
/*
                        // geometry
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData.width + "x" + modelData.height
                            color: Theme.colorText
                            font.pixelSize: Theme.fontSizeContentSmall
                        }
*/
                        // filesize
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: UtilsString.bytesToString(modelData.size)
                            color: Theme.colorSubText
                            font.pixelSize: Theme.fontSizeContentSmall
                        }

                        // filepath
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData.name + "." + modelData.ext
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
                            backgroundColor: Theme.colorBackground
                            source: "qrc:/assets/icons_material/baseline-launch-24px.svg"
                            onClicked: utilsApp.openWith(modelData.path)
                        }
                        ItemImageButton {
                            width: 32; height: 32;
                            visible: false
                            backgroundColor: Theme.colorBackground
                            source: "qrc:/assets/icons_material/baseline-delete-24px.svg"
                        }
                    }
                }
            }
        }
    }
}
