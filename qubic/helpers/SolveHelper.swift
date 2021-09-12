//
//  SolveHelper.swift
//  qubic
//
//  Created by Chris McElroy on 9/11/21.
//  Copyright © 2021 XNO LLC. All rights reserved.
//

import Foundation

// old daily boards
//let dailyBoards = ["dZsf-RvH", "QR9v-HMCh_", "-vHRD9ojCMh", "RmDO9zvh-siL", "sRdGC1hQ", "dZsf-RvH", "QR9v-HMCh_", "-vHRD9ojCMh", "RmDO9zvh-siL",  "vmDHQ9khV-q", "RHvu96Dh-MPU", "mR9vDdH-VlhQ", "9R-vDHojqMC",  "dsqtRF9hMmVD", "Hd-yvqVjhRms", "dsVqHhC4M9", "RmvCsqJj", "VdMqhs-RDe", "VdMZhRmqs6Db9v-z", "RQj9hgX-s0_E", "mRHCVh90Wq", "Vqhsv9dHtRCD", "RHtqvu9hj27C",  "pmD93VvMqhRs",  "m-DQCMsdqVZU3vjY", "DQvMRhPU9-Cd", "jCdhqVbmH", "sdqMVvCQmD", "mdvnqVsHh",  "m-DQvdRsCjhq", "QW9X-C0_BRjmhDMPUOHt",  "m-CDrMbQvnRj", "-qm8hjVRs", "sdMCqhRHvbDW0a_", "vQJHY-yCjkR3VM", "9V-j_0RdfBQMJuc",  "mRD9vM-qVh",  "hVMsjqTD-", "jhVdCqvQ-nG_RBt9H", "sdMCqj9Hv1R"]

var solveBoards: [Key: [String]] = [:]

func solveBoardCount(_ key: Key) -> Int {
	solveBoards[key]?.count ?? 0
}

private let dailyBoards = [
	["DQvqm-jRbnMdF", "D9tV-rHGsvzihyMPqwRSQjWEC", "Rhs-jHcu09v_D5lVqQYm836n7o", "vq1h2daju-bQC9igk", "DQHv9-mEelMdtzwfyrZV", "HMDjQFRsbP9h6vm3KoWi", "CsM7j8hid6m", "CshdMgjPQ-O8Wk", "CshdMgjPQ-O8W0RE9VKrmoZpLJib", "CpsQhRWH", "-CmMHRvhqs27ycbn4831wf69", "VdCsjhqMQ-E_JyLtvuRW", "jhdDHq-Rmv84MQ", "jdqhVCMsvmRHLt", "jdqhVCMsvmRHLiztZ-", "jqdhVsH3C94TBXIfRS-k", "djqVMsHvh1I_E95-", "Vdhlz9HDe-sQ", "RHviQsMhzC-0WD", "Vmh9d-1638", "Rh9j-dpmuvoi6nbG0", "jqdhVsH3C94TBXIfRS-", "djqVMsHvh1I_E95Sm-"],
	["MqhPjkdxspVzQ", "DH-QYmKr90FPs2v1faRiVhel", "QRVCqtsvLMjA9c-0HghzD", "DT9dVaMlhRsIvqFbzi", "CshdMgjPQ-O8W0RE9VKrmoZpLJ", "QjDM9vHhOTAYGFUE", "-CmMHRvhqs27ycbn4831", "CQv9VmqtHsd-GnDFNaXB", "VdCsjhqMQ-E_JyLtvu", "jdsqGhlVRMwHP9m", "ndjqshM9VClH8OE_1IcuS", "djhMqusvCVQ2-aD1", "jdqmvCVs-1", "jdqhVCMsvmRH", "dqjRChMV9S5HIvsmD", "dm-8sjCMOqhD9V", "pjudqoxMChVQs", "jQdmoxVER9XU-BHuqvJD", "djqVMsHvh1I_E95SwN",  "HMDjQFRsbP9h6vm3Ko","VjRmD0ShIHUPTYOQA"],
	["Rhs-jHcu09v_D5lVqQYm8KoXgCB", "VMqjCRO-km4dDoxQKEWpZ", "THDMU9dRasl", "CpsQhRW0Y2iz", "-RH9dmjqGM", "jmR-hDQq", "jmRhqdH9ODM8", "jmRdVhCq", "jmRdVhCB", "jmHhsdxMDC", "jdqhCsVM_EtLyJ-Q", "jhdDHq-Rmv", "-vk9ymSp", "dqjRChMV9S5HIvsm", "BjsdhMVRQq9-H", "jdqVhM-s97"],
	["DH-QYmKr90FPs2v1faRi", "THDMU9dRas", "DT9dVaMlhRsI", "CshdMgjPQ-O8W0RE9VKrmo", "QjDM9vHhOTAY", "-CmMHRvhqs27ycbn", "CQv9VmqtHsd-GnDF", "-RH9dmjsvD", "jmRhqdH9D-", "jmRdsqHVhC", "jmHhsdlVDq", "jdqhCsVMD9A7E_UG", "jdqmvCVs9h", "jdqChDMs", "-vk9ymSpcHBRZwf", "jdVqh9-s", "m-DQvdRsCjhq", "VdMZhRmqs6Db9v-z"]
]

