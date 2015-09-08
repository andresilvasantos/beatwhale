import QtQuick 2.2
import QtQuick.Layouts 1.1
import BeatWhaleAPI 1.0
import "qrc:/components/qml/"

Rectangle {
    id: rootRect
    color: "transparent"

    property bool controlKeyPressed: false
    property bool shiftKeyPressed: false
    property string nextPageToken
    property int pageNumber: 0
    property bool searchRequested: false
    property string searchText


    signal searchFieldFocus()
    signal playVideoAndAddToQueue(string id, string title, string subtitle, string thumbnail, string duration)
    signal addVideoToPlayQueue(string id, string title, string subtitle, string thumbnail, string duration)
    signal dragVideosStarted(string dragInfo)
    signal dragVideosFinished()

    signal showTooltip(string text, real x, real y)
    signal hideTooltip()

    function newSearch(search) {
        resultsGrid.videosSelected = []
        informativeText.text = "SEARCHING..."
        searchModel.clear()
        searchRequested = true
        pageNumber = 0
        searchText = search
        YoutubeAPI.search(search)
    }

    function checkLoadMore() {
        if(searchRequested || nextPageToken.length == 0 || pageNumber > 5) return;

        if(resultsGrid.contentY + resultsGrid.height > resultsGrid.contentHeight + 100) {
            searchRequested = true
            YoutubeAPI.search(searchText, nextPageToken)

            ++pageNumber
        }
    }

    ListModel {
        id: searchModel
    }

    Rectangle {
        id: mainPanel
        color: "#20e7ebee"

        anchors.fill: parent
        clip: true

        Text {
            id: informativeText
            text: "SEARCH FOR ANYTHING"
            font.family: "Open Sans"
            color: "#111111"
            font.pixelSize: 40
            font.letterSpacing: 2
            wrapMode: Text.WordWrap

            anchors.centerIn: parent

            visible: searchModel.count == 0 ? true : false
            opacity: visible ? .5 : 0

            Behavior on opacity {
                NumberAnimation { property: "opacity"; duration: 200; easing.type: Easing.OutSine }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true

                onEntered: {
                    ApplicationManager.setCursor(ApplicationManager.CURSORTYPE_BUTTON)
                }

                onExited: {
                    ApplicationManager.setCursor(ApplicationManager.CURSORTYPE_NORMAL)
                }

                onClicked: {
                    ApplicationManager.setCursor(ApplicationManager.CURSORTYPE_NORMAL)
                    visible = false
                    searchFieldFocus()
                }
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

                property int cellSize: 200
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

                    onShowTooltip: {
                        rootRect.showTooltip(text, x + thumbnailDelegate.x + resultsGridHolder.x,
                                             y + thumbnailDelegate.y + resultsGridHolder.y - resultsGrid.contentY)
                    }

                    onHideTooltip: {
                        rootRect.hideTooltip()
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
