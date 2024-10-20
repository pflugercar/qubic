//
//  Game.swift
//  qubic
//
//  Created by 4 on 10/13/20.
//  Copyright © 2020 XNO LLC. All rights reserved.
//

import SwiftUI

enum GameMode: Int {
    case novice, defender, warrior, tyrant, oracle, cubist
    case daily, simple, common, tricky
    case local, bot, online, invite
//	case dictLesson
//	case picture1, picture2, picture3, picture4
    
    var train: Bool { [.novice, .defender, .warrior, .tyrant, .oracle, .cubist].contains(self) }
    var solve: Bool { [.daily, .simple, .common, .tricky].contains(self) }
	var play: Bool { [.local, .bot, .online, .invite].contains(self) }
    
    var trainValue: Int { self.rawValue - GameMode.novice.rawValue }
}

enum GameState: Int {
    // each one is 1 more — remember to add new ones to the end!!!
	case error = 0, new, active, myWin, opWin, myTimeout, opTimeout, myResign, opResign, draw, ended, off, restart
    
    func mirror() -> GameState {
        switch self {
        case .myWin: return .opWin
        case .opWin: return .myWin
        case .myTimeout: return .opTimeout
        case .opTimeout: return .myTimeout
        case .myResign: return .opResign
        case .opResign: return .myResign
        case .draw: return .draw
		case .ended: return .ended
		case .restart: return .restart
        default: return .error
        }
    }
    
    var myWin: Bool {
        self == .myWin || self == .opTimeout || self == .opResign
    }
    
    var opWin: Bool {
        self == .opWin || self == .myTimeout || self == .myResign
    }
	
	var ended: Bool {
		self != .new && self != .active && self != .off && self != .error
	}
}

enum HintValue: Comparable {
	case noW, c2, dw, dl, cm2, c2d1, w2, w2d1, c1, cm1, w1, w0
}

enum SolveType {
    case d1, d2, d3, d4, si, tr, no
}

class Move: Equatable {
    let p: Int
    var hints: [HintValue?] = [nil, nil]
    var allMoves: [Set<Int>?] = [nil, nil]
	var bestMoves: [Set<Int>?] = [nil, nil]
	var winLen: Int = 0
    var solveType: SolveType? = nil
    
    init(_ p: Int) {
        self.p = p
    }
    
    static func == (lhs: Move, rhs: Move) -> Bool {
        lhs.p == rhs.p
    }
}

struct GameSetup {
	var mode: GameMode
	var setupNum: Int = 0
	var turn: Int?
	var hints: Bool = false
	var time: Double?
	var preset: [Int]?
	var solved: Bool = false
}

var game: Game { Game.main }

class Game {
    static var main = Game()
    
    var moves: [Move] = []
	var currentMove: Move? = nil
    var hints: Bool = false
    var currentTimes: [Int] = [0,0]
    
	var gameNum: Int = 0
	var gameID: Int = 0 // not even sure this is needed? now updating this in startgame
    var turn: Int { board.getTurn() }
    var realTurn: Int { gameState == .active ? moves.count % 2 : (gameState.myWin ? myTurn : (gameState.opWin ? myTurn^1 : 2)) }
    var myTurn: Int = 0
    var player: [Player] = [Player(b: Board(), n: 0), Player(b: Board(), n: 0)]
    var times: [[Double]] = [[], []]
    var totalTime: Double? = nil
    var lastStart: [Double] = [0,0]
    var preset: [Int] = []
    var mode: GameMode = .local
    var dayInt: Int = Date.int
	var lastDC: Int = 0
    var setupNum: Int = 0
    var gameState: GameState = .new
	var processingMove: Bool = false
	var lastCheck: Int = 0
    var solved: Bool = false
    var leaving: Bool = false
	var board = Board()
	let hintQueue = OperationQueue()
	let presetHintQueue = OperationQueue()
    var movesBack: Int = 0
    var ghostMoveStart: Int = 0
    var ghostMoveCount: Int = 0
    var timers: [Timer] = []
    var premoves: [Int] = []
	var reviewingGame: Bool = false
	var gameSetup: GameSetup = GameSetup(mode: .novice, setupNum: 0, hints: false)
	let notificationGenerator = UINotificationFeedbackGenerator()
	let moveImpactGenerator = UIImpactFeedbackGenerator(style: .medium)
	let arrowImpactGenerator = UIImpactFeedbackGenerator(style: .light)
    
