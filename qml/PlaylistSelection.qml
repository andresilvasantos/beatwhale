import QtQuick 2.0
import BeatWhaleAPI 1.0
import "qrc:/components/qml/"

Rectangle {
    id: rootRect
    color: "white"
    radius: 20
    border.width: .5
    border.color: "#50cccccc"
    width: 250
    height: createPlaylistSwitch.on ? 200 : 350

    Behavior on height {
        NumberAnimation {duration: 200; easing.type: Easing.OutSine}
    }

    property string currentPlaylistName

    signal addItemsToPlaylist(string name)
    signal cancel()

    function accept() {
        var playlists = PlaylistsManager.playlistNames()

        if(playlists.indexOf(currentPlaylistName) === -1) {
            var playlist = PlaylistsManager.createPlaylist(currentPlaylistName)
        }

        addItemsToPlaylist(currentPlaylistName)
    }

    BWSwitch {
        id: createPlaylistSwitch
        height: 16
        on: false
        labelText: "create playlist?"
        labelColor: "#929292"
        labelFont: "Open Sans"
        labelPixelSize: 11
        labelRightSide: false

        fillColor: "#00addc"
        borderColor: "white"
        knobBorderWidth: 1
        backgroundColor: "#666666"

        anchors {
            top: parent.top
            topMargin: 20
            horizontalCenter: parent.horizontalCenter
        }

        onOnChanged: {
            if(on) formsLoader.sourceComponent = createPlaylistComponent
            else formsLoader.sourceComponent = addToPlaylistComponent
        }
    }

    Component {
        id: addToPlaylistComponent

        Item {
            BWListModel {
                id: playlistsModel
                sortColumnName: "name"
            }

            ListView {
                id: playlistsView
                width: parent.width
                height: parent.height
                clip: true

                property int selectedIndex: -1
                property bool loaded: rootRect.visible

                model: playlistsModel
                delegate: BWButton {
                    id: button
                    width: playlistsView.width
                    height: 30
                    color: "transparent"
                    hoverColor: "#5000addc"
                    selectedColor: "#00addc"
                    checkable: true
                    checked: playlistsView.selectedIndex == index

                    property string caption

                    onClicked: {
                        playlistsView.selectedIndex = index
                        currentPlaylistName = name
                    }

                    Text {
                        id: buttonText
                        text: name
                        color: button.checked ? "white" : "#61666a"
                        font.pixelSize: 13
                        font.family: "Open Sans"
                        horizontalAlignment: Text.AlignHCenter

                        anchors {
                            horizontalCenter: parent.horizontalCenter
                            verticalCenter: parent.verticalCenter
                        }
                    }
                }

                onLoadedChanged: {
                    if(loaded) {
                        var playlists = PlaylistsManager.playlistNames()

                        playlistsModel.clear()
                        for(var i = 0; i < playlists.length; ++i) {
                            playlistsModel.append({"name": playlists[i]})
                        }

                        if(playlists.length) {
                            selectedIndex = 0
                            currentPlaylistName = playlists[0]
                        }
                    }
                }
            }

            TOPScrollBar {
                flickable: playlistsView
            }
        }
    }

    Component {
        id: createPlaylistComponent

        Item {
            Rectangle {
                id: playlistInputHolder
                width: parent.width
                height: 35
                color: "#eceded"
                radius: 5
                border.color: "#cccccc"
                border.width: 1

                anchors {
                    horizontalCenter: parent.horizontalCenter
                    verticalCenter: parent.verticalCenter
                }

                TextInput {
                    id: playlistInput
                    height: parent.height * .5 - 1
                    font.pixelSize: 14
                    font.family: "Open Sans"
                    color: "#666666"
                    selectByMouse: true
                    selectionColor: "#333333"
                    clip: true
                    text: "Playlist Name"
                    validator: RegExpValidator { regExp:/^[A-Za-z0-9].{0,30}$/i }

                    anchors {
                        verticalCenter: parent.verticalCenter
                        left: parent.left
                        leftMargin: 10
                        right: parent.right
                        rightMargin: 5
                    }

                    onTextChanged: {
                        currentPlaylistName = text
                    }
                }
            }

            Component.onCompleted: {
                currentPlaylistName = playlistInput.text
            }
        }
    }

    BWButton {
        id: okButton
        width: parent.width * 0.44
        height: 35
        color: "#00addc"
        hoverColor: "#0093bb"
        selectedColor: "#1fb3db"
        radius: 5

        anchors {
            right: parent.right
            rightMargin: 12
            bottom: parent.bottom
            bottomMargin: 12
        }

        Text {
            text: "OK"
            color: "white"
            font.bold: true
            font.pixelSize: 14
            font.family: "Open Sans"
            anchors.centerIn: okButton
        }

        onClicked: {
            accept()
        }
    }

    BWButton {
        id: cancelButton
        width: parent.width * 0.44
        height: 35
        color: "#00addc"
        hoverColor: "#0093bb"
        selectedColor: "#1fb3db"
        radius: 5

        anchors {
            left: parent.left
            leftMargin: 12
            bottom: parent.bottom
            bottomMargin: 12
        }

        Text {
            text: "CANCEL"
            color: "white"
            font.bold: true
            font.pixelSize: 14
            font.family: "Open Sans"
            anchors.centerIn: cancelButton
        }

        onClicked: {
            cancel()
        }
    }

    Keys.onReturnPressed: {
        accept()
    }

    Keys.onEnterPressed: {
        accept()
    }

    Keys.onEscapePressed: {
        cancel()
    }

    Loader {
        id: formsLoader
        sourceComponent: addToPlaylistComponent

        width: parent.width * 0.9
        height: parent.height - 120

        anchors {
            horizontalCenter: parent.horizontalCenter
            top: createPlaylistSwitch.bottom
            topMargin: 20
        }
    }

}
