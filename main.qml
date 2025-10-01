import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import QtCore

import org.qfield
import org.qgis
import Theme


Item {
  id: plugin
  
  Settings {
    id: settings
    property string file_url: "https://sentinel-cogs.s3.us-west-2.amazonaws.com/sentinel-s2-l2a-cogs/36/Q/WD/2020/7/S2A_36QWD_20200701_0_L2A/TCI.tif"
  }

  property var mainWindow: iface.mainWindow()

  Component.onCompleted: {
    iface.addItemToPluginsToolbar(pluginButton)
  }
  
  QfToolButton {
    id: pluginButton
    iconSource: 'icon.svg'
    iconColor: Theme.mainColor
    bgcolor: Theme.darkGray
    round: true
    
    onClicked: {
      layerDialog.open()
    }
  }

  function chooseLayer() {

    let prompt = `Hello`;
    console.log(prompt);    

    mainWindow.displayToast(qsTr('Your current position is unknown\n Not loading POIs nearby'))
    
    console.log('Fetching results....');
  }

  function loadRemoteLayer(url, title, is_vector){
    mainWindow.displayToast(qsTr('Loading ') + url)
    let layer;
    if (is_vector) {
      layer = LayerUtils.loadVectorLayer("/vsicurl/" + url, title ? title : qsTr("Remote layer"))
    } else {
      layer = LayerUtils.loadRasterLayer("/vsicurl/" + url, title ? title : qsTr("Remote layer"))
    }
    ProjectUtils.addMapLayer(qgisProject, layer)
  }


  function loadLocalLayer(){
    mainWindow.displayToast(qsTr('Open local file picker '))
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

      ColumnLayout {
          width: parent.width
          spacing: 10
          
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
              id: labelfileUrl
              Layout.fillWidth: true
              text: qsTr("Remote layer name")
          }

          QfTextField {
              id: textFieldFileName
              Layout.fillWidth: true
              text: 'QGIS Hackfest POIs'
          }

          Label {
              id: labelFileName
              Layout.fillWidth: true
              text: qsTr("Remote layer URL")
          }

          QfTextField {
              id: textFieldFileUrl
              Layout.fillWidth: true
              text: "https://raw.githubusercontent.com/qgis/QGIS/refs/heads/master/resources/data/qgis-hackfests.json"
          }  
      }

      onAccepted: {
          loadRemoteLayer(textFieldFileUrl.text, textFieldFileName.text, radioVector.checked)
      }
    }
}