    init() {
        hintQueue.qualityOfService = .userInitiated
		presetHintQueue.qualityOfService = .utility
    }
	
	func load(setup: GameSetup) {
		Game.main.turnOff()
		Game.main = self
		gameSetup = setup // this is to save it for a rematch/next game
		gameState = .new
		mode = setup.mode
		
        board = Board()
		BoardScene.main.reset()
		gameNum += 1
		GameLayout.main.loadGameOpacities()
		reviewingGame = false
		processingMove = false
		lastCheck = 0
        currentMove = nil
        moves = []
		totalTime = setup.time
		if let total = setup.time {
            currentTimes = [Int(total),Int(total)]
            times = [[total],[total]]
            lastStart = [0,0]
        }
//		if mode == .picture1 {
//			totalTime = 200
//			currentTimes = [183, 156]
//			times = [[183], [156]]
//			lastStart = [0,0]
//		}
        movesBack = 0
        ghostMoveStart = 0
        ghostMoveCount = 0
        premoves = []
		GameLayout.main.showWinsFor = nil
		GameLayout.main.analysisMode = 2 // otherwise newHints keeps the old one
		GameLayout.main.analysisTurn = 1
		GameLayout.main.showAllHints = true
		GameLayout.main.popup = .none
//        newStreak = nil
		dayInt = Date.int
		lastDC = Storage.int(.lastDC)
		setupNum = setup.setupNum
		setPreset()
		if !preset.isEmpty { myTurn = preset.count % 2 }
		else if let givenTurn = setup.turn { myTurn = givenTurn }
		else { myTurn = .random(in: 0...1) }
//		if mode == .picture2 {
//			myTurn ^= 1
//		}
//		if mode == .picture3 {
//			myTurn ^= 1
//			Timer.after(0.2, run: { BoardScene.main.rotate(right: true); BoardScene.main.rotate(right: true) })
//		}
		hints = setup.hints
        let me = User(b: board, n: myTurn)
        let op = getOp(myColor: me.color)
//		if mode == .picture1 {
//			me = User(b: board, n: myTurn, name: "𝓽𝓪𝓷𝓰𝓸")
//			me.color = 1
//			op.name = "Vimz"
//			op.color = 2
//			op.rounded = true
//		} else if mode == .picture2 {
//			me = User(b: board, n: myTurn, name: "Patashnik")
//			me.color = 5
//		} else if mode == .picture3 {
//			me = User(b: board, n: myTurn, name: "4Dliner")
//			me.color = 6
//		} else if mode == .picture4 {
//			me = User(b: board, n: myTurn, name: "Sam")
//			me.color = 0
//		}
		player = myTurn == 0 ? [me, op] : [op, me]
//		if mode == .dictLesson { // laterDO uncomment this
//			player = [User(b: board, n: 0, name: "player 1"), User(b: board, n: 1, name: "player 2")]
//			player[1].color = [4, 4, 4, 8, 6, 7, 4, 5, 3][player[0].color]
//		}
		
        for p in preset { loadMove(p) }
		GameLayout.main.refreshHints()
        
        func setPreset() {
			if let presetPreset = setup.preset {
				preset = presetPreset
				solved = setup.solved
				return
			}
//			if mode == .picture1 {
//				preset = expandMoves("HRVDGqlJdhmiv9") // move anywhere
//				solved = false
//				return
//			} else if mode == .picture2 {
//				preset = expandMoves("Vqhsv9dHtRCDT") // ends on its own
//				solved = false
//				return
//			} else if mode == .picture3 {
//				preset = expandMoves("MRVQCJmDOXsvuN") // ends on its own
//				solved = true
//				return
//			} else if mode == .picture4 {
//				preset = expandMoves("DH-QYmKr90FPs2v1faRiVhelMb") // get the 4 in a row
//				solved = false
//				return
//			}
			
			if mode == .daily { getInfo(key: .daily) }
            else if mode == .simple { getInfo(key: .simple) }
            else if mode == .common { getInfo(key: .common) }
            else if mode == .tricky { getInfo(key: .tricky) }
            else {
                preset = []
                solved = false
            }
			
			gameSetup.preset = preset
			gameSetup.solved = solved
            
            func getInfo(key: Key) {
				let boards = solveBoards[key] ?? [""]
                if setupNum < boards.count {
                    preset = expandMoves(boards[setupNum])
					solved = (Storage.array(key) as? [Bool])?[setupNum] ?? true
                } else {
                    preset = Board.getAutomorphism(for: expandMoves(boards.randomElement() ?? ""))
                    solved = false
                }
            }
        }
        
        func getOp(myColor: Int) -> Player {
            let op: Player
            switch mode {
            case .novice:   op = Novice(b: board, n: myTurn^1)
            case .defender: op = Defender(b: board, n: myTurn^1)
            case .warrior:  op = Warrior(b: board, n: myTurn^1)
            case .tyrant:   op = Tyrant(b: board, n: myTurn^1)
            case .oracle:   op = Oracle(b: board, n: myTurn^1)
            case .cubist:   op = Cubist(b: board, n: myTurn^1)
            case .daily:    op = Daily(b: board, n: myTurn^1, num: setupNum)
            case .simple:   op = Simple(b: board, n: myTurn^1, num: setupNum)
            case .common:   op = Common(b: board, n: myTurn^1, num: setupNum)
            case .tricky:   op = Tricky(b: board, n: myTurn^1, num: setupNum)
			case .local:    op = User(b: board, n: myTurn^1, id: "friend", name: "friend")
			case .bot:		op = Bot(b: board, n: myTurn^1, botNum: setupNum)
			case .online:   op = Online(b: board, n: myTurn^1)
//			case .picture1: op = Online(b: board, n: myTurn^1)
//			case .picture2: op = Tricky(b: board, n: myTurn^1, num: 22)
//			case .picture3: op = Cubist(b: board, n: myTurn^1)
//			case .picture4: op = Daily(b: board, n: myTurn^1, num: 3)
            default:        op = Novice(b: board, n: myTurn^1)
            }
            if myColor == op.color { op.color = [4, 4, 4, 8, 6, 7, 4, 5, 3][myColor] }
            return op
        }
    }
	
