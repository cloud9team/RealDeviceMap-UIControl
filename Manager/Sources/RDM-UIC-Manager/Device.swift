//
//  DeviceConfig.swift
//  RDM-UIC-Manager
//
//  Created by Florian Kostenzer on 27.11.18.
//

import Foundation
import StORM
import SQLiteStORM
import PerfectLib

class Device: SQLiteStORM, Equatable, Hashable {

    #if swift(>=4.2)
    public func hash(into hasher: inout Hasher) {
        hasher.combine(uuid)
    }
    #else
    public var hashValue: Int {
        return uuid.hashValue
    }
    #endif
    
    var uuid: String
    var name: String
    var enabled: Int
    var token: String
    var backendURL: String
    var enableAccountManager: Int
    var port: Int
    var pokemonMaxTime: Double
    var raidMaxTime: Double
    var maxWarningTimeRaid: Int
    var delayMultiplier: Int
    var jitterValue: Double
    var targetMaxDistance: Double
    var itemFullCount: Int
    var questFullCount: Int
    var itemsPerStop: Int
    var minDelayLogout: Double
    var maxNoQuestCount: Int
    var maxFailedCount: Int
    var maxEmptyGMO: Int
    var startupLocationLat: Double
    var startupLocationLon: Double
    var encounterMaxWait: Int
    var encounterDelay: Double
    var fastIV: Int
    var ultraIV: Int
    var ultraQuests: Int
    var deployEggs: Int

    
    override init() {
        self.uuid = ""
        self.name = ""
        self.enabled = 1
        self.token = ""
        self.backendURL = ""
        self.enableAccountManager = 0
        self.port = 8080
        self.pokemonMaxTime = 25.0
        self.raidMaxTime = 25.0
        self.maxWarningTimeRaid = 432000
        self.delayMultiplier = 1
        self.jitterValue = 0.00005
        self.targetMaxDistance = 250.0
        self.itemFullCount = 250
        self.questFullCount = 3
        self.itemsPerStop = 10
        self.minDelayLogout = 180
        self.maxNoQuestCount = 5
        self.maxFailedCount = 20
        self.maxEmptyGMO = 50
        self.startupLocationLat = 35.914067
        self.startupLocationLon = -5.418532
        self.encounterMaxWait = 7
        self.encounterDelay = 1.0
        self.fastIV = 0
        self.ultraIV = 1
        self.ultraQuests = 1
        self.deployEggs = 1
        
        super.init()
    }
    
    init(uuid: String, name: String, enabled: Int, token: String, backendURL: String, enableAccountManager: Int, port: Int, pokemonMaxTime: Double, raidMaxTime: Double, maxWarningTimeRaid: Int, delayMultiplier: Int, jitterValue: Double, targetMaxDistance: Double, itemFullCount: Int, questFullCount: Int, itemsPerStop: Int, minDelayLogout: Double, maxNoQuestCount: Int, maxFailedCount: Int, maxEmptyGMO: Int, startupLocationLat: Double, startupLocationLon: Double, encounterMaxWait: Int, encounterDelay: Double, fastIV: Int, ultraIV: Int, ultraQuests: Int, deployEggs: Int) {
        self.uuid = uuid
        self.name = name
        self.enabled = enabled
        self.token = token
        self.backendURL = backendURL
        self.enableAccountManager = enableAccountManager
        self.port = port
        self.pokemonMaxTime = pokemonMaxTime
        self.raidMaxTime = raidMaxTime
        self.maxWarningTimeRaid = maxWarningTimeRaid
        self.delayMultiplier = delayMultiplier
        self.jitterValue = jitterValue
        self.targetMaxDistance = targetMaxDistance
        self.itemFullCount = itemFullCount
        self.questFullCount = questFullCount
        self.itemsPerStop = itemsPerStop
        self.minDelayLogout = minDelayLogout
        self.maxNoQuestCount = maxNoQuestCount
        self.maxFailedCount = maxFailedCount
        self.maxEmptyGMO = maxEmptyGMO
        self.startupLocationLat = startupLocationLat
        self.startupLocationLon = startupLocationLon
        self.encounterMaxWait = encounterMaxWait
        self.encounterDelay = encounterDelay
        self.fastIV = fastIV
        self.ultraIV = ultraIV
        self.ultraQuests = ultraQuests
        self.deployEggs = deployEggs
        
        super.init()
    }
    
    override open func table() -> String {
        return "device"
    }
    
