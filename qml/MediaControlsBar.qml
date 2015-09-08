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

        sec = sec - min * 60

        var secStr = sec.toString()
        var minStr = min.toString()

        while(secStr.length < 2)
        {
            secStr = "0" + secStr
        }
        while(minStr.length < 2)
        {
            minStr = "0" + minStr
        }

        return minStr + ":" + secStr
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
            source: "qrc:/images/forward"
            mirror: true

            onClicked: {
                previous()
            }
        }

        BWMediaControlButton {
            id: buttonPlay
            width: 30
            height: width
            source: playing ? "qrc:/images/pause" : "qrc:/images/playDark"

            onClicked: {
                if(playing) pause()
                else play()
            }
        }

        BWMediaControlButton {
            id: buttonNext
            width: 30
            height: width
            source: "qrc:/images/forward"

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

                backgroundColor: "#e8ebee"
                fillColor: "#14aaff"
                gripColor: "white"

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

        TOPSlider {
            id: volumeSlider
            width: 80
            focus: true
            value: 1

            backgroundColor: "#e8ebee"
            fillColor: "#14aaff"
            gripColor: "white"

            onSliderMoved: {
                volume = value
            }

            onSliderReleased: {
                UserManager.setVolume(value)
            }

            Component.onCompleted: {
                value = UserManager.volume()
            }
        }

        Item {
            width: 20
        }

        BWMediaControlButton {
            id: buttonShuffle
            width: 30
            height: width
            source: shuffle ? "qrc:/images/shuffleToggled" : "qrc:/images/shuffle"

            onClicked: {
                shuffle = !shuffle
            }
        }

        BWMediaControlButton {
            id: buttonRepeat
            width: 30
            height: width
            source: repeat ? "qrc:/images/repeatToggled" : "qrc:/images/repeat"

            onClicked: {
                repeat = !repeat
            }
        }

        BWMediaControlButton {
            id: buttonOpenQueue
            width: 30
            height: width
            source: queueOpened ? "qrc:/images/openQueueToggled" : "qrc:/images/openQueue"

            onClicked: {
                queueOpened = !queueOpened
            }
        }
    }
}