	func loadNextGame(setup: GameSetup) {
		var newSetup = setup
		switch newSetup.mode {
		case .novice: newSetup.mode = .defender
		case .defender:  newSetup.mode = .warrior
		case .warrior:  newSetup.mode = .tyrant
		case .tyrant:  newSetup.mode = .oracle
		case .oracle:  newSetup.mode = .cubist
//		case .picture1: newMode = .picture2
//		case .picture2: newMode = .picture3
//		case .picture3: newMode = .picture4
		default: break
		}
		if  newSetup.mode.train && setup.mode != .cubist {
			Layout.main.trainSelection[0] += 1
		}
		
		if newSetup.mode.solve {
			let key: Key = [.simple: .simple, .common: .common, .tricky: .tricky][newSetup.mode, default: .daily]
			if newSetup.setupNum < solveBoardCount(key) {
				newSetup.setupNum += 1
				Layout.main.solveSelection[0] += 1
			}
		} else if newSetup.mode == .bot {
			repeat {
				newSetup.setupNum = .random(in: 0..<Bot.bots.count)
//				print("bots", newSetupNum, Bot.bots[newSetupNum].care, Storage.int(.myBotSkill))
			} while abs(Bot.bots[newSetup.setupNum].care*10 - Double(Storage.int(.myBotSkill))) > 2
		}
		
		// online is based on the turn that was selected during the online matchmaking process
		newSetup.turn = newSetup.mode == .online ? FB.main.myGameData?.myTurn : newSetup.turn
		// preset should only be saved for rematches
		newSetup.preset = nil
		
		load(setup: newSetup)
	}
    
    func startGame() {
		moveImpactGenerator.prepare()
		GameLayout.main.startGameOpacities()
        if totalTime != nil {
			let num = gameNum
            lastStart[turn] = Date.now+2
			timers.append(Timer.every(0.1, run: { self.updateCurrentTime(num: num) }))
        }
		gameState = .active
		
		if mode != .online && type(of: self) == Game.self { // checking type to avoid uploading tutorial/share/review games
			print("uploading", player[myTurn^1], player[myTurn], player[myTurn^1].id, PlayerData.getData(for: player[myTurn^1].id, mode: .local))
			FB.main.uploadGame(self) // uploading here so it's set when active
		}
		gameID = FB.main.myGameData?.gameID ?? 0 // FB should have set gameID either in uploadGame above or while offering
		
        player[turn].move()
    }
    
