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
        return self.rgbAtLocation(pos: (pos.x, pos.y))
    }
    
    func rgbAtLocation(pos: (x: Int, y: Int), min: (red: CGFloat, green: CGFloat, blue: CGFloat), max: (red: CGFloat, green: CGFloat, blue: CGFloat)) -> Bool {

        let color = self.rgbAtLocation(pos: pos)
        
        return  color.red >= min.red && color.red <= max.red &&
                color.green >= min.green && color.green <= max.green &&
                color.blue >= min.blue && color.blue <= max.blue
    }
    
    func rgbAtLocation(pos: DeviceCoordinate, min: (red: CGFloat, green: CGFloat, blue: CGFloat), max: (red: CGFloat, green: CGFloat, blue: CGFloat)) -> Bool {
        return self.rgbAtLocation(pos: (pos.x, pos.y), min: min, max: max)
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
        
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 10)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        
        let task = URLSession.shared.dataTask(with: request) {(data, response, error) in
            if let data = data {
                let resultJSON = try? JSONSerialization.jsonObject(with: data)
                resultDict = resultJSON as? [String: Any]
                if !blocking {
                    completion(resultDict)
                }
            } else {
                if !blocking {
                    completion(nil)
                }
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

        if screenshotComp.rgbAtLocation(
            pos: deviceConfig.compareWarningL,
            min: (red: 0.03, green: 0.07, blue: 0.10),
            max: (red: 0.07, green: 0.11, blue: 0.14)) &&
           screenshotComp.rgbAtLocation(
            pos: deviceConfig.compareWarningR,
            min: (red: 0.03, green: 0.07, blue: 0.10),
            max: (red: 0.07, green: 0.11, blue: 0.14)) {
            return true
        } else {
            return false
        }
        
    }
    
    func isTutorial(screenshot: XCUIScreenshot?=nil) -> Bool {
        
        let screenshotComp = screenshot ?? XCUIScreen.main.screenshot()
        
        if screenshotComp.rgbAtLocation(
            pos: deviceConfig.compareTutorialL,
            min: (red: 0.3, green: 0.5, blue: 0.6),
            max: (red: 0.4, green: 0.6, blue: 0.7)) &&
           screenshotComp.rgbAtLocation(
            pos: deviceConfig.compareWarningR,
            min: (red: 0.3, green: 0.5, blue: 0.6),
            max: (red: 0.4, green: 0.6, blue: 0.7)) {
            return true
        } else {
            return false
        }
    
    }
    
    func findAndClickPokemon(screenshot: XCUIScreenshot?=nil) -> Bool {
        
        let screenshotComp = screenshot ?? XCUIScreen.main.screenshot()
        
        let normalized = app.coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0))
        
        Log.debug("Searching Pokemon...")
        for x in 0...screenshotComp.image.cgImage!.width / 10  {
            for y in 0...screenshotComp.image.cgImage!.height / 10 {
                let color = screenshotComp.image.getPixelColor(pos: CGPoint(x: x * 10, y: y * 10))
                var red: CGFloat = 0
                var green: CGFloat = 0
                var blue: CGFloat = 0
                var alpha: CGFloat = 0
                color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
                
                if (
                    red > 0.9 &&
                        green > 0.6 && green < 0.7 &&
                        blue > 0.3 && blue < 0.4
                    ) {
                    Log.debug("Pokemon Found!")
                    normalized.withOffset(CGVector(dx: x * 10, dy: y * 10)).tap()
                    return true
                }
                
            }
        }
        Log.debug("No Pokemon Found! ")
        
        return false
    }
    
    func freeScreen(run: Bool=true) {
        
        var screenshot = XCUIScreen.main.screenshot()
        screenshot = clickPassengerWarning()
        
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
        
        if screenshot.rgbAtLocation(
            pos: deviceConfig.weather,
            min: (red: 0.23, green: 0.35, blue: 0.50),
            max: (red: 0.36, green: 0.47, blue: 0.65)
        ) {
            deviceConfig.closeWeather1.toXCUICoordinate(app: app).tap()
            sleep(1 * config.delayMultiplier)
            deviceConfig.closeWeather2.toXCUICoordinate(app: app).tap()
            sleep(1 * config.delayMultiplier)
            screenshot = XCUIScreen.main.screenshot()
            screenshot = clickPassengerWarning()
            sleep(1 * config.delayMultiplier)
        }
        
        if run && screenshot.rgbAtLocation(
            pos: deviceConfig.encounterPokemonRun,
            min: (red: 0.98, green: 0.98, blue: 0.98),
            max: (red: 1.00, green: 1.00, blue: 1.00)
        ) {
            deviceConfig.encounterPokemonRun.toXCUICoordinate(app: app).tap()
            sleep(1 * config.delayMultiplier)
            screenshot = XCUIScreen.main.screenshot()
            screenshot = clickPassengerWarning()
            sleep(1 * config.delayMultiplier)
        }

        if run && !screenshot.rgbAtLocation(
            pos: deviceConfig.closeMenu,
            min: (red: 0.98, green: 0.98, blue: 0.98),
            max: (red: 1.00, green: 1.00, blue: 1.00)) {
            deviceConfig.closeMenu.toXCUICoordinate(app: app).tap()
            sleep(1 * config.delayMultiplier)
            screenshot = XCUIScreen.main.screenshot()
            screenshot = clickPassengerWarning()
            sleep(1 * config.delayMultiplier)
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
        
        let normalized = app.coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0))
        
        deviceConfig.closeMenu.toXCUICoordinate(app: app).tap()
        sleep(2 * config.delayMultiplier)
        deviceConfig.settingsButton.toXCUICoordinate(app: app).tap()
        sleep(2 * config.delayMultiplier)
        deviceConfig.logoutDragStart.toXCUICoordinate(app: app).press(forDuration: 0.1, thenDragTo: deviceConfig.logoutDragEnd.toXCUICoordinate(app: app))
        sleep(2 * config.delayMultiplier)
        
        let screenshot = XCUIScreen.main.screenshot()
        for y in 0...screenshot.image.cgImage!.height / 10 {
            if screenshot.rgbAtLocation(
                pos: (x: deviceConfig.logoutCompareX, y: y * 10),
                min: (red: 0.60, green: 0.9, blue: 0.6),
                max: (red: 0.75, green: 1.0, blue: 0.7)) {
                normalized.withOffset(CGVector(dx: deviceConfig.logoutCompareX, dy: y * 10)).tap()
                break
            }
        }
        sleep(2 * config.delayMultiplier)
        deviceConfig.logoutConfirm.toXCUICoordinate(app: app).tap()
        sleep(10 * config.delayMultiplier)
        let screenshotComp = XCUIScreen.main.screenshot()
        
        if screenshotComp.rgbAtLocation(
            pos: deviceConfig.startupLoggedOut,
            min: (0.95, 0.75, 0.0),
            max: (1.00, 0.85, 0.1)
        ) {
            Log.debug("Logged out sucesfully")
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
    }
    
    func clearQuest() {
        deviceConfig.openQuest.toXCUICoordinate(app: app).tap()
        sleep(1 * config.delayMultiplier)
        app.swipeRight()
        sleep(1 * config.delayMultiplier)
    
        for _ in 0...2 {
            deviceConfig.questDelete.toXCUICoordinate(app: app).tap()
            sleep(1 * config.delayMultiplier)
            deviceConfig.questDeleteConfirm.toXCUICoordinate(app: app).tap()
            sleep(1 * config.delayMultiplier)
        }

        deviceConfig.closeMenu.toXCUICoordinate(app: app).tap()
        sleep(1 * config.delayMultiplier)
    }
    
    func clearItems() {
        
        let normalized = app.coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0))
        var index = 0
        var done = false
        
        deviceConfig.closeMenu.toXCUICoordinate(app: app).tap()
        sleep(1 * config.delayMultiplier)
        deviceConfig.openItems.toXCUICoordinate(app: app).tap()
        sleep(1 * config.delayMultiplier)

        while !done && deviceConfig.itemDeleteYs.count != 0 {
            let screenshot = XCUIScreen.main.screenshot()
            
            if itemHasDelete(screenshot, x: deviceConfig.itemDeleteX, y: deviceConfig.itemDeleteYs[index]) && !itemIsGift(screenshot, x: deviceConfig.itemGiftX, y: deviceConfig.itemDeleteYs[index]) {
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
        
        deviceConfig.closeMenu.toXCUICoordinate(app: app).tap()
        sleep(1 * config.delayMultiplier)
    }
    
    func itemHasDelete(_ screenshot: XCUIScreenshot, x: Int, y: Int) -> Bool {
        
        
        return screenshot.rgbAtLocation(
            pos: (x: x, y: y),
            min: (red: 0.50, green: 0.50, blue: 0.50),
            max: (red: 0.75, green: 0.75, blue: 0.75)
        )
    }
    
    func itemIsGift(_ screenshot: XCUIScreenshot, x: Int, y: Int) -> Bool {
        return screenshot.rgbAtLocation(
            pos: (x: x, y: y),
            min: (red: 0.6, green: 0.05, blue: 0.5),
            max: (red: 0.7, green: 0.15, blue: 0.6)
        )
    }

    func prepareEncounter() -> Bool {
        
        let start = Date()
        while UInt32(Date().timeIntervalSince(start)) <= (config.encoutnerMaxWait * config.delayMultiplier) {
            
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
        return false
        
    }
    
}
