//
//  TrainView.swift
//  qubic
//
//  Created by 4 on 7/25/20.
//  Copyright © 2020 XNO LLC. All rights reserved.
//

import SwiftUI

struct TrainView: View {
    @Binding var view: ViewStates
    @State var selected: [Int] = [0,1,UserDefaults.standard.integer(forKey: lastTrainKey)]
    let board: BoardScene
    let beaten = UserDefaults.standard.array(forKey: trainKey) as? [Int] ?? [0,0,0,0,0,0]
    
    var body: some View {
        VStack(spacing: 0) {
            if view == .train {
                GameView(board: board)
                    .onAppear { board.load(GameData(mode: mode, turn: turn)) }
            } else if view == .trainMenu {
                Spacer()
                HPicker(use: .train, content: pickerText, dim: (90, 55), selected: $selected, action: onSelection)
                    .frame(height: 180)
                    .opacity(view == .trainMenu ? 1 : 0)
            }
        }
    }
    
    func onSelection(row: Int, component: Int) {
        if component == 2 {
            UserDefaults.standard.setValue(row, forKey: lastTrainKey)
        }
    }
    
    var pickerText: [[(String, Bool)]] {
        [[("sandbox", false),("challenge", false)],
         [("first", false),("random", false),("second", false)],
         [("novice",    beaten[0] == 1),
          ("defender",  beaten[1] == 1),
          ("warrior",   beaten[2] == 1),
          ("tyrant",    beaten[3] == 1),
          ("oracle",    beaten[4] == 1),
          ("cubist",    beaten[5] == 1)]]
    }
    
    var mode: GameMode {
        switch selected[2] {
        case 0: return .novice
        case 1: return .defender
        case 2: return .warrior
        case 3: return .tyrant
        case 4: return .oracle
        default: return .cubist
        }
    }
    
    var turn: Int {
        switch selected[1] {
        case 0: return 0
        case 2: return 1
        default: return Int.random(in: 0...1)
        }
    }
    
//    var difficultyPicker: some View {
//        HStack {
//            Image("pinkCube")
//                .resizable()
//                .frame(width: 40, height: 40)
//        }
//    }
//
//    var boardPicker: some View {
//        Text("Beginner")
//            .foregroundColor(.white)
//            .frame(width: 160, height: 40)
//            .background(Rectangle().foregroundColor(.red))
//            .cornerRadius(100)
//    }
}

struct TrainView_Previews: PreviewProvider {
    static var previews: some View {
        TrainView(view: .constant(.solveMenu), board: BoardScene())
    }
}
