import QtQuick 2.2
import QtQuick.Controls 1.1
import QtQuick.Dialogs 1.1
import QtQuick.Layouts 1.1
import QtQuick.Window 2.0
import BeatWhaleAPI 1.0
import QmlVlc 0.1

Rectangle {
    id: rootRect
    color: "#eeeeee"
    focus: true

    property int currentVideoIndex: -1
    property bool shuffleEnabled: false
    property bool repeatEnabled: false
    property bool suggestionRequested: false
    property bool playingQueueMinEnabled: false
    property var shuffleList: new Array

    signal loggedOut()

    function playVideo(index) {
        if(playingModel.count <= index || index < 0) return

        var element = playingModel.get(index)

        mediaPlayer.stop()
        YoutubeAPI.videoUrl(element.id)

        sideBar.currentVideoID = element.id
        sideBar.currentTitle = element.title
        sideBar.currentSubTitle = element.subtitle
        sideBar.currentThumbnail = element.thumbnail
        sideBar.currentDuration = element.duration
        sideBar.currentVideoFavorited = PlaylistsManager.isFavorited(element.id)

        var message
        if(element.subtitle.length) message = "Playing now: " + element.title + " - " + element.subtitle
        else message = "Playing now: " + element.title
        ApplicationManager.triggerNotification(message)

        currentVideoIndex = index

        if(controlsBar.tvMode && index >= playingModel.count - 1 && (!shuffleEnabled || !shuffleList.length)) {
            if(shuffleEnabled) {
                controlsBar.shuffle = false
            }

            newSuggestion()
        }
    }

    function removeVideo(index) {
        if(playingModel.count <= index || index < 0) return

        playingModel.remove(index)
        UserManager.removedFromQueue(index);

        if(playingModel.count == 0 || (index === currentVideoIndex && index >= playingModel.count)) {
            mediaPlayer.stop()
            currentVideoIndex = -1
            return
        }

        if(controlsBar.tvMode && index >= playingModel.count - 1) {
            newSuggestion()
        }

        if(currentVideoIndex === index) playVideo(index)
        else if(currentVideoIndex > index) --currentVideoIndex
    }

    function playNextVideo() {
        if(playingModel.count == 0) return

        var nextVideo, index

        if(shuffleEnabled) {
            if(shuffleList.length) {
                nextVideo = shuffleList[Math.floor((Math.random() * (shuffleList.length - 1)))];
                index = shuffleList.indexOf(nextVideo)
                shuffleList.splice(index, 1)
            }
            else {
                generateShuffleList()
                nextVideo = shuffleList[Math.floor((Math.random() * (shuffleList.length - 1)))];
                index = shuffleList.indexOf(nextVideo)
                shuffleList.splice(index, 1)
            }
        }
        else {
            //Check if it is the last video in queue
            if(currentVideoIndex >= playingModel.count - 1) {
                if(repeatEnabled) {
                    nextVideo = 0
                }
                else return
            }
            else
            {
                nextVideo = currentVideoIndex
                ++nextVideo
            }
        }

        playVideo(nextVideo)
    }

    function playPreviousVideo() {
        var previousVideo = currentVideoIndex;
        --previousVideo

        if(previousVideo < 0) previousVideo = playingModel.count - 1

        playVideo(previousVideo)
    }

    function generateShuffleList() {
        shuffleList = []
        for(var i = 0; i < playingModel.count; ++i) {
            shuffleList.push(i)
        }

        if((mediaPlayer.state == VlcPlayer.Playing ||  mediaPlayer.state == VlcPlayer.Paused) && currentVideoIndex >= 0) {
            var index = shuffleList.indexOf(currentVideoIndex)
            shuffleList.splice(index, 1)
        }
    }

    function startVideosDrag(dragInfo) {
        videoDragInfo.visible = true
        ApplicationManager.dragStarted(dragInfo)

        var videosDraggedInfo = dragInfo
        if(videosDraggedInfo.indexOf("#!#!") === -1) {
            dragInfoText.text = "Unknown video item"
            return;
        }

        var displayText = ""
        var videoItems = videosDraggedInfo.split("##!##!")

        for(var i = 0; i < videoItems.length - 1; ++i) {
            var videoSettings = videoItems[i].split("#!#!")

            var title = videoSettings[1]
            var subTitle = videoSettings[2]
            var duration = videoSettings[4]

            if(subTitle.length) displayText += title + " - " + subTitle + "     " + duration
            else displayText += title + "     " + duration
            if(i < videoItems.length - 2) displayText += "\n"

            if(i >= 8 && videoItems.length >= 10) {
                displayText += "And " + parseInt((videoItems.length - 2) - i) + " more items"
                break
            }
        }

        dragInfoText.text = displayText
    }

    function finishVideosDrag() {
        videoDragInfo.visible = false
        ApplicationManager.dragFinished()
    }

    function newSuggestion() {
        if(!playingModel.count || suggestionRequested) return

        suggestionRequested = true

        var element = playingModel.get(Math.floor((Math.random() * (playingModel.count - 1))))
        var queueList = new Array

        for(var i = 0; i < playingModel.count; ++i) {
            queueList.push(playingModel.get(i).id)
        }

        YoutubeAPI.suggestion(element.id, queueList)

        console.log("New suggestion based on: " + element.title + "  " + element.subtitle)
    }

    ListModel {
        id: playingModel
    }

    SplitView {
        id: splitView
        orientation: Qt.Horizontal

        anchors {
            left: parent.left
            right: parent.right
            top: topBar.bottom
            bottom: controlsBar.top
        }

        SideBar {
            id: sideBar
            width: 200
            height: parent.height
            clip: true

            Layout.minimumWidth: 150
            Layout.maximumWidth: 300

            currentVideo: mediaPlayer

            onFullscreenVideoRequested: {
                videoFullscreen.visible = true
                ApplicationManager.showFullscreen()
            }

            onMaximizeVideoRequested: {
                videoMaximized.visible = true
            }

            onMinimizeVideoRequested: {
                videoMaximized.visible = false
                videoFullscreen.visible = false
                ApplicationManager.showFullscreen(false)
            }

            onRequestScreen: {
                if(url == "SearchView.qml") {
                    searchViewLoader.visible = true
                    listsViewLoader.visible = false
                }
                else
                {
                    listsViewLoader.source = url
                    searchViewLoader.visible = false
                    listsViewLoader.visible = true
                }
                topBar.untoggleUserButton()
            }

            onRequestPlaylist: {
                listsViewLoader.source = "PlaylistView.qml"
                listsViewLoader.item.playlistItem = PlaylistsManager.playlist(name)
                listsViewLoader.visible = true
                searchViewLoader.visible = false
                topBar.untoggleUserButton()
            }

            onAddVideoToPlayQueue: {
                var message
                if(subtitle.length) message = "Added to playing queue: " + title + " - " + subtitle
                else message = "Added to playing queue: " + title
                ApplicationManager.triggerNotification(message)
                playingModel.append({"id": id, "title": title, "subtitle": subtitle, "thumbnail": thumbnail, "duration": duration})
                UserManager.addedToQueue(id, title, subtitle, thumbnail, duration)

                if(playingModel.count == 1) playVideo(0)
                else {
                    if(shuffleEnabled) {
                        generateShuffleList()
                    }
                }
            }

            onAddPlaylistToPlayQueue: {
                var needsToPlay = false
                if(playingModel.count == 0) needsToPlay = true


                var playlist = PlaylistsManager.playlist(name)
                var items = playlist.items()

                for(var i = 0; i < items.length; ++i) {
                    var item = items[i]

                    playingModel.append({"id": item.id, "title": item.title, "subtitle": item.subTitle,
                                            "thumbnail": item.thumbnail, "duration": item.duration})
                    UserManager.addedToQueue(item.id, item.title, item.subTitle, item.thumbnail, item.duration)

                    if(items.length === 1 && !needsToPlay) {
                        var message
                        if(item.subTitle.length) message = "Added to playing queue: " + item.title + " - " + item.subTitle
                        else message = "Added to playing queue: " + item.title
                        ApplicationManager.triggerNotification(message)
                    }
                }

                if(shuffleEnabled) {
                    generateShuffleList()
                }

                if(needsToPlay) {
                    playNextVideo()
                }
                else {
                    if(items.length > 1)
                    {
                        ApplicationManager.triggerNotification("Added " + items.length + " items to playing queue")
                    }
                }
            }

            onDragVideoStarted: {
                startVideosDrag(dragInfo)
            }

            onDragVideoFinished: {
                finishVideosDrag()
            }
        }

        Rectangle {
            id: mainPanel
            Layout.fillWidth: true
            height: parent.height
            color: "transparent"

            Loader {
                id: listsViewLoader
                width: parent.width

                anchors {
                    top: parent.top
                    bottom: playingQueueMinHolder.top
                }

                //anchors.fill: parent
                visible: false
                //clip: true
            }

            Loader {
                id: searchViewLoader
                width: parent.width
                source: "SearchView.qml"

                //anchors.fill: parent
                anchors {
                    top: parent.top
                    bottom: playingQueueMinHolder.top
                }
            }

            BWVideo {
                id: videoMaximized
                visible: false
                aspectFill: false
                mediaSource: mediaPlayer
                fullscreen: false

                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                    bottom: playingQueueMinHolder.top
                }

                onClose: {
                    sideBar.minimizeVideo()
                }

                onFullscreenVideoRequested: {
                    visible = false
                    videoFullscreen.visible = true
                    ApplicationManager.showFullscreen()
                }
            }

            Item {
                id: notification
                width: 250
                height: 0
                visible: true

                anchors {
                    bottom: playingQueueMinHolder.top
                    right: parent.right
                    rightMargin: 20
                }

                Behavior on height {
                    NumberAnimation { duration: 200; easing.type: Easing.OutSine }
                }

                Rectangle {
                    id: notificationHolder
                    color: "white"
                    width: parent.width
                    height: notificationText.contentHeight + 10
                    radius: 5

                    Text {
                        id: notificationText
                        font.pixelSize: 12
                        font.family: "Open Sans"
                        color: "#333333"
                        wrapMode: Text.WordWrap

                        anchors {
                            left: parent.left
                            right: parent.right
                            top: parent.top
                            margins: 5
                        }
                    }
                }

                Timer {
                    id: notificationTimer
                    interval: 2500

                    onTriggered: {
                        notification.height = 0
                    }
                }
            }

            Rectangle {
                id: playingQueueMinHolder
                width: parent.width
                height: playingQueueMinEnabled ? 55 : 0
                clip: true
                visible: height != 0

                anchors {
                    bottom: parent.bottom
                }

                Behavior on height {
                    NumberAnimation { duration: 200; easing.type: Easing.OutSine }
                }

                Rectangle {
                    id: playingQueueMinSeparator
                    color: "#cccccc"
                    width: parent.width
                    height: 1

                    anchors {
                        top: parent.top
                    }
                }

                ListView {
                    id: playingQueueMin
                    orientation: Qt.Horizontal
                    width: parent.width

                    anchors {
                        top: playingQueueMinSeparator.bottom
                        bottom: parent.bottom
                    }

                    model: playingModel
                    delegate: Rectangle {
                        id: playingQueueMinThumbnail
                        width: 54
                        height: 54
                        color: selected ? "#14aaff" : "transparent"
                        opacity: selected ? 1 : .5 + hoverOpacity

                        property bool selected: currentVideoIndex == index
                        property real hoverOpacity: 0

                        Behavior on opacity {
                            NumberAnimation { duration: 200; easing.type: Easing.OutSine }
                        }

                        Rectangle {
                            color: "#cccccc"
                            anchors.fill: playingQueueMinImage
                            visible: playingQueueMinImage.status != Image.Ready
                        }

                        Image {
                            id: playingQueueMinImage
                            source: thumbnail
                            sourceSize.width: 100
                            sourceSize.height: 100
                            fillMode: Image.PreserveAspectCrop

                            anchors {
                                fill: parent
                                margins: 2
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true

                            onEntered: {
                                playingQueueMinThumbnail.hoverOpacity = .3
                                if(subtitle.length) tooltipQueueText.text = title + " - " + subtitle
                                else tooltipQueueText.text = title
                                tooltipQueue.x = sideBar.width + parent.x - tooltipQueue.width / 2 + parent.width / 2 - playingQueueMin.contentX
                                tooltipQueue.y = playingQueueMinHolder.y + 20
                                tooltipQueue.visible = true
                            }

                            onExited: {
                                playingQueueMinThumbnail.hoverOpacity = 0
                                tooltipQueue.visible = false
                            }

                            onClicked: {
                                playVideo(index)
                            }
                        }
                    }
                }
            }
        }
    }

    VlcPlayer {
        id: mediaPlayer

        volume: controlsBar.volume * 100

        onStateChanged: {
            if(state == VlcPlayer.Ended || state == VlcPlayer.Error) {

                if(state == VlcPlayer.Error) {
                    if(currentVideoIndex == -1) return

                    var element = playingModel.get(currentVideoIndex)

                    var message
                    if(element.subtitle.length) message = "Problem playing item: " + element.title + " - " + element.subtitle
                    else message = "Problem playing item: " + element.title
                    ApplicationManager.triggerNotification(message)

                    if(playingModel.count == 0 || (shuffleEnabled && !shuffleList.length && !repeatEnabled) ||
                            (currentVideoIndex >= playingModel.count - 1 && !repeatEnabled)) return

                    problemPlayingVideoTimer.start()
                }
                else {
                    if(playingModel.count == 0 || (shuffleEnabled && !shuffleList.length && !repeatEnabled) ||
                            (currentVideoIndex >= playingModel.count - 1 && !repeatEnabled)) return

                    playNextVideo()
                }
            }
        }
    }

    TopBar {
        id: topBar
        width: parent.width
        height: 60
        videoMaximized: sideBar.videoMaximized
    }

    MediaControlsBar {
        id: controlsBar
        width: parent.width
        height: 50
        focus: true

        anchors {
            bottom: parent.bottom
        }

        property double lastPausedTime: 0

        playing: mediaPlayer.state == VlcPlayer.Playing
        currentSeekSec: Math.ceil(mediaPlayer.time / 1000)
        durationSec: Math.ceil(mediaPlayer.length / 1000)

        onPlay: {
            var now = new Date().valueOf()
            if(mediaPlayer.state == VlcPlayer.Paused && now - lastPausedTime > 60000 * 4) {
                var url = mediaPlayer.mrl
                var position = mediaPlayer.position
                mediaPlayer.stop()
                mediaPlayer.play(url)
                seek(position)
            }
            else {
                if(mediaPlayer.mrl.length) {
                    mediaPlayer.play()
                }
                else if(playingModel.count && currentVideoIndex > -1) {
                    playVideo(currentVideoIndex)
                }
            }
        }

        onPause: {
            mediaPlayer.pause()
            var date = new Date();
            lastPausedTime = date.valueOf()
        }

        onStop: mediaPlayer.stop()

        onSeek: {
            if(mediaPlayer.state !== VlcPlayer.Stopped)
                mediaPlayer.position = seekTo
        }

        onNext: {
            playNextVideo()
        }

        onPrevious: {
            playPreviousVideo()
        }

        onShuffleChanged: {
            shuffleEnabled = shuffle

            if(shuffleEnabled) {
                generateShuffleList()
            }
        }

        onRepeatChanged: {
            repeatEnabled = repeat
        }

        onQueueOpenedChanged: {
            playingQueueMinEnabled = queueOpened
        }

        onTvModeChanged: {
            if(tvMode) {
                if(!playingModel.count) {
                    ApplicationManager.triggerNotification("Before turning TV Mode on, please add videos to your Playing Queue.", 3500)
                    tvMode = false
                    return
                }

                ApplicationManager.triggerNotification("TV Mode is on.\nVideos will be automatically added to your Playing Queue based on what you are listening.", 4500)
            }

            if(tvMode && currentVideoIndex >= 0 && currentVideoIndex >= playingModel.count - 1) {
                repeat = false
                newSuggestion()
            }
        }
    }

    Keys.onPressed: {
        if(event.key === Qt.Key_Space || event.key === Qt.Key_Play) {
            if(controlsBar.playing) controlsBar.pause()
            else controlsBar.play()
            event.accepted = true;
        }
        else if(event.key === Qt.Key_Minus || event.key === Qt.Key_Back) {
            controlsBar.previous()
            event.accepted = true;
        }
        else if(event.key === Qt.Key_Plus || event.key === Qt.Key_Forward) {
            controlsBar.next()
            event.accepted = true;
        }
    }

    BWVideo {
        id: videoFullscreen
        visible: false
        aspectFill: true
        mediaSource: mediaPlayer
        fullscreen: true

        anchors.fill: parent

        onClose: {
            sideBar.minimizeVideo()
        }
    }

    Rectangle {
        id: tooltipQueue
        color: "white"
        width: tooltipQueueText.contentWidth + 10
        height: tooltipQueueText.contentHeight + 10
        radius: 5
        visible: false

        Text {
            id: tooltipQueueText
            font.pixelSize: 12
            font.family: "Open Sans"
            color: "#333333"

            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: 5
            }
        }
    }

    BWTooltip {
        id: tooltip
        visible: opacity != 0
        opacity: 0
        x: invertX ? ApplicationManager.mouseX - displacementX - tooltip.childrenRect.width : ApplicationManager.mouseX + displacementX
        y: ApplicationManager.mouseY + displacementY

        property int displacementX: 0
        property int displacementY: 0
        property bool invertX: false

        onXChanged: {
            tooltip.height = rootRect.height - (y + 20)
        }

        onDisplayTextChanged: {
            invertX = false
        }

        Connections {
            target: ApplicationManager

            onMouseXChanged: {
                if(ApplicationManager.mouseX + tooltip.displacementX + tooltip.childrenRect.width > rootRect.width) {
                     tooltip.invertX = true
                }
                else tooltip.invertX = false
            }
        }

        Timer {
            id: tooltipTimer
            interval: 1500

            onTriggered: {
                tooltip.opacity = 1
            }
        }
    }

    Rectangle {
        id: videoDragInfo
        color: "white"
        opacity: .9
        radius: 5
        width: dragInfoText.contentWidth + 10
        height: dragInfoText.contentHeight + 10
        visible: false
        x: ApplicationManager.mouseX
        y: ApplicationManager.mouseY

        Text {
            id: dragInfoText
            font.pixelSize: 12
            font.family: "Open Sans"

            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: 5
            }
        }
    }

    Timer {
        id: problemPlayingVideoTimer
        interval: 3000

        onTriggered: {
            playNextVideo()
        }
    }

    Connections {
        target: ApplicationManager

        onNotification: {
            notificationTimer.stop()
            notificationText.text = message
            notification.height = notificationText.contentHeight + 30
            notificationTimer.interval = duration
            notificationTimer.start()
        }

        onShowTooltip: {
            tooltipTimer.stop()
            tooltip.displayText = text
            tooltip.displacementX = displacementX
            tooltip.displacementY = displacementY
            tooltipTimer.interval = duration
            tooltipTimer.start()
        }

        onHideTooltip: {
            tooltipTimer.stop()
            tooltip.opacity = 0
        }
    }

    Connections {
        target: topBar

        onSearchRequested: {
            searchViewLoader.visible = true
            listsViewLoader.visible = false
            searchViewLoader.item.newSearch(search)
            topBar.untoggleUserButton()
            sideBar.searchRequested()
        }

        onSettingsRequested: {
            searchViewLoader.visible = false
            listsViewLoader.visible = true
            listsViewLoader.source = "SettingsView.qml"
            sideBar.userSettings = true
        }
    }

    Connections {
        target: listsViewLoader.item && listsViewLoader.visible ? listsViewLoader.item : searchViewLoader.item
        ignoreUnknownSignals: true

        onSearchFieldFocus: {
            topBar.searchFocus()
        }

        onPlayVideoAndAddToQueue: {
            var message
            if(subtitle.length) message = "Added to playing queue: " + title + " - " + subtitle
            else message = "Added to playing queue: " + title
            ApplicationManager.triggerNotification(message)
            playingModel.append({"id": id, "title": title, "subtitle": subtitle, "thumbnail": thumbnail, "duration": duration})
            UserManager.addedToQueue(id, title, subtitle, thumbnail, duration)

            playVideo(playingModel.count - 1)
        }

        onAddVideoToPlayQueue: {
            var message
            if(subtitle.length) message = "Added to playing queue: " + title + " - " + subtitle
            else message = "Added to playing queue: " + title
            ApplicationManager.triggerNotification(message)
            playingModel.append({"id": id, "title": title, "subtitle": subtitle, "thumbnail": thumbnail, "duration": duration})
            UserManager.addedToQueue(id, title, subtitle, thumbnail, duration)

            if(playingModel.count == 1) playVideo(0)
            else {
                if(shuffleEnabled) {
                    generateShuffleList()
                }
            }
        }

        onPlayVideoRequested: {
            playVideo(index)
        }

        onRemoveVideoRequested: {
            removeVideo(index)
        }

        onClearQueue: {
            playingModel.clear()
            UserManager.queueCleared()
            currentVideoIndex = -1
        }

        onAddAllToQueue: {
            var needsToPlay = false
            if(playingModel.count == 0) needsToPlay = true
            for(var i = 0; i < model.count; ++i)
            {
                var item = model.get(i)
                playingModel.append({"id": item.id, "title": item.title, "subtitle": item.subtitle,
                                        "thumbnail": item.thumbnail, "duration": item.duration})
                UserManager.addedToQueue(item.id, item.title, item.subtitle, item.thumbnail, item.duration)

                if(model.count == 1 && !needsToPlay) {
                    var message
                    if(item.subtitle.length) message = "Added to playing queue: " + item.title + " - " + item.subtitle
                    else message = "Added to playing queue: " + item.title
                    ApplicationManager.triggerNotification(message)
                }
            }

            if(shuffleEnabled) {
                generateShuffleList()
            }

            if(needsToPlay) {
                playNextVideo()
            }
            else {
                if(model.count > 1)
                {
                    ApplicationManager.triggerNotification("Added " + model.count + " items to playing queue")
                }
            }
        }

        onDragVideosStarted: {
            startVideosDrag(dragInfo)
        }

        onDragVideosFinished: {
            finishVideosDrag()
        }

        onLogoutRequested: {
            UserManager.logout()
            loggedOut()
        }
    }

    Connections {
        target: YoutubeAPI

        onVideoUrlSuccess: {
            console.log(url)
            mediaPlayer.mrl = url
            mediaPlayer.play()
        }

        onVideoUrlFailed: {
            console.log("Problem playing file: " + id)

            var element = playingModel.get(currentVideoIndex)

            if(element.id === id) {
                var message
                if(element.subtitle.length) message = "Problem playing item: " + element.title + " - " + element.subtitle
                else message = "Problem playing item: " + element.title
                ApplicationManager.triggerNotification(message)
                problemPlayingVideoTimer.start()
            }
        }

        onSuggestionSuccess: {
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

            playingModel.append({"id": id, "title": videoTitle, "subtitle": videoSubTitle, "thumbnail": thumbnail, "duration": duration})
            UserManager.addedToQueue(id, videoTitle, videoSubTitle, thumbnail, duration)

            suggestionRequested = false
        }

        onSuggestionFailed: {
            if(mediaPlayer.state === VlcPlayer.Playing ||  mediaPlayer.state === VlcPlayer.Paused) newSuggestion()
            else suggestionRequested = false
        }
    }

    Connections {
        target: UserManager

        onQueueItemAdded: {
            playingModel.append({"id": item.id, "title": item.title, "subtitle": item.subTitle, "thumbnail": item.thumbnail, "duration": item.duration})
            if(playingModel.count == 1) {
                sideBar.currentVideoID = item.id
                sideBar.currentTitle = item.title
                sideBar.currentSubTitle = item.subTitle
                sideBar.currentThumbnail = item.thumbnail
                sideBar.currentDuration = item.duration
                sideBar.currentVideoFavorited = PlaylistsManager.isFavorited(item.id)

                currentVideoIndex = 0
            }
        }
    }
}
