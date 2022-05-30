//
//  GameLayout.swift
//  qubic
//
//  Created by Chris McElroy on 10/17/21.
//  Copyright © 2021 XNO LLC. All rights reserved.
//

import SwiftUI

enum GamePopup {
	case none, analysis, options, gameEnd, gameEndPending, settings
	
	var up: Bool {
		!(self == .none || self == .gameEndPending)
	}
}

class GameLayout: ObservableObject {
	static let main = GameLayout()
	
	@Published var undoOpacity: Opacity = .clear
	@Published var prevOpacity: Opacity = .clear
	@Published var nextOpacity: Opacity = .clear
	@Published var optionsOpacity: Opacity = .clear
	
	@Published var popup: GamePopup = .none
	@Published var delayPopups: Bool = true
	@Published var showWinsFor: Int? = nil
	@Published var showAllHints: Bool = true
	
	@Published var hideAll: Bool = true
	@Published var hideBoard: Bool = true
	@Published var centerNames: Bool = true
	
	@Published var showDCAlert: Bool = false
	@Published var showCubistAlert: Bool = false
	
	@Published var analysisMode = 2
	@Published var analysisTurn = 1
	@Published var analysisText: [[String]?] = [nil, nil, nil]
	@Published var winAvailable: [Bool] = [false, false, false]
	@Published var currentSolveType: SolveType? = nil
	@Published var currentPriority: Int = 0
	@Published var beatCubist = false
	@Published var confirmMoves = Storage.int(.confirmMoves)
	@Published var premoves = Storage.int(.premoves)
	@Published var moveChecker = Storage.int(.moveChecker)
	@Published var arrowSide = Storage.int(.arrowSide)
	
	let nameSpace: CGFloat = 65
	let gameControlSpace: CGFloat = Layout.main.hasBottomGap ? 45 : 60
	let gameControlHeight: CGFloat = 40
	
	var currentHintMoves: Set<Int>? {
		guard let winsFor = showWinsFor else { return nil }
		guard let currentMove = game.currentMove else {
			if winsFor == 1 { return nil }
			return Set(Board.positionDict[[0,0]]?.1 ?? [])
		}
		return showAllHints ? currentMove.allMoves[winsFor] : currentMove.bestMoves[winsFor]
	}
	
	func animateIntro() {
		hideAll = true
		hideBoard = true
		centerNames = true
		showWinsFor = nil
		analysisMode = 2
		analysisTurn = 1
		updateSettings()
		
//        BoardScene.main.rotate(right: true) // this created a race condition
		game.timers.append(Timer.after(0.1) {
			withAnimation {
				self.hideAll = false
			}
		})
		
		game.timers.append(Timer.after(1) {
			withAnimation {
				self.centerNames = false
			}
		})
		
		game.timers.append(Timer.after(1.1) {
			withAnimation {
				self.hideBoard = false
			}
			BoardScene.main.rotate(right: false)
		})
		
		game.timers.append(Timer.after(1.5) {
			game.startGame()
		})
	}
	
	func animateGameChange(rematch: Bool) {
		hidePopups()
		analysisMode = 2
		analysisTurn = 1
		updateSettings()
		
		withAnimation {
			undoOpacity = .clear
			prevOpacity = .clear
			nextOpacity = .clear
			optionsOpacity = .clear
		}
		
		game.timers.append(Timer.after(0.3) {
			withAnimation {
				self.hideBoard = true
			}
			BoardScene.main.rotate(right: false)
		})
		
		game.timers.append(Timer.after(0.6) {
			withAnimation { self.showWinsFor = nil }
			game.turnOff()
			if rematch { game.loadRematch() }
			else { game.loadNextGame() }
			
			// inside this one so they don't get cancled when the game turns off
			game.timers.append(Timer.after(0.2) {
				withAnimation {
					self.hideBoard = false
				}
				BoardScene.main.rotate(right: false)
			})
			
			game.timers.append(Timer.after(0.6) {
				game.startGame()
			})
		})
	}
	
	
	func loadGameOpacities() {
		undoOpacity = .clear
		prevOpacity = .clear
		nextOpacity = .clear
		optionsOpacity = .clear
	}
	
	func startGameOpacities() {
		withAnimation {
			undoOpacity = game.hints || game.mode.solve ? .half : .clear
			prevOpacity = .half
			nextOpacity = game.movesBack > 0 ? .full : .half // for tutorial
			optionsOpacity = .full
		}
	}
	
