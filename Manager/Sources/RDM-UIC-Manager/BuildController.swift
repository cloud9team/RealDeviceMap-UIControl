//
//  BuildController.swift
//  RDM-UIC-Manager
//
//  Created by Florian Kostenzer on 28.11.18.
//

import Foundation
import PerfectLib
import PerfectThread

class BuildController {
    
    public static var global = BuildController()
    
    private var devicesLock = Threading.Lock()
    private var devicesToRemove = [Device]()
    private var devicesToAdd = [Device]()
    
    private var managerQueue: ThreadQueue!
    
    private var activeDeviceLock = Threading.Lock()
    private var activeDevices = [Device]()
    
    private var path: String = ""
    private var derivedDataPath: String = ""
    private var timeout: Int = 60
    
    private var maxSimultaneousBuilds: Int!
    private var buildLock = Threading.Lock()
    private var buildingCount = 0
    
    private var statuse = [String: String]()
    private var statusf = [String: Int]()
    private var statusLock = Threading.Lock()

    private func setStatus(uuid: String, dateStarted: Int, status: String) {
        statusLock.lock()
        statuse[uuid] = status
        statusf[uuid] = dateStarted
        statusLock.unlock()
    }
    
    public func getTime(uuid: String) -> Int? {
        statusLock.lock()
        let dateStarted = statusf[uuid]
        statusLock.unlock()
        return dateStarted
    }
    public func getStatus(uuid: String) -> String? {
        statusLock.lock()
        let status = statuse[uuid]
        statusLock.unlock()
        return status
    }
    public func start(path: String, derivedDataPath: String, timeout: Int, maxSimultaneousBuilds: Int) {
        
        self.path = path
        self.timeout = timeout
        self.maxSimultaneousBuilds = maxSimultaneousBuilds
        self.derivedDataPath = derivedDataPath
        
        print("[INFO] Preparing DerivedDataPath")
        let derivedDataDir = Dir(derivedDataPath)
        if derivedDataDir.exists {
            try? derivedDataDir.forEachEntry { (name) in
                let dir = Dir(derivedDataDir.path + name)
                if dir.exists && dir.name != "Template" {
                    let command = Shell("rm", "-rf", dir.path)
                    _ = command.run(wait: true)
                }
            }
        }
        
        print("[INFO] Building Project...")
        Log.info(message: "Building Project...")
        let xcodebuild = Shell("xcodebuild", "build-for-testing", "-workspace", "\(path)/RealDeviceMap-UIControl.xcworkspace", "-scheme", "RealDeviceMap-UIControl", "-destination", "generic/platform=iOS", "-derivedDataPath", "\(derivedDataDir.path)/Template")
        // gets stuck here -->
        let errorPipe = Pipe()
        let outputPipe = Pipe()
        _ = xcodebuild.run(outputPipe: outputPipe, errorPipe: errorPipe)
        let error = String(data: errorPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        let output = String(data: outputPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""

        if error.trimmingCharacters(in: .whitespacesAndNewlines) != "" {
            
            for line in error.components(separatedBy: "\n") {
                let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmed != "" && !trimmed.contains(string: "Using the first of multiple matching destinations") && !trimmed.contains(string: "Generic iOS Device") && !trimmed.contains(string: "DTDeviceKit: deviceType from") {
                    Log.debug(message: "Abort triggered by line: \"\(trimmed)\"")
                    Log.terminal(message: "Building Project Failed!\n\(output)\n\(error)")
                }
            }
            
        }
        print("[INFO] Building Project done")
        Log.info(message: "Building Project done")
        
        let derivedDataLogsDir = Dir("\(derivedDataDir.path)/Template/Logs")
        if derivedDataLogsDir.exists {
            let command = Shell("rm", "-rf", derivedDataLogsDir.path)
            _ = command.run(wait: true)
        }
        
        devicesLock.lock()
        devicesToAdd = Device.getAll()
        devicesLock.unlock()
        managerQueue = Threading.getQueue(name: "BuildController-Manager", type: .serial)
        managerQueue.dispatch(managerQueueRun)
    }
    
    public func addDevice(device: Device) {
        devicesLock.lock()
        devicesToAdd.append(device)
        devicesLock.unlock()
    }
    
    public func removeDevice(device: Device) {
        devicesLock.lock()
        devicesToRemove.append(device)
        devicesLock.unlock()
    }
    
    private func managerQueueRun() {
        while true {
            devicesLock.lock()
            let devicesToAdd = self.devicesToAdd
            let devicesToRemove = self.devicesToRemove
            self.devicesToAdd = [Device]()
            self.devicesToRemove = [Device]()
            devicesLock.unlock()
            
            for device in devicesToRemove {
                let queue = Threading.getQueue(name: "BuildController-\(device.uuid)", type: .serial)
                activeDeviceLock.lock()
                if let index = activeDevices.index(of: device) {
                    activeDevices.remove(at: index)
                }
                activeDeviceLock.unlock()
                let derivedDataDir = Dir(self.derivedDataPath + "/\(device.uuid)")
                if derivedDataDir.exists {
                    let command = Shell("rm", "-rf", derivedDataDir.path)
                    _ = command.run(wait: true)
                }
                
                Threading.destroyQueue(queue)
            }
            
            for device in devicesToAdd {
                if device.enabled == 0 {
                    let disabledtimestamp = Int(Date().timeIntervalSince1970)
                    self.setStatus(uuid: device.uuid, dateStarted: disabledtimestamp, status: "Disabled")
                    continue
                }
                
                let queue = Threading.getQueue(name: "BuildController-\(device.uuid)", type: .serial)
                activeDeviceLock.lock()
                activeDevices.append(device)
                activeDeviceLock.unlock()
                let derivedDataTemplateDir = self.derivedDataPath + "/Template/."
                let derivedDataDir = File(self.derivedDataPath + "/\(device.uuid)/")
                if derivedDataDir.exists {
                    let command = Shell("rm", "-rf", derivedDataDir.path)
                    _ = command.run(wait: true)
                }
                let command = Shell("cp", "-a", derivedDataTemplateDir, derivedDataDir.path)
                _ = command.run(wait: true)
                
                queue.dispatch {
                    self.deviceQueueRun(device: device)
                }
            }
            
            Threading.sleep(seconds: 1)
        }
    }
    
    private func deviceQueueRun(device: Device) {
        
        Log.info(message: "Starting \(device.name)'s Manager")
        
        let derivedDataPath = self.derivedDataPath + "/" + device.uuid
        
        let xcodebuild = Shell("xcodebuild", "test-without-building", "-workspace", "\(path)/RealDeviceMap-UIControl.xcworkspace", "-scheme", "RealDeviceMap-UIControl", "-destination", "id=\(device.uuid)", "-destination-timeout", "\(timeout * device.delayMultiplier)", "-derivedDataPath", derivedDataPath,
            "name=\(device.name)", "enabled=\(device.enabled)", "token=\(device.token)", "backendURL=\(device.backendURL)", "enableAccountManager=\(device.enableAccountManager)", "port=\(device.port)", "pokemonMaxTime=\(device.pokemonMaxTime)", "raidMaxTime=\(device.raidMaxTime)", "maxWarningTimeRaid=\(device.maxWarningTimeRaid)", "delayMultiplier=\(device.delayMultiplier)", "jitterValue=\(device.jitterValue)", "targetMaxDistance=\(device.targetMaxDistance)", "itemFullCount=\(device.itemFullCount)", "questFullCount=\(device.questFullCount)", "itemsPerStop=\(device.itemsPerStop)", "minDelayLogout=\(device.minDelayLogout)", "maxNoQuestCount=\(device.maxNoQuestCount)", "maxFailedCount=\(device.maxFailedCount)", "maxEmptyGMO=\(device.maxEmptyGMO)", "startupLocationLat=\(device.startupLocationLat)", "startupLocationLon=\(device.startupLocationLon)", "encounterMaxWait=\(device.encounterMaxWait)", "encounterDelay=\(device.encounterDelay)", "fastIV=\(device.fastIV)", "ultraIV=\(device.ultraIV)", "ultraQuests=\(device.ultraQuests)", "deployEggs=\(device.deployEggs)"
        )

        var contains = true
        
        let lastChangedLock = Threading.Lock()
        var lastChanged: Date?
        
        var task: Process?
        let xcodebuildQueue = Threading.getQueue(name: "BuildController-\(device.uuid)-runner", type: .serial)
        xcodebuildQueue.dispatch {
            
            var locked = false
            
            while contains {
                let outputPipe = Pipe()
                let errorPipe = Pipe()
            
                Log.debug(message: "[\(device.name)] Waiting for build lock...")
                let buildtimestamp = Int(Date().timeIntervalSince1970)
                self.setStatus(uuid: device.uuid, dateStarted: buildtimestamp, status: "Waiting for build")
                locked = true
                self.buildLock.lock()
                while self.buildingCount >= self.maxSimultaneousBuilds {
                    self.buildLock.unlock()
                    Threading.sleep(seconds: 1)
                    self.buildLock.lock()
                }
                self.buildingCount += 1
                self.buildLock.unlock()
                lastChangedLock.lock()
                lastChanged = Date()
                lastChangedLock.unlock()
            
                Log.info(message: "[\(device.name)] Starting xcodebuild")
                let timestamp = Int(Date().timeIntervalSince1970)
                self.setStatus(uuid: device.uuid, dateStarted: timestamp, status: "Building")
            
               
                let fullLog = FileLogger(file: "./logs/\(device.name)-\(timestamp)-xcodebuild.full.log")
                let debugLog = FileLogger(file: "./logs/\(device.name)-\(timestamp)-xcodebuild.debug.log")
            
                task = xcodebuild.run(outputPipe: outputPipe, errorPipe: errorPipe)

                outputPipe.fileHandleForReading.readabilityHandler = { fileHandle in
                    let string = String(data: fileHandle.availableData, encoding: .utf8)
                    if string != nil && string!.trimmingCharacters(in: .whitespacesAndNewlines) != "" {
                        var stringSplit = string!.components(separatedBy: "\n")
                        let statusUpdate = stringSplit[0]
                        
                        if string!.contains(string: "[STATUS] Started") && locked {
                            Log.debug(message: "[\(device.name)] Done building")
                            self.setStatus(uuid: device.uuid, dateStarted: timestamp, status: "Running: Starting")
                            locked = false
                            self.buildLock.lock()
                            self.buildingCount -= 1
                            self.buildLock.unlock()
                        }
                        if string!.contains(string: "[STATUS] Disabled") && string!.contains(string: "Logged out and") {
                            let statusUpdate = statusUpdate.replacingOccurrences(of: "[STATUS] ", with: "")
                            self.setStatus(uuid: device.uuid, dateStarted: timestamp, status: statusUpdate)
                        }
                        if string!.contains(string: "[STATUS] Startup") {
                            self.setStatus(uuid: device.uuid, dateStarted: timestamp, status: "Running: Startup")
                        }
                        if string!.contains(string: "[STATUS] Logout") {
                            self.setStatus(uuid: device.uuid, dateStarted: timestamp, status: "Running: Logout")
                        }
                        if string!.contains(string: "[STATUS] Login") {
                            self.setStatus(uuid: device.uuid, dateStarted: timestamp, status: "Running: Login")
                        }
                        if string!.contains(string: "[STATUS] Tutorial") {
                            self.setStatus(uuid: device.uuid, dateStarted: timestamp, status: "Running: Tutorial")
                        }
                        if string!.contains(string: "[STATUS] Pokemon") && string!.contains(string: "Account has") {
                                self.setStatus(uuid: device.uuid, dateStarted: timestamp, status: "Running: Pokemon - Account Warned")
                        } else if string!.contains(string: "[STATUS] Pokemon") && string!.contains(string: "Pokemon scan at") {
                            let statusUpdate = statusUpdate.replacingOccurrences(of: "[STATUS] ", with: "")
                            self.setStatus(uuid: device.uuid, dateStarted: timestamp, status: statusUpdate)
                        } else {
                            if string!.contains(string: "[STATUS] Pokemon") {
                                self.setStatus(uuid: device.uuid, dateStarted: timestamp, status: "Running: Pokemon")
                            }
                        }
                        if string!.contains(string: "[STATUS] Raid") && string!.contains(string: "Account has") {
                            self.setStatus(uuid: device.uuid, dateStarted: timestamp, status: "Running: Raid - Account Warned")
                        } else if string!.contains(string: "[STATUS] Raid") && string!.contains(string: "Raid scan at") {
                            let statusUpdate = statusUpdate.replacingOccurrences(of: "[STATUS] ", with: "")
                            self.setStatus(uuid: device.uuid, dateStarted: timestamp, status: statusUpdate)
                        } else {
                            if string!.contains(string: "[STATUS] Raid") {
                                self.setStatus(uuid: device.uuid, dateStarted: timestamp, status: "Running: Raid")
                            }
                        }
                        if string!.contains(string: "[STATUS] Quest") && string!.contains(string: "Account has") {
                            self.setStatus(uuid: device.uuid, dateStarted: timestamp, status: "Running: Quest - Account Warned")
                        } else if string!.contains(string: "[STATUS] Quest") && string!.contains(string: "Quest at") {
                            let statusUpdate = statusUpdate.replacingOccurrences(of: "[STATUS] ", with: "")
                            self.setStatus(uuid: device.uuid, dateStarted: timestamp, status: statusUpdate)
                        } else if string!.contains(string: "[STATUS] Quest") && string!.contains(string: "Error at") {
                            let statusUpdate = statusUpdate.replacingOccurrences(of: "[STATUS] ", with: "")
                            self.setStatus(uuid: device.uuid, dateStarted: timestamp, status: statusUpdate)
                        } else {
                            if string!.contains(string: "[STATUS] Quest") {
                                self.setStatus(uuid: device.uuid, dateStarted: timestamp, status: "Running: Quest")
                            }
                        }
                        if string!.contains(string: "[STATUS] IV") && string!.contains(string: "Account has") {
                            self.setStatus(uuid: device.uuid, dateStarted: timestamp, status: "Running: IV - Account Warned")
                        } else if string!.contains(string: "[STATUS] IV") && string!.contains(string: "IV scan at") {
                            let statusUpdate = statusUpdate.replacingOccurrences(of: "[STATUS] ", with: "")
                            self.setStatus(uuid: device.uuid, dateStarted: timestamp, status: statusUpdate)
                        } else if string!.contains(string: "[STATUS] IV") && string!.contains(string: "IV - Pokemon loading") {
                            let statusUpdate = statusUpdate.replacingOccurrences(of: "[STATUS] ", with: "")
                            self.setStatus(uuid: device.uuid, dateStarted: timestamp, status: statusUpdate)
                        } else {
                            if string!.contains(string: "[STATUS] IV") {
                                self.setStatus(uuid: device.uuid, dateStarted: timestamp, status: "Running: IV")
                            }
                        }
                        if string!.contains(string: "no job left (Got result:") {
                            self.setStatus(uuid: device.uuid, dateStarted: timestamp, status: "Completed: Need Assignment")
                        }
                        if string!.contains(string: "IV Queue Empty") {
                            self.setStatus(uuid: device.uuid, dateStarted: timestamp, status: "IV Queue Empty")
                        }

            
                        fullLog.uic(message: string!, all: true)
                        debugLog.uic(message: string!, all: false)
                        lastChangedLock.lock()
                        lastChanged = Date()
                        lastChangedLock.unlock()
                    }
                }
                errorPipe.fileHandleForReading.readabilityHandler = { fileHandle in
                    let string = String(data: fileHandle.availableData, encoding: .utf8)
                    if string != nil && string!.trimmingCharacters(in: .whitespacesAndNewlines) != "" {
                        fullLog.uic(message: string!, all: true)
                        debugLog.uic(message: string!, all: false)
                        lastChangedLock.lock()
                        lastChanged = Date()
                        lastChangedLock.unlock()
                    }

                }
                task?.waitUntilExit()
                errorPipe.fileHandleForReading.closeFile()
                outputPipe.fileHandleForReading.closeFile()
                Log.debug(message: "[\(device.name)] Xcodebuild ended")
                if locked {
                    locked = false
                    self.buildLock.lock()
                    self.buildingCount -= 1
                    self.buildLock.unlock()
                }
            
                lastChangedLock.lock()
                lastChanged = nil
                lastChangedLock.unlock()
                Threading.sleep(seconds: 1.0)
            }
            task?.suspend()
        }
        
        while contains {
            
            lastChangedLock.lock()
            if task != nil && lastChanged != nil && Int(Date().timeIntervalSince(lastChanged!)) >= (timeout * device.delayMultiplier) {
                task!.terminate()
                Log.info(message: "[\(device.name)] Stopping xcodebuild. No output for over \(timeout * device.delayMultiplier)s")
            }
            lastChangedLock.unlock()
            
            Threading.sleep(seconds: 5.0)
            activeDeviceLock.lock()
            contains = activeDevices.contains(device)
            activeDeviceLock.unlock()
        }
        task?.terminate()
        Threading.destroyQueue(xcodebuildQueue)
        Log.info(message: "Stopping \(device.name)'s Manager")
    }
    
}
