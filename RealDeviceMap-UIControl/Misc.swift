//
//  Misc.swift
//  RealDeviceMap-UIControlUITests
//
//  Created by Florian Kostenzer on 28.09.18.
//

import Foundation
import XCTest

extension UIImage {
    func getPixelColor(pos: CGPoint) -> UIColor {
        
        let pixelData = cgImage!.dataProvider!.data!
        let data: UnsafePointer<UInt8> = CFDataGetBytePtr(pixelData)

        if cgImage!.bitsPerComponent == 16 {
            let pixelInfo: Int = ((Int(cgImage!.width) * Int(pos.y)) + Int(pos.x)) * 8

            var rValue: UInt32 = 0
            var gValue: UInt32 = 0
            var bValue: UInt32 = 0
            var aValue: UInt32 = 0

            NSData(bytes: [data[pixelInfo], data[pixelInfo+1]], length: 2).getBytes(&rValue, length: 2)
            NSData(bytes: [data[pixelInfo+2], data[pixelInfo+3]], length: 2).getBytes(&gValue, length: 2)
            NSData(bytes: [data[pixelInfo+4], data[pixelInfo+5]], length: 2).getBytes(&bValue, length: 2)
            NSData(bytes: [data[pixelInfo+6], data[pixelInfo+7]], length: 2).getBytes(&aValue, length: 2)
            
            let r = CGFloat(rValue) / CGFloat(65535.0)
            let g = CGFloat(gValue) / CGFloat(65535.0)
            let b = CGFloat(bValue) / CGFloat(65535.0)
            let a = CGFloat(aValue) / CGFloat(65535.0)
            
            return UIColor(red: r, green: g, blue: b, alpha: a)
        } else {
            let pixelInfo: Int = ((Int(cgImage!.width) * Int(pos.y)) + Int(pos.x)) * 4
            
            let r = CGFloat(data[pixelInfo]) / CGFloat(255.0)
            let g = CGFloat(data[pixelInfo+1]) / CGFloat(255.0)
            let b = CGFloat(data[pixelInfo+2]) / CGFloat(255.0)
            let a = CGFloat(data[pixelInfo+3]) / CGFloat(255.0)
            
            return UIColor(red: r, green: g, blue: b, alpha: a)
        }
        
    }
    
    func getPixelColor(pos: DeviceCoordinate) -> UIColor {
        return self.getPixelColor(pos: CGPoint(x: pos.x, y: pos.y))
    }
}

extension XCUIScreenshot {
    
    func rgbAtLocation(pos: (x: Int, y: Int)) -> (red: CGFloat, green: CGFloat, blue: CGFloat){
        
        let color = self.image.getPixelColor(pos: CGPoint(x: pos.x, y: pos.y))
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        return (red, green, blue)
        
    }
    
    func rgbAtLocation(pos: DeviceCoordinate) -> (red: CGFloat, green: CGFloat, blue: CGFloat){
        return self.rgbAtLocation(pos: pos.toXY())
    }
    
    func rgbAtLocation(pos: (x: Int, y: Int), min: (red: CGFloat, green: CGFloat, blue: CGFloat), max: (red: CGFloat, green: CGFloat, blue: CGFloat)) -> Bool {

        let color = self.rgbAtLocation(pos: pos)
        
        return  color.red >= min.red && color.red <= max.red &&
                color.green >= min.green && color.green <= max.green &&
                color.blue >= min.blue && color.blue <= max.blue
    }
    
    func rgbAtLocation(pos: DeviceCoordinate, min: (red: CGFloat, green: CGFloat, blue: CGFloat), max: (red: CGFloat, green: CGFloat, blue: CGFloat)) -> Bool {
        return self.rgbAtLocation(pos: pos.toXY(), min: min, max: max)
    }
}

extension XCTestCase {
    