// crashed:
// "HMDjQFRsbP9h6vm3Ko" (now fixed, see guard for nextStack in getW2())

// ties:
// QR9D-Cm2sjqvVUPMYHSha184360_dfpgkwGnyexOZN5JXKrFIiLtWzAbBoE7l
// sdMCqhQvHW0FmwlVYATDUI_jk9RpZ-oK54B13yiJNOuxrzGngaP72bcSt

private let simpleBoards = [
	"RmIQDUFh", "7sqRh-kS", "mRQoYvfI", "R-SHVvqt", // checkmates no distractions
	"hjqVsH9RCWm", "jVdhRovs91ImQuHSD", "H-DRdVhjEmqGQv95", "dhqRV9HDe31m6Q", // checkmates with distractions
	"DQRUImPOW-", "HQR9ZmyS", "qdhjV-Hs", "qVjshS8-5A", // 3 move wins no distractions
	"qVdjhC-s_HDY2v", "CQv9VmqtHsd-GnDFNa", "hMqjCdosaVcFbDmU3", "vjqsCdhMW0Jy5S91VRaDmxo", // 3 move wins with distractions
	"H-R9DIQm", "jDQHuvosqFG", "Rhs-jHcu09v_D5lV", "m-DQvdRsCjhq", // 4 move wins with distractions
	"QRm-DdVhMjkSq", "jDqARdHOhSPs", "dsVqHhC4M9", "QW9X-C0_BRjmhDMPUOHt" // 5 move wins with distractions
]

private let commonBoards = [
	"HmR9Dj", "qhjCd-", "m9dRoq", "VRfDUH", // triangles with no distractions
	"H9-QmS", "VHjqCg", "HDVmh5", "hHFmzK", // triangles with moves in the plane, no distractions
	"Hd-yvqVjhRms", "R9Hmqv-CkBSI1d", "RHmCD9VIkBcpljT", "sVhjH-9z_0r6bR", // triangles with distractions
	"HRDv-9mdqQ", "CjVMdsqhHR", // 4-1 corner wins, 6 6
	"VhqCjdsM", "RHmv9DQ-", "jCdhqVMs", "HR-9vQmD", // 2-2 splits from 4 corners 7 7 7 7
	"dZsf-RvH", "MdqhQVj-", "CsMqhVdD", "H-RQ9vmh", // standard 4 move wins, 7 7 8 8
	"H-9DvRQqmj", "jdqCMhsHVD" // 5 corner wins, 9 9
]

private let trickyBoards = [
	"Vqhsv9dHtRCD", "HRhQdmplvs9j", "-h9jm0Hkgs", "DQvqm-jR",
	"m9-MhRQH", "9h-CH0WMYP6m", "qHV9dtzjMCmDr", "DHRvmMQ-9",
	"DRH-kQjvmdo9", "Rhs-jHcu09v_D5", "VMqjCRO-km4", "cjdshVCqH-lp79_",
	"cjdshVCq", "Vjdqh9mMs", "QR9v-HMCh_", "-vHRD9ojCMh",
	"RmDO9zvh-siL", "sRdGC1hQ", "vmDHQ9khV-q", "RHvu96Dh-MPU",
	"mR9vDdH-VlhQ", "9R-vDHojqMC",  "dsqtRF9hMmVD", "RmvCsqJj",
	"VdMqhs-RDe", "RQj9hgX-s0_E", "mRHCVh90Wq", "RHtqvu9hj27C",
	"pmD93VvMqhRs", "m-DQCMsdqVZU3vjY", "DQvMRhPU9-Cd", "jCdhqVbmH",
	"sdqMVvCQmD", "mdvnqVsHh", "m-CDrMbQvnRj", "-qm8hjVRs",
	"sdMCqhRHvbDW0a_", "vQJHY-yCjkR3VM", "9V-j_0RdfBQMJuc", "mRD9vM-qVh",
	"hVMsjqTD-", "jhVdCqvQ-nG_RBt9H", "sdMCqj9Hv1R", "HRDv-9mdhQ"
]

