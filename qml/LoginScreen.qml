import QtQuick 2.2
import QtQuick.Window 2.0
import QtQuick.Layouts 1.1
import BeatWhaleAPI 1.0
import "qrc:/components/qml/"

Rectangle {
    id: rootRect
    anchors.fill: parent
    color: "#eceded"
    focus: true

    property int formCloseHeight: 190
    property int formOpenHeight: 450
    property int formSemiOpenHeight: 230
    property bool waitingInterface: false

    signal loggedIn()

    MouseArea {
        width: parent.width
        height: 40

        onPressed: {
            ApplicationManager.setGrabbingWindowMoveHandle(true)
        }

        onReleased: {
            ApplicationManager.setGrabbingWindowMoveHandle(false)
        }
    }

    Rectangle {
        id: backgroundFormRect
        width: 300
        height: formOpenHeight
        color: "white"
        radius: 20
        clip: true

        anchors.centerIn: parent

        Image {
            id: logoImage
            source: "qrc:/images/logo"
            fillMode: Image.PreserveAspectFit
            width: parent.width
            height: 175

            anchors {
                top: parent.top
                topMargin: 5
                horizontalCenter: parent.horizontalCenter
            }
        }

        TOPSwitch {
            id: createAccountSwitch
            height: 16
            on: false
            labelText: "create account?"
            labelColor: "#929292"
            labelFont: "Open Sans"
            labelPixelSize: 11
            labelRightSide: false
            opacity: waitingInterface ?  0 : 1

            fillColor: "#00addc"
            borderColor: "white"
            knobBorderWidth: 1
            backgroundColor: "#666666"

            anchors {
                top: logoImage.bottom
                horizontalCenter: parent.horizontalCenter
            }

            Behavior on opacity {
                NumberAnimation { duration: 200; easing.type: Easing.OutSine }
            }

            onOnChanged: {
                if(on) formsLoader.source = "RegisterComponent.qml"
                else formsLoader.source = "LoginComponent.qml"
            }
        }

        Loader {
            id: formsLoader
            source: "LoginComponent.qml"

            width: parent.width * 0.9
            height: childrenRect.height

            anchors {
                horizontalCenter: parent.horizontalCenter
                top: createAccountSwitch.bottom
                topMargin: 20
            }
        }
    }
}

