import QtQuick 2.12
import QtQuick.Controls 2.12

import ThemeEngine 1.0
import com.offloadbuddy.shared 1.0
import "qrc:/js/UtilsString.js" as UtilsString

Item {
    id: contentDetails
    anchors.fill: parent

    // CONTENT /////////////////////////////////////////////////////////////////

    Rectangle {
        id: infosFiles
        width: 640
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.bottom: parent.bottom

        color: Theme.colorForeground

        Text {
            id: labelFileCount
            anchors.top: parent.top
            anchors.topMargin: 24
            anchors.left: parent.left
            anchors.leftMargin: 24
            anchors.right: parent.right
            anchors.rightMargin: 24

            text: qsTr("File(s):")
            horizontalAlignment: Text.AlignLeft
            verticalAlignment: Text.AlignVCenter
            color: Theme.colorText
            font.bold: true
            font.pixelSize: Theme.fontSizeContent
        }

        Text {
            id: textFileList
            anchors.top: labelFileCount.bottom
            anchors.topMargin: 16
            anchors.left: parent.left
            anchors.leftMargin: 24
            anchors.right: parent.right
            anchors.rightMargin: 24
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 24

            text: shot.fileList
            clip: true
            color: Theme.colorText
            font.pixelSize: Theme.fontSizeContentSmall
        }
    }

}
