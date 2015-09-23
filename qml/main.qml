import QtQuick 2.2
import QtQuick.Controls 1.1
import QtQuick.Window 2.0
import BeatWhaleAPI 1.0

ApplicationWindow {
    id: mainWindow
    title: qsTr("BeatWhale vBeta (" + ApplicationManager.version() + ")")
    width: 1024
    height: 600
    minimumWidth: 1024
    minimumHeight: 600
    color: "#cccccc"

    Loader{
        id: loaderApplication
        width: parent.width
        height: parent.height
    }

    Loader{
        id: loaderLogin
        focus: true
        width: parent.width
        height: parent.height
        source: "LoginScreen.qml"
    }

    Rectangle {
        width: 25
        height: width
        rotation: 45
        color: "#cccccc"
        opacity: .5
        visible: !ApplicationManager.maximized && !ApplicationManager.fullscreen && ApplicationManager.windowControlButtonsEnabled

        anchors {
            right: parent.right
            rightMargin: -13
            bottom: parent.bottom
            bottomMargin: -13
        }

        Behavior on opacity {
            NumberAnimation { duration: 200; easing.type: Easing.OutSine }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true

            onEntered: {
                parent.opacity = 1
            }

            onExited: {
                parent.opacity = .5
            }

            onPressed: {
                ApplicationManager.setGrabbingWindowResizeHandle(true)
            }

            onReleased: {
                ApplicationManager.setGrabbingWindowResizeHandle(false)
            }
        }
    }

    Rectangle {
        color: "transparent"
        border.color: "#cccccc"
        border.width: 1
        anchors.fill: parent
        visible: !ApplicationManager.fullscreen
    }

    WindowControls {
        id: windowControls
        height: 20
        spacing: 10
        visible: !ApplicationManager.fullscreen && ApplicationManager.windowControlButtonsEnabled

        anchors {
            right: parent.right
            rightMargin: 20
            top: parent.top
            topMargin: 20
        }

        onMaximize: ApplicationManager.showMaximized()
        onMinimize: ApplicationManager.showMinimized()
        onClose: ApplicationManager.quit()
    }

    Connections {
        id: connectionsLoginScreen
        target: loaderLogin.item
        ignoreUnknownSignals: true

        onLoggedIn: {
            loaderApplication.source = "ApplicationView.qml"
            loaderApplication.focus = true
            loginToApplicationAnim.start()
        }
    }

    Connections {
        id: connectionsApplication
        target: loaderApplication.item
        ignoreUnknownSignals: true

        onLoggedOut: {
            loaderLogin.source = "LoginScreen.qml"
            loaderLogin.focus = true
            applicationToLoginAnim.start()
        }
    }

    NumberAnimation {
        id: loginToApplicationAnim
        target: loaderLogin
        property: "y"
        to: -mainWindow.height
        duration: 400
        easing.type: Easing.InCirc

        onStopped: loaderLogin.source = ""
    }

    NumberAnimation {
        id: applicationToLoginAnim
        target: loaderLogin
        property: "y"
        from: -mainWindow.height
        to: 0
        duration: 400
        easing.type: Easing.OutCirc

        onStopped: loaderApplication.source = ""
    }
}
