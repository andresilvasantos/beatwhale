import QtQuick 2.2
import QtQuick.Layouts 1.1
import BeatWhaleAPI 1.0

Rectangle {

    property bool videoMaximized: false
    property bool showSearchFilters: false

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
            source: "qrc:/images/logoSymbol"
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

    Image {
        id: searchFiltersButton
        width: 20
        height: width
        source: "qrc:/buttons/addDark"
        sourceSize.width: 50
        sourceSize.height: 50
        rotation: showSearchFilters ? 45 : 0
        opacity: .5

        anchors {
            left: searchForm.right
            leftMargin: 10
            verticalCenter: parent.verticalCenter
        }

        Behavior on rotation {
            NumberAnimation {duration: 200; easing.type: Easing.OutSine}
        }

        Behavior on opacity {
            NumberAnimation {duration: 200; easing.type: Easing.OutSine}
        }

        Behavior on scale {
            NumberAnimation { duration: 200; easing.type: Easing.OutSine }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true

            onEntered: {
                ApplicationManager.setCursor(ApplicationManager.CURSORTYPE_BUTTON)
                ApplicationManager.triggerTooltip(showSearchFilters ? "Hide Search Filters" : "Show Search Filters", 15, -10, 1200)
                parent.opacity = 1
            }

            onExited: {
                ApplicationManager.setCursor(ApplicationManager.CURSORTYPE_NORMAL)
                ApplicationManager.cancelTooltip()
                parent.opacity = .5
            }

            onClicked: {
                showSearchFilters = !showSearchFilters
                ApplicationManager.cancelTooltip()
            }

            onPressed: {
                parent.scale = 1.1
            }

            onReleased: {
                parent.scale = 1
            }
        }
    }

    Item {
        id: searchFilters
        width: showSearchFilters ? 300 : 0
        height: parent.height
        clip: true

        anchors {
            left: searchFiltersButton.right
            leftMargin: 10
        }

        Behavior on width {
            NumberAnimation {duration: 200; easing.type: Easing.OutSine}
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
                verticalCenter: parent.verticalCenter
            }

            property int orderFilter: UserManager.orderFilter

            onHovered: {
                ApplicationManager.triggerTooltip("Order Search Filter", 15, -10, 1200)
            }

            onHoveredOut: {
                ApplicationManager.cancelTooltip()
            }

            onClicked: {
                ++orderFilter
                if(orderFilter > 3) orderFilter = 0

                UserManager.orderFilter = orderFilter
            }

            Text {
                id: buttonOrderFilterText
                text: {
                    switch(buttonOrderFilter.orderFilter) {
                    case 1:
                        return "Relevance"
                    case 2:
                        return "Date"
                    case 3:
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

            property int durationFilter: UserManager.durationFilter

            onHovered: {
                ApplicationManager.triggerTooltip("Duration Search Filter", 15, -10, 1200)
            }

            onHoveredOut: {
                ApplicationManager.cancelTooltip()
            }

            onClicked: {
                ++durationFilter
                if(durationFilter > 3) durationFilter = 0

                UserManager.durationFilter = durationFilter
            }

            Text {
                id: buttonDurationFilterText
                text: {
                    switch(buttonDurationFilter.durationFilter) {
                    case 1:
                        return "Short"
                    case 2:
                        return "Medium"
                    case 3:
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

        BWButton {
            id: buttonOnlyMusicFilter
            width: buttonOnlyMusicFilterText.width + 20
            height: 25
            color: "#ebeff1"
            hoverColor: "#5000addc"
            selectedColor: "#00addc"
            radius: 5
            checkable: true
            checked: UserManager.musicOnlyFilter

            anchors {
                left: buttonDurationFilter.right
                leftMargin: 20
                verticalCenter: parent.verticalCenter
            }

            onHovered: {
                ApplicationManager.triggerTooltip("Music Only Search Filter", 15, -10, 1200)
            }

            onHoveredOut: {
                ApplicationManager.cancelTooltip()
            }

            onClicked: {
                checked = !checked

                UserManager.musicOnlyFilter = checked
            }

            Text {
                id: buttonOnlyMusicFilterText
                text: "Only Music"
                color: parent.checked ? "white" : "#aaaaaa"
                font.pixelSize: 13
                font.family: "Open Sans"

                anchors.centerIn: parent

                Behavior on color {
                    ColorAnimation { duration: 200; easing.type: Easing.OutSine }
                }
            }
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
            rightMargin: ApplicationManager.windowControlButtonsEnabled ? 120 : 20
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
