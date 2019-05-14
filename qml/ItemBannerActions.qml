import QtQuick 2.9
import QtQuick.Controls 2.2

import com.offloadbuddy.theme 1.0
import "UtilsString.js" as UtilsString

Rectangle {
    id: menuSelection
    height: 56
    anchors.right: parent.right
    anchors.rightMargin: 0
    anchors.left: parent.left
    anchors.leftMargin: 0
    
    color: Theme.colorPrimary
    
    Row {
        id: row1
        spacing: 16
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 0
        anchors.top: parent.top
        anchors.topMargin: 0
        anchors.left: parent.left
        anchors.leftMargin: 16
        
        ButtonImageThemed {
            id: buttonOffload
            anchors.verticalCenter: parent.verticalCenter
            
            text: qsTr("Offload")
            source: "qrc:/icons_material/baseline-save_alt-24px.svg"
        }
        ButtonImageThemed {
            id: buttonMerge
            anchors.verticalCenter: parent.verticalCenter
            
            text: qsTr("Merge")
            source: "qrc:/icons_material/baseline-save_alt-24px.svg"
        }
        ButtonImageThemed {
            //id: button
            anchors.verticalCenter: parent.verticalCenter
            
            text: qsTr("Extract metadatas")
            source: "qrc:/icons_material/baseline-insert_chart_outlined-24px.svg"
        }
        ButtonImageThemed {
            id: buttonDelete
            anchors.verticalCenter: parent.verticalCenter
            
            text: qsTr("Delete")
            source: "qrc:/icons_material/baseline-delete-24px.svg"
        }
    }
    
    Text {
        id: elementCounter
        anchors.right: parent.right
        anchors.rightMargin: 56
        anchors.verticalCenter: parent.verticalCenter
        
        text: qsTr("%1 elements selected").arg(mediaGrid.selectionCount)
        color: "white"
        font.pixelSize: 16
    }
    ItemImageButton {
        id: rectangleClear
        anchors.right: parent.right
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        
        source: "qrc:/icons_material/baseline-close-24px.svg"
        iconColor: "white"
        onClicked: mediaGrid.exitSelectionMode()
    }
}