	func newMoveOpacities() {
		if undoOpacity == .half { withAnimation { undoOpacity = .full } }
		withAnimation { prevOpacity = .full }
	}
	
	
	func newGhostMoveOpacities() {
		withAnimation {
			prevOpacity = .full
			nextOpacity = .half
		}
	}
	
	func undoMoveOpacities() {
		if game.moves.count == game.preset.count {
			withAnimation {
				undoOpacity = .half
				prevOpacity = .half
			}
		}
	}
	
	func prevMoveOpacities() {
		withAnimation {
			nextOpacity = game.movesBack > 0 ? .full : .half
			if undoOpacity == .full { undoOpacity = .half }
			var minMoves = 0
			if game.mode.solve && (game.gameState == .active || !game.hints) {
				minMoves = game.preset.count
			}
			if game.moves.count - game.movesBack == minMoves { prevOpacity = .half }
		}
	}
	
	func nextMoveOpacities() {
		withAnimation {
			prevOpacity = .full
			if game.movesBack == 0 {
				if undoOpacity == .half { undoOpacity = .full }
				nextOpacity = .half
			}
		}
	}
	
	func flashNextArrow() {
		for delay in stride(from: 0.0, to: 0.4, by: 0.3) {
			game.timers.append(Timer.after(delay, run: { self.nextOpacity = .half }))
			game.timers.append(Timer.after(delay + 0.15, run: { self.nextOpacity = .full }))
		}
	}
	
	func flashPrevArrow() {
		for delay in stride(from: 0.0, to: 0.4, by: 0.3) {
			game.timers.append(Timer.after(delay, run: { self.prevOpacity = .half }))
			game.timers.append(Timer.after(delay + 0.15, run: { self.prevOpacity = .full }))
		}
	}
	
	func hidePopups() {
		if popup == .gameEnd {
			game.reviewingGame = true
			FB.main.cancelOnlineSearch?()
		}
		if popup == .none { return }
		withAnimation {
			popup = .none
		}
	}
	
	func setPopups(to newSetting: GamePopup) {
		if popup == .gameEnd {
			game.reviewingGame = true
			FB.main.cancelOnlineSearch?()
		}
		withAnimation {
			popup = newSetting
			delayPopups = true
		}
		Timer.after(0.1) {
			withAnimation { self.delayPopups = false }
		}
	}
	
	func updateSettings() {
		confirmMoves = Storage.int(.confirmMoves)
		premoves = Storage.int(.premoves)
		moveChecker = Storage.int(.moveChecker)
		arrowSide = Storage.int(.arrowSide)
		if let trainArray = Storage.array(.train) as? [Int] {
			beatCubist = trainArray[5] == 1
		}
	}
	
	func setConfirmMoves(to v: Int) {
		confirmMoves = v
		Storage.set(v, for: .confirmMoves)
		if v == 0 {
			setPremoves(to: 1)
		} else {
			BoardScene.main.potentialMove = nil
		}
		BoardScene.main.spinMoves()
	}
	
	func setPremoves(to v: Int) {
		premoves = v
		Storage.set(v, for: .premoves)
		if v == 0 {
			setConfirmMoves(to: 1)
			BoardScene.main.potentialMove = nil
		} else {
			game.premoves = []
		}
		BoardScene.main.spinMoves()
	}
	
	func setMoveChecker(to v: Int) {
		if beatCubist {
			moveChecker = v
			Storage.set(v, for: .moveChecker)
		}
	}
	
	func setArrowSide(to v: Int) {
		withAnimation { Layout.main.leftArrows = v == 0 }
		arrowSide = v
		Storage.set(v, for: .arrowSide)
	}
	
	func onAnalysisModeSelection(to v: Int) {
		analysisMode = v
		withAnimation {
			if v < 2 {
				if analysisTurn == 1 {
					showWinsFor = currentPriority
				} else {
					showWinsFor = analysisTurn == 0 ? 0 : 1
				}
				showAllHints = v == 0
				game.timers.append(Timer.after(0.4) {
					self.hidePopups()
				})
			} else {
				showWinsFor = nil
			}
		}
		BoardScene.main.spinMoves()
	}
	
	func onAnalysisTurnSelection(v: Int) {
		analysisTurn = v
		withAnimation {
			analysisMode = 2
			showWinsFor = nil
		}
		BoardScene.main.spinMoves()
	}
	
