import QtQuick 2.2
import QtQuick.Layouts 1.1
import BeatWhaleAPI 1.0
import "qrc:/components/qml/"

Rectangle {
    id: loginComponentRect
    anchors.fill: parent

    Component {
        id: loginFormComponent

        Item {
            function loggingIn() {
                if(usernameInput.text.length == 0 || usernameInput.text == "username" ||
                        passwordInput.text.length == 0 || passwordInput.text == "password") return;

                UserManager.login(usernameInput.text, passwordInput.text)

                state = "LOGGING_IN"
                waitingInterface = true
            }

            Rectangle {
                id: loginForm
                width: parent.width * 0.9
                height: childrenRect.height
                color: "#eceded"
                radius: 5
                border.color: "#cccccc"
                border.width: 1

                anchors {
                    horizontalCenter: parent.horizontalCenter
                }

                ColumnLayout {
                    width: parent.width
                    spacing: 0

                    Item {
                        width: parent.width
                        height: 45

                        Image {
                            id: imageUserIcon
                            source: "qrc:/icons/user"
                            width: 20
                            height: width
                            fillMode: Image.PreserveAspectFit
                            opacity: .5

                            anchors {
                                verticalCenter: parent.verticalCenter
                                left: parent.left
                                leftMargin: 10
                            }
                        }

                        TextInput {
                            id: usernameInput
                            height: parent.height * .5 - 1
                            //font.bold: true
                            font.pixelSize: 14
                            font.family: "Open Sans"
                            color: "#666666"
                            text: "username"
                            opacity: .5
                            selectByMouse: true
                            selectionColor: "#333333"
                            clip: true

                            anchors {
                                verticalCenter: parent.verticalCenter
                                left: imageUserIcon.right
                                leftMargin: 10
                                right: parent.right
                                rightMargin: 5
                            }

                            KeyNavigation.tab: passwordInput

                            onFocusChanged: {
                                if(!focus && text.length == 0)
                                {
                                    text = "username"
                                    opacity = .5
                                }
                                else if(focus && text == "username")
                                {
                                    text = ""
                                    opacity = 1
                                }
                            }
                        }
                    }

                    Rectangle {
                        id: borderSeparator
                        width: parent.width
                        height: 1
                        color: "#cccccc"

                        anchors.centerIn: parent
                    }

                    Item {
                        width: parent.width
                        height: 45

                        Image {
                            id: imagePasswordIcon
                            source: "qrc:/icons/lock"
                            width: 20
                            height: width
                            fillMode: Image.PreserveAspectFit
                            opacity: .5

                            anchors {
                                verticalCenter: parent.verticalCenter
                                left: parent.left
                                leftMargin: 10
                            }
                        }

                        TextInput {
                            id: passwordInput
                            height: parent.height * .5 - 1
                            //font.bold: true
                            font.pixelSize: 14
                            color: "#666666"
                            text: "password"
                            opacity: .5
                            selectByMouse: true
                            selectionColor: "#333333"
                            clip: true
                            font.family: "Open Sans"

                            anchors {
                                verticalCenter: parent.verticalCenter
                                left: imagePasswordIcon.right
                                leftMargin: 10
                                right: parent.right
                                rightMargin: 5
                            }

                            KeyNavigation.tab: usernameInput

                            onFocusChanged: {
                                if(!focus && text.length == 0)
                                {
                                    text = "password"
                                    font.family = "Open Sans"
                                    echoMode = TextInput.Normal
                                    opacity = .5
                                }
                                else if(focus && text == "password" && echoMode == TextInput.Normal)
                                {
                                    text = ""
                                    font.family = "Arial Narrow"
                                    echoMode = TextInput.Password
                                    opacity = 1
                                }
                            }
                        }
                    }
                }
            }

            TOPSwitch {
                id: rememberSwitch
                height: 16
                on: UserManager.rememberCredentials()
                labelText: "remember"
                labelColor: "#929292"
                labelFont: "Open Sans"
                labelPixelSize: 11
                labelRightSide: false

                fillColor: "#00addc"
                borderColor: "white"
                knobBorderWidth: 1
                backgroundColor: "#666666"

                anchors {
                    left: parent.left
                    leftMargin: parent.width * 0.05
                    top: loginForm.bottom
                    topMargin: 18
                }
            }

            Text {
                id: forgotDetails
                text: "forgot details?"
                color: "#929292"
                font.family: "Open Sans"

                anchors {
                    right: parent.right
                    rightMargin: parent.width * 0.05
                    top: rememberSwitch.top
                }

                MouseArea {
                    anchors.fill: parent

                    onClicked: {
                        loginComponentLoader.sourceComponent = forgotDetailsComponent
                    }
                }
            }

            Text {
                id: statusText
                text: ""
                color: "#D90F30"
                width: parent.width - 30
                wrapMode: Text.WordWrap
                font.pixelSize: 12
                font.family: "Open Sans"
                horizontalAlignment: Text.AlignHCenter

                anchors {
                    horizontalCenter: parent.horizontalCenter
                    bottom: loginButton.top
                    bottomMargin: 5
                }
            }

            TOPButton {
                id: loginButton
                width: parent.width * 0.9
                height: 45
                color: "#00addc"
                hoverColor: "#0093bb"
                selectedColor: "#1fb3db"
                radius: 5

                anchors {
                    horizontalCenter: parent.horizontalCenter
                    top: forgotDetails.bottom
                    topMargin: 50
                }

                Text {
                    text: "LOGIN"
                    color: "white"
                    font.bold: true
                    font.pixelSize: 16
                    font.family: "Open Sans"
                    anchors.centerIn: loginButton
                }

                onClicked: {
                    loggingIn()
                }
            }

            states: [
                State {
                    name: "LOGGED_OFF"
                    PropertyChanges { target: loginForm; opacity: 1 }
                    PropertyChanges { target: forgotDetails; opacity: 1 }
                    PropertyChanges { target: loginButton; opacity: 1 }
                }
                ,State {
                    name: "LOGGING_IN"
                    PropertyChanges { target: loginForm; opacity: 0 }
                    PropertyChanges { target: forgotDetails; opacity: 0 }
                    PropertyChanges { target: loginButton; opacity: 0 }
                    PropertyChanges { target: backgroundFormRect; height: formCloseHeight }
                }
                ,State {
                    name: "LOGGED_IN"
                }
            ]

            transitions: Transition {
                NumberAnimation { properties: "height"; duration: 300; easing.type: Easing.InOutQuad }
                NumberAnimation { target: loginForm; properties: "opacity"; duration: 200; easing.type: Easing.OutSine }
                NumberAnimation { target: forgotDetails; properties: "opacity"; duration: 200; easing.type: Easing.OutSine }
                NumberAnimation { target: loginButton; properties: "opacity"; duration: 200; easing.type: Easing.OutSine }
            }

            Keys.onPressed: {
                if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return) {
                    loggingIn()
                    event.accepted = true;
                }
            }

            Connections {
                target: UserManager

                onLoginFailed: {
                    statusText.text = message
                    state = "LOGGED_OFF"
                    waitingInterface = false
                }

                onLoginSuccess: {
                    UserManager.setRememberCredentials(rememberSwitch.on)
                    UserManager.startListeningToChanges()
                    loggedIn()
                }
            }

            Component.onCompleted: {
                state = "LOGGED_OFF"
                waitingInterface = false

                if(UserManager.rememberCredentials()) {
                    var username = UserManager.storedUsername()
                    if(username.length) {
                        usernameInput.text = username
                        usernameInput.opacity = 1
                    }

                    var password = UserManager.storedPassword()
                    if(password.length) {
                        passwordInput.text = password
                        passwordInput.font.family = "Arial Narrow"
                        passwordInput.echoMode = TextInput.Password
                        passwordInput.opacity = 1
                    }
                }
            }
        }
    }

    Component {
        id: forgotDetailsComponent

        Item {
            function sendEmailInformation() {
                if(emailInput.text.length == 0 || emailInput.text == "email") return;

                var indexAt = emailInput.text.indexOf("@")
                var indexDot = emailInput.text.lastIndexOf(".")
                var emailLength = emailInput.text.length

                if(indexAt == -1 || indexDot == -1 || indexAt > indexDot || emailLength - indexDot < 2 || indexDot - indexAt < 2) {
                    statusText.text = "Invalid email entered."
                    return;
                }

                state = "SENDING_EMAIL"
                waitingInterface = true
                UserManager.forgotDetails(emailInput.text)
            }

            Text {
                id: infoText
                text: "Tell us your BeatWhale email\nand we'll send you an email with your login information."
                color: "#333333"
                width: parent.width - 30
                wrapMode: Text.WordWrap
                font.pixelSize: 12
                font.family: "Open Sans"
                horizontalAlignment: Text.AlignHCenter

                anchors {
                    horizontalCenter: parent.horizontalCenter
                }
            }

            Rectangle {
                id: emailInputHolder
                width: parent.width * 0.9
                height: 45
                color: "#eceded"
                radius: 5
                border.color: "#cccccc"
                border.width: 1

                anchors {
                    horizontalCenter: parent.horizontalCenter
                    top: infoText.bottom
                    topMargin: 10
                }

                Image {
                    id: imageEmailIcon
                    source: "qrc:/icons/email"
                    width: 20
                    height: width
                    fillMode: Image.PreserveAspectFit
                    opacity: .5

                    anchors {
                        verticalCenter: parent.verticalCenter
                        left: parent.left
                        leftMargin: 10
                    }
                }

                TextInput {
                    id: emailInput
                    height: parent.height * .5 - 1
                    font.pixelSize: 14
                    font.family: "Open Sans"
                    color: "#666666"
                    opacity: .5
                    text: "email"
                    selectByMouse: true
                    selectionColor: "#333333"
                    clip: true
                    inputMethodHints: Qt.ImhEmailCharactersOnly
                    validator: RegExpValidator { regExp:/^([\w-]+(?:\.[\w-]+)*)@((?:[\w-]+\.)*\w[\w-]{0,66})\.([a-z]{2,6}(?:\.[a-z]{2})?)$/i }

                    anchors {
                        verticalCenter: parent.verticalCenter
                        left: imageEmailIcon.right
                        leftMargin: 10
                        right: parent.right
                        rightMargin: 5
                    }

                    onFocusChanged: {
                        if(!focus && text.length == 0)
                        {
                            text = "email"
                            opacity = .5
                        }
                        else if(focus && text == "email" && echoMode == TextInput.Normal)
                        {
                            text = ""
                            opacity = 1
                        }
                    }
                }
            }

            Text {
                id: statusText
                text: ""
                color: "#D90F30"
                width: parent.width - 30
                wrapMode: Text.WordWrap
                font.pixelSize: 12
                font.family: "Open Sans"
                horizontalAlignment: Text.AlignHCenter

                anchors {
                    horizontalCenter: parent.horizontalCenter
                    bottom: sendEmailButton.top
                    bottomMargin: 5
                }
            }

            TOPButton {
                id: sendEmailButton
                width: parent.width * 0.42
                height: 45
                color: "#00addc"
                hoverColor: "#0093bb"
                selectedColor: "#1fb3db"
                radius: 5

                anchors {
                    right: emailInputHolder.right
                    top: emailInputHolder.bottom
                    topMargin: 68
                }

                Text {
                    text: "SEND EMAIL"
                    color: "white"
                    font.bold: true
                    font.pixelSize: 16
                    font.family: "Open Sans"
                    anchors.centerIn: parent
                }

                onClicked: {
                    sendEmailInformation()
                }
            }

            TOPButton {
                id: backButton
                width: parent.width * 0.4
                height: 45
                color: "#00addc"
                hoverColor: "#0093bb"
                selectedColor: "#1fb3db"
                radius: 5

                anchors {
                    left: emailInputHolder.left
                    top: emailInputHolder.bottom
                    topMargin: 68
                }

                Text {
                    text: "BACK"
                    color: "white"
                    font.bold: true
                    font.pixelSize: 16
                    font.family: "Open Sans"
                    anchors.centerIn: parent
                }

                onClicked: {
                    loginComponentLoader.sourceComponent = loginFormComponent
                }
            }

            states: [
                State {
                    name: "WAITING_USER_DATA"
                    PropertyChanges { target: infoText; opacity: 1 }
                    PropertyChanges { target: emailInputHolder; opacity: 1 }
                    PropertyChanges { target: sendEmailButton; opacity: 1 }
                    PropertyChanges { target: backButton; opacity: 1 }
                }
                ,State {
                    name: "SENDING_EMAIL"
                    PropertyChanges { target: infoText; opacity: 0 }
                    PropertyChanges { target: emailInputHolder; opacity: 0 }
                    PropertyChanges { target: sendEmailButton; opacity: 0 }
                    PropertyChanges { target: backButton; opacity: 0 }
                    PropertyChanges { target: backgroundFormRect; height: formCloseHeight }
                }
            ]

            transitions: Transition {
                NumberAnimation { properties: "height"; duration: 300; easing.type: Easing.InOutQuad }
                NumberAnimation { target: infoText; properties: "opacity"; duration: 200; easing.type: Easing.OutSine }
                NumberAnimation { target: emailInputHolder; properties: "opacity"; duration: 200; easing.type: Easing.OutSine }
                NumberAnimation { target: sendEmailButton; properties: "opacity"; duration: 200; easing.type: Easing.OutSine }
                NumberAnimation { target: backButton; properties: "opacity"; duration: 200; easing.type: Easing.OutSine }
            }

            Connections {
                target: UserManager

                onForgotDetailsFailed: {
                    statusText.text = message
                    state = "WAITING_USER_DATA"
                    waitingInterface = false
                }

                onForgotDetailsSuccess: {
                    statusText.text = "Email sent!"
                    state = "WAITING_USER_DATA"
                    waitingInterface = false
                }
            }

            Component.onCompleted: {
                state = "WAITING_USER_DATA"
                waitingInterface = false
            }
        }
    }

    Loader {
        id: loginComponentLoader
        anchors.fill: parent
        sourceComponent: loginFormComponent
    }
}
