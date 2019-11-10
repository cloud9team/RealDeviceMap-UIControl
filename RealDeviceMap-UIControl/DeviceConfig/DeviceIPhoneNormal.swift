//
//  DeviceIPhoneNormal.swift
//  RealDeviceMap-UIControlUITests
//
//  Created by Florian Kostenzer on 19.11.18.
//

import Foundation

class DeviceIPhoneNormal: DeviceRatio1775 {

    
    // All values not overriden here default to DeviceRatio1775s values
    override var startup: DeviceCoordinate {
        return DeviceCoordinate(x: 325, y: 960)
    }
   /* override var cautionButton: DeviceCoordinate {
            return DeviceCoordinate(x: 205, y: 986)
    }
    override var twothreelineButton: DeviceCoordinate {
            return DeviceCoordinate(x: 224, y: 761)
    } */
    
    
    override var encounterNoARConfirm: DeviceCoordinate {  //no AR popup after saying no on iPhone6
        return DeviceCoordinate(x: 0, y: 0)
    }
    override var encounterTmp: DeviceCoordinate {
        return DeviceCoordinate(x: 0, y: 0)
    }
    
   
    
    
    
    // MARK: - Item Clearing
    
    override var itemDeleteIncrease: DeviceCoordinate {
        return DeviceCoordinate(x: 540, y: 573)
    }
    override var itemDeleteConfirm: DeviceCoordinate {
        return DeviceCoordinate(x: 320, y: 826)
    }
    override var itemDeleteX: Int {
        return 686
    }
    override var itemGiftX: Int {
        return 156
    }
    override var itemEggX: Int {
        return 173
    }
    override var itemDeleteYs: [Int] {
        return [
            252,
            516,
            785,
            1053,
            1315
        ]
    }
    
}
