import QtQuick 2.2
import QtQuick.Layouts 1.1
import BeatWhaleAPI 1.0

Rectangle {

    property bool videoMaximized: false

    signal searchRequested(string search)
    signal settingsRequested()

    function untoggleUserButton() {
        userButton.selected = false
    }

    Image {
        id: logo
        width: 150
        height: parent.height
        source: "qrc:/images/logoHorizontal"
        asynchronous: true
        fillMode: Image.PreserveAspectFit
        //smooth: true
        //sourceSize.width: 150

        anchors {
            left: parent.left
            leftMargin: 20
            verticalCenter: parent.verticalCenter
        }
    }

    Rectangle {
        id: searchForm
        color: "#ebeff1"
        radius: 15
        width: 220
        height: 25
        border.color: "#e2e6e8"
        border.width: 1

        anchors {
            verticalCenter: parent.verticalCenter
            left: logo.right
            leftMargin: 25
        }

        TextInput {
            id: searchText
            color: "#111111"
            anchors.fill: parent
            font.pixelSize: 13
            font.family: "Open Sans"
            verticalAlignment: TextInput.AlignVCenter
            clip: true
            selectByMouse: true
            selectionColor: "#333333"

            anchors {
                left: parent.left
                leftMargin: 10
                right: parent.right
                rightMargin: 10

                verticalCenter: parent.verticalCenter
            }

            onAccepted: {
                searchRequested(text)
            }
        }
    }

    BWButton {
        id: buttonSearchDuration
        width: buttonSearchDurationText.width + 20
        height: 25
        color: "#ebeff1"
        hoverColor: "#5000addc"
        selectedColor: "#5000addc"
        radius: 5

        anchors {
            left: searchForm.right
            leftMargin: 20
            verticalCenter: parent.verticalCenter
        }

        property int searchDuration: -1

        onClicked: {
            ++searchDuration
            if(searchDuration > 2) searchDuration = -1

            YoutubeAPI.setVideoDurationSearch(searchDuration)
        }

        Text {
            id: buttonSearchDurationText
            text: {
                switch(buttonSearchDuration.searchDuration) {
                case 0:
                    return "Short"
                case 1:
                    return "Medium"
                case 2:
                    return "Long"
                default:
                    return "Any"
                }
            }
            color: "#aaaaaa"
            font.pixelSize: 13
            font.family: "Open Sans"

            anchors.centerIn: parent
        }
    }

    Rectangle {
        id: userButton
        width: hovered ? usernameText.width + 40 : usernameText.width + 20
        height: hovered ? 40 : 30
        color: {
            if(toggled) {
                return "#e2e6e8"
            }
            else {
                if(hovered) {
                    return "#ebeff1"
                }
                else return "#00ebeff1"
            }
        }
        radius: width * .5

        anchors {
            right: parent.right
            rightMargin: 20
            verticalCenter: parent.verticalCenter
        }

        property bool selected: false
        property bool toggled: selected && !videoMaximized
        property bool hovered: false

        Behavior on color {
            ColorAnimation { duration: 200; easing.type: Easing.OutSine }
        }

        Behavior on width {
            NumberAnimation { duration: 200; easing.type: Easing.OutSine }
        }

        Behavior on height {
            NumberAnimation { duration: 200; easing.type: Easing.OutSine }
        }

        Text {
            id: usernameText
            text: "username"//UserManager.username()
            color: "#9ca5aa"
            font.pixelSize: 14
            font.family: "Open Sans"

            anchors.centerIn: parent
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true

            onEntered: {
                userButton.hovered = true
            }

            onExited: {
                userButton.hovered = false
            }

            onClicked: {
                userButton.selected = !userButton.selected

                if(userButton.selected) settingsRequested()
            }
        }
    }

    Rectangle {
        color: "#cccccc"
        width: parent.width
        height: 1

        anchors.bottom: parent.bottom
    }
}