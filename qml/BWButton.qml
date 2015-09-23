import QtQuick 2.2
import BeatWhaleAPI 1.0

Rectangle {
    id: buttonRectangle

    signal clicked
    signal doubleClicked
    signal hovered
    signal hoveredOut

    property string text
    property color hoverColor
    property color selectedColor
    property bool checkable: false
    property bool checked: false

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true

        onEntered: {
            if(!checked) buttonRectangle.state = "hovered"
            ApplicationManager.setCursor(ApplicationManager.CURSORTYPE_BUTTON)
            hovered()
        }

        onExited: {
            if(!checkable || !checked) buttonRectangle.state = "default"
            ApplicationManager.setCursor(ApplicationManager.CURSORTYPE_NORMAL)
            hoveredOut()
        }

        onClicked: {
            buttonRectangle.state = "pressed"
            buttonRectangle.clicked()

            if(!checkable) stateTimer.start()
        }

        onDoubleClicked: {
            buttonRectangle.doubleClicked()
        }
    }

    Text {
        color: "#fff"
        anchors.centerIn: buttonRectangle
        font.pixelSize: 12
        text: buttonRectangle.text
    }

    states: [
        /*State {
                name: "default"
                PropertyChanges { target: buttonRectangle; color: container.color }
            }
            ,*/State {
            name: "hovered"
            PropertyChanges { target: buttonRectangle; color: hoverColor }
        }
        ,State {
            name: "pressed"
            PropertyChanges { target: buttonRectangle; color: selectedColor }
        }
    ]

    Timer {
        id: stateTimer
        interval: 200;
        repeat: false
        onTriggered: buttonRectangle.state = "default"
    }

    transitions: Transition {
        ColorAnimation { properties: "color"; duration: 200; easing.type: Easing.InOutQuad }
    }

    onCheckedChanged: {
        if(checked)
        {
            buttonRectangle.state = "pressed"
        }
        else
        {
            buttonRectangle.state = "default"
        }
    }
}