    internal var app: XCUIApplication { return XCUIApplication(bundleIdentifier: "com.nianticlabs.pokemongo") }
    internal var deviceConfig: DeviceConfigProtocol { return DeviceConfig.global }
    internal var config: Config { return Config.global }
    
    func postRequest(url: URL, data: [String: Any], blocking: Bool=false, completion: @escaping ([String: Any]?) -> Swift.Void) {
        
        var done = false
        var resultDict: [String: Any]?
        let jsonData = try! JSONSerialization.data(withJSONObject: data)
        
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 20)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = jsonData
        if config.token != "" {
            request.addValue("Bearer \(config.token)", forHTTPHeaderField: "Authorization")
        }
        let session = URLSession.shared
        let task = session.dataTask(with: request) {(data, response, error) in
            if let response = response {
                let nsHTTPResponse = response as! HTTPURLResponse
                _ = nsHTTPResponse.statusCode
              // Log.debug("status code = \(statusCode)")
            }
            if let error = error {
               Log.debug("\(error)...Rebuilding Controller")
               exit(-3)
            }
            if let data = data {
                do{
                    let resultJSON = try? JSONSerialization.jsonObject(with: data)
                    resultDict = resultJSON as? [String: Any]
                }
                if !blocking {
                    completion(resultDict)
                }
                print("[HTTP] Blocking: \(blocking), data = \(data)\n")
            } else {
                if !blocking {
                    completion(nil)
                }
                print("[HTTP] NIL\n")
            }
            done = true
        }
        
