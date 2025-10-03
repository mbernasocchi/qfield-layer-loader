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

    QfDialog {
        id: layerDialog
        parent: mainWindow.contentItem
        visible: false
        modal: true
        font: Theme.defaultFont
        standardButtons: Dialog.Apply | Dialog.Cancel
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

            Label {
                Layout.fillWidth: true
                text: qsTr("Layer source")
            }

            QfComboBox {
                id: comboLayerSource
                Layout.fillWidth: true
                model: [qsTr("Remote Layer"), qsTr("Local Layer")]
                currentIndex: 0
            }

            Label {
                Layout.fillWidth: true
                text: qsTr("Layer type")
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 20

                RadioButton {
                    id: radioRaster
                    text: qsTr("Raster")
                    checked: false
                }

                RadioButton {
                    id: radioVector
                    text: qsTr("Vector")
                    checked: true
                }
            }

            Label {
                Layout.fillWidth: true
                text: qsTr("Legend name")
            }

            QfTextField {
                id: textFieldFileName
                Layout.fillWidth: true
                text: 'QGIS Hackfest POIs'
            }

            Label {
                Layout.fillWidth: true
                text: qsTr("URL")
                visible: comboLayerSource.currentIndex === 0
            }

            QfTextField {
                id: textFieldUrl
                Layout.fillWidth: true
                text: "https://raw.githubusercontent.com/qgis/QGIS/refs/heads/master/resources/data/qgis-hackfests.json"
                visible: comboLayerSource.currentIndex === 0
            }

            Button {
                Layout.fillWidth: true
                text: qsTr("Browse local file...")
                onClicked: getFile()
                visible: comboLayerSource.currentIndex === 1
            }

            Label {
                Layout.fillWidth: true
                text: connections.localPath ? connections.localPath : qsTr("No file selected")
                font.italic: !connections.localPath
                visible: comboLayerSource.currentIndex === 1
            }
        }

        onAccepted: {
            if (comboLayerSource.currentIndex === 0) {
                loadRemoteLayer(textFieldUrl.text, textFieldFileName.text, radioVector.checked);
            } 
            else {
                loadLayer(connections.localPath, textFieldFileName.text, radioVector.checked);
            }
        }
    }
}
