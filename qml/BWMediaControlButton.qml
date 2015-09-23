import QtQuick 2.2
import BeatWhaleAPI 1.0

Item {
    id: rootRect

    property string source
    property string tooltip
    property bool mirror

    signal clicked()

    Image {
        anchors.fill: parent
        source: parent.source
        sourceSize.width: width
        sourceSize.height: height
        opacity: .7
        mirror: parent.mirror

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
                parent.opacity = 1
                ApplicationManager.setCursor(ApplicationManager.CURSORTYPE_BUTTON)
                if(tooltip.length) ApplicationManager.triggerTooltip(tooltip, 15, -10, 1200)
            }

            onExited: {
                parent.opacity = .7
                ApplicationManager.setCursor(ApplicationManager.CURSORTYPE_NORMAL)
                if(tooltip.length) ApplicationManager.cancelTooltip()
            }

            onClicked: {
                rootRect.clicked()
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
