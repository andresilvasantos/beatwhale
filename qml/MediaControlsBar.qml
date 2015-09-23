import QtQuick 2.2
import QtQuick.Layouts 1.1
import BeatWhaleAPI 1.0
import "qrc:/components/qml/"

Rectangle {
    color: "white"

    property bool playing: false
    property int currentSeekSec: 0
    property int durationSec: 0
    property real volume: volumeSlider.value
    property bool tvMode: false
    property bool shuffle: false
    property bool repeat: false
    property bool queueOpened: false
    property bool seeking: false
    signal previous()
    signal next()
    signal play()
    signal pause()
    signal stop()
    signal seek(real seekTo)

    onDurationSecChanged: {
        if(durationSec < 0) durationSeekText.text = numberToTimeFormat(0)
        else durationSeekText.text = numberToTimeFormat(durationSec)
    }

    onCurrentSeekSecChanged: {
        if(!seeking) {
            if(durationSec > 0) seekSlider.value = currentSeekSec / durationSec
            positionSeekText.text = numberToTimeFormat(currentSeekSec)
        }
    }

    function numberToTimeFormat(number) {
        var sec = Math.round(number)
        var min = Math.floor(sec / 60)
        var hour = Math.floor(min / 60)

        sec = sec - min * 60

        var secStr = sec.toString()
        var minStr
        var hourStr = hour.toString()

        while(secStr.length < 2)
        {
            secStr = "0" + secStr
        }

        if(hour == 0) {
            minStr = min.toString()
            while(minStr.length < 2)
            {
                minStr = "0" + minStr
            }

            return minStr + ":" + secStr
        }

        min = min - hour * 60
        minStr = min.toString()

        while(minStr.length < 2)
        {
            minStr = "0" + minStr
        }

        while(hourStr.length < 2)
        {
            hourStr = "0" + hourStr
        }

        return hourStr + ":" + minStr + ":" + secStr
    }

    Rectangle {
        color: "#cccccc"
        width: parent.width
        height: 1

        anchors.top: parent.top
    }

    RowLayout {
        focus: true
        spacing: 16

        anchors {
            fill: parent
            leftMargin: 20
            rightMargin: 20
        }

        BWMediaControlButton {
            id: buttonPrevious
            width: 30
            height: width
            source: "qrc:/buttons/forward"
            mirror: true
            tooltip: "Previous"

            onClicked: {
                previous()
            }
        }

        BWMediaControlButton {
            id: buttonPlay
            width: 30
            height: width
            source: playing ? "qrc:/buttons/pause" : "qrc:/buttons/playDark"
            tooltip: playing ? "Pause" : "Play"

            onClicked: {
                if(playing) pause()
                else play()
            }
        }

        BWMediaControlButton {
            id: buttonNext
            width: 30
            height: width
            source: "qrc:/buttons/forward"
            tooltip: "Next"

            onClicked: {
                next()
            }
        }

        Item {
            width: 20
        }

        Text {
            id: positionSeekText
            font.pixelSize: 14
            font.family: "Open Sans"
            text: "00:00"
            color: "#c5c5c5"
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.minimumWidth: 100

            TOPSlider {
                id: seekSlider
                focus: true
                value: 0
                enabled: durationSec != 0
                backgroundColor: "#e8ebee"
                fillColor: "#14aaff"
                gripColor: "white"
                gripTolerance: 1

                anchors {
                    left: parent.left
                    leftMargin: 10
                    right: parent.right
                    rightMargin: 10
                }

                onSliderMoved: {
                    seeking = true
                    positionSeekText.text = numberToTimeFormat(value * durationSec)
                }

                onSliderReleased: {
                    seeking = false
                    seek(value)
                }
            }
        }

        Text {
            id: durationSeekText
            font.pixelSize: 14
            font.family: "Open Sans"
            text: "00:00"
            color: "#c5c5c5"
        }

        Item {
            width: 5
        }

        Item {
            width: childrenRect.width

            Image {
                id: volumeIcon
                source: volumeSlider.value !== 0 ? "qrc:/icons/sound" : "qrc:/icons/soundMute"
                width: 20
                height: width
                opacity: .5

                anchors {
                    verticalCenter: parent.verticalCenter
                    left: parent.left
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true

                    onEntered: {
                        ApplicationManager.setCursor(ApplicationManager.CURSORTYPE_BUTTON)
                        ApplicationManager.triggerTooltip(volumeSlider.value !== 0 ? "Mute" : "Unmute", 15, -10, 1200)
                    }

                    onExited: {
                        ApplicationManager.setCursor(ApplicationManager.CURSORTYPE_NORMAL)
                        ApplicationManager.cancelTooltip()
                    }

                    onClicked: {
                        volumeSlider.value === 0 ? volumeSlider.value = volumeSlider.oldValue : volumeSlider.value = 0
                    }
                }
            }

            TOPSlider {
                id: volumeSlider
                width: 80
                backgroundColor: "#e8ebee"
                fillColor: "#14aaff"
                gripColor: "white"
                focus: true
                value: 1
                gripTolerance: 1

                anchors {
                    left: volumeIcon.right
                    leftMargin: 15
                    verticalCenter: parent.verticalCenter
                }

                property real oldValue: 1

                onSliderMoved: {
                    oldValue = value
                }

                onSliderReleased: {
                    UserManager.setVolume(value)
                }

                Component.onCompleted: {
                    value = UserManager.volume()
                    oldValue = value
                }
            }
        }

        Item {
            width: 20
        }

        BWMediaControlButton {
            id: buttonTV
            width: 30
            height: width
            source: tvMode ? "qrc:/buttons/tvToggled" : "qrc:/buttons/tv"
            tooltip: "TV Mode"

            anchors {
                bottom: buttonShuffle.bottom
                bottomMargin: 3
            }

            onClicked: {
                tvMode = !tvMode
            }
        }

        BWMediaControlButton {
            id: buttonShuffle
            width: 30
            height: width
            source: shuffle ? "qrc:/buttons/shuffleToggled" : "qrc:/buttons/shuffle"
            tooltip: "Shuffle"

            onClicked: {
                shuffle = !shuffle
            }
        }

        BWMediaControlButton {
            id: buttonRepeat
            width: 30
            height: width
            source: repeat ? "qrc:/buttons/repeatToggled" : "qrc:/buttons/repeat"
            tooltip: "Repeat"

            onClicked: {
                repeat = !repeat
            }
        }

        BWMediaControlButton {
            id: buttonOpenQueue
            width: 30
            height: width
            source: queueOpened ? "qrc:/buttons/openQueueToggled" : "qrc:/buttons/openQueue"
            tooltip: "Open Mini Queue"

            onClicked: {
                queueOpened = !queueOpened
            }
        }
    }
}