	func updateCurrentTime(num: Int) {
        if gameState == .active && num == gameNum {
            let newTime = Int((times[realTurn].last ?? 0) + lastStart[realTurn] - Date.now + 10) - 10
            if newTime < currentTimes[realTurn] {
                currentTimes[realTurn] = max(0, newTime)
                if newTime < 0 && player[realTurn].local {
					times[realTurn].append(0)
                    endGame(with: realTurn == myTurn ? .myTimeout : .opTimeout)
                }
            }
			GameLayout.main.updateGameView.toggle()
        }
    }
	
	func getTime(for turn: Int) -> Int {
		max(0, Int(times[turn][board.move[turn].count]))
	}
    
    func loadMove(_ p: Int) {
        // Assumes no wins!
        let move = Move(p)
        guard !moves.contains(move) && (0..<64).contains(move.p) else { return }
        board.addMove(move.p)
        moves.append(move)
        currentMove = move
		getHints(for: moves, loading: true, preset: moves.count <= preset.count)
		BoardScene.main.addCube(move: move.p, color: player[turn^1].color, preset: moves.count <= preset.count)
    }
    
    func processMove(_ p: Int, for turn: Int, setup: [Int], time: Double? = nil) {
//		if [.picture2, .picture3, .picture4].contains(mode) {
//			Timer.after(mode == .picture2 ? 1.5 : mode == .picture3 ? 4 : 0, run: { self.endGame(with: .myWin) })
//			return
//		}
        let move = Move(p)
		if processingMove { return }
        guard gameState == .active else { return }
		guard turn == realTurn else { print("Invalid turn!"); return }
		guard setup == moves.map({ $0.p }) else { print("Invalid setup!"); return }
        guard !moves.contains(move) && (0..<64).contains(move.p) else { print("Invalid move!"); return }
		processingMove = true
        moves.append(move)
        if movesBack != 0 { movesBack += 1 }
        moveImpactGenerator.impactOccurred()
        getHints(for: moves, time: time)
		guard movesBack == 0 else { processingMove = false; return }
        board.addMove(p)
        currentMove = move
		GameLayout.main.refreshHints()
		BoardScene.main.showMove(p, color: player[turn].color, wins: board.getWinLines(for: p))
		GameLayout.main.newMoveOpacities()
		processingMove = false
    }
	
    func processGhostMove(_ p: Int) {
		print("processing ghost move", gameState)
        let move = Move(p)
		if processingMove { return }
        guard board.pointEmpty(move.p) && (0..<64).contains(move.p) else { return }
        guard reviewingGame else { return }
		processingMove = true
        board.addMove(move.p)
        if ghostMoveCount == 0 {
            ghostMoveStart = moves.count - movesBack
        }
        while ghostMoveStart + ghostMoveCount != moves.count - movesBack && movesBack > 0 {
            ghostMoveCount -= 1
            movesBack -= 1
            moves.remove(at: ghostMoveStart+ghostMoveCount)
        }
        moves.insert(move, at: ghostMoveStart+ghostMoveCount)
        currentMove = move
		GameLayout.main.refreshHints()
        ghostMoveCount += 1
        getHints(for: moves.dropLast(movesBack))
		BoardScene.main.showMove(move.p, color: player[turn^1].color, wins: board.getWinLines(for: move.p), ghost: true)
		GameLayout.main.newGhostMoveOpacities()
		processingMove = false
    }
	
