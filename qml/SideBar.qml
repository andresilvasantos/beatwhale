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
    property bool thumbnailHovered: false

    signal playlistCreated(string id)
    signal fullscreenVideoRequested
    signal maximizeVideoRequested
    signal minimizeVideoRequested
    signal requestScreen(string url)
    signal requestPlaylist(string name)
    signal addVideoToPlayQueue(string id, string title, string subtitle, string thumbnail, string duration)
    signal addPlaylistToPlayQueue(string name)
    signal dragVideoStarted(string dragInfo)
    signal dragVideoFinished()
    signal openYoutubeLink(string id)

    onUserSettingsChanged: {
        if(userSettings) minimizeVideo()
    }

    onThumbnailHoveredChanged: {
        if(thumbnailHovered) {
            if(!currentVideoID) return

            playlistInfo.opacity = 1
            buttonShowVideoLarge.opacity = 1
            buttonShowVideoFullscreen.opacity = 1
            favoriteVideoImage.opacity = currentVideoFavorited ? .7 : .3
            youtubeLinkImage.opacity = .7
        }
        else {
            playlistInfo.opacity = 0
            buttonShowVideoLarge.opacity = 0
            buttonShowVideoFullscreen.opacity = 0
            favoriteVideoImage.opacity = 0
            youtubeLinkImage.opacity = 0
        }
    }

    function searchRequested() {
        sidebarList.selectedIndex = 1
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
            color: "#fdfdfd"
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

            onDoubleClicked: {
                if(!page) {
                    addPlaylistToPlayQueue(caption)
                }
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
                    if(!enabled) return
                    if(contains(Qt.point(dropArea.mapFromItem(null, ApplicationManager.mouseX, 0).x,
                                         dropArea.mapFromItem(null, 0, ApplicationManager.mouseY).y))) {
                        if(!checked) button.color = "transparent"
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

                Behavior on color {
                    ColorAnimation {duration: 200; easing.type: Easing.OutSine}
                }
            }
        }
    }

    Component {
        id: sidebarListSeparator
        Item {
            width: sideBar.width
            height: 40

            property string caption
            property bool playlistSeparator

            Text {
                id: separatorText
                text: caption
                color: "#61666a"
                opacity: .7
                font.pixelSize: 10
                font.family: "Arial"
                horizontalAlignment: Text.AlignLeft
                font.capitalization: Font.AllUppercase
                font.letterSpacing: 2

                anchors {
                    left: parent.left
                    leftMargin: 20
                    bottom: parent.bottom
                    bottomMargin: 10
                }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true

                onEntered: {
                    if(playlistSeparator) buttonAdd.show = true
                }

                onExited: {
                    if(playlistSeparator) buttonAdd.show = false
                }
            }

            Rectangle {
                id: buttonAddStrobe
                width: 30
                height: width
                color: "#00addc"
                radius: width * .5
                opacity: .2
                visible: playlistSeparator && buttonsModel.count == 6
                scale: .7

                anchors.centerIn: buttonAdd

                SequentialAnimation on scale {
                    loops: Animation.Infinite
                    NumberAnimation {to: .7; duration: 1000; easing.type: Easing.OutSine}
                    PauseAnimation { duration: 2000 }
                    NumberAnimation {to: 1; duration: 1000; easing.type: Easing.OutSine}
                    NumberAnimation {to: .7; duration: 1000; easing.type: Easing.OutSine}
                    NumberAnimation {to: 1; duration: 1000; easing.type: Easing.OutSine}
                }
            }

            Rectangle {
                width: 20
                height: width
                color: "white"
                radius: width * .5
                visible: buttonAddStrobe.visible

                anchors.centerIn: buttonAdd
            }

            Image {
                id: buttonAdd
                width: 26
                height: width
                sourceSize.width: 52
                sourceSize.height: 52
                source: "qrc:/buttons/addDark"
                opacity: {
                    if(buttonsModel.count == 6) {
                        if(hovered) return 1
                        return .7
                    }
                    else {
                        if(show) return .7
                        else if(hovered) return 1
                    }
                    return 0
                }
                visible: playlistSeparator

                anchors {
                    verticalCenter: separatorText.verticalCenter
                    right: parent.right
                    rightMargin: 20
                }

                Behavior on opacity {
                    NumberAnimation { duration: 200; easing.type: Easing.OutSine }
                }

                Behavior on scale {
                    NumberAnimation { duration: 200; easing.type: Easing.OutSine }
                }

                property bool show: false
                property bool hovered: false

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true

                    onEntered: {
                        ApplicationManager.setCursor(ApplicationManager.CURSORTYPE_BUTTON)
                        ApplicationManager.triggerTooltip("Create New Playlist", 15, -10, 1200)
                        parent.hovered = true
                    }

                    onExited: {
                        ApplicationManager.setCursor(ApplicationManager.CURSORTYPE_NORMAL)
                        ApplicationManager.cancelTooltip()

                        parent.hovered = false
                    }

                    onPressed: {
                        parent.scale = 1.1
                    }

                    onReleased: {
                        parent.scale = 1
                    }

                    onClicked: {
                        var playlist = PlaylistsManager.createPlaylist()
                    }
                }
            }
        }
    }

    BWListModel {
        id: buttonsModel
        sortColumnName: "captionText"

        Component.onCompleted: {
            buttonsModel.append({"captionText": "Browse", url: "", type: "separator"})
            buttonsModel.append({"captionText": "Search", url: "SearchView.qml", type: "page"})
            buttonsModel.append({"captionText": "Discover", url: "DiscoverView.qml", type: "page"})
            buttonsModel.append({"captionText": "Favorites", url: "FavoritesView.qml", type: "page"})
            buttonsModel.append({"captionText": "Playing Queue", url: "PlayingQueue.qml", type: "page"})
            buttonsModel.append({"captionText": "Playlists", url: "", type: "separator", playlistSeparator: true})
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
            property int currentIndex: index

            onCaptionChanged: {
                if(item) item.caption = caption
            }

            onCurrentIndexChanged: {
                if(item && type != "separator") item.index = currentIndex
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
        height: sidebarList.height
        flickable: sidebarList
        anchors.right: sidebarList.right
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

        onVisibleChanged: {
            playlistInfo.opacity = 0
            buttonShowVideoLarge.opacity = 0
            buttonShowVideoFullscreen.opacity = 0
            favoriteVideoImage.opacity = 0
            youtubeLinkImage.opacity = 0
        }

        Item {
            anchors.fill: parent

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
                hoverEnabled: true

                onEntered: {
                    thumbnailHovered = true
                }

                onExited: {
                    thumbnailHovered = false
                }
            }
        }

        Rectangle {
            id: playlistInfo
            width: 8
            height: width
            radius: width * .5
            border.width: 1
            border.color: "#333333"
            color: "#cccccc"
            visible: playlists.length
            opacity: 0

            property var playlists: PlaylistsManager.itemPlaylists(currentVideoID, "")

            anchors {
                left: parent.left
                leftMargin: 13
                verticalCenter: buttonShowVideoLarge.verticalCenter
            }

            Behavior on opacity {
                NumberAnimation { duration: 200; easing.type: Easing.OutSine }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true

                onEntered: {
                    parent.opacity = 1
                    ApplicationManager.triggerTooltip(parent.playlists, 15, 0, 0)
                }

                onExited: {
                    ApplicationManager.cancelTooltip()
                }
            }
        }

        Image {
            id: buttonShowVideoLarge
            width: 25
            height: 25
            source: "qrc:/buttons/enlarge"
            opacity: 0
            sourceSize.width: width
            sourceSize.height: height
            smooth: false

            anchors {
                right: buttonShowVideoFullscreen.left
                rightMargin: 5
                top: parent.top
                topMargin: 4
            }

            Behavior on opacity {
                NumberAnimation { duration: 200; easing.type: Easing.OutSine }
            }

            Behavior on scale {
                NumberAnimation { duration: 200; easing.type: Easing.OutSine }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true

                onEntered: {
                    thumbnailHovered = true

                    parent.opacity = 1
                    parent.scale = 1.1
                    ApplicationManager.setCursor(ApplicationManager.CURSORTYPE_BUTTON)
                    ApplicationManager.triggerTooltip("Maximize Video", 10, 0, 1200)
                }

                onExited: {
                    parent.scale = 1
                    ApplicationManager.setCursor(ApplicationManager.CURSORTYPE_NORMAL)
                    ApplicationManager.cancelTooltip()
                }

                onClicked: {
                    maximizeVideo()
                }
            }
        }

        Image {
            id: buttonShowVideoFullscreen
            width: 25
            height: 25
            source: "qrc:/buttons/fullscreen"
            opacity: 0
            sourceSize.width: width
            sourceSize.height: height
            smooth: false

            anchors {
                right: parent.right
                rightMargin: 5
                top: parent.top
                topMargin: 5
            }

            Behavior on opacity {
                NumberAnimation { duration: 200; easing.type: Easing.OutSine }
            }

            Behavior on scale {
                NumberAnimation { duration: 200; easing.type: Easing.OutSine }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true

                onEntered: {
                    thumbnailHovered = true

                    parent.opacity = 1
                    parent.scale = 1.1
                    ApplicationManager.setCursor(ApplicationManager.CURSORTYPE_BUTTON)
                    ApplicationManager.triggerTooltip("Fullscreen", 10, 0, 1200)
                }

                onExited: {
                    ApplicationManager.setCursor(ApplicationManager.CURSORTYPE_NORMAL)
                    ApplicationManager.cancelTooltip()
                    parent.scale = 1
                }

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
            source: currentVideoFavorited ? "qrc:/buttons/heartChecked" : "qrc:/buttons/heartUnchecked"
            sourceSize.width: width
            sourceSize.height: height
            opacity: 0
            asynchronous: true
            smooth: false

            anchors {
                right: parent.right
                rightMargin: 5
                bottom: parent.bottom
                bottomMargin: 5
            }

            Behavior on opacity {
                NumberAnimation { duration: 200; easing.type: Easing.OutSine }
            }

            Behavior on scale {
                NumberAnimation { duration: 200; easing.type: Easing.OutSine }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true

                onEntered: {
                    thumbnailHovered = true

                    if(!currentVideoID) return

                    favoriteVideoImage.opacity = .7
                    ApplicationManager.setCursor(ApplicationManager.CURSORTYPE_BUTTON)
                    ApplicationManager.triggerTooltip(currentVideoFavorited ? "Remove From Favorites" : "Add To Favorites", 10, 0, 1200)
                }

                onExited: {
                    if(!currentVideoID) return

                    if(!currentVideoFavorited) favoriteVideoImage.opacity = .3
                    ApplicationManager.setCursor(ApplicationManager.CURSORTYPE_NORMAL)
                    ApplicationManager.cancelTooltip()
                }

                onClicked: {
                    if(!currentVideoID) return

                    currentVideoFavorited = !currentVideoFavorited

                    if(currentVideoFavorited) PlaylistsManager.addFavorite(currentVideoID, currentTitle, currentSubTitle, currentThumbnail, currentDuration)
                    else PlaylistsManager.removeFavorite(currentVideoID)
                }

                onPressed: {
                    parent.scale = 1.1
                }

                onReleased: {
                    parent.scale = 1
                }
            }
        }


        Image {
            id: youtubeLinkImage
            width: 30
            height: width
            source: "qrc:/buttons/youtube"
            sourceSize.width: width
            sourceSize.height: height
            opacity: 0
            asynchronous: true
            smooth: false

            anchors {
                right: favoriteVideoImage.left
                rightMargin: 5
                bottom: parent.bottom
                bottomMargin: 5
            }

            Behavior on opacity {
                NumberAnimation { duration: 200; easing.type: Easing.OutSine }
            }

            Behavior on scale {
                NumberAnimation { duration: 200; easing.type: Easing.OutSine }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true

                onEntered: {
                    thumbnailHovered = true

                    if(!currentVideoID) return

                    youtubeLinkImage.opacity = .7
                    ApplicationManager.setCursor(ApplicationManager.CURSORTYPE_BUTTON)
                    ApplicationManager.triggerTooltip("Open Video on YouTube", 10, 0, 1200)
                }

                onExited: {
                    if(!currentVideoID) return

                    youtubeLinkImage.opacity = .3
                    ApplicationManager.setCursor(ApplicationManager.CURSORTYPE_NORMAL)
                    ApplicationManager.cancelTooltip()
                }

                onClicked: {
                    if(!currentVideoID) return

                    openYoutubeLink(currentVideoID)
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

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true

                onEntered: {
                    ApplicationManager.triggerTooltip(currentSubTitle, 10, 0, 1200)
                }

                onExited: {
                    ApplicationManager.cancelTooltip()
                }
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

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true

                onEntered: {
                    ApplicationManager.triggerTooltip(currentTitle, 10, 0, 1200)
                }

                onExited: {
                    ApplicationManager.cancelTooltip()
                }
            }
        }
    }

    Connections {
        target: PlaylistsManager

        onPlaylistAdded: {
            buttonsModel.append({"captionText": name, type: "playlist"})
            buttonsModel.quick_sort_starting_at(6)
        }

        onPlaylistCreated: {
            buttonsModel.append({"captionText": name, type: "playlist"})
            buttonsModel.quick_sort_starting_at(6)

            var found = false
            for(var i = 6; i < buttonsModel.count; ++i) {
                var playlistElement = buttonsModel.get(i)
                if(playlistElement.captionText == name) {
                    sidebarList.selectedIndex = i
                    found = true
                    break
                }
            }

            if(!found) sidebarList.selectedIndex = buttonsModel.count - 1

            requestPlaylist(name)
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
                    buttonsModel.quick_sort_starting_at(6)

                    for(var j = 6; j < buttonsModel.count; ++j) {
                        var playlistElement = buttonsModel.get(j)
                        if(playlistElement.captionText == name) {
                            sidebarList.selectedIndex = j
                            break
                        }
                    }

                    break;
                }
            }
        }
    }
}
