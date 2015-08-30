import QtQuick 2.2
import QtQuick.Layouts 1.1
import BeatWhaleAPI 1.0
import "qrc:/components/qml/"

Rectangle {
    id: registerComponentRect
    anchors.fill: parent

    property string username
    property string email
    property string password
    property string code
    property string statusMessage

    Component {
        id: registerFormComponent

        Item {
            function signingUp() {
                if(usernameInput.text.length == 0 || usernameInput.text == "username" ||
                        emailInput.text.length == 0 || emailInput.text == "email" ||
                        passwordInput.text.length == 0 || passwordInput.text == "password") return;

                var indexAt = emailInput.text.indexOf("@")
                var indexDot = emailInput.text.lastIndexOf(".")
                var emailLength = emailInput.text.length

                if(indexAt == -1 || indexDot == -1 || indexAt > indexDot || emailLength - indexDot < 2 || indexDot - indexAt < 2) {
                    statusMessage = "Invalid email entered."
                    return;
                }

                if(usernameInput.text.length < 3) {
                    statusMessage = "Username must have at least 3 characters."
                    return;
                }

                if(passwordInput.text.length < 6) {
                    statusMessage = "Password must have at least 6 characters."
                    return;
                }

                username = usernameInput.text
                email = emailInput.text
                password = passwordInput.text

                statusMessage = ""

                registerComponentRect.state = "CHECKING_UNIQUE_USERNAME_AND_EMAIL"
                waitingInterface = true

                UserManager.checkUniqueUsername(username)
            }

            Rectangle {
                id: registerForm
                width: parent.width * 0.9
                height: 135
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
                            inputMethodHints: Qt.ImhEmailCharactersOnly

                            anchors {
                                verticalCenter: parent.verticalCenter
                                left: imageUserIcon.right
                                leftMargin: 10
                                right: parent.right
                                rightMargin: 5
                            }

                            KeyNavigation.tab: emailInput

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
                        width: parent.width
                        height: 1
                        color: "#cccccc"
                    }

                    Item {
                        width: parent.width
                        height: 45

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
                            //font.bold: true
                            font.pixelSize: 14
                            color: "#666666"
                            text: "email"
                            opacity: .5
                            selectByMouse: true
                            selectionColor: "#333333"
                            clip: true
                            font.family: "Open Sans"
                            inputMethodHints: Qt.ImhEmailCharactersOnly
                            validator: RegExpValidator { regExp:/^([\w-]+(?:\.[\w-]+)*)@((?:[\w-]+\.)*\w[\w-]{0,66})\.([a-z]{2,6}(?:\.[a-z]{2})?)$/i }

                            anchors {
                                verticalCenter: parent.verticalCenter
                                left: imageEmailIcon.right
                                leftMargin: 10
                                right: parent.right
                                rightMargin: 5
                            }

                            KeyNavigation.tab: passwordInput

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

                    Rectangle {
                        width: parent.width
                        height: 1
                        color: "#cccccc"
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

            Text {
                id: statusText
                text: statusMessage
                color: "#D90F30"
                width: parent.width - 30
                wrapMode: Text.WordWrap
                font.pixelSize: 12
                font.family: "Open Sans"
                horizontalAlignment: Text.AlignHCenter

                anchors {
                    horizontalCenter: parent.horizontalCenter
                    bottom: registerButton.top
                    bottomMargin: 5
                }
            }

            TOPButton {
                id: registerButton
                width: parent.width * 0.9
                height: 45
                color: "#00addc"
                hoverColor: "#0093bb"
                selectedColor: "#1fb3db"
                radius: 5

                anchors {
                    horizontalCenter: parent.horizontalCenter
                    top: registerForm.bottom
                    topMargin: 39
                }

                Text {
                    text: "REGISTER"
                    color: "white"
                    font.bold: true
                    font.pixelSize: 16
                    font.family: "Open Sans"
                    anchors.centerIn: parent
                }

                onClicked: {
                    signingUp()
                }
            }

            Keys.onPressed: {
                if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return) {
                    signingUp()
                    event.accepted = true;
                }
            }
        }
    }

    Component {
        id: confirmationCodeComponent

        Item {
            function confirmCode() {
                if(!codeInput.text.length) {
                    statusMessage = "Please copy the code from the email and paste it into the text input above."
                    return
                }

                if(codeInput.text != code) {
                    statusMessage = "Wrong code entered."
                    return
                }

                registerComponentRect.state = "SIGNING_UP"
                waitingInterface = true

                UserManager.createUserDocument(username, password)
            }

            Text {
                id: infoText
                text: "An email was sent to " + email + " with a confirmation code."
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
                id: codeInputHolder
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

                TextInput {
                    id: codeInput
                    height: parent.height * .5 - 1
                    font.pixelSize: 14
                    font.family: "Open Sans"
                    color: "#666666"
                    selectByMouse: true
                    selectionColor: "#333333"
                    clip: true
                    inputMethodHints: Qt.ImhDigitsOnly

                    anchors {
                        verticalCenter: parent.verticalCenter
                        left: parent.left
                        leftMargin: 10
                        right: parent.right
                        rightMargin: 5
                    }
                }
            }

            Text {
                id: resendEmailText
                text: "resend email"
                font.pixelSize: 11
                font.family: "Open Sans"
                color: "#929292"

                anchors {
                    right: codeInputHolder.right
                    top: codeInputHolder.bottom
                    topMargin: 5
                }

                MouseArea {
                    anchors.fill: parent

                    onClicked: {
                        UserManager.sendCodeByEmail(email, code)
                        statusMessage = "New email sent."
                    }
                }
            }

            Text {
                id: statusText
                text: statusMessage
                color: "#D90F30"
                width: parent.width - 30
                wrapMode: Text.WordWrap
                font.pixelSize: 12
                font.family: "Open Sans"
                horizontalAlignment: Text.AlignHCenter

                anchors {
                    horizontalCenter: parent.horizontalCenter
                    bottom: confirmButton.top
                    bottomMargin: 5
                }
            }

            TOPButton {
                id: confirmButton
                width: parent.width * 0.9
                height: 45
                color: "#00addc"
                hoverColor: "#0093bb"
                selectedColor: "#1fb3db"
                radius: 5

                anchors {
                    horizontalCenter: parent.horizontalCenter
                    top: codeInputHolder.bottom
                    topMargin: 120 - infoText.contentHeight
                }

                Text {
                    text: "CONFIRM"
                    color: "white"
                    font.bold: true
                    font.pixelSize: 16
                    font.family: "Open Sans"
                    anchors.centerIn: parent
                }

                onClicked: {
                    confirmCode()
                }
            }
        }
    }

    Loader {
        id: componentLoader
        sourceComponent: registerFormComponent

        anchors.fill: parent
    }

    states: [
        State {
            name: "LOGGED_OFF"
            PropertyChanges { target: componentLoader; opacity: 1 }
        },
        State {
            name: "CHECKING_UNIQUE_USERNAME_AND_EMAIL"
            PropertyChanges { target: componentLoader; opacity: 0 }
            PropertyChanges { target: backgroundFormRect; height: formCloseHeight }
        }
        ,State {
            name: "CODE_CONFIRMATION"
            PropertyChanges { target: componentLoader; opacity: 1 }
        }
        ,State {
            name: "SIGNING_UP"
            PropertyChanges { target: componentLoader; opacity: 0 }
            PropertyChanges { target: backgroundFormRect; height: formCloseHeight }
        }
        /*,State {
            name: "LOGGED_IN"
        }*/
    ]

    transitions: Transition {
        NumberAnimation { properties: "height"; duration: 300; easing.type: Easing.InOutQuad }
        NumberAnimation { target: componentLoader; properties: "opacity"; duration: 200; easing.type: Easing.OutSine }
    }

    Connections {
        target: UserManager

        onCheckUniqueUsernameFailed: {
            statusMessage = message
            registerComponentRect.state = "LOGGED_OFF"
            waitingInterface = false
        }

        onCheckUniqueUsernameSuccess: {
            UserManager.checkUniqueEmail(email)
        }

        onCheckUniqueEmailFailed: {
            statusMessage = message
            registerComponentRect.state = "LOGGED_OFF"
            waitingInterface = false
        }

        onCheckUniqueEmailSuccess: {
            code = UserManager.generateActivationCode()
            UserManager.sendCodeByEmail(email, code)
            componentLoader.sourceComponent = confirmationCodeComponent
            waitingInterface = false
            registerComponentRect.state = "CODE_CONFIRMATION"
        }

        onCreateUserDocumentFailed: {
            componentLoader.sourceComponent = registerFormComponent
            statusMessage = message
            registerComponentRect.state = "LOGGED_OFF"
            waitingInterface = false
        }

        onCreateUserDocumentSuccess: {
            console.log("YAYKS!")
            UserManager.createUserDatabase(username)
        }

        onCreateUserDatabaseFailed: {
            componentLoader.sourceComponent = registerFormComponent
            statusMessage = message
            registerComponentRect.state = "LOGGED_OFF"
            waitingInterface = false
        }

        onCreateUserDatabaseSuccess: {
            console.log("Good.")
            UserManager.updateSettingsFile(username, email)
        }

        onUpdateSettingsFileFailed: {
            componentLoader.sourceComponent = registerFormComponent
            statusMessage = message
            registerComponentRect.state = "LOGGED_OFF"
            waitingInterface = false
        }

        onUpdateSettingsFileSuccess: {
            console.log("Great!")
            UserManager.updateDatabaseSecurity(username)
        }

        onUpdateDatabaseSecurityFailed: {
            componentLoader.sourceComponent = registerFormComponent
            statusMessage = message
            registerComponentRect.state = "LOGGED_OFF"
            waitingInterface = false
        }

        onUpdateDatabaseSecuritySuccess: {
            console.log("Final step!")
            UserManager.createEmailDocument(email, username)
        }

        onCreateEmailDocumentFailed: {
            componentLoader.sourceComponent = registerFormComponent
            statusMessage = message
            registerComponentRect.state = "LOGGED_OFF"
            waitingInterface = false
        }

        onCreateEmailDocumentSuccess: {
            console.log("Almost there...")
            UserManager.setRememberCredentials(false)
            UserManager.login(username, password)
        }

        onLoginFailed: {
            componentLoader.sourceComponent = registerFormComponent
            statusMessage = message
            loginComponentRect.state = "LOGGED_OFF"
            waitingInterface = false
        }

        onLoginSuccess: {
            UserManager.startListeningToChanges()
            loggedIn()
        }
    }
}