	func checkAndProcessMove(_ p: Int, for turn: Int, setup: [Int], time: Double? = nil) {
//		if mode == .picture1 {
//			endGame(with: .myWin)
//			return
//		}
		let move = Move(p)
		if processingMove { return }
		guard gameState == .active else { return }
		guard turn == realTurn else { print("Invalid turn!"); return }
		guard setup == moves.map({ $0.p }) else { print("Invalid setup!"); return }
		guard !moves.contains(move) && (0..<64).contains(move.p) else { print("Invalid move!"); return }
		guard movesBack == 0 else { return }
		processingMove = true
		let lastBoard = Board(board)
		board.addMove(p)
		moveImpactGenerator.impactOccurred()
		BoardScene.main.showMove(p, color: player[turn].color, wins: board.getWinLines(for: move.p))
		
		if Storage.int(.moveChecker) == 2 || !hints || lastCheck >= board.numMoves() {
			confirmMove()
			return
		}
		
		let myW1s = lastBoard.getW1(for: turn)
		if !myW1s.isEmpty {
			if myW1s.contains(p) {
				confirmMove()
			} else {
				cancelMove()
			}
			return
		}
		
		let opW1s = lastBoard.getW1(for: turn^1)
		if !opW1s.isEmpty {
			if opW1s.contains(p) {
				confirmMove()
			} else {
				cancelMove()
			}
			return
		}
		
		guard Storage.int(.moveChecker) == 0 else {
			confirmMove()
			return
		}
		
		let num = gameNum
		hintQueue.addOperation {
			let myW2s = lastBoard.getW2(for: turn, depth: 32, time: 4, valid: { num == self.gameNum }) ?? []
			if !myW2s.isEmpty {
				if myW2s.contains(p) {
					DispatchQueue.main.async { confirmMove() }
				} else {
					DispatchQueue.main.async { cancelMove() }
				}
				return
			}
			
			let opW2 = lastBoard.getW2Blocks(for: turn, depth: 32, time: 4, valid: { num == self.gameNum }) ?? []
			if !opW2.isEmpty {
				if opW2.contains(p) {
					DispatchQueue.main.async { confirmMove() }
				} else {
					DispatchQueue.main.async { cancelMove() }
				}
				return
			}
			
			DispatchQueue.main.async { confirmMove() }
		}
		
		func confirmMove() {
			moves.append(move)
			getHints(for: moves, time: time)
			currentMove = move
			GameLayout.main.refreshHints()
			processingMove = false
			GameLayout.main.newMoveOpacities()
			if !hints && (mode == .online || mode == .bot || mode.train) { findMisses() }
		}
		
		func cancelMove() {
			timers.append(Timer.after(0.3) {
				self.lastCheck = self.board.numMoves()
				self.board.undoMove(for: turn)
				BoardScene.main.undoMove(move.p)
				self.notificationGenerator.notificationOccurred(.error)
				self.premoves = []
				BoardScene.main.spinMoves()
				self.player[0].cancelMove()
				self.player[1].cancelMove()
				self.timers.append(Timer.after(1) {
					self.processingMove = false
				})
			})
		}
		
		func findMisses() {
			let myW1s = lastBoard.getW1(for: turn)
			if !myW1s.isEmpty {
				if !myW1s.contains(p) {
					FB.main.uploadMisses(lastBoard.getMoveString(), key: "d1")
				}
				return
			}
			
			let opW1s = lastBoard.getW1(for: turn^1)
			if !opW1s.isEmpty { return }
			
			let num = gameNum
			hintQueue.addOperation {
				let myW2s = lastBoard.getW2(for: turn, depth: 3, time: 1.0, valid: { num == self.gameNum }) ?? []
				if !myW2s.isEmpty {
					for depth in 1...3 {
						let wins = lastBoard.cachedGetW2[turn][depth] ?? []
						if !wins.isEmpty {
							if !wins.contains(p) {
								FB.main.uploadMisses(lastBoard.getMoveString(), key: "d\(depth + 1)")
							}
							return
						}
					}
				}
			}
		}
	}
    
