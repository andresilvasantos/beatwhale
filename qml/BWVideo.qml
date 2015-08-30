import QtQuick 2.0
import QmlVlc 0.1

Rectangle {
    id: videoHolder
    color: "black"

    property variant mediaSource
    property bool fullscreen: false
    property bool aspectFill: false

    signal close()
    signal fullscreenVideoRequested()

    onFullscreenChanged: {
        if(fullscreen) {
            forceActiveFocus()
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
                buttonShowVideoMinimized.opacity = 1
                buttonShowVideoFullscreen.opacity = 1
            }

            onExited: {
                buttonShowVideoMinimized.opacity = 0
                buttonShowVideoFullscreen.opacity = 0
            }

            onClicked: {
                if(fullscreen) close()
            }
        }

        Image {
            id: buttonShowVideoMinimized
            width: 35
            height: 35
            //color: "white"
            source: "qrc:/images/zoomOut"
            opacity: 0
            visible: !fullscreen

            sourceSize.width: 40
            sourceSize.height: 40

            anchors {
                left: parent.left
                leftMargin: 5
                bottom: parent.bottom
                bottomMargin: 5
            }

            Behavior on opacity {
                NumberAnimation { property: "opacity"; duration: 200; easing.type: Easing.OutSine }
            }

            MouseArea {
                anchors.fill: parent

                onClicked: {
                    close()
                }
            }
        }

        Image {
            id: buttonShowVideoFullscreen
            width: 35
            height: 35
            //color: "white"
            source: "qrc:/images/fullscreen"
            opacity: 0
            visible: !fullscreen

            sourceSize.width: 40
            sourceSize.height: 40

            anchors {
                left: buttonShowVideoMinimized.right
                leftMargin: 5
                bottom: parent.bottom
                bottomMargin: 5
            }

            Behavior on opacity {
                NumberAnimation { property: "opacity"; duration: 200; easing.type: Easing.OutSine }
            }

            MouseArea {
                anchors.fill: parent

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
