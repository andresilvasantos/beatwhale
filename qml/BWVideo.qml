import QtQuick 2.0
import QmlVlc 0.1
import BeatWhaleAPI 1.0

Rectangle {
    id: videoHolder
    color: "black"

    property variant mediaSource
    property bool fullscreen: false
    property bool aspectFill: false
    property bool thumbnailHovered: false
    property string currentVideoID
    property bool currentVideoFavorited

    signal close()
    signal fullscreenVideoRequested()
    signal addToFavorites()
    signal removeFromFavorites()
    signal openYoutubeLink(string id)

    function showButtons() {
        buttonShowVideoMinimized.opacity = 1
        buttonShowVideoFullscreen.opacity = 1
        buttonYoutubeLinkImage.opacity = .7
        buttonFavoriteVideoImage.opacity = .7
    }

    function hideButtons() {
        buttonShowVideoMinimized.opacity = 0
        buttonShowVideoFullscreen.opacity = 0
        buttonYoutubeLinkImage.opacity = 0
        buttonFavoriteVideoImage.opacity = 0
    }

    onVisibleChanged: {
        if(fullscreen) forceActiveFocus()
    }

    onThumbnailHoveredChanged: {
        if(thumbnailHovered) {
            showButtons()
        }
        else {
            hideButtons()
        }
    }

    VlcVideoSurface {
        id: video
        anchors.fill: parent
        fillMode: aspectFill ? Qt.KeepAspectRatioByExpanding : Qt.KeepAspectRatio
        source: mediaSource

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true

            onEntered: {
                thumbnailHovered = true
            }

            onExited: {
                thumbnailHovered = false
            }

            onClicked: {
                if(fullscreen) close()
            }
        }

        Image {
            id: buttonShowVideoMinimized
            width: 35
            height: 35
            source: "qrc:/buttons/remove"
            opacity: 0
            visible: !fullscreen
            smooth: true

            sourceSize.width: 40
            sourceSize.height: 40

            anchors {
                left: parent.left
                leftMargin: 10
                bottom: parent.bottom
                bottomMargin: 10
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
                    ApplicationManager.triggerTooltip("Minimize Video", 10, 0, 1200)
                }

                onExited: {
                    parent.scale = 1
                    ApplicationManager.setCursor(ApplicationManager.CURSORTYPE_NORMAL)
                    ApplicationManager.cancelTooltip()
                }

                onClicked: {
                    close()
                }
            }
        }

        Image {
            id: buttonShowVideoFullscreen
            width: 35
            height: 35
            source: "qrc:/buttons/fullscreen"
            opacity: 0
            visible: !fullscreen
            smooth: true

            sourceSize.width: 40
            sourceSize.height: 40

            anchors {
                right: parent.right
                rightMargin: 10
                top: parent.top
                topMargin: 10
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
                    parent.scale = 1
                    ApplicationManager.setCursor(ApplicationManager.CURSORTYPE_NORMAL)
                    ApplicationManager.cancelTooltip()
                }

                onClicked: {
                    fullscreenVideoRequested()
                }
            }
        }

        Image {
            id: buttonFavoriteVideoImage
            width: 35
            height: width
            source: currentVideoFavorited ? "qrc:/buttons/heartChecked" : "qrc:/buttons/heartUnchecked"
            sourceSize.width: width
            sourceSize.height: height
            opacity: 0
            asynchronous: true
            smooth: false

            anchors {
                right: parent.right
                rightMargin: 10
                bottom: parent.bottom
                bottomMargin: 10
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

                    buttonFavoriteVideoImage.opacity = .7
                    ApplicationManager.setCursor(ApplicationManager.CURSORTYPE_BUTTON)
                    ApplicationManager.triggerTooltip(currentVideoFavorited ? "Remove From Favorites" : "Add To Favorites", 10, 0, 1200)
                }

                onExited: {
                    if(!currentVideoID) return

                    if(!currentVideoFavorited) buttonFavoriteVideoImage.opacity = .3
                    ApplicationManager.setCursor(ApplicationManager.CURSORTYPE_NORMAL)
                    ApplicationManager.cancelTooltip()
                }

                onClicked: {
                    if(!currentVideoID) return

                    currentVideoFavorited = !currentVideoFavorited

                    if(currentVideoFavorited) addToFavorites()
                    else removeFromFavorites()
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
            id: buttonYoutubeLinkImage
            width: 35
            height: width
            source: "qrc:/buttons/youtube"
            sourceSize.width: width
            sourceSize.height: height
            opacity: 0
            asynchronous: true
            smooth: false

            anchors {
                right: buttonFavoriteVideoImage.left
                rightMargin: 10
                bottom: parent.bottom
                bottomMargin: 10
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

                    buttonYoutubeLinkImage.opacity = .7
                    ApplicationManager.setCursor(ApplicationManager.CURSORTYPE_BUTTON)
                    ApplicationManager.triggerTooltip("Open Video on YouTube", 10, 0, 1200)
                }

                onExited: {
                    if(!currentVideoID) return

                    buttonYoutubeLinkImage.opacity = .3
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

    Keys.onEscapePressed: {
        if(fullscreen) {
            close()
        }
    }
}