func updateDailyData() {
	let today = Date.int
	let lastDaily = Storage.int(.currentDaily)
	
	Layout.main.newDaily = Storage.int(.lastDC) != today
	
	if lastDaily == today { return }
	
	var history = Storage.dictionary(.dailyHistory) as? [String: [Bool]] ?? [:]
	history[String(lastDaily)] = Storage.array(.daily) as? [Bool] ?? [false, false, false, false]
	Storage.set(history, for: .dailyHistory)
	Storage.set(history[String(today)], for: .daily)
	
	upadateDailyBoards(today: today)
	
	Storage.set(today, for: .currentDaily)
}

private func upadateDailyBoards(today: Int) {
	var newDailyBoards: [String] = []
	
	for i in 0..<4 {
		let m = today*today*(today+i)
		let size = dailyBoards[i].count/3
		let aNum = (m/(10000000*size)) % 192
		let bNum = ((m/1000000) % size) + size*(today % 3)
		let base = expandMoves(dailyBoards[i][bNum])
		let newBoard = Board.getAutomorphism(for: base, a: aNum)
		newDailyBoards.append(compressMoves(newBoard))
//		print("updating daily boards:", today, i, m, size, aNum, bNum, newDailyBoards.last ?? "")
	}
	
	solveBoards[.daily] = newDailyBoards
}

func updateSolveBoardData() {
	solveBoards = [
		.daily: ["","","",""],
		.simple: simpleBoards,
		.common: commonBoards,
		.tricky: trickyBoards
	]
	upadateDailyBoards(today: Date.int)
	
	if Storage.int(.solveBoardsVersion) < 33 {
		// TODO remove after everyone's on 33:
		transfer32Data()
		
		setArray(for: .simple, length: simpleBoards.count)
		setArray(for: .common, length: commonBoards.count)
		setArray(for: .tricky, length: trickyBoards.count)
		Storage.set(33, for: .solveBoardsVersion)
	}
	
	verifyDailyData()
	
	func transfer32Data() {
		// transfer daily stats
		let today = Date.int
		if var intDaily = Storage.array(.daily) as? [Int] {
			var streak = Storage.int(.streak)
			
			if intDaily.count != 4 {
				intDaily = [0,0,0,0]
				streak = 0
			}
			
			let offset = Storage.int(.lastDC) == today ? 0 : 1
			var dailyHistory = Storage.dictionary(.dailyHistory) as? [String: [Bool]] ?? [:]
			let boolDaily = intDaily.map { $0 >= today || $0 == 1 }
			for daysBack in 0..<streak {
				let date = String(today - daysBack - offset)
				dailyHistory[date] = [true, true, true, true]
			}
			
			dailyHistory[String(today)] = boolDaily
			
			Storage.set(boolDaily, for: .daily)
			Storage.set(dailyHistory, for: .dailyHistory)
		}
		
		// transfer simple boards
		if let list = Storage.array(.simple) as? [Int] {
			var solved = Storage.array(.solvedBoards) as? [String] ?? []
			
			for (i, n) in list.enumerated() where n != 0 {
				solved.append(simpleBoards[i])
			}
			
			Storage.set(solved, for: .solvedBoards)
			// don't set simple bc the next step resets that
		}
		
		// transfer training data
		if let intTrain = Storage.array(.train) as? [Int] {
			var boolTrain: [Bool] = []
			for i in 0..<6 {
				boolTrain.append(intTrain[i] != 0)
			}
			Storage.set(boolTrain, for: .train)
		}
	}
	
	func setArray(for type: Key, length: Int) {
		let solved = Storage.array(.solvedBoards) as? [String] ?? []
		var list: [Bool] = []
		
		for i in 0..<length {
			if let board = solveBoards[type]?[i] {
				list.append(solved.contains(board))
			}
		}
		
		Storage.set(list, for: type)
	}
	
	func verifyDailyData() {
		let today = Date.int
		var date = today - 1
		let history = Storage.dictionary(.dailyHistory) as? [String: [Bool]] ?? [:]
		
		while history[String(date)] == [true, true, true, true] {
			date -= 1
		}
		
		let streak: Int
		let lastDC: Int
		if history[String(today)] == [true, true, true, true] {
			streak = today - date
			lastDC = today
		} else {
			streak = today - date - 1
			lastDC = streak == 0 ? 0 : today - 1
		}
		Storage.set(streak, for: .streak)
		Storage.set(lastDC, for: .lastDC)
		
		Layout.main.newDaily = Storage.int(.lastDC) != today
		Storage.set(today, for: .currentDaily)
	}
}

//let solveBoardDates: [Key: [Int]] = [
//	.simple: Array(repeating: 737991, count: simpleBoards.count),
//	.common: Array(repeating: 737991, count: commonBoards.count),
//	.tricky: Array(repeating: 1, count: trickyBoards.count)
//]
