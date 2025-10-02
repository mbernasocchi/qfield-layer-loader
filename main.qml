import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import QtCore

import org.qfield
import org.qgis
import Theme

Item {
    id: plugin

    property var mainWindow: iface.mainWindow()
    property ResourceSource __resourceSource

    Component.onCompleted: {
        iface.addItemToPluginsToolbar(pluginButton);
    }

    QfToolButton {
        id: pluginButton
        iconSource: 'icon.svg'
        iconColor: Theme.mainColor
        bgcolor: Theme.darkGray
        round: true

        onClicked: {
            layerDialog.open();
        }
    }

    Connections {
        id: connections
        target: __resourceSource
        property string localPath: ""
        function onResourceReceived(path) {
            if (path) {
                localPath = qgisProject.homePath + '/tmp/' + path;
            }
        }
    }

    function getFile() {
        platformUtilities.requestStoragePermission();
        __resourceSource = platformUtilities.getFile(qgisProject.homePath + '/tmp/', '{filename}', this);
    }

    function loadRemoteLayer(url, title, is_vector) {
        let path = "/vsicurl/" + url;
        loadLayer(path, title, is_vector);
    }

    function loadLayer(path, title, is_vector=false) {
        mainWindow.displayToast(qsTr('Loading ') + path + ' as ' + title);
        let layer;
        if (is_vector) {
            layer = LayerUtils.loadVectorLayer(path, title ? title : qsTr("Read-only layer"));
        } else {
            layer = LayerUtils.loadRasterLayer(path, title ? title : qsTr("Read-only layer"));
        }
        ProjectUtils.addMapLayer(qgisProject, layer);
    }

    Dialog {
        id: layerDialog
        parent: mainWindow.contentItem
        visible: false
        modal: true
        font: Theme.defaultFont
        standardButtons: Dialog.Ok | Dialog.Cancel
        title: qsTr("Load read-only layer")

        width: mainWindow.width * 0.8
        x: (mainWindow.width - width) / 2
        y: (mainWindow.height - height) / 2

        onAboutToShow: {
            // reset fields
            connections.localPath = "";
        }

        ColumnLayout {
            width: parent.width
            spacing: 10

            TabBar {
                id: tabBar
                Layout.fillWidth: true

                TabButton {
                    text: qsTr("Remote Layer")
                }

                TabButton {
                    text: qsTr("Local Layer")
                }
            }

            StackLayout {
                Layout.fillWidth: true
                currentIndex: tabBar.currentIndex

                // Remote Layer Tab
                ColumnLayout {
                    spacing: 10

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 20

                        RadioButton {
                            id: radioRemoteRaster
                            text: qsTr("Raster")
                            checked: false
                        }

                        RadioButton {
                            id: radioRemoteVector
                            text: qsTr("Vector")
                            checked: true
                        }
                    }

                    Label {
                        id: labelRemoteFileName
                        Layout.fillWidth: true
                        text: qsTr("Legend name")
                    }

                    QfTextField {
                        id: textFieldRemoteFileName
                        Layout.fillWidth: true
                        text: 'QGIS Hackfest POIs'
                    }

                    Label {
                        id: labelRemoteUrl
                        Layout.fillWidth: true
                        text: qsTr("URL")
                    }

                    QfTextField {
                        id: textFieldRemoteUrl
                        Layout.fillWidth: true
                        text: "https://raw.githubusercontent.com/qgis/QGIS/refs/heads/master/resources/data/qgis-hackfests.json"
                    }
                }

                // Local Layer Tab
                ColumnLayout {
                    spacing: 10
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 20

                        RadioButton {
                            id: radioLocalRaster
                            text: qsTr("Raster")
                            checked: false
                        }

                        RadioButton {
                            id: radioLocalVector
                            text: qsTr("Vector")
                            checked: true
                        }
                    }

                    Label {
                        id: labelLocalFileName
                        Layout.fillWidth: true
                        text: qsTr("Legend name")
                    }

                    QfTextField {
                        id: textFieldLocalFileName
                        Layout.fillWidth: true
                        text: 'QGIS Hackfest POIs'
                    }

                    Button {
                        Layout.fillWidth: true
                        text: qsTr("Browse local file...")
                        onClicked: getFile()
                    }
                }
            }
        }

        onAccepted: {
            if (tabBar.currentIndex === 0) {
                loadRemoteLayer(textFieldRemoteUrl.text, textFieldRemoteFileName.text, radioRemoteVector.checked);
            } 
            else{
                loadLayer(connections.localPath, textFieldLocalFileName.text, radioLocalVector.checked);
                }
        }
    }
}
