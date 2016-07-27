import QtQuick 2.0
import BeatWhaleAPI 1.0
import "qrc:/components/qml/"

Rectangle {
    id: rootRect
    color: "transparent"

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

        favoritesModel.clear()
        var videoItems = PlaylistsManager.favorites()
        for(var i = 0; i < videoItems.length; ++i) {
            favoritesModel.append({"id": videoItems[i].id, "title": videoItems[i].title, "subtitle": videoItems[i].subTitle, "thumbnail": videoItems[i].thumbnail,
                                      "duration": videoItems[i].duration, "timestamp": videoItems[i].timestamp})
        }

        favoritesModel.quick_sort()

        if(searchText.text.length) populateFilterModel()
    }

    function populateFilterModel() {
        resultsGrid.videosSelected = []

        favoritesFilterModel.clear()
        for(var i = 0; i < favoritesModel.count; ++i) {
            if(favoritesModel.get(i).title.toLowerCase().indexOf(searchText.text.toLowerCase()) > -1 ||
                    favoritesModel.get(i).subtitle.toLowerCase().indexOf(searchText.text.toLowerCase()) > -1) {
                favoritesFilterModel.append(favoritesModel.get(i))
            }
        }
        favoritesFilterModel.quick_sort()
    }

    BWListModel {
        id: favoritesModel
        sortColumnName: "timestamp"
    }

    BWListModel {
        id: favoritesFilterModel
        sortColumnName: favoritesModel.sortColumnName
    }

    Rectangle {
        id: mainPanel
        color: "#20e7ebee"
        anchors.fill: parent
        clip: true

        Image {
            source: "qrc:/images/backgroundPattern"
            fillMode: Image.PreserveAspectCrop
            opacity: favoritesModel.count ? 0 : .1
            visible: opacity != 0
            asynchronous: true
            anchors.fill: parent

            Behavior on opacity {
                NumberAnimation { duration: 200; easing.type: Easing.OutSine }
            }
        }

        Text {
            id: informativeText
            text: "NO FAVORITES YET? :("
            color: "#111111"
            font.pixelSize: 40
            font.letterSpacing: 2
            wrapMode: Text.WordWrap

            anchors.centerIn: parent

            opacity: favoritesModel.count === 0 ? .5 : 0

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
//                    NumberAnimation { properties: "x,y"; duration: 200; easing.type: Easing.OutSine }
//                }

                move: Transition {
                    NumberAnimation { properties: "x,y"; duration: 200; easing.type: Easing.OutSine }
                }

                model: searchText.text.length ? favoritesFilterModel : favoritesModel
                delegate: VideoThumbnail {
                    id: thumbnailDelegate
                    width: resultsGrid.cellSize
                    height: resultsGrid.cellSize

                    videoID: id
                    videoTitle: title
                    videoSubTitle: subtitle
                    videoThumbnail: thumbnail
                    videoDuration: duration
                    selected: resultsGrid.videosSelected.indexOf(index) > -1

                    onPlayVideo: {
                        playVideoAndAddToQueue(id, title, subtitle, thumbnail, duration)
                    }

                    onAddVideo: {
                        addVideoToPlayQueue(id, title, subtitle, thumbnail, duration)
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
                        PlaylistsManager.removeFavorites(videosToRemove)
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

        Text {
            id: screenName
            text: "Your Favorites"
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
                    favoritesModel.sortColumnName = "timestamp"
                    break;
                case 1:
                    buttonSortText.text = "Sort: Title / Artist"
                    favoritesModel.sortColumnName = "title"
                    break;
                case 2:
                    buttonSortText.text = "Sort: SubTitle / Track"
                    favoritesModel.sortColumnName = "subtitle"
                    break;
                }
                favoritesModel.quick_sort()
                favoritesFilterModel.quick_sort()
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
                addAllToQueue(searchText.text.length ? favoritesFilterModel : favoritesModel)
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
                    PlaylistsManager.removeFavorites(videosToRemove)
                    resultsGrid.videosSelected = []
                }
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

    Connections {
        target: PlaylistsManager
        ignoreUnknownSignals: true

        onFavoritesChanged: {
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

