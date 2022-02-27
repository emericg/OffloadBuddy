import QtQuick 2.15
import ThemeEngine 1.0

Row {
    id: fileWarning
    anchors.left: parent.left
    anchors.leftMargin: 8
    anchors.right: parent.right
    anchors.rightMargin: 8

    height: 48
    spacing: 12
    visible: false

    function setError() {
        imgFileWarning.color = Theme.colorError
        txtFileWarning.text = qsTr("Warning, this file will overwrite this shot source file!")
        visible = true
    }
    function setWarning() {
        imgFileWarning.color = Theme.colorWarning
        txtFileWarning.text = qsTr("Warning, this file exists already and will be overwritten...")
        visible = true
    }
    function setOK() {
        visible = false
    }

    IconSvg {
        id: imgFileWarning
        width: 28
        height: 28
        anchors.verticalCenter: parent.verticalCenter

        color: Theme.colorWarning
        source: "qrc:/assets/icons_material/baseline-warning-24px.svg"
    }

    Text {
        id: txtFileWarning
        anchors.verticalCenter: parent.verticalCenter
        color: Theme.colorText
        font.bold: false
        font.pixelSize: Theme.fontSizeContent
        wrapMode: Text.WordWrap
    }
}
