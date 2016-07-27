import QtQuick 2.0
import BeatWhaleAPI 1.0
import "qrc:/components/qml/"

Rectangle {
    id: rootRect
    color: "transparent"

    property bool controlKeyPressed: false
    property bool shiftKeyPressed: false
    property bool menuOpened: false

    signal playVideoRequested(int index)
    signal removeVideoRequested(int index)
    signal clearQueue()
    signal dragVideosStarted(string dragInfo)
    signal dragVideosFinished()


    Rectangle {
        id: mainPanel
        color: "#20e7ebee"
        anchors.fill: parent
        clip: true

        Image {
            source: "qrc:/images/backgroundPattern"
            fillMode: Image.PreserveAspectCrop
            opacity: playingModel.count ? 0 : .1
            visible: opacity != 0
            asynchronous: true
            anchors.fill: parent

            Behavior on opacity {
                NumberAnimation { duration: 200; easing.type: Easing.OutSine }
            }
        }

        Text {
            id: informativeText
            text: "NOTHING COOL TO PLAY?"
            color: "#111111"
            font.pixelSize: 40
            font.letterSpacing: 2
            wrapMode: Text.WordWrap

            anchors.centerIn: parent

            opacity: playingModel.count === 0 ? .5 : 0

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

                add: Transition {
                    NumberAnimation { properties: "opacity"; from: 0; to: 1; duration: 200; easing.type: Easing.OutSine }
                }

                move: Transition {
                    NumberAnimation { properties: "x,y"; duration: 200; easing.type: Easing.OutSine }
                }

                model: playingModel
                delegate: VideoThumbnail {
                    id: thumbnailDelegate
                    width: resultsGrid.cellSize
                    height: resultsGrid.cellSize

                    videoID: id
                    videoTitle: title
                    videoSubTitle: subtitle
                    videoThumbnail: thumbnail
                    videoDuration: duration
                    playQueue: true
                    currentlyPlaying: currentVideoIndex == index
                    opacity: currentVideoIndex == index ? 1 : .5 + hoverOpacity
                    selected: resultsGrid.videosSelected.indexOf(index) > -1

                    property real hoverOpacity: 0

                    Behavior on opacity {
                        NumberAnimation { duration: 200; easing.type: Easing.OutSine}
                    }

                    onEntered: {
                        hoverOpacity = .3
                    }

                    onExited: {
                        hoverOpacity = 0
                    }

                    onPlayVideo: {
                        rootRect.playVideoRequested(index)
                    }

                    onRemoveVideo: {
                        resultsGrid.videosSelected = []
                        rootRect.removeVideoRequested(index)
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
                        for(var i = resultsGrid.videosSelected.length - 1; i >= 0; --i) {
                            rootRect.removeVideoRequested(resultsGrid.videosSelected[i])
                        }
                        resultsGrid.videosSelected = []
                    }
                }

                DropArea {
                    id: dropArea
                    anchors.fill: parent

                    property bool dragging: ApplicationManager.dragging

                    onDraggingChanged: {
                        if(dragging) return
                        var point = Qt.point(dropArea.mapFromItem(null, ApplicationManager.mouseX, 0).x, dropArea.mapFromItem(null, 0, ApplicationManager.mouseY).y)
                        if(contains(point)) {

                            function sortNumber(a,b) {
                                return a - b;
                            }

                            var overIndex = resultsGrid.indexAt(point.x, point.y + resultsGrid.contentY)
                            resultsGrid.videosSelected.sort(sortNumber)

                            var subtract = 0
                            var newVideosSelected = new Array
                            for(var i = 0; i < resultsGrid.videosSelected.length; ++i) {
                                if(overIndex === -1) overIndex = resultsGrid.model.count - 1
                                if(overIndex > resultsGrid.videosSelected[i]) {
                                    resultsGrid.model.move(resultsGrid.videosSelected[i] - subtract, overIndex, 1)
                                    ++subtract

                                    for(var j = 0; j < newVideosSelected.length; ++j) {
                                        var selection = newVideosSelected[j]
                                        newVideosSelected[j] = --selection
                                    }
                                }
                                else
                                {
                                    resultsGrid.model.move(resultsGrid.videosSelected[i], overIndex, 1)

                                    for(j = 0; j < newVideosSelected.length; ++j) {
                                        selection = newVideosSelected[j]
                                        newVideosSelected[j] = ++selection
                                    }
                                }

                                newVideosSelected.push(overIndex)
                            }

                            resultsGrid.videosSelected = newVideosSelected
                        }
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
            text: "Playing Right Now"
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
                optionsModel.append({"name": "Add selected to playlist...", "danger": false, "active": resultsGrid.videosSelected.length})
                optionsModel.append({"name": "Remove selected", "danger": false, "active": resultsGrid.videosSelected.length})
                optionsModel.append({"name": "Clear queue", "danger": false, "active": resultsGrid.model.count})
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
                playlistSelectionPopUp.visible = true
                playlistSelectionPopUp.forceActiveFocus()
                topBar.enabled = false
                mainPanel.enabled = false
                break;
            case 1:
                if(resultsGrid.videosSelected.length) {
                    for(var i = resultsGrid.videosSelected.length - 1; i >= 0; --i) {
                        rootRect.removeVideoRequested(resultsGrid.videosSelected[i])
                    }
                    resultsGrid.videosSelected = []
                }
                break;
            case 2:
                resultsGrid.videosSelected = []
                clearQueue()
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
}
