import QtQuick 2.0
import BeatWhaleAPI 1.0
import "qrc:/components/qml/"

Rectangle {
    id: rootRect
    color: "transparent"

    property var playlistItem
    property bool controlKeyPressed: false
    property bool shiftKeyPressed: false

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

                    onShowTooltip: {
                        tooltip.displayText = text
                        tooltip.x = thumbnailDelegate.x + x
                        tooltip.y = thumbnailDelegate.y + y - resultsGrid.contentY + resultsGrid.topMarginValue
                        tooltip.opacity = 1
                    }

                    onHideTooltip: {
                        tooltip.opacity = 0
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

            BWTooltip {
                id: tooltip
                visible: opacity != 0
                opacity: 0

                onXChanged: {
                    tooltip.width = mainPanel.width - (resultsGridHolder.x + x + 20)
                    tooltip.height = mainPanel.height - (resultsGridHolder.y + y + 20)
                }
            }

            TOPScrollBar {
                flickable: resultsGrid
            }
        }
    }

    Rectangle {
        id: topBar
        width: parent.width
        height: 50
        color: "#bb333333"

        Text {
            id: screenName
            text: playlistItem ? playlistItem.name : ""
            color: "white"
            font.pixelSize: 15
//            font.family: "Open Sans"
            font.capitalization: Font.AllUppercase
            font.letterSpacing: 2

            anchors {
                left: parent.left
                leftMargin: 20
                verticalCenter: parent.verticalCenter
            }

            MouseArea {
                anchors.fill: parent

                onClicked: {
                    playlistInputName.text = screenName.text
                    playlistInputNameHolder.visible = true
                    playlistInputName.forceActiveFocus()
                    screenName.visible = false
                }
            }
        }

        Rectangle {
            id: playlistInputNameHolder
            width: 300
            height: 30
            color: "white"
            radius: 5
            visible: false

            anchors {
                left: parent.left
                leftMargin: 20
                verticalCenter: parent.verticalCenter
            }

            TextInput {
                id: playlistInputName
                font.pixelSize: 14
//                font.family: "Open Sans"
                font.letterSpacing: 2
                clip: true
                color: "#333333"
                selectByMouse: true
                selectionColor: "#666666"

                anchors {
                    left: parent.left
                    leftMargin: 5
                    right: parent.right
                    rightMargin: 5
                    verticalCenter: parent.verticalCenter
                }

                function playlistNameChanged() {
                    var playlists = PlaylistsManager.playlistNames();

                    if(playlistItem.name === text || !text.length) {
                        playlistInputNameHolder.focus = false
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

                    playlistInputNameHolder.focus = false
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
                    playlistInputNameHolder.focus = false
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
                right: buttonDelete.left
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
                    rightMargin: 10

                    verticalCenter: parent.verticalCenter
                }

                onTextChanged: {
                    if(text.length) populateFilterModel()
                }
            }
        }

        BWButton {
            id: buttonDelete
            color: "#656565"
            hoverColor: "#D90F30"
            selectedColor: "#F24261"
            width: buttonDeleteText.width + 20
            height: 28
            radius: 5

            anchors {
                right: buttonSort.left
                rightMargin: 20
                verticalCenter: parent.verticalCenter
            }

            Text {
                id: buttonDeleteText
                text: "Delete Playlist"
                font.family: "Open Sans"
                color: "white"
                font.pixelSize: 14

                anchors.centerIn: parent
            }

            onClicked: {
                popupDeletePlaylist.visible = true
                mainPanel.enabled = false
                topBar.enabled = false
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
                right: buttonAddQueue.left
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

        BWButton {
            id: buttonAddQueue
            color: "#656565"
            hoverColor: "#545454"
            selectedColor: "#898989"
            width: buttonAddQueueText.width + 20
            height: 28
            radius: 5

            anchors {
                right: parent.right
                rightMargin: 20
                verticalCenter: parent.verticalCenter
            }

            Text {
                id: buttonAddQueueText
                text: "Add to Queue"
                font.family: "Open Sans"
                color: "white"
                font.pixelSize: 14

                anchors.centerIn: parent
            }

            onClicked: {
                addAllToQueue(playlistModel)
            }
        }
    }

    Connections {
        id: playlistConnection
        ignoreUnknownSignals: true

        onPlaylistChanged: {
            populateModel()
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

    Component.onCompleted: {
        populateModel()
    }
}
