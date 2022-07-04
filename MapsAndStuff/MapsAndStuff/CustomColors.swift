//
//  CustomColors.swift
//  MapsAndStuff
//
//  Created by Iuliia Volkova on 26.06.2022.
//

import Foundation
import UIKit

enum CustomColors {
    case almostWhite
    case dustyTeal
    case lightGray
    case pastelSandy
    
    static func setColor (style: CustomColors) -> UIColor {
        switch style {
        case .almostWhite:
            return UIColor(named: "almostWhite")!
        case .dustyTeal:
            return UIColor(named: "dustyTeal")!
        case .lightGray:
            return UIColor(named: "lightGray")!
        case .pastelSandy:
            return UIColor(named: "pastelSandy")!
        }
    }
}
