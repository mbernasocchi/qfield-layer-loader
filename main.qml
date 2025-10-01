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
                      text: qsTr("Legend name")
                  }

                  QfTextField {
                      id: textFieldFileName
                      Layout.fillWidth: true
                      text: 'QGIS Hackfest POIs'
                  }

                  Label {
                      id: labelFileName
                      Layout.fillWidth: true
                      text: qsTr("URL")
                  }

                  QfTextField {
                      id: textFieldFileUrl
                      Layout.fillWidth: true
                      text: "https://raw.githubusercontent.com/qgis/QGIS/refs/heads/master/resources/data/qgis-hackfests.json"
                  }
              }
              
              // Local Layer Tab
              ColumnLayout {
                  spacing: 10
                  
                  Label {
                      Layout.fillWidth: true
                      text: qsTr("Select a local file")
                  }
                  
                  Button {
                      Layout.fillWidth: true
                      text: qsTr("Browse...")
                      onClicked: loadLocalLayer()
                  }
              }
          }
      }

      onAccepted: {
          if (tabBar.currentIndex === 0) {
              loadRemoteLayer(textFieldFileUrl.text, textFieldFileName.text, radioVector.checked)
          } else {
              loadLocalLayer()
          }
      }
    }
}