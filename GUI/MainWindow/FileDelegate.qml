/****************************************************************
 *  This file is part of Emoty.
 *  Emoty is distributed under the following license:
 *
 *  Copyright (C) 2017, Konrad Dębiec
 *
 *  Emoty is free software; you can redistribute it and/or
 *  modify it under the terms of the GNU General Public License
 *  as published by the Free Software Foundation; either version 3
 *  of the License, or (at your option) any later version.
 *
 *  Emoty is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 51 Franklin Street, Fifth Floor,
 *  Boston, MA  02110-1301, USA.
 ****************************************************************/
import QtQuick 2.5

import Material 0.3 as Material

Component {
	Item {
		property string modelName: GridView.view.model.objectName
		property var modelObject: GridView.view.model

		width: GridView.view.cellWidth
		height: GridView.view.cellHeight

		Item {
			anchors.centerIn: parent
			width: parent.GridView.view.idealCellWidth - 10
			height: parent.height - 10

			clip: true

			Material.Ink {
				anchors.fill: parent
				circular: true

				onEntered: {
					fileIcon.color = Material.Theme.primaryColor
					fileName.color = Material.Theme.primaryColor
					fileSize.color = Material.Theme.primaryColor
				}

				onExited: {
					fileIcon.color = Material.Theme.light.iconColor
					fileName.color = Material.Theme.light.iconColor
					fileSize.color = Material.Theme.light.iconColor
				}

				onClicked: {
					if(model.type == "folder" || model.type == "person") {
						var jsonData = {
							reference: model.reference,
							remote: false,
							local:	true
						}

						if(modelName == "friendsFiles") {
							jsonData.remote = true
							jsonData.local = false
						}

						function callbackFn(par) {
							modelObject.loadJSONSharedFolders(par.response)
						}

						rsApi.request("/filesharing/get_dir_childs/", JSON.stringify(jsonData), callbackFn)
					}
					else if(model.type == "file" && (modelName == "friendsFiles" || modelName == "searchFiles")) {
						var downloadData = {
							action: "begin",
							hash: model.hash,
							name: model.name,
							size: model.count
						}

						rsApi.request("/transfers/control_download/", JSON.stringify(downloadData), function(){})
					}
				}
			}

			Material.Icon {
				id: fileIcon
				anchors {
					top: parent.top
					left: parent.left
					right: parent.right
					topMargin: dp(10)
				}

				name: {
					if(model.type == "folder")
						return "awesome/folder_o"
					else if(model.type == "file")
						return "awesome/file_o"
					else if(model.type == "person")
						return "awesome/user_o"
					else
						return "awesome/question"
				}

				size: parent.height*0.45
			}

			TextEdit {
				id: fileName
				anchors {
					top: fileIcon.bottom
					left: parent.left
					right: parent.right
					topMargin: dp(7)
				}

				clip: true
				color: Material.Theme.light.iconColor
				text: model.virtual_name

				font.weight: Font.DemiBold
				font.pixelSize: dp(14)*parent.height/170

				wrapMode: TextEdit.WrapAnywhere
				horizontalAlignment: Text.AlignHCenter

				Behavior on color {
					ColorAnimation {
						easing.type: Easing.InOutQuad;
						duration: Material.MaterialAnimation.pageTransitionDuration
					}
				}
			}

			Material.Label {
				id: fileSize
				anchors {
					top: fileName.bottom
					left: parent.left
					right: parent.right
					topMargin: dp(3)
				}

				clip: true
				color: Material.Theme.light.iconColor
				text: {
					if(model.type == "folder" || model.type == "person") {
						if(model.contain_folders == 0 && model.contain_files == 0)
							return "empty"
						else if(model.contain_folders == 1 && model.contain_files == 0)
							return "1 folder"
						else if(model.contain_folders > 1 && model.contain_files == 0)
							return model.contain_folders + " folders"
						else if(model.contain_folders == 0 && model.contain_files == 1)
							return "1 file"
						else if(model.contain_folders == 0 && model.contain_files > 1)
							return model.contain_files + " files"
						else if(model.contain_folders == 1 && model.contain_files > 1)
							return "1 folder, " + model.contain_files + " files"
						else if(model.contain_folders > 1 && model.contain_files == 1)
							return model.contain_folders + " folders, " + "1 file"
						else if(model.contain_folders == 1 && model.contain_files == 1)
							return "1 folder, 1 file"
						else if(model.contain_folders > 1 && model.contain_files > 1)
							return model.contain_folders + " folders, " + model.contain_files + " files"
					}
					else if(model.type == "file") {
						if(model.count < 1000)
							return model.count + " B"
						else if(model.count >= 1000 && model.count < 1000000)
							return Math.round(model.count/1000) + " KB"
						else if(model.count >= 1000000 && model.count < 1000000000)
							return Math.round(model.count/1000000) + " MB"
						else if(model.count >= 1000000000 && model.count < 1000000000000)
							return Math.round(model.count/1000000000) + " GB"
					}
				}

				font.weight: Font.DemiBold
				font.pixelSize: dp(12)*parent.height/170

				horizontalAlignment: Text.AlignHCenter

				Behavior on color {
					ColorAnimation {
						easing.type: Easing.InOutQuad;
						duration: Material.MaterialAnimation.pageTransitionDuration
					}
				}
			}
		}
	}
}