        task.resume()
        if blocking {
            repeat {
                usleep(1000)
            } while !done
            completion(resultDict)
        }
    }
	
   func checkHasWarning(screenshot: XCUIScreenshot?=nil) -> Bool {
        
        let screenshotComp = screenshot ?? XCUIScreen.main.screenshot()
        Log.debug("Checking for red warning on account...")
        if screenshotComp.rgbAtLocation(
            pos: deviceConfig.compareWarningL,
            min: (red: 0.85, green: 0.23, blue: 0.30),
            max: (red: 0.98, green: 0.32, blue: 0.40)) &&
           screenshotComp.rgbAtLocation(
            pos: deviceConfig.compareWarningR,
            min: (red: 0.0, green: 0.0, blue: 0.0),
            max: (red: 0.2, green: 0.2, blue: 0.2)) {
            return true
        } else {
            Log.debug("Account passed...for now......")
            return false
        }
        
    } 
    func isStartup(click: Int = 0, screenshot: XCUIScreenshot?=nil) -> Bool {
        let tap = click
        let screenshotComp = screenshot ?? XCUIScreen.main.screenshot()
        if self.config.verbose {
            Log.debug("cornerTest location check at \(deviceConfig.cornerTest.x),\(deviceConfig.cornerTest.y) color range allowed(R:.27-.3 G:.68-.73 B:.49-.53)")
            Log.debug("rgbA (cornerTest) result: \(screenshotComp.rgbAtLocation(pos: deviceConfig.cornerTest))")
            
        }
        if screenshotComp.rgbAtLocation(pos: deviceConfig.cornerTest, min: (red: 0.27, green: 0.68, blue: 0.49), max: (red: 0.30, green: 0.73, blue: 0.53)) {
            Log.startup("Attempting to clear startup warning")
            if self.config.verbose {
                Log.debug("cautionButton location check at \(deviceConfig.cautionButton.x),\(deviceConfig.cautionButton.y) color range allowed(R:.61-.66 G:.83-.87 B:.56-.61) Result----")
                Log.debug("rgbA (cautionButton) result: \(screenshotComp.rgbAtLocation(pos: deviceConfig.cautionButton))")
            }
            if screenshotComp.rgbAtLocation(pos: deviceConfig.cautionButton, min: (red: 0.61, green: 0.83, blue: 0.56), max: (red: 0.66, green: 0.87, blue: 0.61)) {
                if tap == 1 {
                    deviceConfig.cautionButton.toXCUICoordinate(app: app).tap()
                    Log.debug("Cleared Caution warning.")
                }
                return true
            } else if screenshotComp.rgbAtLocation(pos: deviceConfig.twothreelineButton, min: (red: 0.61, green: 0.83, blue: 0.56), max: (red: 0.66, green: 0.87, blue: 0.61)) {
                if tap == 1 {
                    deviceConfig.twothreelineButton.toXCUICoordinate(app: app).tap()
                    Log.debug("Cleared two-three line warning.")
                }
                return true
            } else {
                    Log.debug("Could not find OK button.")
            }
         }
        return false
    }
    func checkTos(screenshot: XCUIScreenshot?=nil) -> Bool {
        
        let screenshotComp = screenshot ?? XCUIScreen.main.screenshot()
        if (screenshotComp.rgbAtLocation(
                pos: deviceConfig.loginTerms,
                min: (red: 0.0, green: 0.75, blue: 0.55),
                max: (red: 1.0, green: 0.90, blue: 0.70)) &&
                screenshotComp.rgbAtLocation(
                    pos: deviceConfig.loginTermsText,
                    min: (red: 0.0, green: 0.0, blue: 0.0),
                    max: (red: 0.3, green: 0.5, blue: 0.5)) ) {
            Log.debug("Accepting Terms")
            deviceConfig.loginTerms.toXCUICoordinate(app: app).tap()
            sleep(2 * config.delayMultiplier)
            return true
        } else if (screenshotComp.rgbAtLocation(
                pos: deviceConfig.loginTerms2,
                min: (red: 0.0, green: 0.75, blue: 0.55),
                max: (red: 1.0, green: 0.90, blue: 0.70)) &&
                screenshotComp.rgbAtLocation(
                    pos: deviceConfig.loginTerms2Text,
                    min: (red: 0.0, green: 0.0, blue: 0.0),
                    max: (red: 0.3, green: 0.5, blue: 0.5)) ) {
            Log.debug("Accepting Updated Terms.")
            deviceConfig.loginTerms2.toXCUICoordinate(app: app).tap()
            sleep(2 * config.delayMultiplier)
            return true
        } else if (screenshotComp.rgbAtLocation(
                pos: deviceConfig.loginPrivacy,
                min: (red: 0.0, green: 0.75, blue: 0.55),
                max: (red: 1.0, green: 0.90, blue: 0.70)) &&
                screenshotComp.rgbAtLocation(
                    pos: deviceConfig.loginPrivacyText,
                    min: (red: 0.0, green: 0.75, blue: 0.55),
                    max: (red: 1.0, green: 0.90, blue: 0.70)) ) {
            Log.debug("Accepting Privacy.")
            deviceConfig.loginPrivacy.toXCUICoordinate(app: app).tap()
            sleep(2 * config.delayMultiplier)
            return true
        }
        return false
    }
    
    func adventureSync(screenshot: XCUIScreenshot?=nil) -> Bool {
        
        let screenshotComp = screenshot ?? XCUIScreen.main.screenshot()
        if screenshotComp.rgbAtLocation(
            pos: deviceConfig.adventureSyncRewardsL,
            min: (red: 0.98, green: 0.3, blue: 0.45),
            max: (red: 1.00, green: 0.5, blue: 0.60)) &&
            screenshotComp.rgbAtLocation(
                pos: deviceConfig.adventureSyncRewardsR,
                min: (red: 0.98, green: 0.3, blue: 0.45),
                max: (red: 1.00, green: 0.5, blue: 0.60)) {
            return true
        }
        return false
    }
    func checkSuspended(screenshot: XCUIScreenshot?=nil) -> Bool {
        let screenshotComp = screenshot ?? XCUIScreen.main.screenshot()
        if screenshotComp.rgbAtLocation(pos: deviceConfig.suspendedAccountcheck1,
            min: (red: 0.8, green: 0.75, blue: 0.01),
            max: (red: 1.0, green: 0.85, blue: 0.1)) &&
                screenshotComp.rgbAtLocation(pos: deviceConfig.suspendedAccountcheck2,
                min: (red: 0.01, green: 0.09, blue: 0.2),
                max: (red: 0.1, green: 0.16, blue: 0.4)) {
                Log.debug("Account Suspended.")
                return true
            
        }
        return false
    }
    
    
    func freeScreen(run: Bool=true) {
        let tapMultiplier: Double
        if #available(iOS 13.0, *)
        {
            tapMultiplier = 0.5
        }
        else
        {
            tapMultiplier = 1.0
        }

        var screenshot = clickPassengerWarning()
        if !self.config.ultraIV {
            if screenshot.rgbAtLocation(
                pos: deviceConfig.encounterNoAR,
                min: (red: 0.20, green: 0.70, blue: 0.55),
                max: (red: 0.35, green: 0.85, blue: 0.65)) {
                deviceConfig.encounterNoAR.toXCUICoordinate(app: app).tap()
                sleep(2 * config.delayMultiplier)
                deviceConfig.encounterNoARConfirm.toXCUICoordinate(app: app).tap()
                sleep(3 * config.delayMultiplier)
                deviceConfig.encounterTmp.toXCUICoordinate(app: app).tap()
                sleep(3 * config.delayMultiplier)
                screenshot = XCUIScreen.main.screenshot()
                sleep(1 * config.delayMultiplier)
            }
        }
        Log.debug("Checking for adventure sync rewards")
        if screenshot.rgbAtLocation(
            pos: deviceConfig.adventureSyncRewards,
            min: (red: 0.98, green: 0.3, blue: 0.45),
            max: (red: 1.00, green: 0.5, blue: 0.60)
        ) {
            if self.config.verbose {
                Log.debug("Pixel color test range allowed(R:.4-.5 G:.8-.9 B:.5-.7) Result----")
                Log.debug("rgbAtLocation(adventureSyncButton): \(screenshot.rgbAtLocation(pos: deviceConfig.adventureSyncButton))")
                
            }
            if screenshot.rgbAtLocation(
                pos: deviceConfig.adventureSyncButton,
                min: (red: 0.40, green: 0.80, blue: 0.50),
                max: (red: 0.50, green: 0.90, blue: 0.70)
            ) {
                Log.debug("Collecting AdventureSync rewards")
                deviceConfig.adventureSyncButton.toXCUICoordinate(app: app).tap()
                sleep(2 * config.delayMultiplier)
                deviceConfig.adventureSyncButton.toXCUICoordinate(app: app).tap()
                sleep(2 * config.delayMultiplier)
                screenshot = clickPassengerWarning()
            } else if screenshot.rgbAtLocation(
                pos: deviceConfig.adventureSyncButton,
                min: (red: 0.05, green: 0.45, blue: 0.50),
                max: (red: 0.20, green: 0.60, blue: 0.65)
            ) {
                deviceConfig.adventureSyncButton.toXCUICoordinate(app: app).tap()
                sleep(2 * config.delayMultiplier)
                screenshot = clickPassengerWarning()
            }
        }
        if !self.config.ultraIV {
            if screenshot.rgbAtLocation(
                pos: deviceConfig.teamSelectBackgorundL,
                min: (red: 0.00, green: 0.20, blue: 0.25),
                max: (red: 0.05, green: 0.35, blue: 0.35)) &&
               screenshot.rgbAtLocation(
                pos: deviceConfig.teamSelectBackgorundR,
                min: (red: 0.00, green: 0.20, blue: 0.25),
                max: (red: 0.05, green: 0.35, blue: 0.35)
            ) {
                
                for _ in 1...6 {
                    deviceConfig.teamSelectNext.toXCUICoordinate(app: app).tap()
                    sleep(1 * config.delayMultiplier)
                }
                sleep(3 * config.delayMultiplier)
                
                for _ in 1...3 {
                    for _ in 1...5 {
                        deviceConfig.teamSelectNext.toXCUICoordinate(app: app).tap()
                        sleep(1 * config.delayMultiplier)
                    }
                    sleep(4 * config.delayMultiplier)
                }
                
                let x = Int(arc4random_uniform(UInt32(app.frame.width)))
                _ = DeviceCoordinate(x: x, y: deviceConfig.teamSelectY, tapScaler: tapMultiplier).toXCUICoordinate(app: app) //was "let button"
                sleep(3 * config.delayMultiplier)
                deviceConfig.teamSelectNext.toXCUICoordinate(app: app).tap()
                sleep(2 * config.delayMultiplier)
                deviceConfig.teamSelectWelcomeOk.toXCUICoordinate(app: app).tap()
                sleep(2 * config.delayMultiplier)
                screenshot = clickPassengerWarning()
            }
        }
        Log.debug("Checking for weather condition.")
        if screenshot.rgbAtLocation(
            pos: deviceConfig.closeWeather1,
            min: (red: 0.61, green: 0.83, blue: 0.56), max: (red: 0.66, green: 0.87, blue: 0.61)
        ) {
            Log.debug("Clearing weather warning.")
            deviceConfig.closeWeather1.toXCUICoordinate(app: app).tap()
            sleep(3 * config.delayMultiplier)
            deviceConfig.closeWeather2.toXCUICoordinate(app: app).tap()
            sleep(1 * config.delayMultiplier)
            screenshot = clickPassengerWarning()
        }
        if !self.config.ultraIV {
            if run && screenshot.rgbAtLocation(
                pos: deviceConfig.encounterPokemonRun,
                min: (red: 0.98, green: 0.98, blue: 0.98),
                max: (red: 1.00, green: 1.00, blue: 1.00)
            ) {
                deviceConfig.encounterPokemonRun.toXCUICoordinate(app: app).tap()
                sleep(1 * config.delayMultiplier)
                screenshot = clickPassengerWarning()
            }
            if run && !screenshot.rgbAtLocation(
                pos: deviceConfig.closeMenu,
                min: (red: 0.98, green: 0.98, blue: 0.98),
                max: (red: 1.00, green: 1.00, blue: 1.00)) {
                deviceConfig.closeMenu.toXCUICoordinate(app: app).tap()
                sleep(1 * config.delayMultiplier)
                screenshot = clickPassengerWarning()
            }
        }
        Log.debug("Checking for Enable Adventure Sync Popup...")
        if screenshot.rgbAtLocation(
            pos: deviceConfig.enableAdventureSync,
            min: (red: 0.8, green: 0.53, blue: 0.69), max: (red: 1.0, green: 0.67, blue: 0.81)
            ) {
            Log.debug("Clearing Enable Adventure Sync Popup.")
            deviceConfig.enableAdventureSyncClose.toXCUICoordinate(app: app).tap()
            
        }

    }
    
    func clickPassengerWarning(screenshot: XCUIScreenshot?=nil) -> XCUIScreenshot {

        let screenshotComp = screenshot ?? XCUIScreen.main.screenshot()
        if screenshotComp.rgbAtLocation(
            pos: deviceConfig.passenger,
            min: (red: 0.0, green: 0.75, blue: 0.55),
            max: (red: 1.0, green: 0.90, blue: 0.70)
        ) {
            deviceConfig.passenger.toXCUICoordinate(app: app).tap()
            sleep(1 * config.delayMultiplier)
            return XCUIScreen.main.screenshot()
        }

        return screenshotComp
    }
    
    func logOut() -> Bool {
        
        print("[STATUS] Logout")
        let tapMultiplier: Double
        if #available(iOS 13.0, *)
        {
            tapMultiplier = 0.5
        }
        else
        {
            tapMultiplier = 1.0
        }
        self.freeScreen()
        if checkHasWarning() {
            Log.debug("Closing warning screen.")
            deviceConfig.closeWarning.toXCUICoordinate(app: app).tap()
            sleep(1 * config.delayMultiplier)
        }
        let normalized = app.coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0))
        var found = false
        deviceConfig.closeMenu.toXCUICoordinate(app: app).tap()
        sleep(2 * config.delayMultiplier)
        deviceConfig.settingsButton.toXCUICoordinate(app: app).tap()
        sleep(2 * config.delayMultiplier)
        deviceConfig.logoutDragStart.toXCUICoordinate(app: app).press(forDuration: 0.1, thenDragTo: deviceConfig.logoutDragEnd.toXCUICoordinate(app: app))
        sleep(1 * config.delayMultiplier)
        let screenshot1 = XCUIScreen.main.screenshot()
        for y in 0...screenshot1.image.cgImage!.height / 10 {
            if screenshot1.rgbAtLocation(
                pos: (x: deviceConfig.logoutCompareX, y: y * 10),
                min: (red: 0.60, green: 0.9, blue: 0.6),
                max: (red: 0.75, green: 1.0, blue: 0.7)) {
                normalized.withOffset(CGVector(dx: lround(Double(deviceConfig.logoutCompareX)*tapMultiplier), dy: lround(Double(y * 10)*tapMultiplier))).tap()
                found = true
                break
            }
         }
        var scrollCount = 0
        logoutLoop: while !found {
            if scrollCount == 6 {
                Log.debug("Can't find logout/ Restarting...")
                app.activate()
            }
            deviceConfig.logoutDragStart.toXCUICoordinate(app: app).press(forDuration: 0.1, thenDragTo: deviceConfig.logoutDragEnd2.toXCUICoordinate(app: app))
            sleep(1 * config.delayMultiplier)
            let screenshot2 = XCUIScreen.main.screenshot()
            for y in 0...screenshot2.image.cgImage!.height / 10 {
                if screenshot2.rgbAtLocation(
                    pos: (x: deviceConfig.logoutCompareX, y: y * 10),
                    min: (red: 0.60, green: 0.9, blue: 0.6),
                    max: (red: 0.75, green: 1.0, blue: 0.7)) {
                    Log.debug("logoutCompareX location check tap at \(normalized.withOffset(CGVector(dx: deviceConfig.logoutCompareX, dy: y * 10)))")
                    
                    normalized.withOffset(CGVector(dx: lround(Double(deviceConfig.logoutCompareX)*tapMultiplier), dy: lround(Double(y * 10)*tapMultiplier))).tap()
                    found = true
                    break logoutLoop
                }
            }
            scrollCount += 1
        }
        sleep(2 * config.delayMultiplier)
        deviceConfig.logoutConfirm.toXCUICoordinate(app: app).tap()
        sleep(20 * config.delayMultiplier)
        let screenshotComp = XCUIScreen.main.screenshot()
        Log.debug("Waiting for startup screen...")
        if screenshotComp.rgbAtLocation(
            pos: deviceConfig.startupLoggedOut,
            min: (0.95, 0.75, 0.0),
            max: (1.00, 0.85, 0.1)
        ) {
            Log.debug("Logged out succesfully")
            return true
        } else {
            Log.error("Logging out failed. Restarting...")
            app.terminate()
            sleep(1 * config.delayMultiplier)
            return false
        }
        
    }
    
    func spin() {
        deviceConfig.openPokestop.toXCUICoordinate(app: app).tap()
        sleep(1 * config.delayMultiplier)
        app.swipeLeft()
        sleep(1 * config.delayMultiplier)
        deviceConfig.closeMenu.toXCUICoordinate(app: app).tap()
        sleep(1 * config.delayMultiplier)
        
        let screenshotComp = XCUIScreen.main.screenshot()
        
        // Rocket invasion detection
        if screenshotComp.rgbAtLocation(
            pos: deviceConfig.rocketLogoGirl,
            min: (red: 0.62, green: 0.24, blue: 0.13),
            max: (red: 0.87, green: 0.36, blue: 0.20)) ||
           screenshotComp.rgbAtLocation(
            pos: deviceConfig.rocketLogoGuy,
            min: (red: 0.62, green: 0.24, blue: 0.13),
            max: (red: 0.87, green: 0.36, blue: 0.20))
        {
            Log.info("Rocket invasion encountered")
        
            // Tap through dialog 4 times and wait 3 seconds between each
            for _ in 1...4 {
                deviceConfig.openPokestop.toXCUICoordinate(app: app).tap()
                sleep(3 * config.delayMultiplier)
            }
            
            // Close battle invasion screen
            deviceConfig.closeInvasion.toXCUICoordinate(app: app).tap()
            sleep(1 * config.delayMultiplier)
        }
    }
    
    func clearQuest() {
        let start = Date()
        deviceConfig.openQuest.toXCUICoordinate(app: app).tap()
        sleep(1 * config.delayMultiplier)
        app.swipeRight()
        sleep(1 * config.delayMultiplier)
    
        let screenshotComp = XCUIScreen.main.screenshot()
        
        if screenshotComp.rgbAtLocation(pos: deviceConfig.questDelete, min: (red: 0.98, green: 0.60, blue: 0.22),max: (red: 1.0, green: 0.65, blue: 0.27))
        {
            Log.test("Clearing stacked quests")
            
            for _ in 0...2 {
                deviceConfig.questDeleteWithStack.toXCUICoordinate(app: app).tap()
                sleep(1 * config.delayMultiplier)
                deviceConfig.questDeleteConfirm.toXCUICoordinate(app: app).tap()
                sleep(1 * config.delayMultiplier)
            }
        } else {
            Log.test("Clearing quests")
            for _ in 0...2 {
                deviceConfig.questDelete.toXCUICoordinate(app: app).tap()
                sleep(1 * config.delayMultiplier)
                deviceConfig.questDeleteConfirm.toXCUICoordinate(app: app).tap()
                sleep(1 * config.delayMultiplier)
            }
        } 

        self.freeScreen()
        deviceConfig.closeMenu.toXCUICoordinate(app: app).tap()
        Log.test("Clearing quests Time to Complete: \(String(format: "%.3f", Date().timeIntervalSince(start)))s")
        sleep(1 * config.delayMultiplier)
    }
    
    func clearItems() {
        Log.test("Starting ClearItems()")
        let normalized = app.coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0))
        var index = 0
        var done = false
        var hasEgg = false
        
        deviceConfig.closeMenu.toXCUICoordinate(app: app).tap()
        sleep(1 * config.delayMultiplier)
        deviceConfig.openItems.toXCUICoordinate(app: app).tap()
        sleep(1 * config.delayMultiplier)

        while !done && deviceConfig.itemDeleteYs.count != 0 {
            let screenshot = XCUIScreen.main.screenshot()

            if itemIsEgg(screenshot, x: deviceConfig.itemEggX, y: deviceConfig.itemDeleteYs[index]) {
                hasEgg = true
            }
            
            if itemHasDelete(screenshot, x: deviceConfig.itemDeleteX, y: deviceConfig.itemDeleteYs[index]) && !itemIsGift(screenshot, x: deviceConfig.itemGiftX, y: deviceConfig.itemDeleteYs[index]) && !itemIsEgg(screenshot, x: deviceConfig.itemEggX, y: deviceConfig.itemDeleteYs[index]) && !itemIsEggActive(screenshot, x: deviceConfig.itemEggX, y: deviceConfig.itemDeleteYs[index]) {
                
                let delete = normalized.withOffset(CGVector(dx: deviceConfig.itemDeleteX, dy: deviceConfig.itemDeleteYs[index]))
                delete.tap()
                sleep(1 * config.delayMultiplier)
                deviceConfig.itemDeleteIncrease.toXCUICoordinate(app: app).press(forDuration: 3)
                deviceConfig.itemDeleteConfirm.toXCUICoordinate(app: app).tap()
                
                sleep(1 * config.delayMultiplier)
            } else if index + 1 < deviceConfig.itemDeleteYs.count {
                index += 1
            } else {
                done = true
            }
        }

        let deployEnabled: Bool = config.deployEggs
        Log.test("deployEnabled: \(deployEnabled)")
        if hasEgg && deployEnabled {
            deviceConfig.itemEggMenuItem.toXCUICoordinate(app: app).tap()
            sleep(1 * config.delayMultiplier)
            deviceConfig.itemEggDeploy.toXCUICoordinate(app: app).tap()
            sleep(2 * config.delayMultiplier)
        } else {
            deviceConfig.closeMenu.toXCUICoordinate(app: app).tap()
            Log.test("Closing Menu")
        }
        sleep(1 * config.delayMultiplier)
        
    }
    
    func itemHasDelete(_ screenshot: XCUIScreenshot, x: Int, y: Int) -> Bool {
        
        
        return screenshot.rgbAtLocation(
            pos: (x: x, y: y),
            min: (red: 0.50, green: 0.50, blue: 0.50),
            max: (red: 0.75, green: 0.80, blue: 0.75)
        )
    }
    
    func itemIsGift(_ screenshot: XCUIScreenshot, x: Int, y: Int) -> Bool {
        return screenshot.rgbAtLocation(
            pos: (x: x, y: y),
            min: (red: 0.6, green: 0.05, blue: 0.5),
            max: (red: 0.7, green: 0.15, blue: 0.6)
        )
    }

    func itemIsEgg(_ screenshot: XCUIScreenshot, x: Int, y: Int) -> Bool {
        return screenshot.rgbAtLocation(
            pos: (x: x, y: y),
            min: (red: 0.45, green: 0.6, blue: 0.65),
            max: (red: 0.60, green: 0.7, blue: 0.75)
        )
    }

    func itemIsEggActive(_ screenshot: XCUIScreenshot, x: Int, y: Int) -> Bool {
        return screenshot.rgbAtLocation(
            pos: (x: x, y: y),
            min: (red: 0.8, green: 0.88, blue: 0.87),
            max: (red: 0.9, green: 0.93, blue: 0.93)
        )
    }
    
    func prepareEncounter() -> Bool {
        
        let start = Date()
        while UInt32(Date().timeIntervalSince(start)) <= (config.encounterMaxWait * config.delayMultiplier) {
            /////// ultra iv we just stand at location for a few ///////////
            if self.config.ultraIV {
                usleep(700000)
                return true
            //////// no ultra we do some more compicated stuff ////////
            } else if !self.config.ultraIV {
                self.freeScreen(run: false)
                
                let screenshot = XCUIScreen.main.screenshot()
                if screenshot.rgbAtLocation(
                    pos: deviceConfig.encounterPokemonRun,
                    min: (red: 0.98, green: 0.98, blue: 0.98),
                    max: (red: 1.00, green: 1.00, blue: 1.00)) &&
                   screenshot.rgbAtLocation(
                    pos: deviceConfig.encounterPokeball,
                    min: (red: 0.70, green: 0.05, blue: 0.05),
                    max: (red: 0.95, green: 0.30, blue: 0.35)) {
                    deviceConfig.encounterPokemonRun.toXCUICoordinate(app: app).tap()
                    return true
                }
                usleep(100000)
            }
        }
        return false
        
    }
    
}

extension String {
    
    func toBool() -> Bool? {
        if self == "1" {
            return true
        }
        return Bool(self)
    }
    
    func toInt() -> Int? {
        return Int(self)
    }
    
    func toUInt32() -> UInt32? {
        return UInt32(self)
    }
    
    func toDouble() -> Double? {
        return Double(self)
    }
    
}
