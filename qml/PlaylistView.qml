import QtQuick 2.0
import BeatWhaleAPI 1.0
import "qrc:/components/qml/"

Rectangle {
    id: rootRect
    color: "transparent"

    property var playlistItem
    property bool controlKeyPressed: false
    property bool shiftKeyPressed: false
    property bool menuOpened: false

    signal playVideoAndAddToQueue(string id, string title, string subtitle, string thumbnail, string duration)
    signal addVideoToPlayQueue(string id, string title, string subtitle, string thumbnail, string duration)
    signal addAllToQueue(var model)
    signal dragVideosStarted(string dragInfo)
    signal dragVideosFinished()

    function populateModel() {
        resultsGrid.videosSelected = []
        popupDeletePlaylist.visible = false
        mainPanel.enabled = true
        topBar.enabled = true

        if(!playlistItem) return;

        playlistModel.clear()
        var videoItems = playlistItem.items()
        for(var i = 0; i < videoItems.length; ++i) {
            playlistModel.append({"id": videoItems[i].id, "title": videoItems[i].title, "subtitle": videoItems[i].subTitle, "thumbnail": videoItems[i].thumbnail,
                                     "duration": videoItems[i].duration, "timestamp": videoItems[i].timestamp})
        }

        playlistModel.quick_sort()

        if(searchText.text.length) populateFilterModel()
    }

    function populateFilterModel() {
        resultsGrid.videosSelected = []

        playlistFilterModel.clear()
        for(var i = 0; i < playlistModel.count; ++i) {
            if(playlistModel.get(i).title.toLowerCase().indexOf(searchText.text.toLowerCase()) > -1 ||
                    playlistModel.get(i).subtitle.toLowerCase().indexOf(searchText.text.toLowerCase()) > -1) {
                playlistFilterModel.append(playlistModel.get(i))
            }
        }
        playlistFilterModel.quick_sort()
    }

    onPlaylistItemChanged: {
        playlistInputNameHolder.visible = false
        screenName.visible = true
        popupDeletePlaylist.visible = false
        mainPanel.enabled = true
        topBar.enabled = true

        if(playlistItem) {
            playlistConnection.target = playlistItem
            screenName.text = playlistItem.name
        }
        populateModel()
    }

    BWListModel {
        id: playlistModel
        sortColumnName: "timestamp"
    }

    BWListModel {
        id: playlistFilterModel
        sortColumnName: playlistModel.sortColumnName
    }

    Rectangle {
        id: mainPanel
        color: "#20e7ebee"
        anchors.fill: parent
        clip: true

        Image {
            source: "qrc:/images/backgroundPattern"
            fillMode: Image.PreserveAspectCrop
            opacity: playlistModel.count ? 0 : .1
            visible: opacity != 0
            asynchronous: true
            anchors.fill: parent

            Behavior on opacity {
                NumberAnimation { duration: 200; easing.type: Easing.OutSine }
            }
        }

        Text {
            id: informativeText
            text: "ADD SOMETHING HERE"
            color: "#111111"
            font.pixelSize: 40
            font.family: "Open Sans"
            font.letterSpacing: 2
            wrapMode: Text.WordWrap

            anchors.centerIn: parent

            opacity: playlistModel.count === 0 ? .5 : 0

            Behavior on opacity {
                NumberAnimation { property: "opacity"; duration: 200; easing.type: Easing.OutSine }
            }
        }

        Rectangle {
            id: resultsGridHolder
            color: "transparent"
            width: {
                Math.floor((parent.width - 20)/ resultsGrid.cellSize) * resultsGrid.cellSize
            }
            height: parent.height

            anchors {
                top: parent.top
                topMargin: 20
                horizontalCenter: parent.horizontalCenter
            }

            GridView {
                id: resultsGrid

                cellWidth: cellSize
                cellHeight: cellSize
                cacheBuffer: 400

                anchors {
                    fill: parent
                    topMargin: topMarginValue
                }

                property int cellSize: 200
                property int topMarginValue: topBar.height + 20
                property var videosSelected: new Array

                contentWidth: width
                contentHeight: resultsGrid.height

//                add: Transition {
//                    NumberAnimation { properties: "opacity"; from: 0; to: 1; duration: 200; easing.type: Easing.OutSine }
//                }

                move: Transition {
                    NumberAnimation { properties: "x,y"; duration: 200; easing.type: Easing.OutSine }
                }

                model: searchText.text.length ? playlistFilterModel : playlistModel
                delegate: VideoThumbnail {
                    id: thumbnailDelegate
                    width: resultsGrid.cellSize
                    height: resultsGrid.cellSize

                    videoID: id
                    videoTitle: title
                    videoSubTitle: subtitle
                    videoThumbnail: thumbnail
                    videoDuration: duration
                    playlist: true
                    playlistName: playlistItem ? playlistItem.name : ""
                    selected: resultsGrid.videosSelected.indexOf(index) > -1

                    onPlayVideo: {
                        playVideoAndAddToQueue(id, title, subtitle, thumbnail, duration)
                    }

                    onAddVideo: {
                        addVideoToPlayQueue(id, title, subtitle, thumbnail, duration)
                    }

                    onRemoveVideo: {
                        resultsGrid.videosSelected = []
                        playlistItem.removeItem(id)
                    }

                    onSelectionRequest: {
                        if(!selected) {
                            if(controlKeyPressed) {
                                if(resultsGrid.videosSelected.indexOf(index) == -1) resultsGrid.videosSelected.push(index)
                            }
                            else if(shiftKeyPressed && resultsGrid.videosSelected.length) {
                                var lastVideoIndex = resultsGrid.videosSelected[resultsGrid.videosSelected.length - 1]
                                var i
                                if(lastVideoIndex > index) {
                                    for(i = index; i < lastVideoIndex; ++i) {
                                        if(resultsGrid.videosSelected.indexOf(i) == -1) resultsGrid.videosSelected.push(i)
                                    }
                                }
                                else {
                                    for(i = lastVideoIndex + 1; i <= index; ++i) {
                                        if(resultsGrid.videosSelected.indexOf(i) == -1) resultsGrid.videosSelected.push(i)
                                    }
                                }
                            }
                            else {
                                resultsGrid.videosSelected = [index]
                            }
                        }
                        else {
                            if(controlKeyPressed) {
                                var selectionIndex = resultsGrid.videosSelected.indexOf(index)
                                resultsGrid.videosSelected.splice(selectionIndex, 1)
                            }
                            else {
                                resultsGrid.videosSelected = []
                            }
                        }
                        resultsGrid.videosSelected = resultsGrid.videosSelected
                    }

                    onDragStarted: {
                        if(!resultsGrid.videosSelected.length) return

                        var dragInfo = ""
                        for(var i = 0; i < resultsGrid.videosSelected.length; ++i) {
                            dragInfo += resultsGrid.model.get(resultsGrid.videosSelected[i]).id
                            dragInfo += "#!#!"
                            dragInfo += resultsGrid.model.get(resultsGrid.videosSelected[i]).title
                            dragInfo += "#!#!"
                            dragInfo += resultsGrid.model.get(resultsGrid.videosSelected[i]).subtitle
                            dragInfo += "#!#!"
                            dragInfo += resultsGrid.model.get(resultsGrid.videosSelected[i]).thumbnail
                            dragInfo += "#!#!"
                            dragInfo += resultsGrid.model.get(resultsGrid.videosSelected[i]).duration

                            dragInfo += "##!##!"
                        }
                        dragVideosStarted(dragInfo)
                    }

                    onDragFinished: {
                        dragVideosFinished()
                    }
                }

                Keys.onPressed: {
                    if(event.key === Qt.Key_Control) {
                        controlKeyPressed = true
                    }
                    else if(event.key === Qt.Key_Shift) {
                        shiftKeyPressed = true
                    }
                }

                Keys.onReleased: {
                    if(event.key === Qt.Key_Control) {
                        controlKeyPressed = false
                    }
                    else if(event.key === Qt.Key_Shift) {
                        shiftKeyPressed = false
                    }
                }

                Keys.onDeletePressed: {
                    if(resultsGrid.videosSelected.length) {
                        var videosToRemove = new Array
                        for(var i = 0; i < resultsGrid.videosSelected.length; ++i) {
                            videosToRemove.push(resultsGrid.model.get(resultsGrid.videosSelected[i]).id)
                        }
                        playlistItem.removeItems(videosToRemove)
                        resultsGrid.videosSelected = []
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    propagateComposedEvents: true
                    enabled: !resultsGrid.activeFocus

                    onClicked: {
                        resultsGrid.forceActiveFocus()
                        mouse.accepted = false
                    }
                }
            }
        }

        TOPScrollBar {
            id: scrollbar
            flickable: resultsGrid

            anchors {
                right: mainPanel.right
                top: mainPanel.top
                topMargin: topBar.height
                bottom: mainPanel.bottom
            }
        }
    }

    Rectangle {
        id: topBar
        width: parent.width
        height: 45
        color: "#333333"
        clip: true

        Rectangle {
            id: editNameIconHolder
            color: hovered ? "#20cccccc" : "#10cccccc"
            radius: width * .5
            width: editNameIcon.width + 14
            height: editNameIcon.height + 14

            anchors {
                right: screenName.right
                rightMargin: -50
                verticalCenter: parent.verticalCenter
            }

            property bool hovered: false

            Behavior on width {
                NumberAnimation {duration: 200; easing.type: Easing.OutSine}
            }

            Behavior on color {
                ColorAnimation {duration: 200; easing.type: Easing.OutSine}
            }

            Binding {
                target: editNameIconHolder;
                property: "width";
                value: editNameIcon.width + 14 + screenName.width - editNameIconHolder.anchors.rightMargin
                when: editNameIconHolder.hovered || playlistInputNameHolder.visible
            }

            Binding {
                target: editNameIconHolder;
                property: "color";
                value: "#20cccccc"
                when: editNameIconHolder.hovered || playlistInputNameHolder.visible
            }

            Binding {
                target: editNameIcon;
                property: "opacity";
                value: .8
                when: editNameIconHolder.hovered || playlistInputNameHolder.visible
            }

            Image {
                id: editNameIcon
                source: "qrc:/icons/edit"
                width: 18
                height: width
                opacity: opacityNormal

                property real opacityNormal: .4

                anchors {
                    right: parent.right
                    rightMargin: 7
                    verticalCenter: parent.verticalCenter
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
                        editNameIconHolder.hovered = true
                    }

                    onExited: {
                        ApplicationManager.setCursor(ApplicationManager.CURSORTYPE_NORMAL)
                        editNameIconHolder.hovered = false
                    }

                    onClicked: {
                        playlistInputName.text = screenName.text
                        playlistInputNameHolder.visible = true
                        playlistInputName.forceActiveFocus()
                        screenName.visible = false
                    }

                    onPressed: {
                        parent.scale = 1.1
                    }

                    onReleased: {
                        parent.scale = 1
                    }
                }
            }
        }

        Text {
            id: screenName
            text: playlistItem ? playlistItem.name : ""
            color: "white"
            font.pixelSize: 15
            font.family: "Open Sans"
            font.capitalization: Font.AllUppercase
            font.letterSpacing: 2

            anchors {
                left: parent.left
                leftMargin: 20
                verticalCenter: parent.verticalCenter
            }
        }

        Rectangle {
            id: playlistInputNameHolder
            color: "#464646"
            radius: 5
            visible: false

            anchors {
                fill: screenName
                topMargin: -4
                bottomMargin: -4
            }

            TextInput {
                id: playlistInputName
                font.pixelSize: 14
                font.family: "Open Sans"
                font.letterSpacing: 2
                clip: true
                color: "white"
                selectByMouse: true
                selectionColor: "#666666"
                validator: RegExpValidator { regExp:/^[A-Za-z0-9].{0,30}$/i }

                anchors {
                    left: parent.left
                    leftMargin: 5
                    right: parent.right
                    rightMargin: 5
                    verticalCenter: parent.verticalCenter
                }

                onFocusChanged: {
                    if(parent.visible && !focus) {
                        editNameIconHolder.hovered = false
                        playlistInputNameHolder.visible = false
                        screenName.visible = true
                    }
                }

                function playlistNameChanged() {
                    var playlists = PlaylistsManager.playlistNames();

                    if(playlistItem.name === text || !text.length) {
                        playlistInputName.focus = false
                        playlistInputNameHolder.visible = false
                        screenName.visible = true
                        return
                    }

                    var alreadyExists = false
                    for(var i = 0; i < playlists.length; ++i) {
                        if(playlists[i].toLowerCase() === text.toLowerCase()) {
                            alreadyExists = true
                            break
                        }
                    }

                    if(!alreadyExists)
                    {
                        screenName.text = text
                        playlistItem.name = text
                    }
                    else {
                        ApplicationManager.triggerNotification("A playlist named " + text + " already exists")
                    }

                    playlistInputName.focus = false
                    playlistInputNameHolder.visible = false
                    screenName.visible = true
                }

                Keys.onReturnPressed: {
                    playlistNameChanged()
                }

                Keys.onEnterPressed: {
                    playlistNameChanged()
                }

                Keys.onEscapePressed: {
                    playlistInputName.focus = false
                    playlistInputNameHolder.visible = false
                    screenName.visible = true
                }
            }
        }

        Rectangle {
            id: searchForm
            color: "#ebeff1"
            radius: 15
            width: 140
            height: 25
            border.color: "#e2e6e8"
            border.width: 1

            anchors {
                right: buttonSort.left
                rightMargin: 20
                verticalCenter: parent.verticalCenter
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

                onTextChanged: {
                    if(text.length) populateFilterModel()
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
            id: buttonSort
            color: "#656565"
            hoverColor: "#545454"
            selectedColor: "#898989"
            width: buttonSortText.width + 20
            height: 28
            radius: 5

            property int sorting: 0

            anchors {
                right: buttonHamburgerMenu.left
                rightMargin: 20
                verticalCenter: parent.verticalCenter
            }

            Text {
                id: buttonSortText
                text: "Sort: Date Added"
                font.family: "Open Sans"
                color: "white"
                font.pixelSize: 14

                anchors.centerIn: parent
            }

            onClicked: {
                ++sorting
                if(sorting >= 3) sorting = 0

                switch(sorting)
                {
                case 0:
                    buttonSortText.text = "Sort: Date Added"
                    playlistModel.sortColumnName = "timestamp"
                    break;
                case 1:
                    buttonSortText.text = "Sort: Title / Artist"
                    playlistModel.sortColumnName = "title"
                    break;
                case 2:
                    buttonSortText.text = "Sort: SubTitle / Track"
                    playlistModel.sortColumnName = "subtitle"
                    break;
                }
                playlistModel.quick_sort()
                playlistFilterModel.quick_sort()
            }
        }

        BWMediaControlButton {
            id: buttonHamburgerMenu
            width: 30
            height: width
            source: menuOpened ? "qrc:/buttons/burgerMenuToggled" : "qrc:/buttons/burgerMenu"

            anchors {
                right: parent.right
                rightMargin: 20
                verticalCenter: parent.verticalCenter
            }

            onClicked: {
                menuOpened = !menuOpened
            }
        }
    }

    HamburgerMenu {
        width: 200
        visible: height != 0
        opened: menuOpened

        onOpenedChanged: {
            if(opened) {
                focus = true
                optionsModel.clear()
                optionsModel.append({"name": "Add all to queue", "danger": false, "active": resultsGrid.model.count})
                optionsModel.append({"name": "Add selected to queue", "danger": false, "active": resultsGrid.videosSelected.length})
                optionsModel.append({"name": "Add selected to playlist...", "danger": false, "active": resultsGrid.videosSelected.length})
                optionsModel.append({"name": "Remove selected", "danger": true, "active": resultsGrid.videosSelected.length})
                optionsModel.append({"name": "Delete playlist", "danger": true, "active": 1})
            }
        }

        onFocusChanged: {
            if(!focus) {
                menuOpened = false
            }
        }

        anchors {
            right: parent.right
            top: topBar.bottom
        }

        onOptionClicked: {
            switch(index)
            {
            case 0:
            default:
                addAllToQueue(searchText.text.length ? playlistFilterModel : playlistModel)
                break;
            case 1:
                if(resultsGrid.videosSelected.length) {
                    for(var i = 0; i < resultsGrid.videosSelected.length; ++i) {
                        var element = resultsGrid.model.get(resultsGrid.videosSelected[i])
                        addVideoToPlayQueue(element.id, element.title, element.subtitle, element.thumbnail, element.duration)
                    }
                    if(resultsGrid.videosSelected.length > 1) {
                        ApplicationManager.triggerNotification("Added " + resultsGrid.videosSelected.length + " items to playing queue")
                    }

                    resultsGrid.videosSelected = []
                }
                break;
            case 2:
                playlistSelectionPopUp.visible = true
                playlistSelectionPopUp.forceActiveFocus()
                topBar.enabled = false
                mainPanel.enabled = false
                break;
            case 3:
                if(resultsGrid.videosSelected.length) {
                    var videosToRemove = new Array
                    for(var i = 0; i < resultsGrid.videosSelected.length; ++i) {
                        videosToRemove.push(resultsGrid.model.get(resultsGrid.videosSelected[i]).id)
                    }
                    playlistItem.removeItems(videosToRemove)
                    resultsGrid.videosSelected = []
                }
                break;
            case 4:
                popupDeletePlaylist.visible = true
                mainPanel.enabled = false
                topBar.enabled = false
                break;
            }

            menuOpened = false
        }

        ListModel {
            id: optionsModel
        }

        menuModel: optionsModel
    }

    PlaylistSelection {
        id: playlistSelectionPopUp
        visible: false

        anchors.centerIn: parent

        onAddItemsToPlaylist: {
            var playlist = PlaylistsManager.playlist(name)

            var ids = new Array
            var titles = new Array
            var subTitles = new Array
            var thumbnails = new Array
            var durations = new Array

            for(var i = 0; i < resultsGrid.videosSelected.length; ++i) {
                var videoSelected = resultsGrid.model.get(resultsGrid.videosSelected[i])
                ids.push(videoSelected.id)
                titles.push(videoSelected.title)
                subTitles.push(videoSelected.subtitle)
                thumbnails.push(videoSelected.thumbnail)
                durations.push(videoSelected.duration)
            }

            playlist.addItems(ids, titles, subTitles, thumbnails, durations)

            visible = false
            topBar.enabled = true
            mainPanel.enabled = true
        }

        onCancel: {
            visible = false
            topBar.enabled = true
            mainPanel.enabled = true
        }
    }

    BWPopup {
        id: popupDeletePlaylist
        color: "#333333"
        width: 360
        height: 140
        radius: 5
        visible: false

        anchors.centerIn: parent

        title: "Delete Playlist"
        question: "Are you sure you want to delete this playlist?\nThis action is not reversible!"
        textColor: "white"
        fontFamily: "Open Sans"

        onAccepted: {
            PlaylistsManager.deletePlaylist(playlistItem.name)
        }

        onRejected: {
            visible = false
            mainPanel.enabled = true
            topBar.enabled = true
        }
    }

    Connections {
        id: playlistConnection
        ignoreUnknownSignals: true

        onPlaylistChanged: {
            populateModel()
        }
    }

    Keys.onPressed: {
        switch(event.key)
        {
        case Qt.Key_PageUp:
            scrollbar.scrollUp()
            break;
        case Qt.Key_PageDown:
            scrollbar.scrollDown()
            break;
        }
    }

    Component.onCompleted: {
        populateModel()
    }
}