	func getHints(for moves: [Move], loading: Bool = false, preset: Bool = false, time: Double? = nil) {
        let b = Board()
        for move in moves { b.addMove(move.p) }
        let turn = b.getTurn()
		let num = gameNum
        
        if gameState == .active {
            if let total = totalTime {
                let timeLeft = time ?? ((times[turn^1].last ?? 0) + lastStart[turn^1] - Date.now)
                times[turn^1].append(min(total, max(0, timeLeft)))
                currentTimes[turn^1] = Int(min(total, max(timeLeft, 0)))
                lastStart[turn] = Date.now + 0.2
            }
			
			if turn^1 == myTurn {
				FB.main.sendMyMove(p: moves.last?.p ?? -1, time: times[turn^1].last ?? -1)
			} else if mode != .online {
				FB.main.sendOpMove(p: moves.last?.p ?? -1, time: times[turn^1].last ?? -1)
			}
			
            if b.hasW0(turn^1) { endGame(with: turn^1 == myTurn ? .myWin : .opWin) }
            else if b.numMoves() == 64 { endGame(with: .draw) }
            else if !loading {
                timers.append(Timer.after(0.2, run: player[turn].move))
            }
        }
        
		(preset ? presetHintQueue : hintQueue).addOperation {
            var nHint: HintValue = .noW
			if b.inDict() { nHint = (turn == 0 ? .dw : .dl); moves.last?.winLen = b.cachedDictMoves?.0 ?? 0 }
			else if b.hasW0(turn) { nHint = .w0 }
            else if b.hasW1(turn) { nHint = .w1 }
			else if b.hasW2(turn, depth: 1, valid: { num == self.gameNum }) == true { nHint = .w2d1; moves.last?.winLen = 2 }
			else if b.hasW2(turn, valid: { num == self.gameNum }) == true { nHint = .w2; moves.last?.winLen = (b.cachedHasW2[turn] ?? 0) + 1 }
			guard num == self.gameNum else { return }
            moves.last?.hints[turn] = nHint

            if solveButtonsEnabled {
                if nHint == .w1 {
                    moves.last?.solveType = .d1
                } else if nHint == .w2d1 {
                    moves.last?.solveType = .d2
                } else if nHint == .w2 {
                    if b.hasW2(turn, depth: 2, valid: { num == self.gameNum }) == true {
                        moves.last?.solveType = .d3
                    } else if b.hasW2(turn, depth: 3, valid: { num == self.gameNum }) == true {
                        moves.last?.solveType = .d4
                    } else if b.hasW2(turn, depth: 5, valid: { num == self.gameNum }) == false {
                        moves.last?.solveType = .tr
                    } else {
                        moves.last?.solveType = .si
                    }
                } else {
                    moves.last?.solveType = .no
                }
            }
			guard num == self.gameNum else { return }
            DispatchQueue.main.async { GameLayout.main.refreshHints() }

            var oHint: HintValue = .noW
			if b.inDict() && turn == 1 { oHint = .dw; moves.last?.winLen = b.cachedDictMoves?.0 ?? 0 }
			else if b.hasW0(turn^1) { oHint = .w0 }
            else if b.getW1(for: turn^1).count > 1 { oHint = .cm1 }
            else if b.hasW1(turn^1) { oHint = .c1 }
			else if b.hasW2(turn^1, valid: { num == self.gameNum }) == true {
				if b.getW2Blocks(for: turn, valid: { num == self.gameNum }) == nil { oHint = .cm2 }
                else if b.hasW2(turn^1, depth: 1, valid: { num == self.gameNum }) == true { oHint = .c2d1 }
                else { oHint = .c2 }
            }
			
			guard num == self.gameNum else { return }
			moves.last?.hints[turn^1] = oHint
            DispatchQueue.main.async { GameLayout.main.refreshHints() }

            var nAllMoves: Set<Int> = []
			var nBestMoves: Set<Int> = []
            switch nHint {
			case .dw, .dl:
				nAllMoves = b.cachedDictMoves?.1 ?? []
				nBestMoves = b.cachedDictMoves?.1 ?? []
            case .w1:
				nAllMoves = b.getW1(for: turn)
				nBestMoves = nAllMoves
			case .w2:
				nAllMoves = b.getW2(for: turn, valid: { num == self.gameNum }) ?? []
				nBestMoves = b.getW2(for: turn, depth: b.cachedHasW2[turn] ?? 0, valid: { num == self.gameNum }) ?? []
			case .w2d1:
				nAllMoves = b.getW2(for: turn, valid: { num == self.gameNum }) ?? []
				nBestMoves = b.getW2(for: turn, depth: 1, valid: { num == self.gameNum }) ?? []
            default: break
            }
			
			guard num == self.gameNum else { return }
			moves.last?.allMoves[turn] = nAllMoves
			moves.last?.bestMoves[turn] = nBestMoves
			// show hint for == 1 -> my wins
			// if i go first then that's showWinFor = 0
			// no what i'm testing for here is that showWinFor is equal to the person who's move it is
			if self.myTurn == turn ? GameLayout.main.showWinsFor == 0 : GameLayout.main.showWinsFor == 1 {
                DispatchQueue.main.async { BoardScene.main.spinMoves() }
            }

			var oAllMoves: Set<Int> = []
			var oBestMoves: Set<Int> = []
            switch oHint {
            case .c1, .cm1:
				oAllMoves = b.getW1(for: turn^1)
				oBestMoves = oAllMoves
            case .c2d1:
				oAllMoves = b.getW2Blocks(for: turn, valid: { num == self.gameNum }) ?? []
				oBestMoves = oAllMoves
			case .c2:
				oAllMoves = b.getW2Blocks(for: turn, valid: { num == self.gameNum }) ?? []
				oBestMoves = oAllMoves
            default: break
            }
			
			guard num == self.gameNum else { return }
			moves.last?.allMoves[turn^1] = oAllMoves
			moves.last?.bestMoves[turn^1] = oBestMoves
			if GameLayout.main.showWinsFor == (self.myTurn == turn ? 1 : 0) {
                DispatchQueue.main.async { BoardScene.main.spinMoves() }
            }
        }
    }
	
