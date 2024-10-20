//
//  Beginner.swift
//  qubic
//
//  Created by 4 on 12/9/20.
//  Copyright © 2020 XNO LLC. All rights reserved.
//

import Foundation

class Novice: Player {
    
    override init(b: Board, n: Int) {
		super.init(b: b, n: n, id: "novice", name: "novice", color: 6,
                   lineP: [3: 1.0, -3: 0.9, 2: 0.20],
                   dirStats: Player.setStats(hs: 0.98, vs: 0.65, hd: 0.95, vd: 0.20, md: 0.25),
                   depth: 1,
                   w2BlockP: 0.2,
                   lineScore: [0,0,2,1,1,1,2,0,0], // my points on the left
                   bucketP: 0.4)
//                   w1: [Player.setStats(hs: 0.98, vs: 0.85, hd: 0.95, vd: 0.40, md: 0.40),
//                        Player.setStats(hs: 0.95, vs: 0.60, hd: 0.85, vd: 0.30, md: 0.20)],
//                   w2: [Player.setStats(hs: 0.20, vs: 0.10, hd: 0.10, vd: 0.05, md: 0.05), // was 0.6 total
//                        Player.setStats(hs: 0.20, vs: 0.10, hd: 0.10, vd: 0.03, md: 0.03)], // was 0.2 total
//                   c1: [Player.setStats(hs: 0.20, vs: 0.10, hd: 0.10, vd: 0.05, md: 0.05),
//                        Player.setStats(hs: 0.20, vs: 0.10, hd: 0.10, vd: 0.03, md: 0.03)])
    }
    
    override func getPause() -> Double {
        if b.hasW1(0) || b.hasW1(1) {
            return Double.random(in: 1.0..<2.0)
        }
        
//        if b.getO1CheckmatesFor(0).count + b.getO1CheckmatesFor(1).count > 0 {
//            return Double.random(in: 1.5..<4.0)
//        }
        
        let moves = Double(b.move[0].count)
        let bottom = 0.6 + moves/6
        let top = 1.5 + moves/4
        return Double.random(in: bottom..<top)
    }
    
//    override func unforcedHeuristic() -> Int {
//        let rich = (0..<64).filter {  Board.rich.contains($0) && b.pointEmpty($0) }
//        let poor = (0..<64).filter { !Board.rich.contains($0) && b.pointEmpty($0) }
//        let bias = 5.1*Double(rich.count)/(0.001+Double(poor.count))
//        if poor.isEmpty { return rich.randomElement() ?? 0}
//        if rich.isEmpty { return poor.randomElement() ?? 0}
//        return .random(in: 0...1) < (bias/(1+bias)) ? rich.randomElement() ?? 0 : poor.randomElement() ?? 0
//    }
}
