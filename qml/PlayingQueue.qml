import QtQuick 2.0
import BeatWhaleAPI 1.0
import "qrc:/components/qml/"

Rectangle {
    id: rootRect
    color: "transparent"

    property bool controlKeyPressed: false
    property bool shiftKeyPressed: false

    signal playVideoRequested(int index)
    signal removeVideoRequested(int index)
    signal dragVideosStarted(string dragInfo)
    signal dragVideosFinished()

    signal showTooltip(string text, real x, real y)
    signal hideTooltip()

    Rectangle {
        id: mainPanel
        color: "#20e7ebee"
        anchors.fill: parent
        clip: true

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

                    onShowTooltip: {
                        rootRect.showTooltip(text, x + thumbnailDelegate.x + resultsGridHolder.x,
                                             y + thumbnailDelegate.y + resultsGridHolder.y - resultsGrid.contentY + resultsGrid.topMarginValue)
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
        height: 50
        color: "#bb333333"

        Text {
            id: screenName
            text: "Playing Right Now"
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
        }

        BWButton {
            id: buttonClearQueue
            color: "#656565"
            hoverColor: "#545454"
            selectedColor: "#898989"
            width: buttonClearQueueText.width + 20
            height: 28
            radius: 5

            anchors {
                right: parent.right
                rightMargin: 20
                verticalCenter: parent.verticalCenter
            }

            Text {
                id: buttonClearQueueText
                text: "Clear Queue"
                color: "white"
                font.pixelSize: 14

                anchors.centerIn: parent
            }

            onClicked: {
                resultsGrid.videosSelected = []
                playingModel.clear()
                UserManager.queueCleared()
            }
        }
    }
}
