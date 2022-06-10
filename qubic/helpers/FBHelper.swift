//
//  FB.swift
//  qubic
//
//  Created by Chris McElroy on 3/28/21.
//  Copyright © 2021 XNO LLC. All rights reserved.
//

import SwiftUI
import FirebaseDatabase
import FirebaseAuth
import OrderedCollections

class FB {
    static let main = FB()
    
    var ref = Database.database().reference()
    var playerDict: [String: PlayerData] = [:]
	var pastGamesDict: OrderedDictionary<Int, GameData> = [:]
    var myGameData: GameData? = nil
    var opGameData: GameData? = nil
    var op: PlayerData? = nil
    var onlineInviteState: MatchingState = .stopped
    var gotOnlineMove: ((Int, Double, Int) -> Void)? = nil
    var cancelOnlineSearch: (() -> Void)? = nil
    
    func start() {
        Auth.auth().addStateDidChangeListener { (auth, user) in
            if let user = user {
                Storage.set(user.uid, for: .uuid)
				myID = user.uid
                self.checkVersion()
                self.updateMyData()
				self.updateMyStats()
				self.observePlayers()
				self.observePastGames()
				self.startActiveTimer()
				// removed finished online game
            } else {
                // should only happen once, when they first use the app
                Auth.auth().signInAnonymously() { (authResult, error) in
                    if let error = error {
                        print("Sign in error:", error)
                    }
                }
            }
        }
    }
	
	func startActiveTimer() {
		let myActiveRef = ref.child("active/\(myID)")
		myActiveRef.setValue(Date.ms)
		Timer.every(30, run: {
			myActiveRef.setValue(Date.ms)
		})
	}
    
    func checkVersion() {
		let versionRef = ref.child("newestBuild/\(versionType.rawValue)")
		versionRef.removeAllObservers()
		versionRef.observe(DataEventType.value, with: { snapshot in
			Layout.main.updateAvailable = snapshot.value as? Int ?? 0 > buildNumber
		})
    }
    
    func observePlayers() {
		let playerRef = ref.child("players")
		playerRef.removeAllObservers()
		playerRef.observe(DataEventType.value, with: { snapshot in
            if let dict = snapshot.value as? [String: [String: Any]] {
                for entry in dict {
                    self.playerDict[entry.key] = PlayerData(from: entry.value)
                }
            }
        })
    }
    
	func observePastGames() {
		let gameRef = ref.child("games/\(myID)")
		gameRef.removeAllObservers()
		gameRef.observe(DataEventType.value, with: { snapshot in
			if let dict = snapshot.value as? [String: [String: Any]] {
				for entry in dict.sorted(by: { $0.key < $1.key }) {
					let data = GameData(from: entry.value, gameID: Int(entry.key) ?? 0)
					guard data.state.ended else { continue }
					// order is preserved even when entries are updated
					self.pastGamesDict[data.gameID] = data
				}
			}
		})
	}
	
    func updateMyData() {
        let myPlayerRef = ref.child("players/\(myID)")
        let name = Storage.string(.name) ?? ""
        let color = Storage.int(.color)
        myPlayerRef.setValue([Key.name.rawValue: name, Key.color.rawValue: color])
    }
	
	func updateMyStats() {
		let myStatsRef = ref.child("stats/\(myID)")
		let train = Storage.array(.train) as? [Bool] ?? []
		let streak = Storage.int(.streak)
		let lastDC = Storage.int(.lastDC)
		let currentDaily = Storage.int(.currentDaily)
		let dailyHistory = Storage.dictionary(.dailyHistory) as? [String: [Bool]] ?? [:]
		let simple = Storage.array(.simple) as? [Bool] ?? []
		let common = Storage.array(.common) as? [Bool] ?? []
		let tricky = Storage.array(.tricky) as? [Bool] ?? []
		let solves = Storage.array(.solvedBoards) as? [String] ?? []
		let solveBoardVersion = Storage.int(.solveBoardsVersion)
		let tutorialPlays = Storage.int(.playedTutorial)
		myStatsRef.setValue([
			Key.buildNumber.rawValue: buildNumber,
			Key.versionType.rawValue: versionType.rawValue,
			Key.train.rawValue: train,
			Key.streak.rawValue: streak,
			Key.lastDC.rawValue: lastDC,
			Key.currentDaily.rawValue: currentDaily,
			Key.dailyHistory.rawValue: dailyHistory,
			Key.simple.rawValue: simple,
			Key.common.rawValue: common,
			Key.tricky.rawValue: tricky,
			Key.solvedBoards.rawValue: solves,
			Key.solveBoardsVersion.rawValue: solveBoardVersion,
			Key.playedTutorial.rawValue: tutorialPlays
		])
	}
    
