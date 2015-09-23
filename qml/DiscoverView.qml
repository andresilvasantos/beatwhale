import QtQuick 2.2
import QtQuick.Layouts 1.1
import BeatWhaleAPI 1.0
import "qrc:/components/qml/"

Rectangle {
    id: rootRect
    color: "transparent"

    property bool controlKeyPressed: false
    property bool shiftKeyPressed: false
    property string searchString
    property var selectedTags: []
    property string nextPageToken
    property int pageNumber: 0
    property bool searchRequested: false
    property bool menuOpened: false

    signal playVideoAndAddToQueue(string id, string title, string subtitle, string thumbnail, string duration)
    signal addVideoToPlayQueue(string id, string title, string subtitle, string thumbnail, string duration)
    signal dragVideosStarted(string dragInfo)
    signal dragVideosFinished()

    function checkLoadMore() {
        if(searchRequested || nextPageToken.length == 0 || pageNumber > 5) return;

        if(resultsGrid.contentY + resultsGrid.height > resultsGrid.contentHeight + 100) {
            searchRequested = true
            YoutubeAPI.search(searchString, nextPageToken)

            ++pageNumber
        }
    }

    function tagChecked(checked, index) {
        if(checked) {
            selectedTags.push(index)
        }
        else {
            var tagIndex = selectedTags.indexOf(index)
            if(tagIndex > -1) selectedTags.splice(tagIndex, 1)
        }

        searchString = ""
        for(var i = 0; i < selectedTags.length; ++i) {
            searchString += tagsModel.get(selectedTags[i]).tag + " "
        }

        if(selectedTags.length == 0) searchString = "new song"

        informativeText.text = "FETCHING..."
        searchModel.clear()
        searchRequested = true
        pageNumber = 0
        YoutubeAPI.search(searchString)
    }

    TOPListModel {
        id: tagsModel
        sortColumnName: "tag"

        Component.onCompleted: {
            tagsModel.append({"tag": "MUSIC VIDEO"})
            tagsModel.append({"tag": "DUBSTEP"})
            tagsModel.append({"tag": "CLASSICAL"})
            tagsModel.append({"tag": "ROCK"})
            tagsModel.append({"tag": "HOUSE"})
            tagsModel.append({"tag": "SAMBA"})
            tagsModel.append({"tag": "FLUTE"})
            tagsModel.append({"tag": "ACOUSTIC"})
            tagsModel.append({"tag": "GUITAR"})
            tagsModel.append({"tag": "ELECTRONIC"})
            tagsModel.append({"tag": "ELECTRO"})
            tagsModel.append({"tag": "MINIMAL"})
            tagsModel.append({"tag": "ALTERNATIVE"})
            tagsModel.append({"tag": "PIANO"})
            tagsModel.append({"tag": "TECHNO"})
            tagsModel.append({"tag": "SOUNDTRACK"})
            tagsModel.append({"tag": "TANGO"})
            tagsModel.append({"tag": "DEEP"})
            tagsModel.append({"tag": "HIPSTER"})
            tagsModel.append({"tag": "EMOTIONAL"})
            tagsModel.append({"tag": "CHILL-OUT"})
            tagsModel.append({"tag": "REGGAE"})
            tagsModel.append({"tag": "TRIP HOP"})
            tagsModel.append({"tag": "HIP HOP"})
            tagsModel.append({"tag": "INDIE"})
            tagsModel.append({"tag": "SINGER"})
            tagsModel.append({"tag": "METAL"})
            tagsModel.append({"tag": "HEAVY"})

            tagsModel.quick_sort()
        }
    }

    ListModel {
        id: searchModel
    }

    Rectangle {
        id: tagsHolder
        color: "#c5c5c5"
        width: 150

        anchors {
            top: parent.top
            bottom: parent.bottom
            topMargin: topMarginValue
        }

        property int topMarginValue: topBar.height

        ListView {
            id: tagsList
            anchors.fill: parent

            spacing: 1

            model: tagsModel

            delegate: BWButton {
                id: tagButton
                width: tagsList.width
                height: 30
                color: "white"
                hoverColor: "#afe5f4"
                selectedColor: "#00addc"
                checkable: true

                Text {
                    color: tagButton.checked ? "white" : "#61666a"
                    text: tag
                    font.pixelSize: 13
                    font.family: "Open Sans"

                    anchors.centerIn: parent
                }

                onClicked: {
                    resultsGrid.videosSelected = []

                    checked = !checked

                    tagChecked(checked, index)
                }

                Component.onCompleted: {
                    if(tag.toLowerCase() == "music video") {
                        checked = true
                        tagChecked(checked, index)
                    }
                }
            }
        }
        TOPScrollBar {
            flickable: tagsList
        }
    }

    Rectangle {
        id: mainPanel
        color: "#20e7ebee"
        height: parent.height
        clip: true

        anchors {
            left: tagsHolder.right
            right: parent.right
        }

        Image {
            source: "qrc:/images/backgroundPattern"
            fillMode: Image.PreserveAspectCrop
            opacity: searchModel.count ? 0 : .1
            visible: opacity != 0
            asynchronous: true
            anchors.fill: parent

            Behavior on opacity {
                NumberAnimation { duration: 200; easing.type: Easing.OutSine }
            }
        }


        Text {
            id: informativeText
            text: "DISCOVER YOUR NEW FAVORITE THING"
            color: "#111111"
            font.pixelSize: 40
            font.family: "Open Sans"
            font.letterSpacing: 2
            wrapMode: Text.WordWrap

            anchors.centerIn: parent

            opacity: searchModel.count == 0 ? .5 : 0

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

                width: parent.width
                height: parent.height
                cellWidth: cellSize
                cellHeight: cellSize
                cacheBuffer: 400

                anchors {
                    fill: parent
                    topMargin: topMarginValue
                }

                property int cellSize: 200
                property int topMarginValue: topBar.height
                property var videosSelected: new Array

                contentWidth: width
                contentHeight: resultsGrid.height

                add: Transition {
                    NumberAnimation { properties: "opacity"; from: 0; to: 1; duration: 200; easing.type: Easing.OutSine }
                }

                move: Transition {
                    NumberAnimation { properties: "x,y"; duration: 200; easing.type: Easing.OutSine }
                }

                model: searchModel
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

                onContentYChanged: {
                    checkLoadMore()
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

            TOPScrollBar {
                flickable: resultsGrid
            }
        }
    }

    Rectangle {
        id: topBar
        width: parent.width
        height: resultsGrid.videosSelected.length ? 45 : 0
        color: "#333333"
        visible: height != 0
        clip: true

        Behavior on height {
            NumberAnimation {duration: 200; easing.type: Easing.OutSine}
        }

        Text {
            id: screenName
            text: "Discover"
            color: "white"
            font.pixelSize: 15
            font.family: "Open Sans"
            font.capitalization: Font.AllUppercase
            font.letterSpacing: 2

            anchors {
                left: parent.left
                leftMargin: 20
                bottom: parent.bottom
                bottomMargin: 12
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
                bottom: parent.bottom
                bottomMargin: 7
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
                optionsModel.append({"name": "Add selected to queue", "danger": false, "active": resultsGrid.videosSelected.length})
                optionsModel.append({"name": "Add selected to playlist...", "danger": false, "active": resultsGrid.videosSelected.length})
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
            case 1:
                playlistSelectionPopUp.visible = true
                playlistSelectionPopUp.forceActiveFocus()
                tagsHolder.enabled = false
                topBar.enabled = false
                mainPanel.enabled = false
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
            tagsHolder.enabled = true
            topBar.enabled = true
            mainPanel.enabled = true
        }

        onCancel: {
            visible = false
            tagsHolder.enabled = true
            topBar.enabled = true
            mainPanel.enabled = true
        }
    }

    Connections {
        target: YoutubeAPI

        onSearchSuccess: {
            if(!searchRequested) return;

            searchRequested = false
            var obj = JSON.parse(documentString);

            if(obj.hasOwnProperty("nextPageToken")) {
                nextPageToken = obj["nextPageToken"]
            }
            else {
                nextPageToken = ""
            }

            for(var key in obj["items"]) {
                if(key === "nextPageToken") continue

                var videoID = obj["items"][key]["id"]
                var title = obj["items"][key]["title"]
                var videoThumbnailUrl = obj["items"][key]["thumbnail"]
                var videoDuration = obj["items"][key]["duration"]

                var videoTitle;
                var videoSubTitle;

                if(title) {
                    var count = 3
                    var separatorIndex = title.indexOf(" - ")
                    if(separatorIndex === -1) {
                        count = 2
                        separatorIndex = title.indexOf(", ")

                        if(separatorIndex === -1) {
                            count = 1
                            separatorIndex = title.indexOf(" \"")

                            if(separatorIndex === 0) separatorIndex = -1
                        }
                    }

                    if(separatorIndex === -1) {
                        videoTitle = title
                        videoSubTitle = ""
                    }
                    else {
                        var artist = title.substring(0, separatorIndex)
                        var trackName = title.substring(separatorIndex + count, title.length)

                        videoTitle = artist
                        videoSubTitle = trackName
                    }
                }

                searchModel.append({"id": videoID, "title": videoTitle, "subtitle": videoSubTitle, "thumbnail": videoThumbnailUrl, "duration": videoDuration})
            }

            if(searchModel.count == 0) informativeText.text = "NO RESULTS FOUND"
        }

        onSearchFailed: {
            searchRequested = false
        }
    }
}
