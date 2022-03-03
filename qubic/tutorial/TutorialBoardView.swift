//
//  TutorialBoardView.swift
//  qubic
//
//  Created by Chris McElroy on 11/7/21.
//  Copyright © 2021 XNO LLC. All rights reserved.
//

import SwiftUI
import SceneKit

struct TutorialBoardView: UIViewRepresentable {
	func makeUIView(context: Context) -> SCNView { return TutorialBoardScene.tutorialMain.view }
	func updateUIView(_ scnView: SCNView, context: Context) { }
}

class TutorialBoardScene: BoardScene {
	static let tutorialMain = TutorialBoardScene()
	var pannedOut = false
	var line: [Int]? = nil
	var answer: Int? = nil
	var currentColor: UIColor? = nil
	
	override init() {
		super.init()
		reset()
	}
	
	func reset() {
		super.reset(for: Game.main)
		
		camera.position = SCNVector3(-1, 10, -1)
		camera.rotation = SCNVector4(1, 0, 0, -Float.pi/2)
		camera.camera?.orthographicScale = 6.7
		
		for i in 0..<64 where ![0, 1, 2, 4, 5, 6, 8, 9, 10].contains(i) {
			self.spaces[i].opacity = 0
		}
		
		pannedOut = false
	}
	
	@objc override func handleTap(_ gestureRecognize: UIGestureRecognizer) {
		print("tapped")
		if TutorialLayout.main.readyToContinue {
			TutorialLayout.main.next()
			return
		}
		guard pannedOut else { return }
		if GameLayout.main.hidePopups() { return } // TODO make this a tutorial game layout thing once I have one
		let hit = gestureRecognize.location(in: view)
		let hitResults = view.hitTest(hit, options: [:])
		guard let result = hitResults.first?.node else {
			if let oldTap = mostRecentTap, oldTap.distance(to: Date()) < 0.5 {
				resetRotation()
				mostRecentTap = nil
			} else {
				mostRecentTap = Date()
			}
			return
		}
		if let p = spaces.firstIndex(where: { $0.childNodes.contains(result) || $0 == result }) {
			if moves[p].opacity > 0 {
				// make sure it's settled to avoid rowen's bug
				if moves[p].position.y == 0 {
					spaces[p].runAction(SceneHelper.getFullRotate(1.0))
				}
				return
			}
			if answer == p {
				answer = nil
				
				placeCube(move: p, color: currentColor ?? .primary())
				
				for (i, move) in (line ?? []).enumerated() {
					Timer.after(0.16*Double(i) + 0) { self.spinMove(move, space: self.spaces[move], spin: true) }
					Timer.after(0.12*Double(i) + 0.6) { self.undoMove(move) }
				}
				
				let currentLine = line
				Timer.after(1.2) {
					if self.line == currentLine {
						TutorialLayout.main.next()
					}
				}
				return
			}
			let turn = TutorialGame.tutorialMain.gameState == .active ? TutorialGame.tutorialMain.turn : TutorialGame.tutorialMain.myTurn
			if TutorialGame.tutorialMain.gameState == .active && GameLayout.main.nextOpacity == .full {
				TutorialGame.tutorialMain.notificationGenerator.notificationOccurred(.error)
				GameLayout.main.flashNextArrow()
				return
			}
			if let user = TutorialGame.tutorialMain.player[turn] as? User, TutorialGame.tutorialMain.premoves.isEmpty {
				if Storage.int(.confirmMoves) == 0 {
					if p == potentialMove {
						potentialMove = nil
						spinMoves()
						user.move(at: p)
					} else {
						potentialMove = potentialMove == nil ? p : nil
						spinMoves()
					}
				} else {
					user.move(at: p)
				}
			} // not tryna do premoves here bc spin moves doesn't even work and i want to hide settings anyway
//			} else if TutorialGame.tutorialMain.gameState == .active && Storage.int(.premoves) == 0 {
//				print("b")
//				if TutorialGame.tutorialMain.premoves.contains(p) {
//					TutorialGame.tutorialMain.premoves = []
//				} else {
//					TutorialGame.tutorialMain.premoves.append(p)
//				}
//				spinMoves()
//			} else {
//				print("C")
//			}
		}
	}
	
	func clearMoves() {
		for (p, cube) in moves.enumerated() {
			if cube.opacity != 0 {
				self.undoMove(p)
			}
		}
	}
	
	func panOut() {
		pannedOut = true
		
		let duration1 = 1.2
		let zoomAction = SCNAction.customAction(duration: duration1, action: { node, time in
			node.camera?.orthographicScale = 6.7 + (9.6 - 6.7)*(time / duration1)
		})
		let moveAction1 = SCNAction.move(to: SCNVector3(x: 0, y: 10, z: 0), duration: duration1)
		let rotateAction1 = SCNAction.rotate(by: -0.53, around: SCNVector3(0,1,0), duration: duration1)
		let cameraMove1 = SCNAction.group([zoomAction, moveAction1, rotateAction1])
		cameraMove1.timingMode = .easeInEaseOut
		camera.runAction(cameraMove1)
		
		let fadeInAction = SCNAction.fadeIn(duration: 0.6)
		fadeInAction.timingMode = .easeInEaseOut
		
		for i in 0..<64 where ![0, 1, 2, 4, 5, 6, 8, 9, 10].contains(i) {
			spaces[i].runAction(fadeInAction)
		}
		
		let duration2 = 1.6
		let moveAction2 = SCNAction.move(to: SCNVector3(x: -5.65, y: 4.9, z: 10.0), duration: duration2)
		let rotateAction2 = SCNAction.rotateTo(x: -0.403, y: -0.5135, z: 0, duration: duration2, usesShortestUnitArc: true)
		let cameraMove2 = SCNAction.group([moveAction2, rotateAction2])
		cameraMove2.timingMode = .easeInEaseOut
		Timer.after(duration1) { self.camera.runAction(cameraMove2) }
	}
}
