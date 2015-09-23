import QtQuick 2.0

Item {

    property string displayText

    Rectangle {
        color: "white"
        opacity: .9
        width: tooltipText.contentWidth + 10
        height: tooltipText.contentHeight + 10
        radius: 5
        border.width: .5
        border.color: "#50cccccc"
    }

    Text {
        id: tooltipText
        text: displayText
        font.pixelSize: 12
        font.family: "Open Sans"
        color: "#333333"
        wrapMode: Text.WordWrap

        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: 5
        }
    }
}