    override func to(_ this: StORMRow) {
        uuid = this.data["uuid"] as? String ?? ""
        name = this.data["name"] as? String ?? ""
        enabled = this.data["enabled"] as? Int ?? 1
        token = this.data["token"] as? String ?? ""
        backendURL = this.data["backendURL"] as? String ?? ""
        enableAccountManager = this.data["enableAccountManager"] as? Int ?? 0
        port = this.data["port"] as? Int ?? 8080
        pokemonMaxTime = this.data["pokemonMaxTime"] as? Double ?? 25.0
        raidMaxTime = this.data["raidMaxTime"] as? Double ?? 25.0
        maxWarningTimeRaid = this.data["maxWarningTimeRaid"] as? Int ?? 432000
        delayMultiplier = this.data["delayMultiplier"] as? Int ?? 1
        jitterValue = this.data["jitterValue"] as? Double ?? 0.00005
        targetMaxDistance = this.data["targetMaxDistance"] as? Double ?? 250.0
        itemFullCount = this.data["itemFullCount"] as? Int ?? 250
        questFullCount = this.data["questFullCount"] as? Int ?? 3
        itemsPerStop = this.data["itemsPerStop"] as? Int ?? 10
        minDelayLogout = this.data["minDelayLogout"] as? Double ?? 180
        maxNoQuestCount = this.data["maxNoQuestCount"] as? Int ?? 5
        maxFailedCount = this.data["maxFailedCount"] as? Int ?? 20
        maxEmptyGMO = this.data["maxEmptyGMO"] as? Int ?? 50
        startupLocationLat = this.data["startupLocationLat"] as? Double ?? 1
        startupLocationLon = this.data["startupLocationLon"] as? Double ?? 1
        encounterMaxWait = this.data["encounterMaxWait"] as? Int ?? 7
        encounterDelay = this.data["encounterDelay"] as? Double ?? 1.0
        fastIV = this.data["fastIV"] as? Int ?? 0
        ultraIV = this.data["ultraIV"] as? Int ?? 1
        ultraQuests = this.data["ultraQuests"] as? Int ?? 1
        deployEggs = this.data["deployEggs"] as? Int ?? 1

    }
    
    static func getAll() -> [Device] {
        let work = Device()
        do {
            try work.findAll()
        } catch {
            return [Device]()
        }
        var rows = [Device]()
        for i in 0..<work.results.rows.count {
            let row = Device()
            row.to(work.results.rows[i])
            if row.uuid != "default" {
                rows.append(row)
            }
        }
        rows.sort { (lhs, rhs) -> Bool in
            return lhs.name < rhs.name
        }
        return rows
    }
    
    static func get(uuid: String) -> Device? {
        let work = Device()
        do {
            try work.find(["uuid": uuid])
        } catch {
            return nil
        }
        if work.results.rows.isEmpty {
            return nil
        }
        let row = Device()
        row.to(work.results.rows[0])
        return row
    }
    
    static func == (lhs: Device, rhs: Device) -> Bool {
        return lhs.uuid == rhs.uuid
    }
        
    override func setup() throws {
        try super.setup()
        
        var hasEnabled = false
        var hasToken = false
        var hasFastIV = false
        var hasUltraIV = false
        var hasUltraQuests = false
        var hasDeployEggs = false
        var hasEncounterMaxWait = false
        var hasEncounterDelay = false
        
        
        let rows = try sqlRows("PRAGMA table_info(\(table()))", params: [String]())
        for row in rows {
            let name = row.data["name"] as! String

            if name == "enabled" {
                hasEnabled = true
            } else if name == "token" {
                hasToken = true
            } else if name == "fastIV" {
                hasFastIV = true
            } else if name == "ultraIV" {
                hasUltraIV = true
            } else if name == "ultraQuests" {
                hasUltraQuests = true
            } else if name == "deployEggs" {
                hasDeployEggs = true
            } else if name == "encounterMaxWait" {
                hasEncounterMaxWait = true
            } else if name == "encounterDelay" {
                hasEncounterDelay = true
            }
        }
        
        
        if !hasEnabled {
            try sqlExec("ALTER TABLE \(table()) ADD COLUMN enabled INTEGER DEFAULT 1")
        }
        if !hasToken {
            try sqlExec("ALTER TABLE \(table()) ADD COLUMN token STRING DEFAULT NULL")
        }
        if !hasFastIV {
            try sqlExec("ALTER TABLE \(table()) ADD COLUMN fastIV INTEGER DEFAULT 0")
        }
        if !hasUltraIV {
            try sqlExec("ALTER TABLE \(table()) ADD COLUMN ultraIV INTEGER DEFAULT 0")
        }
        if !hasUltraQuests {
            try sqlExec("ALTER TABLE \(table()) ADD COLUMN ultraQuests INTEGER DEFAULT 0")
        }
        if !hasDeployEggs {
            try sqlExec("ALTER TABLE \(table()) ADD COLUMN deployEggs INTEGER DEFAULT 0")
        }
        if !hasEncounterMaxWait {
            try sqlExec("ALTER TABLE \(table()) ADD COLUMN encounterMaxWait INTEGER DEFAULT 7")
        }
        if !hasEncounterDelay {
            try sqlExec("ALTER TABLE \(table()) ADD COLUMN encounterDelay DOUBLE DEFAULT 1.0")
        }
        
    }
    
}