	func undoMove() {
        guard movesBack == 0 else {
            notificationGenerator.notificationOccurred(.error)
			GameLayout.main.flashNextArrow()
            return
        }
		guard GameLayout.main.undoOpacity == .full else { return }
		if processingMove { return }
        guard gameState == .active else { return }
        guard let move = moves.popLast() else { return }
        moveImpactGenerator.impactOccurred()
        player[0].cancelMove()
        player[1].cancelMove()
		board.undoMove(for: turn^1)
		premoves = []
        currentMove = moves.last
		lastCheck = 0
		GameLayout.main.refreshHints()
        if totalTime != nil {
            times[turn].removeLast()
            currentTimes[turn] = max(0, Int((times[turn].last ?? 0)))
            currentTimes[turn^1] = max(0, Int((times[turn^1].last ?? 0)))
            lastStart[turn] = Date.now + 0.5
        }
        BoardScene.main.undoMove(move.p)
		GameLayout.main.undoMoveOpacities()
		if turn == myTurn {
			FB.main.undoMyMove(p: move.p)
		} else {
			FB.main.undoOpMove(p: move.p)
		}
        timers.append(Timer.after(0.5, run: player[turn].move))
    }
    
    func prevMove() {
		guard GameLayout.main.prevOpacity == .full else { return }
		if processingMove { return }
        let i = moves.count - movesBack - 1
		guard i >= 0 else { return } // old: ((!hints && mode.solve) ? preset.count : 0)
        arrowImpactGenerator.impactOccurred()
        movesBack += 1
        board.undoMove(for: turn^1)
        currentMove = i > 0 ? moves[i-1] : nil
        if gameState != .active {
            if totalTime != nil && ghostMoveCount == 0 {
                currentTimes[turn] = getTime(for: turn)
				if currentTimes[turn^1] == 0 {
					currentTimes[turn^1] = getTime(for: turn^1)
				}
            }
        }
        BoardScene.main.undoMove(moves[i].p)
		GameLayout.main.refreshHints()
        if i-1 < ghostMoveStart {
            moves.removeSubrange(ghostMoveStart..<(ghostMoveStart+ghostMoveCount))
            movesBack -= ghostMoveCount
            ghostMoveCount = 0
        }
		GameLayout.main.prevMoveOpacities()
    }
    
    func nextMove() {
		// for geting the board state
//		print(board.getMoveArray(), board.getMoveString())
        guard ghostMoveCount == 0 || ghostMoveStart + ghostMoveCount > moves.count - movesBack else {
			if GameLayout.main.prevOpacity == .full && movesBack != 0 {
                notificationGenerator.notificationOccurred(.error)
				GameLayout.main.flashPrevArrow()
            }
            return
        }
		guard GameLayout.main.nextOpacity == .full else { return }
		if processingMove { return }
        guard movesBack > 0 else { return }
        let i = moves.count - movesBack
        guard board.pointEmpty(moves[i].p) && (0..<64).contains(moves[i].p) else { return }
        arrowImpactGenerator.impactOccurred()
        board.addMove(moves[i].p)
        movesBack -= 1
        currentMove = moves[i]
        if gameState != .active && totalTime != nil && ghostMoveCount == 0 {
            currentTimes[turn^1] = getTime(for: turn^1)
        }
		GameLayout.main.refreshHints()
		BoardScene.main.showMove(moves[i].p, color: player[turn^1].color, wins: board.getWinLines(for: moves[i].p), ghost: ghostMoveCount != 0, preset: moves.count - movesBack <= preset.count)
		GameLayout.main.nextMoveOpacities()
        if gameState == .active && movesBack == 0 {
            player[turn].move()
        }
    }
    
