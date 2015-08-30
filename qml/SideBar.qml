import QtQuick 2.0
import QtQuick.Layouts 1.1
import BeatWhaleAPI 1.0
import QmlVlc 0.1
import "qrc:/components/qml/"

Rectangle {
    color: "white"

    property variant currentVideo
    property string currentVideoID
    property string currentThumbnail
    property string currentTitle: "No track selected"
    property string currentSubTitle
    property string currentDuration
    property bool currentVideoFavorited
    property bool videoMaximized: false
    property bool userSettings: false

    signal playlistCreated(string id)
    signal fullscreenVideoRequested
    signal maximizeVideoRequested
    signal minimizeVideoRequested
    signal requestScreen(string url)
    signal requestPlaylist(string name)
    signal addVideoToPlayQueue(string id, string title, string subtitle, string thumbnail, string duration)
    signal dragVideoStarted(string dragInfo)
    signal dragVideoFinished()

    onUserSettingsChanged: {
        if(userSettings) minimizeVideo()
    }

    function maximizeVideo() {
        video.visible = false
        videoMaximized = true

        maximizeVideoRequested()
    }

    function minimizeVideo() {
        videoMaximized = false
        video.visible = true

        minimizeVideoRequested()
    }

    Component {
        id: sidebarListButton
        BWButton {
            id: button
            width: sideBar.width
            height: 30
            color: "transparent"
            hoverColor: "#5000addc"
            selectedColor: "#00addc"
            checkable: true
            checked: sidebarList.selectedIndex == index && !videoMaximized && !userSettings

            property string caption
            property string url
            property int index
            property bool page

            onClicked: {
                if(page) {
                    minimizeVideo()
                    requestScreen(url)
                }
                else {
                    minimizeVideo()
                    requestPlaylist(caption)
                }

                userSettings = false
                sidebarList.selectedIndex = index
            }

            DropArea {
                id: dropArea
                enabled: !page || url == "PlayingQueue.qml"
                anchors.fill: parent
                keys: ["text/plain"]

                property bool dragging: ApplicationManager.dragging
                property bool dragHover: enabled && dragging && contains(Qt.point(dropArea.mapFromItem(null, ApplicationManager.mouseX, 0).x,
                                                                                  dropArea.mapFromItem(null, 0, ApplicationManager.mouseY).y))

                onDragHoverChanged: {
                    if(dragHover) {
                        button.color = "#00addc"
                        buttonText.dragging = true
                    }
                    else {
                        if(!checked) button.color = "transparent"
                        buttonText.dragging = false
                    }
                }

                onDraggingChanged: {
                    if(contains(Qt.point(dropArea.mapFromItem(null, ApplicationManager.mouseX, 0).x,
                                         dropArea.mapFromItem(null, 0, ApplicationManager.mouseY).y))) {
                        button.color = "transparent"
                        buttonText.dragging = false

                        if(!sidebarList.contains(Qt.point(sidebarList.mapFromItem(null, ApplicationManager.mouseX, 0).x,
                                                          sidebarList.mapFromItem(null, 0, ApplicationManager.mouseY).y))) return

                        var videosDraggedInfo = ApplicationManager.dragInfo()

                        if(videosDraggedInfo.indexOf("#!#!") === -1) return

                        var playlist = PlaylistsManager.playlist(caption)
                        var videoItems = videosDraggedInfo.split("##!##!")

                        var ids = new Array
                        var titles = new Array
                        var subTitles = new Array
                        var thumbnails = new Array
                        var durations = new Array

                        videoItems.pop()

                        for(var i = 0; i < videoItems.length; ++i) {
                            var videoSettings = videoItems[i].split("#!#!")

                            var id = videoSettings[0]
                            var title = videoSettings[1]
                            var subTitle = videoSettings[2]
                            var thumbnail = videoSettings[3]
                            var duration = videoSettings[4]

                            if(page) {
                                addVideoToPlayQueue(id, title, subTitle, thumbnail, duration)
                                if(videoItems.length > 1) {
                                    var message = "Added " + parseInt(videoItems.length) + " items to playing queue"
                                    ApplicationManager.triggerNotification(message)
                                }
                            }

                            ids.push(id)
                            titles.push(title)
                            subTitles.push(subTitle)
                            thumbnails.push(thumbnail)
                            durations.push(duration)
                        }

                        if(!page) playlist.addItems(ids, titles, subTitles, thumbnails, durations)
                    }
                }
            }

            Text {
                id: buttonText
                text: caption
                color: button.checked || dragging ? "white" : "#61666a"
                font.pixelSize: 13
                font.family: "Open Sans"
                horizontalAlignment: Text.AlignLeft

                property bool dragging: false

                anchors {
                    left: parent.left
                    leftMargin: 40
                    verticalCenter: parent.verticalCenter
                }
            }
        }
    }

    Component {
        id: sidebarListSeparator
        Item {
            opacity: 0.7
            width: sideBar.width
            height: 40

            property string caption
            property bool playlistSeparator

            Text {
                id: separatorText
                text: caption
                color: "#61666a"
                font.pixelSize: 11
                horizontalAlignment: Text.AlignLeft
                font.capitalization: Font.AllUppercase
                font.letterSpacing: 2

                anchors {
                    left: parent.left
                    leftMargin: 20
                    bottom: parent.bottom
                    bottomMargin: 5
                }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true

                onEntered: {
                    if(playlistSeparator) buttonAdd.opacity = 1
                }

                onExited: {
                    if(playlistSeparator) buttonAdd.opacity = 0
                }
            }

            Image {
                id: buttonAdd
                width: 25
                height: width
                sourceSize.width: 50
                sourceSize.height: 50
                source: "qrc:/images/addDark"
                opacity: 0
                visible: playlistSeparator

                anchors {
                    verticalCenter: separatorText.verticalCenter
                    right: parent.right
                    rightMargin: 20
                }

                Behavior on opacity {
                    NumberAnimation { duration: 200; easing.type: Easing.OutSine }
                }

                MouseArea {
                    anchors.fill: parent

                    onClicked: {
                        var playlist = PlaylistsManager.createPlaylist()
                        buttonsModel.append({"captionText": playlist.name, type: "playlist"})
                        sidebarList.selectedIndex = buttonsModel.count - 1
                        requestPlaylist(playlist.name)
                    }
                }
            }
        }
    }

    ListModel {
        id: buttonsModel

        ListElement {
            captionText: "Browse"
            url: ""
            type: "separator"
        }
        ListElement {
            captionText: "Search"
            url: "SearchView.qml"
            type: "page"
        }
        ListElement {
            captionText: "Discover"
            url: "DiscoverView.qml"
            type: "page"
        }
        ListElement {
            captionText: "Favorites"
            url: "FavoritesView.qml"
            type: "page"
        }
        ListElement {
            captionText: "Playing Queue"
            url: "PlayingQueue.qml"
            type: "page"
        }
        ListElement {
            captionText: "Playlists"
            url: ""
            type: "separator"
            playlistSeparator: true
        }
    }

    ListView {
        id: sidebarList
        width: parent.width
        model: buttonsModel
        clip: true

        property int selectedIndex: 1

        anchors {
            top: parent.top
            bottom: video.top
        }

        delegate: Loader {
            sourceComponent: type == "separator" ? sidebarListSeparator : sidebarListButton

            property string caption: captionText

            onCaptionChanged: {
                if(item) item.caption = caption
            }

            Component.onCompleted: {
                item.caption = caption
                if(type == "separator") item.playlistSeparator = playlistSeparator
                else {
                    item.index = index
                    item.page = (type == "page")
                    if(type == "page") item.url = url
                }
            }
        }
    }

    TOPScrollBar {
        flickable: sidebarList
    }

    Rectangle {
        color: "#cccccc"
        width: parent.width
        height: 1
        anchors {
            bottom: video.top
        }
    }

    Rectangle {
        color: "#111111"
        visible: !videoThumbnail.visible || videoThumbnail.source == ""
        anchors.fill: video
    }

    Image {
        id: videoThumbnail
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        anchors.fill: video
        visible: !video.visible || (mediaPlayer.state != VlcPlayer.Playing && mediaPlayer.state != VlcPlayer.Paused)
        source: currentThumbnail
    }

    VlcVideoSurface {
        id: video
        width: parent.width
        height: 200
        fillMode: Qt.KeepAspectRatioByExpanding
        source: currentVideo

        anchors {
            bottom: videoTitleHolder.top
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true

            onEntered: {
                if(!currentVideoID) return

                buttonShowVideoLarge.opacity = 1
                buttonShowVideoFullscreen.opacity = 1
                favoriteVideoImage.opacity = currentVideoFavorited ? .7 : .3
            }

            onExited: {
                buttonShowVideoLarge.opacity = 0
                buttonShowVideoFullscreen.opacity = 0
                favoriteVideoImage.opacity = 0
            }
        }

        Image {
            id: buttonShowVideoLarge
            width: 25
            height: 25
            //color: "white"
            source: "qrc:/images/zoomIn"
            opacity: 0

            sourceSize.width: 30
            sourceSize.height: 30

            anchors {
                right: buttonShowVideoFullscreen.left
                rightMargin: 5
                top: parent.top
                topMargin: 5
            }

            Behavior on opacity {
                NumberAnimation { property: "opacity"; duration: 200; easing.type: Easing.OutSine }
            }

            MouseArea {
                anchors.fill: parent

                onClicked: {
                    maximizeVideo()
                }
            }
        }

        Image {
            id: buttonShowVideoFullscreen
            width: 25
            height: 25
            //color: "white"
            source: "qrc:/images/fullscreen"
            opacity: 0

            sourceSize.width: 30
            sourceSize.height: 30

            anchors {
                right: parent.right
                rightMargin: 5
                top: parent.top
                topMargin: 5
            }

            Behavior on opacity {
                NumberAnimation { property: "opacity"; duration: 200; easing.type: Easing.OutSine }
            }

            MouseArea {
                anchors.fill: parent

                onClicked: {
                    video.visible = false
                    fullscreenVideoRequested()
                }
            }
        }

        Image {
            id: favoriteVideoImage
            width: 30
            height: width
            source: currentVideoFavorited ? "qrc:/images/heartChecked" : "qrc:/images/heartUnchecked"
            opacity: 0
            asynchronous: true
            smooth: true

            anchors {
                right: parent.right
                rightMargin: 5
                bottom: parent.bottom
                bottomMargin: 5
            }

            Behavior on opacity {
                NumberAnimation { property: "opacity"; duration: 200; easing.type: Easing.OutSine }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true

                onEntered: {
                    if(!currentVideoID) return

                    favoriteVideoImage.opacity = .7
                }

                onExited: {
                    if(!currentVideoID) return

                    if(!currentVideoFavorited) favoriteVideoImage.opacity = .3
                }

                onClicked: {
                    if(!currentVideoID) return

                    currentVideoFavorited = !currentVideoFavorited

                    if(currentVideoFavorited) PlaylistsManager.addToFavorites(currentVideoID, currentTitle, currentSubTitle, currentThumbnail, currentDuration)
                    else PlaylistsManager.removeFromFavorites(currentVideoID)
                }
            }
        }
    }

    Item {
        anchors.fill: video

        property bool dragActive: dragArea.drag.active
        Drag.dragType: Drag.Automatic

        onDragActiveChanged: {
            if(dragActive && currentVideoID) {
                Drag.start();

                var dragInfo = ""
                dragInfo += currentVideoID
                dragInfo += "#!#!"
                dragInfo += currentTitle
                dragInfo += "#!#!"
                dragInfo += currentSubTitle
                dragInfo += "#!#!"
                dragInfo += currentThumbnail
                dragInfo += "#!#!"
                dragInfo += currentDuration
                dragInfo += "##!##!"

                dragVideoStarted(dragInfo)
            }
            else {
                Drag.drop();
                dragVideoFinished()
            }
        }

        MouseArea {
            id: dragArea
            anchors.fill: parent
            drag.target: parent
            propagateComposedEvents: true
        }
    }

    Item {
        id: videoTitleHolder
        width: parent.width
        height: 55

        anchors {
            bottom: parent.bottom
        }

        Text {
            id: videoSubTitle
            color: "#51565a"
            text: currentSubTitle
            font.pixelSize: 13
            font.family: "Open Sans"
            visible: text.length

            anchors {
                left: parent.left
                leftMargin: 10

                top: parent.top
                topMargin: 5
            }
        }

        Text {
            id: videoTitle
            color: videoSubTitle.visible ? "#a5a9aa" : "#51565a"
            text: currentTitle
            font.pixelSize: 13
            font.family: "Open Sans"

            anchors {
                left: parent.left
                leftMargin: 10

                top: videoSubTitle.visible ? videoSubTitle.bottom : parent.top
                topMargin: 5
            }
        }
    }

    Connections {
        target: PlaylistsManager

        onPlaylistAdded: {
            buttonsModel.append({"captionText": name, type: "playlist"})
        }

        onPlaylistRemoved: {
            var removedIndex = 0;
            for(var i = 0; i < buttonsModel.count; ++i) {
                var item = buttonsModel.get(i)
                if(item.type !== "playlist") continue

                if(item.captionText === name) {
                    removedIndex = i
                    buttonsModel.remove(i)
                    break;
                }
            }

            if(removedIndex === sidebarList.selectedIndex)
                sidebarList.selectedIndex = buttonsModel.count - 1

            var selectedItem = buttonsModel.get(sidebarList.selectedIndex)

            while(selectedItem.type !== "playlist" && selectedItem.type !== "page")
            {
                --sidebarList.selectedIndex
                selectedItem = buttonsModel.get(sidebarList.selectedIndex)
            }

            if(selectedItem.type === "playlist") {
                requestPlaylist(selectedItem.captionText)
            }
            else {
                requestScreen(selectedItem.url)
            }
        }

        onPlaylistNameUpdated: {
            for(var i = 0; i < buttonsModel.count; ++i) {
                var item = buttonsModel.get(i)
                if(item.type !== "playlist") continue

                if(item.captionText === oldName)
                {
                    item.captionText = name
                    break;
                }
            }
        }
    }
}
