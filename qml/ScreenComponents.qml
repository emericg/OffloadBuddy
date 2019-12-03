import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Dialogs 1.3

import ThemeEngine 1.0
import "qrc:/js/UtilsString.js" as UtilsString

Item {
    id: screenComponent
    width: 1280
    height: 720
    anchors.fill: parent

    // HEADER //////////////////////////////////////////////////////////////////

    Rectangle {
        id: rectangleHeader
        height: 64
        anchors.rightMargin: 0
        anchors.right: parent.right
        anchors.leftMargin: 0
        anchors.left: parent.left
        anchors.topMargin: 0
        anchors.top: parent.top
        color: Theme.colorHeader

        ItemImageButton {
            id: buttonBack
            width: 48
            height: 48
            anchors.left: parent.left
            anchors.leftMargin: 8
            anchors.verticalCenter: parent.verticalCenter

            iconColor: Theme.colorHeaderContent
            backgroundColor: Theme.colorForeground

            source: "qrc:/others/navigate_before_big.svg"
            onClicked: applicationContent.state = "library"
        }

        Text {
            id: textShotName
            height: 40
            anchors.leftMargin: 8
            anchors.left: buttonBack.right
            anchors.verticalCenter: parent.verticalCenter

            text: "Components"
            color: Theme.colorHeaderContent
            font.bold: true
            font.pixelSize: Theme.fontSizeHeaderTitle
            verticalAlignment: Text.AlignVCenter
        }

        Row {
            id: rowCodecs
            height: 28
            spacing: 16
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: textShotName.right
            anchors.leftMargin: 32

            ItemCodec {
                id: codecVideo
                text: "H.264"
            }
        }

        Row {
            id: rowMenus
            anchors.right: parent.right
            anchors.rightMargin: 48
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 0
            anchors.top: parent.top
            anchors.topMargin: 0

            ItemMenuButton {
                id: menuFirst
                height: parent.height

                menuText: "First"
                source: "qrc:/icons_material/baseline-aspect_ratio-24px.svg"
                selected: true
                onClicked: {
                    menuFirst.selected = true
                    menuSecond.selected = false
                    menuThird.selected = false
                }
            }
            ItemMenuButton {
                id: menuSecond
                height: parent.height

                menuText: "Second"
                source: "qrc:/icons_material/baseline-insert_chart-24px.svg"
                onClicked: {
                    menuFirst.selected = false
                    menuSecond.selected = true
                    menuThird.selected = false
                }
            }
            ItemMenuButton {
                id: menuThird
                height: parent.height

                menuText: "Third"
                source: "qrc:/icons_material/baseline-map-24px.svg"
                onClicked: {
                    menuFirst.selected = false
                    menuSecond.selected = false
                    menuThird.selected = true
                }
            }
        }
    }

    ////////////////////////////////////////////////////////////////////////////

    Item {
        id: rectangleContent

        anchors.top: rectangleHeader.bottom
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.topMargin: 0

        ////////

        Rectangle {
            id: rectangleAction
            anchors.top: parent.top
            anchors.topMargin: 0
            anchors.left: parent.left
            anchors.leftMargin: 0
            anchors.right: parent.right
            anchors.rightMargin: 0

            height: 56
            color: Theme.colorActionbar

            Text {
                id: element1
                anchors.left: parent.left
                anchors.leftMargin: 32
                anchors.verticalCenter: parent.verticalCenter

                text: "Action bar"
                verticalAlignment: Text.AlignVCenter
                font.pixelSize: 18
                font.bold: true
                color: Theme.colorActionbarContent
            }

            ButtonWireframe {
                id: button_a1
                anchors.right: button_a2.left
                anchors.rightMargin: 16
                anchors.verticalCenter: parent.verticalCenter

                fullColor: true
                primaryColor: Theme.colorActionbarHighlight
                text: "Action 1"
            }

            ButtonWireframeImage {
                id: button_a2
                anchors.right: itemImageButtonX.left
                anchors.rightMargin: 32
                anchors.verticalCenter: parent.verticalCenter

                fullColor: true
                primaryColor: Theme.colorActionbarHighlight
                text: "Action 2"
                source: "qrc:/icons_material/baseline-accessibility-24px.svg"
            }

            ItemImageButton {
                id: itemImageButtonX
                width: 40
                height: 40
                anchors.right: parent.right
                anchors.rightMargin: 32
                anchors.verticalCenter: parent.verticalCenter

                source: "qrc:/icons_material/baseline-close-24px.svg"
                iconColor: "white"
                backgroundColor: Theme.colorActionbarHighlight
            }
        }

        ////////

        Item {
            id: rectangleTheme
            height: 64
            anchors.top: rectangleAction.bottom
            anchors.topMargin: 0
            anchors.left: parent.left
            anchors.leftMargin: 0
            anchors.right: parent.right
            anchors.rightMargin: 0

            ComboBoxThemed {
                id: comboBoxAppTheme
                width: 256
                height: 40
                anchors.left: element.right
                anchors.leftMargin: 24
                anchors.verticalCenter: element.verticalCenter

                model: ListModel {
                    id: cbAppTheme
                    ListElement { text: "LIGHT AND WARM"; }
                    ListElement { text: "DARK AND SPOOKY"; }
                    ListElement { text: "PLAIN AND BORING"; }
                    ListElement { text: "BLOOD AND TEARS"; }
                    ListElement { text: "MIGHTY KITTENS"; }
                }

                Component.onCompleted: {
                    currentIndex = settingsManager.appTheme;
                    if (currentIndex === -1) { currentIndex = 0 }
                }
                property bool cbinit: false
                onCurrentIndexChanged: {
                    if (cbinit)
                        settingsManager.appTheme = currentIndex;
                    else
                        cbinit = true;
                }
            }

            RadioButtonThemed {
                id: radioButtonLight
                anchors.left: comboBoxAppTheme.right
                anchors.leftMargin: 24
                anchors.verticalCenter: element.verticalCenter

                text: "light"
                checked: true
                //onCheckedChanged:
            }
            RadioButtonThemed {
                id: radioButtonDark
                anchors.left: radioButtonLight.right
                anchors.leftMargin: 24
                anchors.verticalCenter: element.verticalCenter

                text: "dark"
                checked: false
                //onCheckedChanged:
            }

            Text {
                id: element
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 32

                text: "Application theme"
                font.pixelSize: 16
                font.bold: true
                color: Theme.colorText
            }
        }

        ////////

        Item {
            id: content

            anchors.top: rectangleTheme.bottom
            anchors.topMargin: 0
            anchors.bottom: rectangleQtQuickThemed.top
            anchors.bottomMargin: 0
            anchors.left: parent.left
            anchors.leftMargin: 0
            anchors.right: parent.right
            anchors.rightMargin: 0

            ItemImageButton {
                id: itemImageButton1
                width: 48
                height: 48
                anchors.top: parent.top
                anchors.topMargin: 32
                anchors.left: parent.left
                anchors.leftMargin: 32

                source: "qrc:/icons_material/baseline-accessibility-24px.svg"
                background: true
                highlightMode: "circle"
            }
            ItemImageButton {
                id: itemImageButton2
                width: 48
                height: 48
                anchors.leftMargin: 16
                anchors.left: itemImageButton1.right
                anchors.verticalCenter: itemImageButton1.verticalCenter

                source: "qrc:/icons_material/baseline-accessibility-24px.svg"
                background: true
                highlightMode: "color"
            }
            ItemImageButton {
                id: itemImageButton3
                width: 48
                height: 48
                anchors.leftMargin: 16
                anchors.left: itemImageButton2.right
                anchors.verticalCenter: itemImageButton1.verticalCenter

                source: "qrc:/icons_material/baseline-accessibility-24px.svg"
                background: true
                highlightMode: "both"
                highlightColor: Theme.colorError
                tooltipText: "this one has a tooltip!"
            }

            ItemImageButton {
                id: itemImageButton11
                anchors.leftMargin: 160
                anchors.left: itemImageButton3.right
                anchors.verticalCenter: itemImageButton1.verticalCenter

                source: "qrc:/icons_material/baseline-accessibility-24px.svg"
                background: false
                highlightMode: "circle"
            }
            ItemImageButton {
                id: itemImageButton22
                anchors.leftMargin: 16
                anchors.left: itemImageButton11.right
                anchors.verticalCenter: itemImageButton1.verticalCenter

                source: "qrc:/icons_material/baseline-accessibility-24px.svg"
                background: false
                highlightMode: "color"
            }
            ItemImageButton {
                id: itemImageButton33
                anchors.leftMargin: 16
                anchors.left: itemImageButton22.right
                anchors.verticalCenter: itemImageButton1.verticalCenter

                source: "qrc:/icons_material/baseline-accessibility-24px.svg"
                background: false
                highlightMode: "both"
                highlightColor: Theme.colorError
                tooltipText: "another tooltip!"
            }

            ////////

            ButtonImageThemed {
                id: buttonImage1
                anchors.top: itemImageButton1.bottom
                anchors.topMargin: 16
                anchors.left: parent.left
                anchors.leftMargin: 32

                text: "ButtonImageThemed"
                source: "qrc:/icons_material/baseline-accessibility-24px.svg"
            }
            ButtonImage {
                id: buttonImage2
                anchors.left: buttonImage1.right
                anchors.leftMargin: 32
                anchors.verticalCenter: buttonImage1.verticalCenter

                text: "ButtonImage"
                source: "qrc:/icons_material/baseline-accessibility-24px.svg"
            }

            ButtonWireframeImage {
                id: buttonImage11
                anchors.top: buttonImage1.bottom
                anchors.topMargin: 16
                anchors.left: parent.left
                anchors.leftMargin: 32

                text: "ButtonWireframeImage"
                source: "qrc:/icons_material/baseline-accessibility-24px.svg"
            }
            ButtonWireframe {
                id: buttonImage22
                anchors.left: buttonImage11.right
                anchors.leftMargin: 32
                anchors.verticalCenter: buttonImage11.verticalCenter

                text: "ButtonWireframe"
            }

            ButtonWireframeImage {
                id: buttonImage111
                anchors.top: buttonImage11.bottom
                anchors.topMargin: 16
                anchors.left: parent.left
                anchors.leftMargin: 32

                fullColor: true
                text: "ButtonWireframeImage"
                source: "qrc:/icons_material/baseline-accessibility-24px.svg"
            }
            ButtonWireframe {
                id: buttonImage222
                anchors.left: buttonImage111.right
                anchors.leftMargin: 32
                anchors.verticalCenter: buttonImage111.verticalCenter

                fullColor: true
                text: "ButtonWireframe"
            }

            ////////

            ItemBadge {
                id: badge1
                width: 128
                anchors.top: buttonImage111.bottom
                anchors.topMargin: 32
                anchors.left: parent.left
                anchors.leftMargin: 32

                legend: "license"
                text: "LGPL 3"
                onClicked: Qt.openUrlExternally("https://www.gnu.org/licenses/lgpl-3.0.html")
            }
            ItemCodec {
                id: codec1
                anchors.left: badge1.right
                anchors.leftMargin: 32
                anchors.verticalCenter: badge1.verticalCenter

                text: "H.264"
                color: Theme.colorForeground
            }

            ////////

            Row {
                id: rowLilMenuTxt
                height: 40
                anchors.top: badge1.bottom
                anchors.topMargin: 32
                anchors.left: parent.left
                anchors.leftMargin: 32

                ItemLilMenuButton {
                    id: lilmenu1
                    height: parent.height

                    text: "4/3"
                    selected: true
                    onClicked: {
                        lilmenu1.selected = true
                        lilmenu2.selected = false
                        lilmenu3.selected = false
                    }
                }
                ItemLilMenuButton {
                    id: lilmenu2
                    height: parent.height

                    text: "16/9"
                    onClicked: {
                        lilmenu1.selected = false
                        lilmenu2.selected = true
                        lilmenu3.selected = false
                    }
                }
                ItemLilMenuButton {
                    id: lilmenu3
                    height: parent.height

                    text: "21/9"
                    onClicked: {
                        lilmenu1.selected = false
                        lilmenu2.selected = false
                        lilmenu3.selected = true
                    }
                }
            }

            Row {
                id: rowLilMenuImg
                height: 40
                anchors.top: badge1.bottom
                anchors.topMargin: 32
                anchors.left: rowLilMenuTxt.right
                anchors.leftMargin: 32

                ItemLilMenuButton {
                    id: lilmenu11
                    height: parent.height

                    source: "qrc:/icons_material/baseline-date_range-24px.svg"
                    sourceSize: 18
                    selected: true
                    onClicked: {
                        lilmenu11.selected = true
                        lilmenu22.selected = false
                        lilmenu33.selected = false
                    }
                }
                ItemLilMenuButton {
                    id: lilmenu22
                    height: parent.height

                    source: "qrc:/icons_material/baseline-date_range-24px.svg"
                    sourceSize: 22
                    onClicked: {
                        lilmenu11.selected = false
                        lilmenu22.selected = true
                        lilmenu33.selected = false
                    }
                }
                ItemLilMenuButton {
                    id: lilmenu33
                    height: parent.height

                    source: "qrc:/icons_material/baseline-date_range-24px.svg"
                    sourceSize: 26
                    onClicked: {
                        lilmenu11.selected = false
                        lilmenu22.selected = false
                        lilmenu33.selected = true
                    }
                }
            }
        }

        ////////

        Item {
            id: rectangleQtQuickThemed
            height: 160
            anchors.right: parent.right
            anchors.rightMargin: 0
            anchors.left: parent.left
            anchors.leftMargin: 0
            anchors.bottom: rectangleQtQuick.top
            anchors.bottomMargin: 0

            Rectangle {
                id: rectangle
                height: 1
                color: Theme.colorSeparator
                anchors.top: parent.top
                anchors.topMargin: 1
                anchors.right: parent.right
                anchors.rightMargin: 0
                anchors.left: parent.left
                anchors.leftMargin: 0
            }

            RangeSliderThemed {
                id: rangeSliderThemed
                anchors.left: sliderThemed.right
                anchors.leftMargin: 32
                anchors.verticalCenter: progressBarThemed.verticalCenter

                second.value: 0.75
                first.value: 0.25
            }

            SliderThemed {
                id: sliderThemed
                y: 73
                anchors.verticalCenter: progressBarThemed.verticalCenter
                value: 0.5
                anchors.leftMargin: 32
                anchors.left: progressBarThemed.right
            }

            ProgressBarThemed {
                id: progressBarThemed
                x: 32
                y: 90
                anchors.bottom: buttonThemed.top
                anchors.bottomMargin: 32
                value: 0.5
                anchors.leftMargin: 32
                anchors.left: parent.left
            }

            TextFieldThemed {
                id: textFieldThemed
                x: 32
                y: 276
                anchors.verticalCenter: buttonThemed.verticalCenter
                anchors.left: roundButton1.right
                anchors.leftMargin: 32
            }

            ButtonThemed {
                id: buttonThemed
                x: 32
                y: 128
                text: "Button"
                anchors.left: parent.left
                anchors.leftMargin: 32
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 32
            }

            SwitchThemedDesktop {
                id: switchThemedDesktop
                anchors.verticalCenter: rangeSliderThemed.verticalCenter
                anchors.left: rangeSliderThemed.right
                anchors.leftMargin: 16

                text: "Switch"
                checked: true
            }

            SwitchThemedMobile {
                id: switchThemedMobile
                anchors.verticalCenterOffset: 0
                anchors.left: switchThemedDesktop.right
                anchors.leftMargin: 16
                anchors.verticalCenter: progressBarThemed.verticalCenter

                text: "Switch"
                checked: true
            }

            RoundButton {
                id: roundButton1
                y: 88
                text: "+"
                anchors.left: buttonThemed.right
                anchors.leftMargin: 32
                anchors.verticalCenter: buttonThemed.verticalCenter
            }

            CheckBoxThemed {
                id: checkBox
                y: 88
                text: "Check Box"
                anchors.left: spinBox.right
                anchors.leftMargin: 32
                anchors.verticalCenter: buttonThemed.verticalCenter
            }

            ComboBoxThemed {
                id: comboBox1
                y: 88
                width: 256
                anchors.left: textFieldThemed.right
                anchors.leftMargin: 32
                anchors.verticalCenter: buttonThemed.verticalCenter

                model: ListModel {
                    ListElement { text: "combobox item1"; }
                    ListElement { text: "combobox item2"; }
                }
            }

            SpinBoxThemed {
                id: spinBox
                y: 88
                anchors.left: comboBox1.right
                anchors.leftMargin: 32
                anchors.verticalCenter: buttonThemed.verticalCenter
            }
        }

        ////////

        Item {
            id: rectangleQtQuick
            height: 160
            anchors.right: parent.right
            anchors.rightMargin: 0
            anchors.left: parent.left
            anchors.leftMargin: 0
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 0

            Rectangle {
                height: 1
                color: Theme.colorSeparator
                anchors.top: parent.top
                anchors.topMargin: 1
                anchors.right: parent.right
                anchors.rightMargin: 0
                anchors.left: parent.left
                anchors.leftMargin: 0
            }

            RangeSlider {
                id: rangeSlider
                x: 496
                y: 73
                anchors.verticalCenter: progressBar.verticalCenter
                second.value: 0.75
                anchors.leftMargin: 32
                first.value: 0.25
                anchors.left: slider.right
            }

            Slider {
                id: slider
                anchors.verticalCenter: progressBar.verticalCenter
                anchors.leftMargin: 32
                anchors.left: progressBar.right
                value: 0.5
            }

            ProgressBar {
                id: progressBar
                anchors.bottom: button.top
                anchors.bottomMargin: 32
                value: 0.5
                anchors.leftMargin: 32
                anchors.left: parent.left
            }

            Switch {
                anchors.verticalCenter: progressBar.verticalCenter
                anchors.left: rangeSlider.right
                anchors.leftMargin: 16

                text: "Switch"
                checked: true
            }

            Button {
                id: button
                width: 128
                text: "Button"
                anchors.left: parent.left
                anchors.leftMargin: 32
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 32
            }

            RoundButton {
                id: roundButton
                text: "+"
                anchors.verticalCenter: button.verticalCenter
                anchors.left: button.right
                anchors.leftMargin: 32
            }

            TextField {
                id: textField
                y: 88
                width: 128
                text: "Text Field"
                anchors.left: roundButton.right
                anchors.leftMargin: 32
                anchors.verticalCenter: roundButton.verticalCenter
            }

            CheckBox {
                id: checkBox1
                y: 88
                text: "Check Box"
                anchors.left: spinBox1.right
                anchors.leftMargin: 32
                anchors.verticalCenter: button.verticalCenter
            }

            ComboBox {
                id: comboBox
                y: 88
                width: 256
                anchors.left: textField.right
                anchors.leftMargin: 32
                anchors.verticalCenter: button.verticalCenter

                model: ListModel {
                    ListElement { text: "combobox item1"; }
                    ListElement { text: "combobox item2"; }
                }
            }

            SpinBox {
                id: spinBox1
                y: 88
                anchors.left: comboBox.right
                anchors.leftMargin: 32
                anchors.verticalCenter: button.verticalCenter
            }
        }

        ////////

        Rectangle {
            id: rectangleColors
            width: 68
            height: 388
            anchors.top: parent.top
            anchors.topMargin: 90
            anchors.right: parent.right
            anchors.rightMargin: 32

            color: "white"

            Column {
                id: palette
                width: 64
                height: 384
                anchors.verticalCenter: parent.verticalCenter
                anchors.horizontalCenter: parent.horizontalCenter

                Rectangle {
                    id: header
                    width: 64
                    height: 64
                    color: Theme.colorHeader
                }
                Rectangle {
                    id: fg
                    width: 64
                    height: 64
                    color: Theme.colorForeground
                }
                Rectangle {
                    id: bg
                    width: 64
                    height: 64
                    color: Theme.colorBackground
                }
                Rectangle {
                    id: primary
                    width: 64
                    height: 64
                    color: Theme.colorPrimary

                    Rectangle {
                        id: secondary
                        width: 24
                        height: 24
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 0
                        anchors.right: parent.right
                        anchors.rightMargin: 0
                        color: Theme.colorSecondary
                    }
                }
                Rectangle {
                    id: warning
                    width: 64
                    height: 64
                    color: Theme.colorWarning
                }
                Rectangle {
                    id: error
                    width: 64
                    height: 64
                    color: Theme.colorError
                }
            }
        }
    }
}
