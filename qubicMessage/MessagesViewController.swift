//
//  MessagesViewController.swift
//  qubicMessage
//
//  Created by 4 on 1/9/21.
//  Copyright © 2021 XNO LLC. All rights reserved.
//

import UIKit
import Messages

class MessagesViewController: MSMessagesAppViewController {
    var selected: MSMessage?
	// using OldHPicker bc it works with UIKit
    let picker = OldHPicker(content: [["first", "random", "second"]], dim: (100,100), selected: [1], action: {_,_ in })
    let loadButton = UIButton()
    var gameView = UIView()
    let sentLabel = UILabel()
    let playerView: [UIView] = [UIView(), UIView()]
    let playerText: [UILabel] = [UILabel(), UILabel()]
	var panStartPoint: CGPoint = CGPoint(x: 0,y: 0)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Storage.set(4, for: .color)
		Storage.set(1, for: .confirmMoves)
		Storage.set(1, for: .premoves)
		Storage.set(2, for: .moveChecker)
		
		picker.picker.frame = CGRect(x: view.center.x-200, y: 50, width: 400, height: 100)
		picker.picker.isHidden = true
		view.addSubview(picker.picker)
		
        loadButton.frame = CGRect(x: view.center.x-40, y: 130, width: 80, height: 40)
        loadButton.setTitle("load", for: .normal)
        loadButton.setTitleColor(.label, for: .normal)
        loadButton.addTarget(self, action: #selector(pressedStart), for: .touchUpInside)
        loadButton.isHidden = true
        view.addSubview(loadButton)
        
        Game.main.sendMessage = sendMessage
        gameView.addSubview(BoardScene.main.view)
//        print(view.bounds.height-200, view.bounds.height-230, view.bounds.height)
//        368.0 338.0 568.0
//        644.0 614.0 844.0
        BoardScene.main.view.frame = CGRect(x: 0, y: 80, width: view.bounds.width, height: view.bounds.height*0.9-145)
        gameView.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: view.bounds.height)
		
