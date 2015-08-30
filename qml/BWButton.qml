import QtQuick 2.2

Rectangle {
    id: buttonRectangle

    signal clicked
    signal hovered
    signal hoveredOut

    property string text
    property color hoverColor
    property color selectedColor
    property bool checkable: false
    property bool checked: false

    MouseArea {
        id: mouseArea;
        anchors.fill: parent
        hoverEnabled: true

        onExited: {
            if(!checkable || !checked) buttonRectangle.state = "default"
            hoveredOut()
        }

        onEntered: {
            if(!checked) buttonRectangle.state = "hovered"
            hovered()
        }

        onClicked: {
            buttonRectangle.state = "pressed"
            buttonRectangle.clicked()

            if(!checkable) stateTimer.start()
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
