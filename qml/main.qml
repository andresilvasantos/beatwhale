import QtQuick 2.2
import QtQuick.Controls 1.1
import QtQuick.Window 2.0

ApplicationWindow {
    id: mainWindow
    title: qsTr("BeatWhale vAlpha")
    width: Screen.width / 2
    height: Screen.height / 2
    minimumWidth: 800
    minimumHeight: 600
    color: "#111111"

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