	func refreshHints() {
		let firstHint: HintValue?
		let secondHint: HintValue?
		let priorityHint: HintValue?
		if game.currentMove == nil {
			firstHint = .dw
			secondHint = .noW
		} else {
			firstHint = game.currentMove?.hints[0]
			secondHint = game.currentMove?.hints[1]
		}
		
		currentSolveType = game.currentMove?.solveType
		
		let opText: [String]?
		let myText: [String]?
		let priorityText: [String]?
		switch (game.myTurn == 1 ? firstHint : secondHint) {
		case .dw:	opText = ["forced win",			"Your opponent can reach a second order checkmate in \(game.currentMove?.winLen ?? 9) moves!"]
		case .dl:	opText = ["strong defense",		"Your opponent can force you to take up to \(game.currentMove?.winLen ?? 9) moves to reach a second order checkmate!"]
		case .w0:   opText = ["4 in a row", 		"Your opponent won the game, better luck next time!"]
		case .w1:   opText = ["3 in a row",			"Your opponent has 3 in a row, so now they can fill in the last move in that line and win!"]
		case .w2d1: opText = ["checkmate", 			"Your opponent can get two checks with their next move, and you can’t block both!"]
		case .w2:   opText = ["2nd order win", 		"Your opponent can get to a checkmate using a series of checks! They can win in \(game.currentMove?.winLen ?? 0) moves!"]
		case .c1:   opText = ["check", 				"Your opponent has 3 in a row, so you should block their line to prevent them from winning!"]
		case .cm1:  opText = ["checkmate", 			"Your opponent has more than one check, and you can’t block them all!"]
		case .cm2:  opText = ["2nd order checkmate","Your opponent has more than one second order check, and you can’t block them all!"]
		case .c2d1: opText = ["2nd order check", 	"Your opponent can get checkmate next move if you don’t stop them!"]
		case .c2:   opText = ["2nd order check", 	"Your opponent can get checkmate through a series of checks if you don’t stop them!"]
		case .noW:  opText = ["no wins", 			"Your opponent doesn't have any forced wins right now, keep it up!"]
		case nil:   opText = nil
		}
		
		switch (game.myTurn == 0 ? firstHint : secondHint) {
		case .dw:	myText = ["forced win",			"You can reach a second order checkmate in \(game.currentMove?.winLen ?? 9) moves!"]
		case .dl:	myText = ["strong defense",		"You can force your oppoennt to take up to \(game.currentMove?.winLen ?? 9) moves to reach a second order checkmate!"]
		case .w0:   myText = ["4 in a row", 		"You won the game, great job!"]
		case .w1:   myText = ["3 in a row",			"You have 3 in a row, so now you can fill in the last move in that line and win!"]
		case .w2d1: myText = ["checkmate", 			"You can get two checks with your next move, and your opponent can’t block both!"]
		case .w2:   myText = ["2nd order win", 		"You can get to a checkmate using a series of checks! You can win in \(game.currentMove?.winLen ?? 0) moves!"]
		case .c1:   myText = ["check", 				"You have 3 in a row, so you can win next turn unless it’s blocked!"]
		case .cm1:  myText = ["checkmate", 			"You have more than one check, and your opponent can’t block them all!"]
		case .cm2:  myText = ["2nd order checkmate","You have more than one second order check, and your opponent can’t block them all!"]
		case .c2d1: myText = ["2nd order check", 	"You can get checkmate next move if your opponent doesn’t stop you!"]
		case .c2:   myText = ["2nd order check", 	"You can get checkmate through a series of checks if your opponent doesn’t stop you!"]
		case .noW:  myText = ["no wins", 			"You don't have any forced wins right now, keep working to set one up!"]
		case nil:   myText = nil
		}
		
		if firstHint == nil || secondHint == nil {
			priorityHint = nil
			priorityText = nil
			currentPriority = showWinsFor ?? game.myTurn
		} else if firstHint == .noW && secondHint == .noW {
			priorityHint = .noW
			priorityText = myText
			currentPriority = game.myTurn
		} else if firstHint ?? .noW > secondHint ?? .noW {
			priorityHint = firstHint
			priorityText = game.myTurn == 0 ? myText : opText
			currentPriority = 0
		} else {
			priorityHint = secondHint
			priorityText = game.myTurn == 1 ? myText : opText
			currentPriority = 1
		}
		
		winAvailable = [firstHint ?? .noW != .noW, priorityHint ?? .noW != .noW, secondHint ?? .noW != .noW]
		
		Timer.after(0.05) {
			self.analysisText = game.myTurn == 0 ? [myText, priorityText,  opText] : [opText, priorityText, myText]
		}
		
		if analysisMode != 2 && analysisTurn == 1 {
			Timer.after(0.06) {
				withAnimation {
					self.showWinsFor = self.currentPriority
				}
				BoardScene.main.spinMoves()
			}
		}
	}
	
