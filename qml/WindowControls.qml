import QtQuick 2.2

Row {
    width: childrenRect.width

    signal maximize()
    signal minimize()
    signal close()

    Rectangle {
        width: 13
        height: 13
        color: hovered ? "#76d90b" : "white"
        border.color: hovered ? "#aaaaaa" : "#cccccc"
        border.width: 1
        radius: width * .5

        anchors {
            verticalCenter: parent.verticalCenter
        }

        property bool hovered: false

        Behavior on color {
            ColorAnimation { duration: 200; easing.type: Easing.OutSine }
        }

        Behavior on border.color {
            ColorAnimation { duration: 200; easing.type: Easing.OutSine }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true

            onEntered: {
                parent.hovered = true
            }

            onExited: {
                parent.hovered = false
            }

            onClicked: {
                maximize()
            }
        }
    }

    Rectangle {
        width: 13
        height: 13
        color: hovered ? "#ffe50b" : "white"
        border.color: hovered ? "#aaaaaa" : "#cccccc"
        border.width: 1
        radius: width * .5

        anchors {
            verticalCenter: parent.verticalCenter
        }

        property bool hovered: false

        Behavior on color {
            ColorAnimation { duration: 200; easing.type: Easing.OutSine }
        }

        Behavior on border.color {
            ColorAnimation { duration: 200; easing.type: Easing.OutSine }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true

            onEntered: {
                parent.hovered = true
            }

            onExited: {
                parent.hovered = false
            }

            onClicked: {
                minimize()
            }
        }
    }

    Rectangle {
        width: 13
        height: 13
        color: hovered ? "#fc4e43" : "white"
        border.color: hovered ? "#aaaaaa" : "#cccccc"
        border.width: 1
        radius: width * .5

        anchors {
            verticalCenter: parent.verticalCenter
        }

        property bool hovered: false

        Behavior on color {
            ColorAnimation { duration: 200; easing.type: Easing.OutSine }
        }

        Behavior on border.color {
            ColorAnimation { duration: 200; easing.type: Easing.OutSine }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true

            onEntered: {
                parent.hovered = true
            }

            onExited: {
                parent.hovered = false
            }

            onClicked: {
                close()
            }
        }
    }
}
