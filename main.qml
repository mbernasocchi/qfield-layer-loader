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
        bgcolor: Theme.toolButtonBackgroundColor
        round: true

        onClicked: {
            layerDialog.open();
        }
    }

    Connections {
        id: resourceSourceConnection
        target: __resourceSource

        function onResourceReceived(path) {
            if (path) {
                const localPath = qgisProject.homePath + '/tmp/' + path;
                localPathTextField.text = localPath;

                const name = FileUtils.fileName(localPath);
                legendNameTextField.text = name;

                layerDialog.updateLoadLayerState();
            }
        }
    }

    function getFile() {
        platformUtilities.requestStoragePermission();
        __resourceSource = platformUtilities.getFile(qgisProject.homePath + '/tmp/', '{filename}', '*/*', this);
    }

    function loadRemoteLayer(url, title, is_vector) {
        let path = "/vsicurl/" + url;
        if (path.endsWith(".zip")) {
            path = "/vsizip/" + path;
        }
        loadLayer(path, title, is_vector);
    }

    function loadLayer(path, title, is_vector=false) {
        mainWindow.displayToast(qsTr('Loading %1 as %2').arg(path).arg(title));
        let layer;
        if (is_vector) {
            layer = LayerUtils.loadVectorLayer(path, title ? title : qsTr("Read-only layer"));
            layer.readOnly = true;
        } else {
            layer = LayerUtils.loadRasterLayer(path, title ? title : qsTr("Read-only layer"));
        }
        ProjectUtils.addMapLayer(qgisProject, layer);
    }

    QfDialog {
        id: layerDialog
        parent: mainWindow.contentItem
        width: mainWindow.width * 0.8
        x: (mainWindow.width - width) / 2
        y: (mainWindow.height - height) / 2
        visible: false
        modal: true
        font: Theme.defaultFont
        standardButtons: Dialog.Ok | Dialog.Cancel
        
        title: qsTr("Add Read-Only Layer")

        ColumnLayout {
            width: parent.width
            spacing: 10

            Label {
                Layout.fillWidth: true
                font: Theme.defaultFont
                text: qsTr("Layer type")
            }

            QfToggleButtonGroup {
              id: layerTypeToggleButtonGroup
              Layout.fillWidth: true
              Layout.preferredHeight: legendNameTextField.height
              model: [qsTr("Raster"), qsTr("Vector")]
              font: Theme.defaultFont
              buttonMininumWidth: parent.width / 2 - buttonSpacing
              selectedIndex: 0

              onSelectedIndexChanged: {
                  layerDialog.updateLoadLayerState();
              }
            }

            Label {
                Layout.fillWidth: true
                font: Theme.defaultFont
                text: qsTr("Layer source")
            }

            QfToggleButtonGroup {
              id: layerSourceToggleButtonGroup
              Layout.fillWidth: true
              Layout.preferredHeight: legendNameTextField.height
              model: [qsTr("Remote"), qsTr("Local")]
              font: Theme.defaultFont
              buttonMininumWidth: parent.width / 2 - buttonSpacing
              selectedIndex: 0

              onSelectedIndexChanged: {
                  layerDialog.updateLoadLayerState();
              }
            }

            Label {
                Layout.fillWidth: true
                text: qsTr("URL")
                visible: layerSourceToggleButtonGroup.selectedIndex === 0
            }

            QfTextField {
                id: urlTextField
                Layout.fillWidth: true
                text: ""
                visible: layerSourceToggleButtonGroup.selectedIndex === 0

                onTextChanged: {
                    layerDialog.updateLoadLayerState();
                }

                onEditingFinished: {
                    const name = UrlUtils.urlDetail(urlTextField.text, "fileName");
                    if (name !== "") {
                        legendNameTextField.text = name;
                    }
                }
            }

            Label {
                Layout.fillWidth: true
                text: qsTr("File")
                visible: layerSourceToggleButtonGroup.selectedIndex === 1
                wrapMode: Text.Wrap
            }

            QfTextField {
                id: localPathTextField
                Layout.fillWidth: true
                visible: layerSourceToggleButtonGroup.selectedIndex === 1 && text !== ""
                text: ""
                readOnly: true
            }

            QfButton {
                Layout.fillWidth: true
                text: qsTr("Browse local file...")
                visible: layerSourceToggleButtonGroup.selectedIndex === 1

                onClicked: {
                    getFile()
                }
            }

            Label {
                Layout.fillWidth: true
                font: Theme.defaultFont
                text: qsTr("Legend name")
            }

            QfTextField {
                id: legendNameTextField
                Layout.fillWidth: true
                text: ""

                onTextChanged: {
                    layerDialog.updateLoadLayerState();
                }
            }
        }

        onAboutToShow: {
            standardButton(Dialog.Ok).text = "Load Layer";
            localPathTextField.text = "";

            updateLoadLayerState();
        }

        onAccepted: {
            if (layerSourceToggleButtonGroup.selectedIndex === 0) {
                loadRemoteLayer(urlTextField.text, legendNameTextField.text, layerTypeToggleButtonGroup.selectedIndex == 1);
            }
            else {
                loadLayer(localPathTextField.text, legendNameTextField.text, layerTypeToggleButtonGroup.selectedIndex == 1);
            }
        }

        function updateLoadLayerState() {
            const okButton = standardButton(Dialog.Ok);
            if (layerSourceToggleButtonGroup.selectedIndex === 0) {
                okButton.enabled = urlTextField.text !== "";
            } else {
                okButton.enabled = localPathTextField.text !== "";
            }
        }
    }
}