	func getGameEndText() -> String {
		let myTurn = game.myTurn
		let opTurn = game.myTurn^1
		switch game.gameState {
		case .myWin:
			if game.mode.solve {
				if game.mode == .daily && Storage.int(.lastDC) > game.lastDC {
					return "\(Storage.int(.streak)) day streak!"
				}
				
				var checksOnly = true
				var i = game.preset.count
				while i < game.moves.count - 1 {
					if game.moves[i].hints[myTurn] != .c1 && game.moves[i].hints[myTurn] != .cm1 { checksOnly = false }
					i += 2
				}
				if checksOnly {
					if game.moves[game.preset.count - 1].hints[myTurn] == .w1 && game.moves.count == game.preset.count + 1 {
						return "you found the fastest win!"
					} else if game.moves[game.preset.count - 1].hints[myTurn] == .cm1 && game.moves.count == game.preset.count + 3 {
						return "you found the fastest win!"
					} else if game.moves.count == game.preset.count + 2*game.moves[game.preset.count - 1].winLen - 1 {
						return "you found the fastest second order win!"
					} else {
						return "though there is a faster win!"
					}
				} else {
					if game.moves.count < game.preset.count + 2*game.moves[game.preset.count - 1].winLen - 1 {
						return "faster than the fastest second order win!"
					} else {
						return "nice creative solution!"
					}
				}
			} else {
				guard game.moves.count >= 7 else {
					print("error")
					return "great job pulling that off!"
				}
				if game.moves[game.moves.count - 3].hints[myTurn] == .c1 {
					return "they didn't see that coming!"
				}
				
				var hadW2 = false
				var fastestW2 = 0
				var W2len = 0
				var checkedFromFirstChance = false
				var opOpening = false
				var winFromMistake = false
				var unbeatable = true
				var successfulW3D1 = false
				for (i, move) in game.moves.enumerated() {
					if i % 2 == opTurn {
						if move.hints[myTurn] == .w2 {
							if !hadW2 {
								checkedFromFirstChance = true
							}
							if W2len == 0 {
								fastestW2 = move.winLen
							}
							hadW2 = true
						}
					} else {
						if move.hints[myTurn] == .c1 || move.hints[myTurn] == .cm1 || move.hints[myTurn] == .w0 {
							W2len += 1
						} else {
							if move.hints[myTurn] != .dw {
								unbeatable = false
							}
							checkedFromFirstChance = false
//							winFromMistake = false
							W2len = 0
							fastestW2 = 0
							switch move.hints[opTurn] {
							case .w2, .w2d1, .w1:
								opOpening = true
								winFromMistake = true
							case .dw:
								opOpening = true
							default: break
							}
						}
						if move.hints[myTurn] == .cm2 {
							successfulW3D1 = true
						} else if move.hints[myTurn] != .cm1 && move.hints[myTurn] != .c1 && move.hints[myTurn] != .w0 {
							successfulW3D1 = false
						}
					}
				}
				
				if unbeatable {
					return "your moves were unbeatable!"
				}
				
				var comments: [String] = []
				if checkedFromFirstChance {
					comments.append("you started forcing at the first opportunity!")
				}
				if W2len > 2 {
					comments.append("you found a \(W2len) move win!")
					if W2len == fastestW2 {
						comments.append("you found the fastest second order win!")
					}
				}
				if successfulW3D1 {
					comments.append("nice second order checkmate!")
				}
				if opOpening {
					if winFromMistake {
						comments.append("you capitalized on their mistake!")
					}
				} else {
					comments.append("they never had an opening!")
				}
				if W2len == 2 {
					comments.append("nice checkmate!")
				}
				
				if let comment = comments.randomElement() {
					return comment
				}
				
				return ["great job!", "keep it up!", "they didn't see that coming!"].randomElement() ?? ""
				// TODO once I have stats, add "your first win!", "your longest second order win!", and "4 wins in a row—meta!"
				// TODO once I can see 3rd order wins, add those in as well
			}
		case .opTimeout:
			return ["nice time managment!", "they ran out of time!", "you must have stumped them!"].randomElement() ?? ""
		case .opResign:
			return "your opponent resigned!" // got to keep this clear so they know what happened
			
		case .opWin:
			if game.moves.count > 4 && game.moves[game.moves.count - 3].hints[opTurn] == .c1 && game.moves[game.moves.count - 3].hints[myTurn] != .w1 && game.moves[game.moves.count - 4].hints[myTurn] == .c1 {
				if game.mode.solve { return ["their block created a check!", "watch out for that one!"].randomElement() ?? "" }
				return "their block created a check!"
			}
			if game.mode.solve {
				var checksOnly = true
				var i = game.preset.count
				while i < game.moves.count - 1 {
					if game.moves[i].hints[myTurn] != .c1 && game.moves[i].hints[myTurn] != .cm1 {
						checksOnly = false
					}
					i += 2
				}
				if checksOnly {
					return "watch out for that one!"
				} else {
					return ["you can win with only checks!", "you'll get it soon!", "you're nearly there!"].randomElement() ?? ""
				}
			} else {
				var W2len = 0
				var blockableW2 = false
				var myOpening = false
				var myMistake = false
				var unbeatable = true
				var successfulW3D1 = false
				var earlyForce = false
				
				for (i, move) in game.moves.enumerated() {
					if i % 2 == myTurn {
						if move.hints[myTurn] == .c1 {
							if i > 0 && (game.moves[i-1].hints[opTurn] == .noW || game.moves[i-1].hints[opTurn] == .dl) && (game.moves[i - 1].hints[myTurn] != .c2 && game.moves[i - 1].hints[myTurn] != .c2d1 && game.moves[i - 1].hints[myTurn] != .w1) {
								earlyForce = true
							}
						}
					} else {
						if move.hints[opTurn] == .c1 || move.hints[opTurn] == .cm1 || move.hints[opTurn] == .w0 {
							W2len += 1
						} else {
							if move.hints[opTurn] != .dw {
								unbeatable = false
							}
							blockableW2 = move.hints[opTurn] == .c2
							W2len = 0
							switch move.hints[myTurn] {
							case .w2, .w2d1, .w1:
								myOpening = true
								myMistake = true
							case .dw:
								myOpening = true
							default: break
							}
						}
						if move.hints[opTurn] == .cm2 {
							successfulW3D1 = true
						} else if move.hints[opTurn] != .cm1 && move.hints[opTurn] != .c1 && move.hints[opTurn] != .w0 {
							successfulW3D1 = false
						}
					}
				}
				
				if unbeatable {
					return "their moves were unbeatable!"
				}
				
				var comments: [String] = []
				
				if game.moves.count > 2 && game.moves[game.moves.count - 3].hints[opTurn] == .c1 {
					comments.append("watch out for that one!")
				}
				
				if W2len > 2 {
					comments.append("they found a \(W2len) move win!")
					if blockableW2 {
						comments.append("you could have blocked that win!")
					}
				}
				if successfulW3D1 {
					comments.append("they found a second order checkmate!")
				}
				if myOpening {
					if myMistake {
						comments.append("you let a win slip through your fingers!")
					}
				} else {
					comments.append("you never had an opening!")
				}
				if earlyForce {
					comments.append("you started forcing too early!")
				}
				
				print("comments:", comments)
				if let comment = comments.randomElement() {
					return comment
				}
				
				return ["watch out for that one!", "they won this round!", "better luck next time!"].randomElement() ?? ""
				// TODO once I have stats, add "your first loss!"
				// TODO once I can see 3rd order wins, add those in as well
			}
		case .myTimeout:
			return ["don't let the clock run out!", "keep your eye on the clock!", "make sure to watch your time!"].randomElement() ?? ""
		case .myResign:
			if let last = game.moves.last {
				if last.hints[opTurn] == .w1 {
					return "you couldn't let them win?"
				}
				if last.hints[myTurn] == .w2 || last.hints[myTurn] == .w1 || last.hints[myTurn] == .w2d1 || last.hints[myTurn] == .cm1 {
					return "but you had a win!"
				}
				if last.hints[myTurn] == .c1 {
					if game.moves.count > 2 {
						let prevHint = game.moves[game.moves.count - 2].hints[myTurn]
						if prevHint == .w2 || prevHint == .w2d1 || prevHint == .w1 {
							return "but you had a win!"
						}
					}
				}
				if last.hints[opTurn] == .w2 || last.hints[opTurn] == .w2d1 || last.hints[opTurn] == .cm1 {
					return "they did have a win!"
				}
				if last.hints[opTurn] == .c1 {
					if game.moves.count > 2 {
						let prevHint = game.moves[game.moves.count - 2].hints[opTurn]
						if prevHint == .w2 || prevHint == .w2d1 || prevHint == .w1 {
							return "they did have a win!"
						}
					}
				}
			}
			return "better luck next time!"
		case .draw:
			// TODO add "your first draw!" when i have stats
			return "that's hard to do!"
		case .ended:
			switch game.moves.count {
			case 0...12: return "a short one!"
			case 24...64: return "a long one!"
			default: return "come back soon!"
			}
			
		default: return ""
		}
	}
}