    func postFeedback(name: String, email: String, feedback: String) {
        let feedbackRef = ref.child("feedback/\(myID)/\(Date.ms)")
        feedbackRef.setValue([Key.name.rawValue: name, Key.email.rawValue: email, Key.feedback.rawValue: feedback])
    }
    
    func uploadSolveBoard(_ string: String, key: String) {
		ref.child("solveBoards/\(myID)/\(key)/\(Date.ms)").setValue(string)
    }
	
	func uploadMisses(_ string: String, key: String) {
		ref.child("misses/\(myID)/\(key)/\(Date.ms)").setValue(string)
	}
    
	func getOnlineMatch(onMatch: @escaping () -> Void) {
		Layout.main.searchingOnline = true
        onlineInviteState = .invited
        myGameData = nil
        opGameData = nil
		
		let timeLimit: Double = [-1, 60, 300, 600][Layout.main.playSelection[2]]
		let humansOnly = Layout.main.playSelection[1] == 2
        var possOp: Set<String> = []
        var myInvite = OnlineInviteData(timeLimit: timeLimit)
        
        let onlineRef = ref.child("onlineInvites")
        onlineRef.removeAllObservers()
        
        // send invite
        onlineRef.child(myID).setValue(myInvite.toDict())
        
        // set end time
        var botTimer: Timer? = nil
        if !humansOnly {
            botTimer = Timer.scheduledTimer(withTimeInterval: 4, repeats: false, block: { _ in
                if self.onlineInviteState == .invited || self.onlineInviteState == .offered {
                    self.finishedOnlineGame(with: .error)
                    self.onlineInviteState = .stopped
                    onlineRef.child(myID).removeValue()
                    onlineRef.removeAllObservers()
					Layout.main.searchingOnline = false
					onMatch()
                }
            })
        }
        
        // set cancel func
        cancelOnlineSearch = {
            self.onlineInviteState = .stopped
            botTimer?.invalidate()
            onlineRef.removeAllObservers()
            onlineRef.child(myID).removeValue()
			Layout.main.searchingOnline = false
            self.cancelOnlineSearch = nil
        }
        
        // check for others
        onlineRef.observe(DataEventType.value, with: { snapshot in
            guard let dict = snapshot.value as? [String: [String: Any]] else { return }
            switch self.onlineInviteState {
            case .invited:
                for entry in dict where entry.key != myID {
                    let opInvite = OnlineInviteData(from: entry)
                    if opInvite.valid && opInvite.timeLimit == timeLimit {
                        // possOp guards for those who went offline without
                        // deleting an offer to you
                        if opInvite.opID != myID { possOp.insert(opInvite.ID) }
                        if opInvite > myInvite && opInvite.opID == "" {
                            self.onlineInviteState = .offered
                            myInvite.opID = entry.key
                            onlineRef.child(myID).setValue(myInvite.toDict())
                            break
                        }
                        if opInvite < myInvite && opInvite.opID == myID && possOp.contains(opInvite.ID) {
                            self.onlineInviteState = .matched
                            myInvite.opID = entry.key
                            onlineRef.child(myID).setValue(myInvite.toDict())
                            playGame(opInvite: opInvite)
                            break
                        }
                    }
                }
                break
            case .offered:
                for entry in dict where entry.key != myID {
                    let opInvite = OnlineInviteData(from: entry)
                    if opInvite.valid && opInvite.timeLimit == timeLimit &&
                        opInvite.opID == myID && (myInvite.opID == opInvite.ID || myInvite.opID == "") &&
                        possOp.contains(opInvite.ID) {
                        // TODO do i need to check for newer here? think out 4 person example
                        self.onlineInviteState = .matched
                        myInvite.opID = opInvite.ID
                        onlineRef.child(myID).setValue(myInvite.toDict())
                        playGame(opInvite: opInvite)
                        break
                    }
                }
                let offeredOp = OnlineInviteData(from: dict[myInvite.opID] ?? [:], ID: myInvite.opID)
                if !offeredOp.valid || offeredOp.timeLimit != timeLimit || !["", myID].contains(offeredOp.opID) {
                    self.onlineInviteState = .invited
                    myInvite.opID = ""
                    onlineRef.child(myID).setValue(myInvite.toDict())
                }
                break
            case .matched:
                if self.myGameData?.state == .new {
                    let offeredOp = OnlineInviteData(from: dict[myInvite.opID] ?? [:], ID: myInvite.opID)
                    if !offeredOp.valid || offeredOp.timeLimit != timeLimit || !["", myID].contains(offeredOp.opID) {
                        self.onlineInviteState = .invited
                        self.myGameData = nil
                        self.opGameData = nil
                        myInvite.opID = ""
                        onlineRef.child(myID).setValue(myInvite.toDict())
                    }
                }
                break
            case .stopped:
                onlineRef.child(myID).removeValue()
                onlineRef.removeAllObservers()
                break
            }
        })
        
        func playGame(opInvite: OnlineInviteData) {
            // post game
            let myData = GameData(myInvite: myInvite, opInvite: opInvite)
            let myGameRef = ref.child("games/\(myID)/\(myData.gameID)")
            myGameData = myData
            myGameRef.setValue(myData.toDict())
            
            // search for their post
            let opGameRef = ref.child("games/\(myData.opID)/\(myData.opGameID)")
            opGameRef.removeAllObservers()
            opGameRef.observe(DataEventType.value, with: { snapshot in
                guard var myData = self.myGameData else {
                    myGameRef.child(Key.state.rawValue).setValue(GameState.error.rawValue)
                    self.myGameData = nil
                    self.opGameData = nil
                    opGameRef.removeAllObservers()
                    return
                }
                guard let dict = snapshot.value as? [String: Any] else { return }
                let opData = GameData(from: dict, gameID: myData.opGameID)
                if opData.valid && opData.opID == myID && opData.opGameID == myData.gameID {
                    if opData.state == .active && self.onlineInviteState != .stopped {
                        // they've seen your game post so you can take down your invite
                        self.onlineInviteState = .stopped
                        onlineRef.child(myID).removeValue()
                        onlineRef.removeAllObservers()
                    }
                    if myData.state == .new {
                        guard let op = self.playerDict[myData.opID] else { return }
                        myData.state = .active
                        self.myGameData = myData
                        self.opGameData = opData
                        self.op = op
                        myGameRef.setValue(myData.toDict())
                        botTimer?.invalidate()
						Layout.main.searchingOnline = false
						onMatch()
                    }
                    if myData.state == .active {
                        self.opGameData = opData
                        let nextCount = myData.opMoves.count + 1
                        // don't include other end states because those are implicit with the moves
                        if opData.state == .error || opData.state == .myResign || opData.state == .myTimeout {
                            Game.main.endGame(with: opData.state.mirror())
                        } else if opData.myMoves.count == nextCount && opData.myTimes.count == nextCount {
                            guard let newMove = opData.myMoves.last else { return }
                            guard let newTime = opData.myTimes.last else { return }
                            
                            myData.opMoves.append(newMove)
                            myData.opTimes.append(newTime)
                            self.myGameData = myData
                            myGameRef.setValue(myData.toDict())
                            
                            self.gotOnlineMove?(newMove, newTime, myData.myMoves.count + myData.opMoves.count - 3)
                        }
                    }
                }
            })
        }
    }
    