    func endGame(with end: GameState) {
        guard gameState == .active else { turnOff(); return }
		
		gameState = end
		premoves = []
		BoardScene.main.spinMoves()
		withAnimation { GameLayout.main.popup = .gameEndPending }
		notificationGenerator.prepare()
		
		if end.myWin {
			if mode == .daily {
				// keeping this custom so that it uses dayInt instead of Date.int
				var dailyHistory = Storage.dictionary(.dailyHistory) as? [String: [Bool]] ?? [:]
				dailyHistory[String(dayInt), default: [false, false, false, false]][setupNum] = true
				Storage.set(dailyHistory, for: .dailyHistory)
				
				if dailyHistory[String(dayInt)] == [true, true, true, true] && dayInt > Storage.int(.lastDC) {
					verifyDailyData()
					Notifications.ifUndetermined {
						DispatchQueue.main.async {
							GameLayout.main.showDCAlert = true
						}
					}
					Notifications.setBadge(justSolved: true, dayInt: dayInt)
//					withAnimation { newStreak = Storage.int(.streak) }
//					timers.append(Timer.after(2.4, run: { withAnimation { self.newStreak = nil } }))
					updateDailyData() // turns off red dot
				}
				
				FB.main.updateMyStats()
			}
			else if mode == .simple { recordSolve(type: .simple, index: setupNum) }
			else if mode == .common { recordSolve(type: .common, index: setupNum) }
			else if mode == .tricky { recordSolve(type: .tricky, index: setupNum) }
			else if let index = [.novice, .defender, .warrior, .tyrant, .oracle, .cubist].firstIndex(of: mode), !hints {
				if mode == .cubist {
					if let trainArray = Storage.array(.train) as? [Int], trainArray[5] == 0 {
						GameLayout.main.showCubistAlert = true
					}
				}
				recordSolve(type: .train, index: index)
			}
		}
		
		if mode == .bot {
			let newValue = Storage.int(.myBotSkill) + (end.myWin ? 1 : 0) - (end.opWin ? 1 : 0)
			Storage.set(bound(0, newValue, 10), for: .myBotSkill)
		}
		
        if !mode.solve || end.myWin { hints = true }
		withAnimation { GameLayout.main.undoOpacity = .clear }
		
		FB.main.finishedGame(with: gameState, newHints: solved || hints) // newHints records whether review games should show analysis
        
        if end == .myTimeout || end == .opTimeout { BoardScene.main.spinBoard() }
        
		if end == .restart { return }
		GameLayout.main.setGameEndText()
		timers.append(Timer.after(end == .myResign || end == .ended ? 0 : 1) {
			withAnimation { GameLayout.main.popup = .gameEnd }
			self.notificationGenerator.notificationOccurred(end.myWin ? .error : .warning)
		})
        
		func recordSolve(type: Key, index: Int) {
			guard var solvesForType = Storage.array(type) as? [Bool] else { print("Can't record solve"); return }
			if index == solvesForType.count { return }
			solvesForType[index] = true
			Storage.set(solvesForType, for: type)
			
			if mode.solve {
				var allSolves = Storage.array(.solvedBoards) as? [String] ?? []
				let solveString = compressMoves(preset)
				if !allSolves.contains(solveString) { allSolves.append(solveString) }
				Storage.set(allSolves, for: .solvedBoards)
			}
			
			FB.main.updateMyStats()
        }
    }
    
    func turnOff() {
//        guard gameState != .off else { return }
//		gameState = .off
		
		for timer in self.timers {
			timer.invalidate()
		}
		timers = []
		
		hintQueue.cancelAllOperations()
		player[0].cancelMove()
		player[1].cancelMove()
    }
    
    func uploadSolveBoard(_ key: String) {
        FB.main.uploadSolveBoard(board.getMoveString(), key: key)
        notificationGenerator.notificationOccurred(.success)
    }
}
