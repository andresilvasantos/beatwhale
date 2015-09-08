import QtQuick 2.0
import BeatWhaleAPI 1.0

Rectangle {
    id: rootRect
    color: "transparent"

    signal logoutRequested()

    Rectangle {
        id: topBar
        width: parent.width
        height: 50
        color: "#bb333333"

        Text {
            id: screenName
            text: "Your Settings"
            color: "white"
            font.pixelSize: 18
            font.family: "Open Sans"
            font.bold: true
            font.capitalization: Font.AllUppercase

            anchors {
                left: parent.left
                leftMargin: 20
                verticalCenter: parent.verticalCenter
            }
        }

        BWButton {
            id: buttonLogout
            width: childrenRect.width + 20
            height: 30
            color: "#656565"
            hoverColor: "#D90F30"
            selectedColor: "#F24261"
            radius: 5

            anchors {
                right: parent.right
                rightMargin: 20
                verticalCenter: parent.verticalCenter
            }

            onClicked: {
                logoutRequested()
            }

            Text {
                id: buttonLogoutText
                text: "Logout"
                color: "white"
                font.pixelSize: 13
                font.family: "Open Sans"

                anchors.centerIn: parent
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        propagateComposedEvents: true

        onClicked: {
            rootRect.forceActiveFocus()
            mouse.accepted = false
        }
    }

    Item {
        id: itemsHolder
        width: childrenRect.width
        height: parent.height

        anchors {
            top: topBar.bottom
            left: parent.left
            margins: 20
        }

        Item {
            id: usernameItem
            width: childrenRect.width
            height: 30

            Text {
                id: labelUsername
                text: "Username:"
                color: "#a5a9aa"
                font.pixelSize: 13
                font.family: "Open Sans"
            }

            Text {
                id: username
                text: UserManager.username()
                color: "#51565a"
                font.pixelSize: 13
                font.family: "Open Sans"

                anchors {
                    left: labelUsername.right
                    leftMargin: 10
                }
            }
        }

        Item {
            id: emailItem
            width: childrenRect.width
            height: 30

            anchors {
                top: usernameItem.bottom
                topMargin: 10
            }

            Text {
                id: labelEmail
                text: "Email:"
                color: "#a5a9aa"
                font.pixelSize: 13
                font.family: "Open Sans"
            }

            Text {
                id: email
                text: UserManager.email()
                color: "#51565a"
                font.pixelSize: 13
                font.family: "Open Sans"

                anchors {
                    left: labelEmail.right
                    leftMargin: 10
                }
            }
        }

        Item {
            id: passwordItem
            width: childrenRect.width
            height: 30

            anchors {
                top: emailItem.bottom
                topMargin: 10
            }

            Rectangle {
                id: newPasswordHolder
                width: 160
                height: 30
                color: "white"
                radius: 5
                border.color: "#cccccc"
                border.width: 1

                anchors {
                    left: parent.left
                    verticalCenter: parent.verticalCenter
                }

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
                        leftMargin: 5
                    }
                }

                TextInput {
                    id: newPasswordInput
                    text: "password"
                    height: parent.height * .5 - 1
                    font.pixelSize: 13
                    font.family: "Open Sans"
                    color: "#666666"
                    opacity: .5
                    selectByMouse: true
                    selectionColor: "#333333"
                    clip: true

                    anchors {
                        verticalCenter: parent.verticalCenter
                        left: imagePasswordIcon.right
                        leftMargin: 5
                        right: parent.right
                        rightMargin: 5
                    }

                    KeyNavigation.tab: retypePasswordInput

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
                            font.family = "Arial"
                            echoMode = TextInput.Password
                            opacity = 1
                        }
                    }
                }
            }

            Rectangle {
                id: retypePasswordHolder
                width: 160
                height: 30
                color: "white"
                radius: 5
                border.color: "#cccccc"
                border.width: 1

                anchors {
                    left: newPasswordHolder.right
                    leftMargin: 10
                    verticalCenter: parent.verticalCenter
                }

                Image {
                    id: imageRetypePasswordIcon
                    source: "qrc:/icons/lock"
                    width: 20
                    height: width
                    fillMode: Image.PreserveAspectFit
                    opacity: .5

                    anchors {
                        verticalCenter: parent.verticalCenter
                        left: parent.left
                        leftMargin: 5
                    }
                }

                TextInput {
                    id: retypePasswordInput
                    text: "retype password"
                    height: parent.height * .5 - 1
                    font.pixelSize: 13
                    font.family: "Open Sans"
                    color: "#666666"
                    opacity: .5
                    selectByMouse: true
                    selectionColor: "#333333"
                    clip: true

                    anchors {
                        verticalCenter: parent.verticalCenter
                        left: imageRetypePasswordIcon.right
                        leftMargin: 5
                        right: parent.right
                        rightMargin: 5
                    }

                    KeyNavigation.tab: newPasswordInput

                    onFocusChanged: {
                        if(!focus && text.length == 0)
                        {
                            text = "retype password"
                            font.family = "Open Sans"
                            echoMode = TextInput.Normal
                            opacity = .5
                        }
                        else if(focus && text == "retype password" && echoMode == TextInput.Normal)
                        {
                            text = ""
                            font.family = "Arial"
                            echoMode = TextInput.Password
                            opacity = 1
                        }
                    }
                }
            }

            BWButton {
                id: buttonChangePassword
                enabled: newPasswordInput.text.length && retypePasswordInput.text.length
                width: childrenRect.width + 20
                height: 30
                color: "#656565"
                hoverColor: "#545454"
                selectedColor: "#898989"
                radius: 5

                anchors {
                    verticalCenter: parent.verticalCenter
                    left: retypePasswordHolder.right
                    leftMargin: 20
                }

                onClicked: {
                    if(newPasswordInput.text.length < 6) {
                        passwordChangeStatusText.color = "#D90F30"
                        passwordChangeStatusText.text = "New password must have at least 6 characters."
                        return
                    }

                    if(newPasswordInput.text != retypePasswordInput.text) {
                        passwordChangeStatusText.color = "#D90F30"
                        passwordChangeStatusText.text = "Passwords do not match."
                        return
                    }

                    passwordChangeStatusText.color = "#333333"
                    passwordChangeStatusText.text = "Changing password..."
                    UserManager.changePassword(newPasswordInput.text)
                }

                Text {
                    id: buttonChangePasswordText
                    text: "Change Password"
                    color: "white"
                    font.pixelSize: 13
                    font.family: "Open Sans"

                    anchors.centerIn: parent
                }
            }

            Text {
                id: passwordChangeStatusText
                text: ""
                color: "#D90F30"
                width: parent.width - 30
                font.pixelSize: 12
                font.family: "Open Sans"

                anchors {
                    left: buttonChangePassword.right
                    leftMargin: 20
                    verticalCenter: parent.verticalCenter
                }
            }
        }

        BWButton {
            id: buttonDeleteAccount
            width: childrenRect.width + 20
            height: 30
            color: "#66D90F30"
            hoverColor: "#D90F30"
            selectedColor: "#F24261"
            radius: 5

            anchors {
                top: passwordItem.bottom
                topMargin: 50
            }

            onClicked: {
                popupDeleteAccount.visible = true
                itemsHolder.enabled = false
                topBar.enabled = false
            }

            Text {
                id: buttonDeleteAccountText
                text: "Delete Account"
                color: "white"
                font.pixelSize: 13
                font.family: "Open Sans"

                anchors.centerIn: parent
            }
        }
    }

    BWPopup {
        id: popupDeleteAccount
        color: "#333333"
        width: 360
        height: 140
        radius: 5
        visible: false

        anchors.centerIn: parent

        title: "Delete Account"
        question: "Are you sure you want to delete your account?\nThis action is not reversible!"
        textColor: "white"
        fontFamily: "Open Sans"

        onAccepted: {
            popupDeleteAccount.enabled = false
            UserManager.deleteAccount()
        }

        onRejected: {
            visible = false
            itemsHolder.enabled = true
            topBar.enabled = true
        }
    }

    BWPopup {
        id: popupDeleteAccountFailed
        color: "#333333"
        width: 360
        height: 140
        radius: 5
        visible: false

        anchors.centerIn: parent

        title: "Failed to Delete Account"
        question: "Would you like to try again?"
        textColor: "white"
        fontFamily: "Open Sans"

        onAccepted: {
            popupDeleteAccountFailed.enabled = false
            UserManager.deleteAccount()
        }

        onRejected: {
            visible = false
            itemsHolder.enabled = true
            topBar.enabled = true
        }
    }

    Connections {
        target: UserManager

        onDeleteAccountSuccess: {
            logoutRequested()
        }

        onDeleteAccountFailed: {
            popupDeleteAccount.visible = false
            popupDeleteAccountFailed.visible = true
        }

        onChangePasswordSuccess: {
            console.log("Password changed!")
            passwordChangeStatusText.color = "#333333"
            passwordChangeStatusText.text = "Password changed."
            newPasswordInput.text = ""
            retypePasswordInput.text = ""
        }

        onChangePasswordFailed: {
            passwordChangeStatusText.color = "#D90F30"
            passwordChangeStatusText.text = "Problem changing password."
        }
    }
}

