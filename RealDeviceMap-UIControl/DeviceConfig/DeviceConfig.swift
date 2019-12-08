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
        let tapMultiplier: Double
        if #available(iOS 13.0, *)
        {
            tapMultiplier = 0.5
        }
        else
        {
            tapMultiplier = 1.0
        }

        let screenRect = UIScreen.main.nativeBounds
        let screenWidth = app.frame.size.width
        let screenHeight = app.frame.size.height
        let screenScale = UIScreen.main.scale
        Log.debug("Screen width = \(screenWidth), screen height = \(screenHeight) scale = \(screenScale)")
            switch screenWidth {
            case 320.0: // iphone 6, 7
                global = DeviceRatio1775(width: Int(app.frame.size.width), height: Int(app.frame.size.height), multiplier: 1.0, tapMultiplier: tapMultiplier)
                Log.debug("using ratio1775 with tapmultiplier \(tapMultiplier)")
            case 1536.0: //ipad
                global = DeviceRatio1333(width: Int(app.frame.size.width), height: Int(app.frame.size.height), multiplier: 1.0, tapMultiplier: tapMultiplier)
                Log.debug("using ratio1335 with tapmultiplier \(tapMultiplier)")
            case 834.0: // iPhone plus
                global = DeviceRatio1778(width: Int(app.frame.size.width), height: Int(app.frame.size.height), multiplier: 1, tapMultiplier: tapMultiplier)
                Log.debug("using ratio1778 with tapmultiplier \(tapMultiplier)")
            default: // other iPhones
                global = DeviceRatio1775(width: Int(app.frame.size.width), height: Int(app.frame.size.height), multiplier: 1.0, tapMultiplier: tapMultiplier)
                Log.debug("using default ratio1775 with tapmultiplier \(tapMultiplier)")
            }
    }
    
}
