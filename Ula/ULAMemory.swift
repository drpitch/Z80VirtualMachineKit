//
//  UlaMemory.swift
//  Z80VirtualMachineKit
//
//  Created by Jose Luis Fernandez-Mayoralas on 9/6/16.
//  Copyright © 2016 lomocorp. All rights reserved.
//

import Foundation

final class ULAMemory : Ram {
    let ulaDelegate: UlaDelegate
    
    init(delegate: UlaDelegate) {
        self.ulaDelegate = delegate
        super.init(base_address: 0x4000, block_size: 0x4000)
    }
    
    override func write(address: UInt16, value: UInt8) {
        super.write(address, value: value)
        ulaDelegate.memoryWrite(address, value: value)
    }
}