		BoardScene.main.view.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(onPan(_:))))
        
        sentLabel.frame = CGRect(x: gameView.center.x-40, y: gameView.center.y, width: 80, height: 40)
        sentLabel.text = "sent!"
        sentLabel.textColor = .white
        sentLabel.textAlignment = .center
        let halfGray = UIColor.gray.withAlphaComponent(0.8)
        sentLabel.backgroundColor = halfGray
        sentLabel.layer.cornerRadius = 12
        sentLabel.layer.masksToBounds = true
        sentLabel.isHidden = true
        gameView.addSubview(sentLabel)
        
        for p in stride(from: 0, through: 1, by: 1) {
            let width = min(150, (gameView.bounds.width-60)/2)
            let x = p == 0 ? 20 : (gameView.bounds.width - 20 - width)
            playerView[p].frame = CGRect(x: x, y: 15, width: width, height: 50)
            playerView[p].layer.cornerRadius = 25
            gameView.addSubview(playerView[p])
            
            playerText[p].frame = playerView[p].frame
            playerText[p].textColor = .white
            playerText[p].textAlignment = .center
            gameView.addSubview(playerText[p])
        }
        
        gameView.isHidden = true
        view.addSubview(gameView)
    }
    
    override func willSelect(_ message: MSMessage, conversation: MSConversation) {
        if selected == nil {
            newMessage(message, movable: message.senderParticipantIdentifier != conversation.localParticipantIdentifier)
        }
    }
    
    override func willBecomeActive(with conversation: MSConversation) {
        // Called when the extension is about to move from the inactive to active state.
        // This will happen when the extension is about to present UI.
        
        // Use this method to configure the extension and restore previously stored state.
        if let message = conversation.selectedMessage {
			// this doesn't work virtually, they can just always send moves
            newMessage(message, movable: message.senderParticipantIdentifier != conversation.localParticipantIdentifier)
//            selected = newMessage
//            loadButton.isHidden = true
//            gameView.isHidden = false
//            print("becoming active", newMessage.url)
//            game.load(from: newMessage.url)
        } else {
            loadButton.isHidden = false
            picker.picker.isHidden = false
            gameView.isHidden = true
        }
    }
    
    override func didResignActive(with conversation: MSConversation) {
        // Called when the extension is about to move from the active to inactive state.
        // This will happen when the user dismisses the extension, changes to a different
        // conversation or quits Messages.
        
        // Use this method to release shared resources, save user data, invalidate timers,
        // and store enough state information to restore your extension to its current state
        // in case it is terminated later.
    }
   
    override func didReceive(_ message: MSMessage, conversation: MSConversation) {
        // Called when a message arrives that was generated by another instance of this
        // extension on a remote device.
//        print("got moves")
        // Use this method to trigger UI updates in response to the message.
        if selected != nil {
            if selected?.session == message.session {
                selected = message
//                print("same session")
                guard Game.main.newMove(from: message.url) else { print("error?"); return }
//                print("got turn!")
                let shadowed = Game.main.realTurn
                for p in stride(from: 0, through: 1, by: 1) {
                    playerView[p].layer.shadowOpacity = shadowed == p ? 1 : 0
                }
            }
        }
    }
    
    override func didStartSending(_ message: MSMessage, conversation: MSConversation) {
        // Called when the user taps the send button.
    }
    
    override func didCancelSending(_ message: MSMessage, conversation: MSConversation) {
        // Called when the user deletes the message without sending it.
    
        // Use this to clean up state related to the deleted message.
    }
    
    override func willTransition(to presentationStyle: MSMessagesAppPresentationStyle) {
        // Called before the extension transitions to a new presentation style.
    
        // Use this method to prepare for the change in presentation style.
        if selected != nil && presentationStyle == .compact {
            selected = nil
            loadButton.isHidden = false
            picker.picker.isHidden = false
            gameView.isHidden = true
        }
    }
    
    override func didTransition(to presentationStyle: MSMessagesAppPresentationStyle) {
        // Called after the extension transitions to a new presentation style.
    
        // Use this method to finalize any behaviors associated with the change in presentation style.
    }
    
    func newMessage(_ message: MSMessage, movable: Bool) {
        selected = message
        loadButton.isHidden = true
        picker.picker.isHidden = false
        gameView.isHidden = false
        Game.main.load(from: message.url, movable: movable)
        let shadowed = Game.main.realTurn
        for p in stride(from: 0, through: 1, by: 1) {
            playerView[p].backgroundColor = .of(n: Game.main.player[p].color)
            playerText[p].text = Game.main.player[p].name
            playerView[p].layer.shadowColor = UIColor.of(n: Game.main.player[p].color).cgColor
            playerView[p].layer.shadowRadius = 12
//                playerView[p].layer.shadowOffset = .init(width: 10, height: 10)
            playerView[p].layer.shadowPath = UIBezierPath(rect: playerView[p].bounds.inset(by: .init(top: 8, left: 0, bottom: 0, right: 0))).cgPath
            playerView[p].layer.shadowOpacity = shadowed == p ? 1 : 0
        }
    }
    
    func sendMessage(move: Character) {
//        print("sending move!")
        if Game.main.gameState == .active {
            playerView[0].layer.shadowOpacity = Game.main.turn == 0 ? 1 : 0
            playerView[1].layer.shadowOpacity = Game.main.turn == 1 ? 1 : 0
        }
        
        let message = MSMessage(session: selected?.session ?? MSSession())
        message.summaryText = "qubic game"
        let layout = MSMessageTemplateLayout()
        layout.image = UIImage(named: "icon1024half")
        layout.caption = "qubic"
        message.layout = layout
        guard let url = selected?.url else { print("no url"); return }
        guard var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: true) else { print("url failed"); return }
        let gameString = (urlComponents.queryItems?[0].value ?? "") + String(move)
        urlComponents.queryItems?[0] = URLQueryItem(name: "game", value: gameString)
        message.url = urlComponents.url
        
        activeConversation?.send(message)
        
        Timer.after(0.3) {
            self.sentLabel.isHidden = false
        }
        Timer.after(1.2) {
            self.sentLabel.isHidden = true
        }
    }
    
    @objc func pressedStart() {
        let message = MSMessage(session: selected?.session ?? MSSession())
        message.summaryText = "qubic game"
        let layout = MSMessageTemplateLayout()
        layout.image = UIImage(named: "icon1024half")
        layout.caption = "qubic"
        message.layout = layout
//        let uuid = UIDevice.current.identifierForVendor?.uuidString ?? ""
        var first: Bool = 0 == .random(in: 0...1)
        if picker.selected[0] == 0 { first = true }
        if picker.selected[0] == 2 { first = false }
        
        var urlComponents = URLComponents()
        urlComponents.host = "qubic"
        urlComponents.queryItems = [
            URLQueryItem(name: "game", value: ".")
//            URLQueryItem(name: "type", value: "default"),
//            URLQueryItem(name: "me", value: messagesID),
//            URLQueryItem(name: "p1", value: first ? "me" : "op")
        ]
        message.url = urlComponents.url
//        print(message.url)
        
        if first {
            requestPresentationStyle(.expanded)
            newMessage(message, movable: true)
        } else {
            activeConversation?.insert(message)
        }
    }
	
	@objc func onPan(_ gestureRecognizer: UIPanGestureRecognizer) {
		if gestureRecognizer.state == .began {
			panStartPoint = gestureRecognizer.location(in: BoardScene.main.view)
		} else if gestureRecognizer.state == .changed {
			let translation = gestureRecognizer.translation(in: BoardScene.main.view)
			let h = translation.y
			let w = translation.x
			if abs(w) > abs(h) {
				BoardScene.main.rotate(angle: w, start: panStartPoint)
			}
		} else if gestureRecognizer.state == .ended {
			BoardScene.main.endRotate()
		}
	}

}
