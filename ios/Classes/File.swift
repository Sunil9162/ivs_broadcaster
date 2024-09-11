//
//  File.swift
//  ivs_broadcaster
//
//  Created by Gitesh Dang iOS on 05/09/24.
//

import Foundation

enum CameraPosition: String {
    case front = "0"
    case back = "1"
    
    // Custom initializer to convert String to CameraPosition
    init?(string: String) {
        self.init(rawValue: string)
    }
}

 
