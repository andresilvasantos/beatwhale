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

    function searchFocus() {
        searchText.forceActiveFocus()
        searchRequested("")
    }

    MouseArea {
        anchors.fill: parent

        onPressed: {
            ApplicationManager.setGrabbingWindowMoveHandle(true)
        }

        onReleased: {
            ApplicationManager.setGrabbingWindowMoveHandle(false)
        }
    }

    Item {
        id: logo
        width: childrenRect.width
        height: parent.height

        anchors {
            left: parent.left
            leftMargin: 20
        }

        Image {
            id: logoImage
            width: 20
            height: width
            source: "qrc:/images/icon"
            asynchronous: true
            fillMode: Image.PreserveAspectFit
            smooth: false
            sourceSize.width: 20
            sourceSize.height: 20

            anchors {
                verticalCenter: parent.verticalCenter
            }
        }

        Text {
            text: "beatwhale"
            color: "#00acdc"
            font.pixelSize: 25
            font.family: "Harabara Mais Demo"
            font.letterSpacing: 2

            anchors {
                left: logoImage.right
                leftMargin: 5
                top: parent.top
                topMargin: parent.height / 2 - height / 2 + 1
            }
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
            leftMargin: 20
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
                rightMargin: searchIcon.width + 10

                verticalCenter: parent.verticalCenter
            }

            onAccepted: {
                searchRequested(text)
            }
        }

        Image {
            id: searchIcon
            width: 15
            height: width
            source: "qrc:/icons/search"
            sourceSize.width: width
            sourceSize.height: height
            smooth: false

            anchors {
                right: parent.right
                rightMargin: 5
                verticalCenter: parent.verticalCenter
            }
        }
    }

    BWButton {
        id: buttonOrderFilter
        width: buttonOrderFilterText.width + 20
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

        property int orderFilter: -1

        onClicked: {
            ++orderFilter
            if(orderFilter > 2) orderFilter = -1

            YoutubeAPI.setOrderFilter(orderFilter + 1)
        }

        Text {
            id: buttonOrderFilterText
            text: {
                switch(buttonOrderFilter.orderFilter) {
                case 0:
                    return "Relevance"
                case 1:
                    return "Date"
                case 2:
                    return "Rating"
                default:
                    return "View Count"
                }
            }
            color: "#aaaaaa"
            font.pixelSize: 13
            font.family: "Open Sans"

            anchors.centerIn: parent
        }
    }

    BWButton {
        id: buttonDurationFilter
        width: buttonDurationFilterText.width + 20
        height: 25
        color: "#ebeff1"
        hoverColor: "#5000addc"
        selectedColor: "#5000addc"
        radius: 5

        anchors {
            left: buttonOrderFilter.right
            leftMargin: 20
            verticalCenter: parent.verticalCenter
        }

        property int durationFilter: -1

        onClicked: {
            ++durationFilter
            if(durationFilter > 2) durationFilter = -1

            YoutubeAPI.setDurationFilter(durationFilter + 1)
        }

        Text {
            id: buttonDurationFilterText
            text: {
                switch(buttonDurationFilter.durationFilter) {
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
        width: userIcon.width + 20
        height: width
        radius: toggled || hovered ? width * .5 : 5
        color: {
            if(toggled) {
                return "#00addc"
            }
            else {
                if(hovered) {
                    return "#6dddfc"
                }
                else return "#ebeff1"
            }
        }

        anchors {
            right: parent.right
            rightMargin: 120
            verticalCenter: parent.verticalCenter
        }

        property bool selected: false
        property bool toggled: selected && !videoMaximized
        property bool hovered: false

        Behavior on color {
            ColorAnimation { duration: 200; easing.type: Easing.OutSine }
        }

        Behavior on radius {
            NumberAnimation { duration: 200; easing.type: Easing.OutSine }
        }

        Image {
            id: userIcon
            source: "qrc:/icons/userToggled"
            width: 20
            height: width

            anchors.centerIn: parent
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true

            onEntered: {
                userButton.hovered = true
                ApplicationManager.setCursor(ApplicationManager.CURSORTYPE_BUTTON)
            }

            onExited: {
                userButton.hovered = false
                ApplicationManager.setCursor(ApplicationManager.CURSORTYPE_NORMAL)
            }

            onClicked: {
                if(!userButton.selected) {
                    userButton.selected = true
                    settingsRequested()
                }
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
