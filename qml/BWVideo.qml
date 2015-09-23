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

    signal close()
    signal fullscreenVideoRequested()

    onVisibleChanged: {
        if(fullscreen) forceActiveFocus()

        buttonShowVideoFullscreen.opacity = 0
        buttonShowVideoMinimized.opacity = 0
    }

    onThumbnailHoveredChanged: {
        if(thumbnailHovered) {
            buttonShowVideoMinimized.opacity = 1
            buttonShowVideoFullscreen.opacity = 1
        }
        else {
            buttonShowVideoMinimized.opacity = 0
            buttonShowVideoFullscreen.opacity = 0
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
                leftMargin: 5
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
                left: buttonShowVideoMinimized.right
                leftMargin: 5
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
    }

    Keys.onEscapePressed: {
        if(fullscreen) {
            close()
        }
    }
}
