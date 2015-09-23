import QtQuick 2.0
import BeatWhaleAPI 1.0
import "qrc:/components/qml/"

TOPSwitch {
    id: toggleSwitch

    onEntered: {
        ApplicationManager.setCursor(ApplicationManager.CURSORTYPE_BUTTON)
    }

    onExited: {
        ApplicationManager.setCursor(ApplicationManager.CURSORTYPE_NORMAL)
    }
}
