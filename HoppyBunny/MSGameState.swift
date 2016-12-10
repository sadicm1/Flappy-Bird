//
//  GameState.swift
//  HoppyBunny
//
//  Created by Mehmet Sadıç on 22/11/2016.
//  Copyright © 2016 Mehmet Sadıç. All rights reserved.
//

import SpriteKit

enum MSStarState {
  case visible, hidden
}

class GameState: SKNode {
  
  // check rewarding star (or highest score) state and update values accoringly
  var starState: MSStarState = .hidden {
    didSet {
      switch starState {
      case .visible:
        self.alpha = 1
      case .hidden:
        self.alpha = 0
      }
    }
  }
  
  
  
}
