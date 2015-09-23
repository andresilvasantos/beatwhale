import QtQuick 2.0
import BeatWhaleAPI 1.0

Rectangle {
    id: resultRect
    color: "transparent"

    property string videoID
    property string videoTitle
    property string videoSubTitle
    property string videoThumbnail
    property string videoDuration
    property string playlistName: ""
    property bool playQueue: false
    property bool playlist: false
    property bool selected
    property bool currentlyPlaying: false
    property bool favorited: PlaylistsManager.isFavorited(id)
    property bool thumbnailHovered: false

    signal addVideo()
    signal playVideo()
    signal removeVideo(string id)
    signal selectionRequest()

    signal entered()
    signal exited()

    signal dragStarted()
    signal dragFinished()

    onThumbnailHoveredChanged: {

        if(thumbnailHovered) {
            thumbnailHovered = true
            playNowImage.opacity = .5
            addToQueueImage.opacity = .5
            removeVideoImage.opacity = .3
            favoriteVideoImage.opacity = favorited ? .7 : .3
            thumbnailHovered = true

            resultRect.entered()
        }
        else {
            playNowImage.opacity = 0
            addToQueueImage.opacity = 0
            removeVideoImage.opacity = 0
            if(!favorited) favoriteVideoImage.opacity = 0
            thumbnailHovered = false

            resultRect.exited()
        }
    }


    Rectangle {
        id: videoSelectionRect
        width: thumbnailImage.width + 6
        height: thumbnailImage.height + 6
        color: "transparent"
        radius: 5
        border.color: "#00addc"
        border.width: 5
        visible: selected

        anchors {
            top: parent.top
            horizontalCenter: parent.horizontalCenter
        }
    }

    Rectangle {
        color: "#cccccc"
        anchors.fill: thumbnailImage
        visible: thumbnailImage.status != Image.Ready
    }

    Image {
        id: thumbnailImage
        width: parent.width - 30
        height: parent.height - titleText.height - subTitleText.height - 50
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        smooth: true
        cache: true

        sourceSize.width: width + width * .2
        sourceSize.height: height + height * .2

        anchors {
            top: parent.top
            topMargin: 3
            horizontalCenter: parent.horizontalCenter
        }

        source: videoThumbnail

        Item {
            id: dragItem
            anchors.fill: parent

            property bool dragActive: dragArea.drag.active
            Drag.dragType: Drag.Automatic

            onDragActiveChanged: {
                if(dragActive) {
                    if(!selected) selectionRequest()
                    Drag.start();
                    dragStarted()
                    ApplicationManager.setCursor(ApplicationManager.CURSORTYPE_DRAGGING)
                }
                else {
                    Drag.drop();
                    dragFinished()
                    ApplicationManager.setCursor(ApplicationManager.CURSORTYPE_NORMAL)
                }
            }

            MouseArea {
                id: dragArea
                anchors.fill: parent
                drag.target: parent
                hoverEnabled: true

                onEntered: {
                    thumbnailHovered = true
                }

                onExited: {
                    thumbnailHovered = false
                }

                onClicked: {
                    selectionRequest()
                }
            }
        }

        Rectangle {
            color: "black"
            width: durationText.width + 8
            height: durationText.height + 4
            opacity: .7
            visible: durationText.text.length

            anchors.centerIn: durationText
        }

        Text {
            id: durationText
            text: videoDuration
            color: "white"
            font.bold: true
            font.pixelSize: 11
            font.family: "Open Sans"
            opacity: .8

            anchors {
                left: parent.left
                leftMargin: 8
                top: parent.top
                topMargin: 6
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

            property var playlists: PlaylistsManager.itemPlaylists(videoID, playlistName)

            anchors {
                left: durationText.right
                leftMargin: 10
                verticalCenter: durationText.verticalCenter
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true

                onEntered: {
                    var playlistsStr = ""
                    for(var i = 0; i < parent.playlists.length; ++i) {
                        playlistsStr += parent.playlists[i]
                        if(i < parent.playlists.length - 1)
                            playlistsStr += "\n"
                    }

                    ApplicationManager.triggerTooltip(playlistsStr, 15, 0, 0)
                }

                onExited: {
                    ApplicationManager.cancelTooltip()
                }
            }
        }

        Image {
            id: removeVideoImage
            width: 30
            height: width
            sourceSize.width: width
            sourceSize.height: width
            source: "qrc:/buttons/remove"
            opacity: 0
            asynchronous: true
            smooth: false
            visible: (playQueue || playlist) && opacity != 0

            anchors {
                right: parent.right
                rightMargin: 5
                top: parent.top
                topMargin: 5
            }

            Behavior on opacity {
                NumberAnimation { property: "opacity"; duration: 400; easing.type: Easing.OutSine }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true

                onEntered: {
                    thumbnailHovered = true
                    removeVideoImage.opacity = .7
                    ApplicationManager.setCursor(ApplicationManager.CURSORTYPE_BUTTON)
                    ApplicationManager.triggerTooltip("Remove Video", 10, 0, 1200)
                }

                onExited: {
                    removeVideoImage.opacity = .3
                    ApplicationManager.setCursor(ApplicationManager.CURSORTYPE_NORMAL)
                    ApplicationManager.cancelTooltip()
                }

                onClicked: {
                    ApplicationManager.setCursor(ApplicationManager.CURSORTYPE_NORMAL)
                    ApplicationManager.cancelTooltip()
                    if(playQueue || playlist) removeVideo(videoID)
                }
            }
        }

        Image {
            id: favoriteVideoImage
            width: 30
            height: width
            sourceSize.width: width
            sourceSize.height: width
            source: favorited ? "qrc:/buttons/heartChecked" : "qrc:/buttons/heartUnchecked"
            opacity: favorited ? .7 : 0
            asynchronous: true
            smooth: true
            visible: opacity != 0

            anchors {
                left: parent.left
                leftMargin: 5
                bottom: parent.bottom
                bottomMargin: 5
            }


            Behavior on opacity {
                NumberAnimation { property: "opacity"; duration: 400; easing.type: Easing.OutSine }
            }

            Behavior on scale {
                NumberAnimation { duration: 200; easing.type: Easing.OutSine }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true

                onEntered: {
                    thumbnailHovered = true
                    favoriteVideoImage.opacity = .7
                    ApplicationManager.setCursor(ApplicationManager.CURSORTYPE_BUTTON)
                    ApplicationManager.triggerTooltip(favorited ? "Remove From Favorites" : "Add To Favorites", 10, 0, 1200)
                }

                onExited: {
                    if(!favorited) favoriteVideoImage.opacity = .3
                    ApplicationManager.setCursor(ApplicationManager.CURSORTYPE_NORMAL)
                    ApplicationManager.cancelTooltip()
                }

                onClicked: {
                    ApplicationManager.setCursor(ApplicationManager.CURSORTYPE_NORMAL)
                    ApplicationManager.cancelTooltip()

                    favorited = !favorited

                    if(favorited) PlaylistsManager.addFavorite(videoID, videoTitle, videoSubTitle, videoThumbnail, videoDuration)
                    else PlaylistsManager.removeFavorite(videoID)
                }

                onPressed: {
                    parent.scale = 1.2
                }

                onReleased: {
                    parent.scale = 1
                }
            }
        }

        Image {
            id: addToQueueImage
            width: 30
            height: width
            sourceSize.width: width
            sourceSize.height: width
            source: "qrc:/buttons/addQueue"
            opacity: 0
            asynchronous: true
            smooth: true
            visible: !playQueue && opacity != 0

            anchors {
                right: playNowImage.left
                rightMargin: 2
                bottom: parent.bottom
                bottomMargin: 5
            }

            Behavior on opacity {
                NumberAnimation { property: "opacity"; duration: 400; easing.type: Easing.OutSine }
            }

            Behavior on scale {
                NumberAnimation { duration: 200; easing.type: Easing.OutSine }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true

                onEntered: {
                    thumbnailHovered = true
                    addToQueueImage.opacity = 1
                    ApplicationManager.setCursor(ApplicationManager.CURSORTYPE_BUTTON)
                    ApplicationManager.triggerTooltip("Add To Playing Queue", 10, 0, 1200)
                }

                onExited: {
                    addToQueueImage.opacity = .5
                    ApplicationManager.setCursor(ApplicationManager.CURSORTYPE_NORMAL)
                    ApplicationManager.cancelTooltip()
                }

                onClicked: {
                    addVideo()
                }

                onPressed: {
                    parent.scale = 1.2
                }

                onReleased: {
                    parent.scale = 1
                }
            }
        }

        Image {
            id: playNowImage
            width: 30
            height: width
            sourceSize.width: width
            sourceSize.height: width
            source: "qrc:/buttons/play"
            opacity: 0
            asynchronous: true
            smooth: true
            visible: opacity != 0

            anchors {
                right: parent.right
                rightMargin: 5
                bottom: parent.bottom
                bottomMargin: 5
            }

            Behavior on opacity {
                NumberAnimation { property: "opacity"; duration: 400; easing.type: Easing.OutSine }
            }

            Behavior on scale {
                NumberAnimation { duration: 200; easing.type: Easing.OutSine }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true

                onEntered: {
                    thumbnailHovered = true
                    playNowImage.opacity = 1

                    ApplicationManager.setCursor(ApplicationManager.CURSORTYPE_BUTTON)
                    ApplicationManager.triggerTooltip("Play Now", 10, 0, 1200)
                }

                onExited: {
                    playNowImage.opacity = .5

                    ApplicationManager.setCursor(ApplicationManager.CURSORTYPE_NORMAL)
                    ApplicationManager.cancelTooltip()
                }

                onClicked: {
                    playVideo()
                }

                onPressed: {
                    parent.scale = 1.2
                }

                onReleased: {
                    parent.scale = 1
                }
            }
        }
    }

    Text {
        id: subTitleText
        text: videoSubTitle
        color: "#51565a"
        width: parent.width - 40
        elide: Text.ElideRight
        horizontalAlignment: Text.AlignLeft
        visible: text.length
        font.family: "Open Sans"

        anchors {
            top: thumbnailImage.bottom
            topMargin: 8
            left: thumbnailImage.left
            leftMargin: 5
        }

        MouseArea {
            id: subTitleTextMouseArea
            anchors.fill: parent
            hoverEnabled: true

            onEntered: {
                ApplicationManager.triggerTooltip(videoSubTitle, 10, 0, 1200)
            }

            onExited: {
                ApplicationManager.cancelTooltip()
            }
        }
    }

    Text {
        id: titleText
        text: videoTitle
        color: subTitleText.visible ? "#a5a9aa" : "#51565a"
        width: parent.width - 40
        elide: Text.ElideRight
        horizontalAlignment: Text.AlignLeft
        font.family: "Open Sans"

        anchors {
            top: subTitleText.visible ? subTitleText.bottom : thumbnailImage.bottom
            topMargin: subTitleText.visible ? 2 : 8
            left: thumbnailImage.left
            leftMargin: 5
        }

        MouseArea {
            id: titleTextMouseArea
            anchors.fill: parent
            hoverEnabled: true

            onEntered: {
                ApplicationManager.triggerTooltip(videoTitle, 10, 0, 1200)
            }

            onExited: {
                ApplicationManager.cancelTooltip()
            }
        }
    }
}
