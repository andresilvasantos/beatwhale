import QtQuick 2.0
import BeatWhaleAPI 1.0

Rectangle {
    color: "#333333"
    radius: 5

    property string title
    property string question
    property string textColor: "white"
    property string fontFamily: "Arrial Narrow"

    signal accepted()
    signal rejected()

    Text {
        id: popupTitle
        text: title
        color: textColor
        font.family: fontFamily
        font.pixelSize: 18

        anchors {
            top: parent.top
            topMargin: 5
            left: parent.left
            leftMargin: 10
        }
    }

    Text {
        text: question
        color: textColor
        font.family: fontFamily

        anchors {
            top: popupTitle.bottom
            topMargin: 15
            left: popupTitle.left
        }
    }

    BWButton {
        id: popupButtonYes
        width: 50
        height: 30
        color: "#656565"
        hoverColor: "#D90F30"
        selectedColor: "#F24261"
        radius: 5

        anchors {
            right: popupButtonNo.left
            rightMargin: 20
            bottom: parent.bottom
            bottomMargin: 10
        }

        onHovered: {
            ApplicationManager.setCursor(ApplicationManager.CURSORTYPE_BUTTON)
        }

        onHoveredOut: {
            ApplicationManager.setCursor(ApplicationManager.CURSORTYPE_NORMAL)
        }

        onClicked: {
            accepted()
        }

        Text {
            text: "Yes"
            color: textColor
            font.pixelSize: 13
            font.family: fontFamily

            anchors.centerIn: parent
        }
    }

    BWButton {
        id: popupButtonNo
        width: 50
        height: 30
        color: "#656565"
        hoverColor: "#545454"
        selectedColor: "#898989"
        radius: 5

        anchors {
            right: parent.right
            rightMargin: 20
            bottom: parent.bottom
            bottomMargin: 10
        }

        onClicked: {
            rejected()
        }

        Text {
            text: "No"
            color: textColor
            font.pixelSize: 13
            font.family: fontFamily

            anchors.centerIn: parent
        }
    }
}
