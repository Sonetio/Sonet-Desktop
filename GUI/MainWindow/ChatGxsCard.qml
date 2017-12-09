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
import Material.ListItems 0.1 as ListItem

import MessagesModel 0.2

Card {
	id: drag

	property string gxsId
	property string chatId
	property alias contentm: contentm

	property int status: 1

	// For handling tokens
	property int stateToken: 0
	property int stateToken_unreadMsgs: 0

	Behavior on height {
		ScriptAction { script: {contentm.positionViewAtEnd()} }
	}

	function initiateChat() {
		var jsonData = {
			own_gxs_hex: mainGUIObject.defaultGxsId,
			remote_gxs_hex: drag.gxsId
		}

		function callbackFn(par) {
			chatId = String(JSON.parse(par.response).data.chat_id)
			getUnreadMsgs()
			timer.running = true
		}

		rsApi.request("/chat/initiate_distant_chat/", JSON.stringify(jsonData), callbackFn)
	}

	function checkChatStatus() {
		var jsonData = {
			chat_id: drag.chatId
		}

		function callbackFn(par) {
			if(status != String(JSON.parse(par.response).data.status)) {
				status = String(JSON.parse(par.response).data.status)
				if(status == 2)
					drag.getChatMessages()
			}
		}

		rsApi.request("/chat/distant_chat_status/", JSON.stringify(jsonData), callbackFn)
	}

	function closeChat() {
		var jsonData = {
			distant_chat_hex: drag.chatId
		}

		rsApi.request("/chat/close_distant_chat/", JSON.stringify(jsonData), function(){})
	}

	function getChatMessages() {
		if (drag.chatId == "")
			return

		function callbackFn(par) {
			stateToken = JSON.parse(par.response).statetoken
			mainGUIObject.registerToken(stateToken, getChatMessages)

			messagesModel.loadJSONMessages(par.response)
		}

		rsApi.request("/chat/messages/"+drag.chatId, "", callbackFn)
	}

	function getUnreadMsgs() {
		function callbackFn(par) {
			var jsonResp = JSON.parse(par.response)

			var found = false
			for (var i = 0; i<jsonResp.data.length; i++) {
				if(jsonResp.data[i].chat_id == chatId) {
					indicatorNumber = jsonResp.data[i].unread_count
					found = true
				}
			}

			if(!found)
				indicatorNumber = 0

			stateToken_unreadMsgs = jsonResp.statetoken
			mainGUIObject.registerToken(stateToken_unreadMsgs, getUnreadMsgs)
		}

		rsApi.request("/chat/unread_msgs/", "", callbackFn)
	}

	Component.onCompleted: drag.initiateChat()
	Component.onDestruction: {
		mainGUIObject.unregisterToken(stateToken)
		mainGUIObject.unregisterToken(stateToken_unreadMsgs)
		closeChat()
	}

	MessagesModel {
		id: messagesModel
	}

	Item {
		id: chat
		anchors.fill: parent

		Item {
			anchors {
				top: parent.top
				bottom: itemInfo.top
				left: parent.left
				right: parent.right
				leftMargin: dp(15)
				rightMargin: dp(15)
			}

			ListView {
				id: contentm

				anchors {
					fill: parent
					leftMargin: dp(5)
					rightMargin: dp(5)
				}

				clip: true
				snapMode: ListView.NoSnap
				flickableDirection: Flickable.AutoFlickDirection

				model: messagesModel
				delegate: ChatMsgDelegate{}

				header: Item {
					width: 1
					height: dp(5)
				}
			}

			Material.Scrollbar {
				anchors.margins: 0
				flickableItem: contentm
			}
		}

		Item {
			id: itemInfo
			anchors {
				bottom: chatFooter.top
				left: parent.left
				right: parent.right
				leftMargin: dp(15)
				rightMargin: dp(15)
			}

			height: viewInfo.height + dp(5)

			states: [
				State {
					name: "hide"; when: drag.status == 2
					PropertyChanges {
						target: itemInfo
						visible: false
					}
				},
				State {
					name: "show"; when: drag.status != 2
					PropertyChanges {
						target: itemInfo
						visible: true
					}
				}
			]

			transitions: [
				Transition {
					from: "hide"; to: "show"

					SequentialAnimation {
						PropertyAction {
							target: itemInfo
							property: "visible"
							value: true
						}
						ParallelAnimation {
							NumberAnimation {
								target: itemInfo
								property: "opacity"
								from: 0
								to: 1
								easing.type: Easing.InOutQuad;
								duration: Material.MaterialAnimation.pageTransitionDuration
							}
							NumberAnimation {
								target: itemInfo
								property: "anchors.bottomMargin"
								from: -itemInfo.height
								to: 0
								easing.type: Easing.InOutQuad;
								duration: Material.MaterialAnimation.pageTransitionDuration
							}
						}
					}
				},
				Transition {
					from: "show"; to: "hide"

					SequentialAnimation {
						PauseAnimation {
							duration: 2000
						}
						ParallelAnimation {
							NumberAnimation {
								target: itemInfo
								property: "opacity"
								from: 1
								to: 0
								easing.type: Easing.InOutQuad
								duration: Material.MaterialAnimation.pageTransitionDuration
							}
							NumberAnimation {
								target: itemInfo
								property: "anchors.bottomMargin"
								from: 0
								to: -itemInfo.height
								easing.type: Easing.InOutQuad
								duration: Material.MaterialAnimation.pageTransitionDuration
							}
						}
						PropertyAction {
							target: itemInfo;
							property: "visible";
							value: false
						}
					}
				}
			]

			Material.View {
				id: viewInfo
				anchors {
					right: parent.right
					left: parent.left
					top: parent.top
					rightMargin: parent.width*0.03
					leftMargin: parent.width*0.03
				}

				height: textMsg.implicitHeight + dp(12)
				width: (parent.width*0.8)

				backgroundColor: Material.Theme.accentColor
				elevation: 1
				radius: 10


				TextEdit {
					id: textMsg

					anchors {
						top: parent.top
						topMargin: dp(6)
						left: parent.left
						right: parent.right
					}

					text: drag.status == 0 ? "Something goes wrong..."
						: drag.status == 1 ? "Tunnel is pending..."
						: drag.status == 2 ? "Connection is established"
						: drag.status == 3 ? "Your friend closed chat."
						: "Something goes wrong..."

					textFormat: Text.RichText
					wrapMode: Text.WordWrap

					color: "white"
					readOnly: true

					selectByMouse: false

					horizontalAlignment: TextEdit.AlignHCenter

					font {
						family: "Roboto"
						pixelSize: dp(13)
					}
				}
			}
		}

		Item {
			id: chatFooter

			anchors {
				bottom: parent.bottom
				left: parent.left
				right: parent.right
			}

			height: (msgBox.contentHeight < dp(20) ? (msgBox.contentHeight+dp(30)) : (msgBox.contentHeight+dp(22))) < dp(200)
					    ? (msgBox.contentHeight < dp(20) ? (msgBox.contentHeight+dp(30)) : (msgBox.contentHeight+dp(22)))
						: dp(200)

			z: 1

			Behavior on height {
				ScriptAction {script: contentm.positionViewAtEnd()}
			}

			Material.View {
				id: footerView

				anchors {
					fill: parent
					bottomMargin: dp(10)
					leftMargin: dp(15)
					rightMargin: dp(15)
				}

				radius: 10
				elevation: 1
				backgroundColor: "white"

				TextArea {
					id: msgBox

					anchors {
						fill: parent
						verticalCenter: parent.verticalCenter
						topMargin: dp(5)
						bottomMargin: dp(5)
						leftMargin: dp(18)
						rightMargin: dp(18)
					}

					placeholderText: footerView.width > dp(195) ? "Say hello to your friend" : "Say hello"

					font.pixelSize: dp(15)

					wrapMode: Text.WordWrap
					frameVisible: false
					focus: true

					horizontalScrollBarPolicy: Qt.ScrollBarAlwaysOff
					verticalScrollBarPolicy: Qt.ScrollBarAlwaysOff

					onActiveFocusChanged: {
						if(activeFocus) {
							if(drag.chatId.length > 0)
								rsApi.request("/chat/mark_chat_as_read/"+drag.chatId, "", function(){})

							footerView.elevation = 2
						}
						else
							footerView.elevation = 1
					}

					Keys.onPressed: {
						if(event.key == Qt.Key_Return) {
							var jsonData = {
								chat_id: drag.chatId,
								msg: msgBox.text
							}
							rsApi.request("chat/send_message/", JSON.stringify(jsonData), function(){})
							drag.getChatMessages()
							msgBox.text = ""
							event.accepted = true

							soundNotifier.playChatMessageSended()
						}
					}
				}
			}
		}

		Timer {
			id: timer
			interval: 1000
			repeat: true
			running: false

			onTriggered: drag.checkChatStatus()
		}
	}
}