    func sendMove(p: Int, time: Double) {
        guard var myData = myGameData else { return }
        let myGameRef = ref.child("games/\(myID)/\(myData.gameID)")
        myData.myMoves.append(p)
        myData.myTimes.append(time)
		myData.myMoveTimes.append(Date.ms)
        self.myGameData = myData
        myGameRef.setValue(myData.toDict())
    }
    
    func finishedOnlineGame(with state: GameState) {
        guard var myData = myGameData else { return }
        let myGameRef = ref.child("games/\(myID)/\(myData.gameID)")
        let opGameRef = ref.child("games/\(myData.opID)/\(myData.opGameID)")
        myData.state = state
        op = nil
        myGameData = nil
        opGameData = nil
        opGameRef.removeAllObservers()
        myGameRef.setValue(myData.toDict())
    }

    struct GameData {
        let gameID: Int         // my gameID
        let myTurn: Int         // 0 for moves first
        let opID: String        // op id
        let opGameID: Int       // op gameID
        let hints: Bool         // true for sandbox mode
        var state: GameState    // current state of the game
		var myMoves: [Int]      // my moves
		var opMoves: [Int]      // op moves
        var myTimes: [Double]       // times remaining on my clock after each of my moves
        var opTimes: [Double]       // times remaining on op clock after each of their moves
		var myMoveTimes: [Int]		// time each move is made
		var opMoveTimes: [Int]		// time each move is made
        let valid: Bool         // whether the given dict was valid
        
