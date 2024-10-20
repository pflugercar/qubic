//
//  LinkHelper.swift
//  qubic
//
//  Created by Chris McElroy on 9/16/22.
//  Copyright © 2022 XNO LLC. All rights reserved.
//

import SwiftUI

struct ShareButton: View {
	let playerID: String
	let gameID: String
	let movesIn: String?
	
	init() {
		playerID = game.player[game.myTurn].id
		gameID = String(game.gameID)
		movesIn = game.movesBack != 0 ? String(game.moves.count - game.movesBack) : nil
	}
	
	init(playerID: String, gameID: String, movesIn: String? = nil) {
		self.playerID = playerID
		self.gameID = gameID
		self.movesIn = movesIn
	}
	
	var body: some View {
		if let url = getURL() {
			if #available(iOS 16.0, *) {
				ShareLink(item: url) {
					Text("share")
				}
			} else {
				Button("share") {
					presentShareSheet(for: url)
				}
			}
		}
	}
	
	func getURL() -> URL? {
		let movesPart = movesIn != nil ? "&m=" + (movesIn ?? "") : ""
		return URL(string: "https://xno.store/share?u=" + playerID + "&g=" + gameID + movesPart)
	}
}

func deeplink(to url: URL) {
	guard let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: true)?.queryItems else { return }
	guard url.lastPathComponent == "share" else { return }
	guard queryItems.count >= 2 else { return }
	guard queryItems[0].name == "u" else { return }
	guard queryItems[1].name == "g" else { return }
	
	let userID = queryItems[0].value ?? ""
	let gameID = Int(queryItems[1].value ?? "") ?? 0
	var movesIn: Int? = nil
	
	if queryItems.count == 3 && queryItems[2].name == "m" {
		movesIn = Int(queryItems[2].value ?? "")
	}
	
	FB.main.getPastGame(userID: userID, gameID: gameID, completion: { gameData in
		let myData = PlayerData.getData(for: userID, mode: gameData.mode)
		let opData = PlayerData.getData(for: gameData.opID, mode: gameData.mode)
		
		if Layout.main.current == .tutorial {
			return
		} else if Layout.main.showGame {
			GameLayout.main.deepLinkAction = {
				Layout.main.change(to: .share)
				let setup = PastGameSetup(gameData: gameData, myData: myData, opData: opData, movesIn: movesIn)
				GameLayout.main.animateGameChange(rematch: true, pastGameSetup: setup)
			}
			GameLayout.main.setPopups(to: .deepLink)
		} else {
			Layout.main.change(to: .share)
			let setup = PastGameSetup(gameData: gameData, myData: myData, opData: opData, movesIn: movesIn)
			PastGame().load(setup: setup)
			GameLayout.main.animateIntro()
		}
	})
}

fileprivate func presentShareSheet(for url: URL) {
	let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
	UIApplication.shared.windows.first?.rootViewController?.present(activityVC, animated: true, completion: nil)
}
