import QtQuick 2.0
import BeatWhaleAPI 1.0

Rectangle {
    id: rootRect
    height: opened ? optionsColumn.height : 0
    color: "white"
    clip: true

    Behavior on height {
        NumberAnimation {duration: 200; easing.type: Easing.OutSine}
    }

    property var menuModel
    property bool opened: false

    signal optionClicked(int index)

    Column {
        id: optionsColumn
        width: parent.width
        height: menuModel.count * 30

        Repeater {
            model: menuModel
            delegate: BWButton {
                id: button
                width: rootRect.width
                height: 30
                color: "transparent"
                hoverColor: danger ? "#50D90F30" : "#5000addc"
                selectedColor: danger ? "#F24261" : "#00addc"
                enabled: active

                onClicked: {
                    if(active) optionClicked(index)
                }

                Text {
                    id: buttonText
                    text: name
                    color: button.checked ? "white" : "#61666a"
                    font.pixelSize: 13
                    font.family: "Open Sans"
                    horizontalAlignment: Text.AlignLeft
                    opacity: active ? 1 : .2

                    anchors {
                        left: parent.left
                        leftMargin: 10
                        verticalCenter: parent.verticalCenter
                    }
                }
            }
        }
    }
}
