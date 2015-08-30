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

    ListModel {
        id: tagsModel

        ListElement {
            tag: "VIDEO CLIP"
        }

        ListElement {
            tag: "DUBSTEP"
        }

        ListElement {
            tag: "CLASSIC"
        }

        ListElement {
            tag: "ROCK"
        }

        ListElement {
            tag: "HOUSE"
        }

        ListElement {
            tag: "SAMBA"
        }

        ListElement {
            tag: "FLUTE"
        }

        ListElement {
            tag: "ACOUSTIC"
        }

        ListElement {
            tag: "GUITAR"
        }

        ListElement {
            tag: "ELECTRONIC"
        }

        ListElement {
            tag: "MINIMAL"
        }

        ListElement {
            tag: "PIANO"
        }

        ListElement {
            tag: "TECHNO"
        }

        ListElement {
            tag: "SOUNDTRACK"
        }

        ListElement {
            tag: "TANGO"
        }

        ListElement {
            tag: "DEEP"
        }

        ListElement {
            tag: "HIPSTER"
        }

        ListElement {
            tag: "EMOTIONAL"
        }

        ListElement {
            tag: "CHILL-OUT"
        }

        ListElement {
            tag: "REGGAE"
        }

        ListElement {
            tag: "TRIP HOP"
        }

        ListElement {
            tag: "HIP HOP"
        }

        ListElement {
            tag: "INDIE"
        }

        ListElement {
            tag: "SINGER"
        }
    }

    ListModel {
        id: searchModel
    }

    Rectangle {
        id: tagsHolder
        color: "#c5c5c5"
        width: 150
        height: parent.height

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
                    //Always select videoclip first
                    if(index == 0) {
                        checked = true
                        tagChecked(checked, 0)
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
        //width: parent.width
        height: parent.height

        anchors {
            left: tagsHolder.right
            right: parent.right
        }

        clip: true

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
                        tooltip.displayText = text
                        tooltip.x = thumbnailDelegate.x + x
                        tooltip.y = thumbnailDelegate.y + y - resultsGrid.contentY
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

            for(var key in obj) {
                if(key === "nextPageToken") continue

                var videoID = key
                var title = obj[key]["title"]
                var videoThumbnailUrl = obj[key]["thumbnail"]
                var videoDuration = obj[key]["duration"]

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