        init(from dict: [String: Any], gameID: Int) {
            valid = (
                dict[Key.myTurn.rawValue] as? Int != nil &&
                    dict[Key.opID.rawValue] as? String != nil &&
                    dict[Key.opGameID.rawValue] as? Int != nil &&
                    dict[Key.hints.rawValue] as? Int != nil &&
                    dict[Key.state.rawValue] as? Int != nil &&
                    dict[Key.myTimes.rawValue] as? [Double] != nil &&
                    dict[Key.opTimes.rawValue] as? [Double] != nil &&
                    dict[Key.myMoves.rawValue] as? [Int] != nil &&
                    dict[Key.opMoves.rawValue] as? [Int] != nil
            )
            
            self.gameID = gameID
            myTurn = dict[Key.myTurn.rawValue] as? Int ?? 0
            opID = dict[Key.opID.rawValue] as? String ?? ""
            opGameID = dict[Key.opGameID.rawValue] as? Int ?? 0
            hints = 1 == dict[Key.hints.rawValue] as? Int ?? 0
            state = GameState(rawValue: dict[Key.state.rawValue] as? Int ?? 0) ?? .error
            myTimes = dict[Key.myTimes.rawValue] as? [Double] ?? []
            opTimes = dict[Key.opTimes.rawValue] as? [Double] ?? []
            myMoves = dict[Key.myMoves.rawValue] as? [Int] ?? []
            opMoves = dict[Key.opMoves.rawValue] as? [Int] ?? []
			myMoveTimes = dict[Key.myMoveTimes.rawValue] as? [Int] ?? []
			opMoveTimes = dict[Key.opMoveTimes.rawValue] as? [Int] ?? []
        }
        
        init(myInvite: OnlineInviteData, opInvite: OnlineInviteData) {
            gameID = myInvite.gameID
            myTurn = myInvite > opInvite ? myInvite.gameID % 2 : (opInvite.gameID % 2)^1
            opID = myInvite.opID
            opGameID = opInvite.gameID
            hints = false
            state = .new
            myTimes = [myInvite.timeLimit]
            opTimes = [myInvite.timeLimit]
            myMoves = [-1]
            opMoves = [-1]
			myMoveTimes = [Date.ms]
			opMoveTimes = [Date.ms]
            valid = true
        }
        
        func toDict() -> [String: Any] {
            [
                Key.myTurn.rawValue: myTurn,
                Key.opID.rawValue: opID,
                Key.opGameID.rawValue: opGameID,
                Key.hints.rawValue: hints ? 1 : 0,
                Key.state.rawValue: state.rawValue,
                Key.myTimes.rawValue: myTimes,
                Key.opTimes.rawValue: opTimes,
                Key.myMoves.rawValue: myMoves,
                Key.opMoves.rawValue: opMoves
            ]
        }
    }
    
    struct PlayerData {
        let name: String
        let color: Int
		
		init(name: String, color: Int) {
			self.name = name
			self.color = color
		}
        
        init(from dict: [String: Any]) {
            name = dict[Key.name.rawValue] as? String ?? "no name"
            color = dict[Key.color.rawValue] as? Int ?? 0
        }
    }
    
    struct OnlineInviteData: Comparable {
        let ID: String
        let gameID: Int
        let timeLimit: Double
        var opID: String
        let valid: Bool
        
        init(from entry: Dictionary<String, [String: Any]>.Element) {
            self.init(from: entry.value, ID: entry.key)
        }
        
        init(from dict: [String: Any], ID: String) {
            valid = (
                dict[Key.gameID.rawValue] as? Int != nil &&
                    dict[Key.timeLimit.rawValue] as? Double != nil &&
                    dict[Key.opID.rawValue] as? String != nil
            )
            
            self.ID = ID
            gameID = dict[Key.gameID.rawValue] as? Int ?? 0
            timeLimit = dict[Key.timeLimit.rawValue] as? Double ?? 0
            opID = dict[Key.opID.rawValue] as? String ?? ""
        }
        
        init(timeLimit: Double) {
            ID = myID
            gameID = Date.ms
            self.timeLimit = timeLimit
            opID = ""
            valid = true
        }
        
        func toDict() -> [String: Any] {
            [
                Key.gameID.rawValue: gameID,
                Key.timeLimit.rawValue: timeLimit,
                Key.opID.rawValue: opID
            ]
        }
        
        static func <(lhs: Self, rhs: Self) -> Bool {
            if lhs.gameID == rhs.gameID {
                return lhs.ID < rhs.ID
            } else {
                return lhs.gameID < rhs.gameID
            }
        }
        
        static func >(lhs: Self, rhs: Self) -> Bool {
            if lhs.gameID == rhs.gameID {
                return lhs.ID > rhs.ID
            } else {
                return lhs.gameID > rhs.gameID
            }
        }
        
        static func ==(lhs: Self, rhs: Self) -> Bool {
            return lhs.gameID == rhs.gameID && lhs.ID == rhs.ID
        }
    }
    
    enum MatchingState {
        case invited, offered, matched, stopped
    }
}


