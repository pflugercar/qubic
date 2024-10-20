//
//  GeneralHelper.swift
//  qubic
//
//  Created by Chris McElroy on 10/17/21.
//  Copyright © 2021 XNO LLC. All rights reserved.
//

import SwiftUI

//00000000-0000-0000-0000-000000000000
var myID: String = Storage.string(.uuid) ?? "00000000000000000000000000000000"
var messagesID: String {
	if let id = Storage.string(.messagesID) {
		return id
	} else {
		let id = UIDevice.current.identifierForVendor?.uuidString ?? ""
		Storage.set(id, for: .messagesID)
		return id
	}
}

enum VersionType: String {
	case xCode = "xCode"
	case testFlight = "testFlight"
	case appStore = "appStore"
}

enum Opacity: Double {
	case clear = 0
	case half = 0.3
	case ghost = 0.7
//	case preset = 0.94
	case full = 1
}

extension Sequence where Element: AdditiveArithmetic {
	func sum() -> Element { reduce(.zero, +) }
}

public extension Collection {
	func first(_ k: Int) -> SubSequence {
		return self.dropLast(count-k)
	}
	
	func last(_ k: Int) -> SubSequence {
		return self.dropFirst(count-k)
	}
}

func bound<N: Numeric>(_ l: N, _ m: N, _ u: N) -> N where N: Comparable {
	min(u, max(l, m))
}

extension Date {
	func isYesterday() -> Bool {
		Calendar.current.isDateInYesterday(self)
	}
	
	func isToday() -> Bool {
		Calendar.current.isDateInToday(self)
	}
	
	static var int: Int {
		return Calendar.current.ordinality(of: .day, in: .era, for: Calendar.current.startOfDay(for: Date())) ?? 0
	}
	
	static var now: TimeInterval {
		timeIntervalSinceReferenceDate
	}
	
	static var ms: Int {
		Int(now*1000)
	}
}

extension Equatable {
	func oneOf(_ o1: Self, _ o2: Self) -> Bool {
		self == o1 || self == o2
	}
	
	func oneOf(_ o1: Self, _ o2: Self, _ o3: Self) -> Bool {
		self == o1 || self == o2 || self == o3
	}
	
	func oneOf(_ o1: Self, _ o2: Self, _ o3: Self, _ o4: Self) -> Bool {
		self == o1 || self == o2 || self == o3 || self == o4
	}
	
	func oneOf(_ o1: Self, _ o2: Self, _ o3: Self, _ o4: Self, _ o5: Self) -> Bool {
		self == o1 || self == o2 || self == o3 || self == o4 || self == o5
	}
	
	func oneOf(_ o1: Self, _ o2: Self, _ o3: Self, _ o4: Self, _ o5: Self, _ o6: Self) -> Bool {
		self == o1 || self == o2 || self == o3 || self == o4 || self == o5 || self == o6
	}
	
	func noneOf(_ o1: Self, _ o2: Self) -> Bool {
		self != o1 && self != o2
	}
	
	func noneOf(_ o1: Self, _ o2: Self, _ o3: Self) -> Bool {
		self != o1 && self != o2 && self != o3
	}
	
	func noneOf(_ o1: Self, _ o2: Self, _ o3: Self, _ o4: Self) -> Bool {
		self != o1 && self != o2 && self != o3 && self != o4
	}
	
	func noneOf(_ o1: Self, _ o2: Self, _ o3: Self, _ o4: Self, _ o5: Self) -> Bool {
		self != o1 && self != o2 && self != o3 && self != o4 && self != o5
	}
}

extension Timer {
	@discardableResult static func after(_ delay: TimeInterval, run: @escaping () -> Void) -> Timer {
		scheduledTimer(withTimeInterval: delay, repeats: false, block: { _ in run() })
	}
	
	@discardableResult static func every(_ delay: TimeInterval, run: @escaping () -> Void) -> Timer {
		scheduledTimer(withTimeInterval: delay, repeats: true, block: { _ in run() })
	}
}
