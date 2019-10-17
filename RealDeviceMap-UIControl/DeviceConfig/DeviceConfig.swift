//
//  DeviceConfig.swift
//  RealDeviceMap-UIControlUITests
//
//  Created by Florian Kostenzer on 18.11.18.
//

import Foundation
import XCTest

class DeviceConfig {
    
    public static private(set) var global: DeviceConfigProtocol!
    
    public static func setup(app: XCUIApplication) {
        let screenRect = UIScreen.main.nativeBounds
        let screenWidth = screenRect.size.width
        let screenHeight = screenRect.size.height
        let screenScale = UIScreen.main.scale
        Log.debug("Screen width = \(screenWidth), screen height = \(screenHeight) scale = \(screenScale)")
            switch screenWidth {
            case 640.0: // iphone 6, 7
                global = DeviceRatio1775(width: Int(app.frame.size.width), height: Int(app.frame.size.height))
                Log.debug("using ratio1775")
            case 1536.0: //ipad
                global = DeviceRatio1333(width: Int(app.frame.size.width), height: Int(app.frame.size.height))
                Log.debug("using ratio1335")
            case 834.0: // iPhone plus
                global = DeviceRatio1778(width: Int(app.frame.size.width), height: Int(app.frame.size.height), multiplier: 1)
                Log.debug("using ratio1778")
            default: // other iPhones
                global = DeviceRatio1775(width: Int(app.frame.size.width), height: Int(app.frame.size.height))
                Log.debug("using ratio1775")
            }
    }
    
}
