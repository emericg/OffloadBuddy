import QtQuick 2.12
import QtQuick.Controls 2.12

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
        z: 5
        color: Theme.colorHeader

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right

        // prevent clicks below this area
        //MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons; }

        DragHandler {
            // Drag on the sidebar to drag the whole window // Qt 5.15+
            // Also, prevent clicks below this area
            onActiveChanged: if (active) appWindow.startSystemMove();
            target: null
        }

        ItemImageButton {
            id: buttonBack
            width: 48
            height: 48
            anchors.left: parent.left
            anchors.leftMargin: 8
            anchors.verticalCenter: parent.verticalCenter

            iconColor: Theme.colorHeaderContent
            backgroundColor: Theme.colorForeground

            source: "qrc:/assets/others/navigate_before_big.svg"
            onClicked: { appContent.state = "library" }
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
            font.pixelSize: Theme.fontSizeHeader
            verticalAlignment: Text.AlignVCenter
        }

        Row {
            id: rowCodecs
            spacing: 16
            anchors.left: textShotName.right
            anchors.leftMargin: 32
            anchors.verticalCenter: parent.verticalCenter

            ItemCodec {
                id: codecVideo1
                text: "H.264"
            }

            ItemCodec {
                id: codecVideo2
                text: "16:9"
            }
        }

        Row {
            id: rowMenus
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.rightMargin: 48
            anchors.bottom: parent.bottom

            ItemMenuButton {
                id: menuFirst
                height: parent.height

                menuText: "First"
                source: "qrc:/assets/icons_material/baseline-aspect_ratio-24px.svg"
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
                source: "qrc:/assets/icons_material/baseline-insert_chart-24px.svg"
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
                source: "qrc:/assets/icons_material/baseline-map-24px.svg"
                onClicked: {
                    menuFirst.selected = false
                    menuSecond.selected = false
                    menuThird.selected = true
                }
            }
        }

        CsdWindows { }
    }

    // CONTENT /////////////////////////////////////////////////////////////////

    Item {
        id: rectangleContent

        anchors.top: rectangleHeader.bottom
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.left: parent.left

        ////////////////

        Rectangle {
            id: rectangleActions
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right

            height: 56
            Behavior on height { NumberAnimation { duration: 133 } }

            clip: true
            visible: (height > 0)
            color: Theme.colorActionbar

            // left

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 24
                anchors.verticalCenter: parent.verticalCenter

                text: "Action bar"
                font.bold: true
                font.pixelSize: Theme.fontSizeContentBig
                color: Theme.colorActionbarContent
                verticalAlignment: Text.AlignVCenter
            }

            // right

            Row {
                anchors.right: itemImageButtonX.left
                anchors.rightMargin: 24
                anchors.verticalCenter: parent.verticalCenter
                spacing: 16

                ButtonWireframeImage {
                    fullColor: true
                    primaryColor: Theme.colorActionbarHighlight
                    source: "qrc:/assets/icons_material/baseline-warning-24px.svg"
                }
                ButtonWireframeImage {
                    fullColor: true
                    primaryColor: Theme.colorActionbarHighlight
                    text: "Action 1"
                    source: "qrc:/assets/icons_material/baseline-warning-24px.svg"
                }
                ButtonWireframeImage {
                    fullColor: true
                    primaryColor: Theme.colorActionbarHighlight
                    text: "Action 2"
                }
            }

            ItemImageButton {
                id: itemImageButtonX
                width: 40
                height: 40
                anchors.right: parent.right
                anchors.rightMargin: 24
                anchors.verticalCenter: parent.verticalCenter

                source: "qrc:/assets/icons_material/baseline-close-24px.svg"
                iconColor: "white"
                backgroundColor: Theme.colorActionbarHighlight
            }
        }

        ////////////////

        Rectangle {
            id: rectangleColors
            width: 64 + 4
            height: 6*64 + 4
            anchors.top: rectangleActions.bottom
            anchors.topMargin: 32
            anchors.right: parent.right
            anchors.rightMargin: 32

            z: 10
            color: "white"

            Column {
                id: palette
                width: 64
                anchors.centerIn: parent

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
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
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

        ////////

        Column {
            id: columnComponents

            anchors.top: rectangleActions.bottom
            anchors.topMargin: 24
            anchors.left: parent.left
            anchors.leftMargin: 24
            anchors.right: parent.right
            anchors.rightMargin: 24
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 24

            spacing: 24

            ////

            Row {
                anchors.left: parent.left
                anchors.right: parent.right
                spacing: 24

                Text {
                    anchors.verticalCenter: parent.verticalCenter

                    text: "Application theme"
                    font.pixelSize: 16
                    font.bold: true
                    color: Theme.colorText
                }
                ComboBoxThemed {
                    id: comboBoxAppTheme
                    width: 256
                    anchors.verticalCenter: parent.verticalCenter

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
                    anchors.verticalCenter: parent.verticalCenter

                    text: "light"
                    checked: true
                }
                RadioButtonThemed {
                    id: radioButtonDark
                    anchors.verticalCenter: parent.verticalCenter

                    text: "dark"
                    checked: false
                }
            }

            ////

            Row {
                anchors.left: parent.left
                anchors.right: parent.right
                spacing: 24

                ItemBadge {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 128
                    legend: "license"
                    text: "LGPL 3"
                    onClicked: Qt.openUrlExternally("https://www.gnu.org/licenses/lgpl-3.0.html")
                }

                ItemCodec {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "H.264"
                    color: Theme.colorForeground
                }
            }

            ////

            Row {
                anchors.left: parent.left
                anchors.right: parent.right
                spacing: 24

                Row {
                    width: 400
                    height: 48
                    spacing: 16

                    ItemImageButton {
                        width: 48
                        height: 48
                        source: "qrc:/assets/icons_material/baseline-accessibility-24px.svg"
                        background: true
                        highlightMode: "color"
                    }
                    ItemImageButton {
                        width: 48
                        height: 48
                        source: "qrc:/assets/icons_material/baseline-accessibility-24px.svg"
                        background: false
                        highlightMode: "circle"
                    }
                    ItemImageButtonTooltip {
                        width: 48
                        height: 48
                        source: "qrc:/assets/icons_material/baseline-accessibility-24px.svg"
                        highlightMode: "color"
                        highlightColor: Theme.colorError

                        tooltipText: "this one has a tooltip!"
                    }
                }

                Row {
                    width: 400
                    height: 48
                    spacing: 16

                    ItemImageButton {
                        source: "qrc:/assets/icons_material/baseline-accessibility-24px.svg"
                        highlightMode: "color"
                    }
                    ItemImageButton {
                        source: "qrc:/assets/icons_material/baseline-accessibility-24px.svg"
                        background: true
                        highlightMode: "circle"
                    }
                    ItemImageButtonTooltip {
                        source: "qrc:/assets/icons_material/baseline-accessibility-24px.svg"
                        highlightMode: "color"
                        highlightColor: Theme.colorError

                        tooltipText: "another tooltip!"
                    }
                }
            }

            ////

            Row {
                anchors.left: parent.left
                anchors.right: parent.right
                spacing: 24

                ButtonImage {
                    anchors.verticalCenter: parent.verticalCenter

                    text: "ButtonImage"
                    source: "qrc:/assets/icons_material/baseline-accessibility-24px.svg"
                }

                ButtonImageThemed {
                    anchors.verticalCenter: parent.verticalCenter

                    text: "ButtonImageThemed"
                    source: "qrc:/assets/icons_material/baseline-accessibility-24px.svg"
                }
            }

            ////

            Row {
                anchors.left: parent.left
                anchors.right: parent.right
                spacing: 24

                ButtonWireframe {
                    anchors.verticalCenter: parent.verticalCenter
                    fullColor: true
                    text: "ButtonWireframe"
                }

                ButtonWireframeImage {
                    anchors.verticalCenter: parent.verticalCenter
                    fullColor: true
                    text: "ButtonWireframeImage"
                    source: "qrc:/assets/icons_material/baseline-accessibility-24px.svg"
                }

                ButtonWireframe {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "ButtonWireframe"
                }

                ButtonWireframeImage {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "ButtonWireframeImage"
                    source: "qrc:/assets/icons_material/baseline-accessibility-24px.svg"
                }
            }

            ////

            Rectangle {
                id: menu
                width: 400
                height: 40
                color: Theme.colorHeader

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: 24
                    anchors.rightMargin: 24

                    ItemMenuButton {
                        id: itemMenuButton1
                        anchors.verticalCenter: parent.verticalCenter

                        menuText: "menu1"
                        source: "qrc:/assets/icons_material/baseline-accessibility-24px.svg"

                        onClicked: {
                            itemMenuButton1.selected = true
                            itemMenuButton2.selected = false
                        }
                    }

                    ItemMenuButton {
                        id: itemMenuButton2
                        anchors.verticalCenter: parent.verticalCenter

                        menuText: "menu2"
                        source: "qrc:/assets/icons_material/baseline-accessibility-24px.svg"

                        onClicked: {
                            itemMenuButton1.selected = false
                            itemMenuButton2.selected = true
                        }
                    }
                }
            }

            ////

            Row {
                anchors.left: parent.left
                anchors.right: parent.right
                spacing: 24

                ItemLilMenu {
                    anchors.verticalCenter: parent.verticalCenter
                    width: rowLilMenuImg.width
                    height: 40

                    Row {
                        id: rowLilMenuImg
                        height: parent.height

                        ItemLilMenuButton {
                            id: lilmenu11
                            height: parent.height

                            source: "qrc:/assets/icons_material/baseline-date_range-24px.svg"
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

                            source: "qrc:/assets/icons_material/baseline-date_range-24px.svg"
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

                            source: "qrc:/assets/icons_material/baseline-date_range-24px.svg"
                            sourceSize: 26
                            onClicked: {
                                lilmenu11.selected = false
                                lilmenu22.selected = false
                                lilmenu33.selected = true
                            }
                        }
                    }
                }

                ItemLilMenu {
                    anchors.verticalCenter: parent.verticalCenter
                    width: rowLilMenuTxt.width

                    Row {
                        id: rowLilMenuTxt
                        height: parent.height

                        ItemLilMenuButton {
                            id: lilmenu1

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

                            text: "16/9"
                            onClicked: {
                                lilmenu1.selected = false
                                lilmenu2.selected = true
                                lilmenu3.selected = false
                            }
                        }
                        ItemLilMenuButton {
                            id: lilmenu3

                            text: "21/9"
                            onClicked: {
                                lilmenu1.selected = false
                                lilmenu2.selected = false
                                lilmenu3.selected = true
                            }
                        }
                    }
                }
            }

            ////

            Row {
                anchors.left: parent.left
                anchors.right: parent.right
                spacing: 24
                /*
                SliderArrow {
                    anchors.verticalCenter: parent.verticalCenter
                    value: 0.75
                    stepSize: 0.1
                }*/
                RangeSliderArrow {
                    anchors.verticalCenter: parent.verticalCenter
                    second.value: 0.75
                    first.value: 0.25
                    stepSize: 0.1
                }
            }
        }

        ////////////////////////////////////////////////////////////////////////

        Column {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 24
            spacing: 24

            Rectangle {
                height: 1
                color: Theme.colorSeparator
                anchors.right: parent.right
                anchors.left: parent.left
            }

            Column {
                id: rectangleQtQuickThemed
                anchors.left: parent.left
                anchors.leftMargin: 24
                anchors.right: parent.right
                anchors.rightMargin: 24
                spacing: 16

                Row {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    spacing: 24

                    ProgressBarThemed {
                        anchors.verticalCenter: parent.verticalCenter
                        value: 0.5
                    }

                    SliderThemed {
                        anchors.verticalCenter: parent.verticalCenter
                        value: 0.5
                    }

                    RangeSliderThemed {
                        anchors.verticalCenter: parent.verticalCenter
                        second.value: 0.75
                        first.value: 0.25
                    }

                    CheckBoxThemed {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Check Box"
                    }

                    RadioButtonThemed {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "RadioButton"
                    }

                    SwitchThemedMobile {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Switch"
                        checked: true
                    }

                    SwitchThemedDesktop {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Switch"
                        checked: true
                    }
                }

                Row {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    spacing: 24

                    TextFieldThemed {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 256
                    }

                    ComboBoxThemed {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 256

                        model: ListModel {
                            ListElement { text: "combobox item1"; }
                            ListElement { text: "combobox item2"; }
                        }
                    }

                    ButtonThemed {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Button"
                    }

                    RoundButton {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "+"
                    }

                    SpinBoxThemed {
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }

            ////////////////////////

            Rectangle {
                height: 1
                color: Theme.colorSeparator
                anchors.left: parent.left
                anchors.right: parent.right
            }

            ////////////////////////

            Column {
                id: rectangleQtQuick
                anchors.left: parent.left
                anchors.leftMargin: 24
                anchors.right: parent.right
                anchors.rightMargin: 24
                spacing: 16

                Row {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    spacing: 24

                    ProgressBar {
                        anchors.verticalCenter: parent.verticalCenter
                        value: 0.5
                    }

                    Slider {
                        anchors.verticalCenter: parent.verticalCenter
                        value: 0.5
                    }

                    RangeSlider {
                        anchors.verticalCenter: parent.verticalCenter
                        first.value: 0.25
                        second.value: 0.75
                    }

                    CheckBox {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Check Box"
                    }

                    RadioButton {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "RadioButton"
                    }

                    Switch {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Switch"
                        checked: true
                    }
                }

                Row {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    spacing: 24

                    TextField {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 256
                        text: "Text Field"
                    }

                    ComboBox {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 256

                        model: ListModel {
                            ListElement { text: "combobox item1"; }
                            ListElement { text: "combobox item2"; }
                        }
                    }

                    Button {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Button"
                    }

                    RoundButton {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "+"
                    }

                    SpinBox {
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }
        }
    }
}
