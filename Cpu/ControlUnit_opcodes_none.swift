//
//  cu_opcodes_none.swift
//  z80
//
//  Created by Jose Luis Fernandez-Mayoralas on 15/12/15.
//  Copyright © 2015 lomocorp. All rights reserved.
//

import Foundation

extension ControlUnit {
    func initOpcodeTableNONE(inout opcodes: OpcodeTable) {
        opcodes[0x00] = { // NOP
            return
        }
        opcodes[0x01] = { // LD BC,&0000
            switch self.m_cycle {
            case 1:
                self.machine_cycle = .MemoryRead
                self.pins.address_bus = self.regs.pc
                self.regs.pc++
            case 2:
                self.regs.c = self.pins.data_bus
                self.pins.address_bus = self.regs.pc
                self.regs.pc++
            default:
                self.regs.b = self.pins.data_bus
                self.machine_cycle = .OpcodeFetch
            }
        }
        opcodes[0x02] = { // LD (BC),A
            switch self.m_cycle {
            case 1:
                self.pins.address_bus = self.addressFromPair(self.regs.b, self.regs.c)
                self.pins.data_bus = self.regs.a
                self.machine_cycle = .MemoryWrite
            default:
                self.machine_cycle = .OpcodeFetch
            }
        }
        opcodes[0x03] = { // INC BC
            self.machine_cycle = .TimeWait
            
            if self.t_cycle == 6 {
                self.regs.c = self.regs.c &+ 1
                self.regs.b = self.regs.c == 0 ? self.regs.b &+ 1 : self.regs.b
                self.machine_cycle = .OpcodeFetch
            }
        }
        opcodes[0x04] = { // INC B
            self.regs.b = self.ulaCall(self.regs.b, 1, ulaOp: .Add, ignoreCarry: true)
        }
        opcodes[0x05] = { // DEC B
            self.regs.b = self.ulaCall(self.regs.b, 1, ulaOp: .Sub, ignoreCarry: true)
        }
        opcodes[0x06] = { // LD B,N
            switch self.m_cycle {
            case 1:
                self.machine_cycle = .MemoryRead
                self.pins.address_bus = self.regs.pc
                self.regs.pc++
            default:
                self.regs.b = self.pins.data_bus
                self.machine_cycle = .OpcodeFetch
            }
        }
        opcodes[0x07] = { // RLCA
            let PV_backup = self.regs.f.bit(PV)
            let S_backup = self.regs.f.bit(S)
            let Z_backup = self.regs.f.bit(Z)
            self.regs.a = self.ulaCall(self.regs.a, 1, ulaOp: .Rlc, ignoreCarry: false)
            self.regs.f.bit(PV, newVal: PV_backup)
            self.regs.f.bit(S, newVal: S_backup)
            self.regs.f.bit(Z, newVal: Z_backup)
        }
        opcodes[0x08] = { // EX AF,AF'
            let a_ = self.regs.a_
            let f_ = self.regs.f_
            self.regs.a_ = self.regs.a
            self.regs.f_ = self.regs.f
            self.regs.a = a_
            self.regs.f = f_
        }
        opcodes[0x09] = { // ADD HL,BC
            switch self.m_cycle {
            case 1:
                self.machine_cycle = .UlaOperation
            case 2:
                self.machine_cycle = .TimeWait
                if self.t_cycle == 4 {
                    self.machine_cycle = .UlaOperation
                }
            default:
                self.machine_cycle = .TimeWait
                if self.t_cycle == 3 {
                    let hl = self.addressFromPair(self.regs.h, self.regs.l)
                    let bc = self.addressFromPair(self.regs.b, self.regs.c)
                    let result = self.ulaCall16(hl, bc, ulaOp: .Add)
                    self.regs.h = result.high
                    self.regs.l = result.low
                    self.machine_cycle = .OpcodeFetch
                }
            }
        }
        opcodes[0x0A] = { // LD A,(BC)
            switch self.m_cycle {
            case 1:
                self.pins.address_bus = self.addressFromPair(self.regs.b, self.regs.c)
                self.machine_cycle = .MemoryRead
            default:
                self.regs.a = self.pins.data_bus
                self.machine_cycle = .OpcodeFetch
            }
        }
        opcodes[0x0B] = { // DEC BC
            self.machine_cycle = .TimeWait
            
            if self.t_cycle == 6 {
                self.regs.c = self.regs.c &- 1
                self.regs.b = self.regs.c == 0xFF ? self.regs.b &- 1 : self.regs.b
                self.machine_cycle = .OpcodeFetch
            }
        }
        opcodes[0x0C] = { // INC C
            self.regs.c = self.ulaCall(self.regs.c, 1, ulaOp: .Add, ignoreCarry: true)
        }
        opcodes[0x0D] = { // DEC C
            self.regs.c = self.ulaCall(self.regs.c, 1, ulaOp: .Sub, ignoreCarry: true)
        }
        opcodes[0x0E] = { // LD C,N
            switch self.m_cycle {
            case 1:
                self.machine_cycle = .MemoryRead
                self.pins.address_bus = self.regs.pc
                self.regs.pc++
            default:
                self.regs.c = self.pins.data_bus
                self.machine_cycle = .OpcodeFetch
            }
        }
        opcodes[0x0F] = { // RRCA
            let PV_backup = self.regs.f.bit(PV)
            let S_backup = self.regs.f.bit(S)
            let Z_backup = self.regs.f.bit(Z)
            self.regs.a = self.ulaCall(self.regs.a, 1, ulaOp: .Rrc, ignoreCarry: false)
            self.regs.f.bit(PV, newVal: PV_backup)
            self.regs.f.bit(S, newVal: S_backup)
            self.regs.f.bit(Z, newVal: Z_backup)

        }
        opcodes[0x10] = { // DJNZ N
            switch self.m_cycle {
            case 1:
                self.machine_cycle = .TimeWait
                if self.t_cycle == 5 {
                    self.machine_cycle = .MemoryRead
                    self.pins.address_bus = self.regs.pc
                    self.regs.pc++
                }
            case 2:
                self.control_reg = self.pins.data_bus // preserve data bus
                self.regs.b--
                if self.regs.b == 0 {
                    self.machine_cycle = .OpcodeFetch
                } else {
                    self.machine_cycle = .UlaOperation
                }
            default:
                self.machine_cycle = .TimeWait
                if self.t_cycle == 5 {
                    self.regs.pc = UInt16(Int(self.regs.pc) + Int(self.control_reg.comp2))
                    self.machine_cycle = .OpcodeFetch
                }
            }
        }
        opcodes[0x11] = { // LD DE,&0000
            switch self.m_cycle {
            case 1:
                self.machine_cycle = .MemoryRead
                self.pins.address_bus = self.regs.pc
                self.regs.pc++
            case 2:
                self.regs.e = self.pins.data_bus
                self.pins.address_bus = self.regs.pc
                self.regs.pc++
            default:
                self.regs.d = self.pins.data_bus
                self.machine_cycle = .OpcodeFetch
            }
        }
        opcodes[0x12] = { // LD (DE),A
            switch self.m_cycle {
            case 1:
                self.pins.address_bus = self.addressFromPair(self.regs.d, self.regs.e)
                self.pins.data_bus = self.regs.a
                self.machine_cycle = .MemoryWrite
            default:
                self.machine_cycle = .OpcodeFetch
            }
        }
        opcodes[0x13] = { // INC DE
            self.machine_cycle = .TimeWait
            
            if self.t_cycle == 6 {
                self.regs.e = self.regs.e &+ 1
                self.regs.d = self.regs.e == 0 ? self.regs.d &+ 1 : self.regs.d
                self.machine_cycle = .OpcodeFetch
            }
        }
        opcodes[0x14] = { // INC D
            self.regs.d = self.ulaCall(self.regs.d, 1, ulaOp: .Add, ignoreCarry: true)
        }
        opcodes[0x15] = { // DEC D
            self.regs.d = self.ulaCall(self.regs.d, 1, ulaOp: .Sub, ignoreCarry: true)
        }
        opcodes[0x16] = { // LD D,&00
            switch self.m_cycle {
            case 1:
                self.machine_cycle = .MemoryRead
                self.pins.address_bus = self.regs.pc
                self.regs.pc++
            default:
                self.regs.d = self.pins.data_bus
                self.machine_cycle = .OpcodeFetch
            }
        }
        opcodes[0x17] = { // RLA
            let PV_backup = self.regs.f.bit(PV)
            let S_backup = self.regs.f.bit(S)
            let Z_backup = self.regs.f.bit(Z)
            self.regs.a = self.ulaCall(self.regs.a, 1, ulaOp: .Rl, ignoreCarry: false)
            self.regs.f.bit(PV, newVal: PV_backup)
            self.regs.f.bit(S, newVal: S_backup)
            self.regs.f.bit(Z, newVal: Z_backup)

        }
        opcodes[0x18] = { // JR &00
            switch self.m_cycle {
            case 1:
                self.machine_cycle = .MemoryRead
                self.pins.address_bus = self.regs.pc
                self.regs.pc++
            case 2:
                self.control_reg = self.pins.data_bus // preserve data bus
                self.machine_cycle = .UlaOperation
            default:
                self.machine_cycle = .TimeWait
                if self.t_cycle == 5 {
                    self.regs.pc = UInt16(Int(self.regs.pc) + Int(self.control_reg.comp2))
                    self.machine_cycle = .OpcodeFetch
                }
            }
        }
        opcodes[0x19] = { // ADD HL,DE
            switch self.m_cycle {
            case 1:
                self.machine_cycle = .UlaOperation
            case 2:
                self.machine_cycle = .TimeWait
                if self.t_cycle == 4 {
                    self.machine_cycle = .UlaOperation
                }
            default:
                self.machine_cycle = .TimeWait
                if self.t_cycle == 3 {
                    let hl = self.addressFromPair(self.regs.h, self.regs.l)
                    let de = self.addressFromPair(self.regs.d, self.regs.e)
                    let result = self.ulaCall16(hl, de, ulaOp: .Add)
                    self.regs.h = result.high
                    self.regs.l = result.low
                    self.machine_cycle = .OpcodeFetch
                }
            }
        }
        opcodes[0x1A] = { // LD A,(DE)
            switch self.m_cycle {
            case 1:
                self.pins.address_bus = self.addressFromPair(self.regs.d, self.regs.e)
                self.machine_cycle = .MemoryRead
            default:
                self.regs.a = self.pins.data_bus
                self.machine_cycle = .OpcodeFetch
            }
        }
        opcodes[0x1B] = { // DEC DE
            self.machine_cycle = .TimeWait
            
            if self.t_cycle == 6 {
                self.regs.e = self.regs.e &- 1
                self.regs.d = self.regs.e == 0xFF ? self.regs.d &- 1 : self.regs.d
                self.machine_cycle = .OpcodeFetch
            }
        }
        opcodes[0x1C] = { // INC E
            self.regs.e = self.ulaCall(self.regs.e, 1, ulaOp: .Add, ignoreCarry: true)
        }
        opcodes[0x1D] = { // DEC E
            self.regs.e = self.ulaCall(self.regs.e, 1, ulaOp: .Sub, ignoreCarry: true)
        }
        opcodes[0x1E] = { // LD E,&00
            switch self.m_cycle {
            case 1:
                self.machine_cycle = .MemoryRead
                self.pins.address_bus = self.regs.pc
                self.regs.pc++
            default:
                self.regs.e = self.pins.data_bus
                self.machine_cycle = .OpcodeFetch
            }
        }
        opcodes[0x1F] = { // RRA
            let PV_backup = self.regs.f.bit(PV)
            let Z_backup = self.regs.f.bit(Z)
            let S_backup = self.regs.f.bit(S)
            self.regs.a = self.ulaCall(self.regs.a, 1, ulaOp: .Rr, ignoreCarry: false)
            self.regs.f.bit(PV, newVal: PV_backup)
            self.regs.f.bit(Z, newVal: Z_backup)
            self.regs.f.bit(S, newVal: S_backup)

        }
        opcodes[0x20] = { // JR NZ &00
            switch self.m_cycle {
            case 1:
                self.machine_cycle = .MemoryRead
                self.pins.address_bus = self.regs.pc
                self.regs.pc++
            case 2:
                self.control_reg = self.pins.data_bus // preserve data bus
                if self.regs.f.bit(Z) == 1 {
                    self.machine_cycle = .OpcodeFetch
                } else {
                    self.machine_cycle = .UlaOperation
                }
            default:
                self.machine_cycle = .TimeWait
                if self.t_cycle == 5 {
                    self.regs.pc = UInt16(Int(self.regs.pc) + Int(self.control_reg.comp2))
                    self.machine_cycle = .OpcodeFetch
                }
            }
        }
        opcodes[0x21] = { // LD HL,&0000
            switch self.m_cycle {
            case 1:
                self.machine_cycle = .MemoryRead
                self.pins.address_bus = self.regs.pc
                self.regs.pc++
            case 2:
                self.regs.l = self.pins.data_bus
                self.pins.address_bus = self.regs.pc
                self.regs.pc++
            default:
                self.regs.h = self.pins.data_bus
                self.machine_cycle = .OpcodeFetch
            }
        }
        opcodes[0x22] = { // LD (&0000),HL
            switch self.m_cycle {
            case 1:
                self.machine_cycle = .MemoryRead
                self.pins.address_bus = self.regs.pc
                self.regs.pc++
            case 2:
                self.control_reg = self.pins.data_bus
                self.pins.address_bus = self.regs.pc
                self.regs.pc++
            case 3:
                self.pins.address_bus = self.addressFromPair(self.pins.data_bus, self.control_reg)
                self.machine_cycle = .MemoryWrite
                self.pins.data_bus = self.regs.l
            case 4:
                self.pins.address_bus++
                self.pins.data_bus = self.regs.h
            default:
                self.machine_cycle = .OpcodeFetch
            }
        }
        opcodes[0x23] = { // INC HL
            self.machine_cycle = .TimeWait
            
            if self.t_cycle == 6 {
                self.regs.l = self.regs.l &+ 1
                self.regs.h = self.regs.l == 0 ? self.regs.h &+ 1 : self.regs.h
                self.machine_cycle = .OpcodeFetch
            }
        }
        opcodes[0x24] = { // INC H
            self.regs.h = self.ulaCall(self.regs.h, 1, ulaOp: .Add, ignoreCarry: true)
        }
        opcodes[0x25] = { // DEC H
            self.regs.h = self.ulaCall(self.regs.h, 1, ulaOp: .Sub, ignoreCarry: true)
        }
        opcodes[0x26] = { // LD H,&00
            switch self.m_cycle {
            case 1:
                self.machine_cycle = .MemoryRead
                self.pins.address_bus = self.regs.pc
                self.regs.pc++
            default:
                self.regs.h = self.pins.data_bus
                self.machine_cycle = .OpcodeFetch
            }
        }
        opcodes[0x27] = { // DAA
            /*
            The exact process is the following:
            - if the least significant four bits of A contain a non-BCD digit (i. e. it is greater than 9) or the H flag is set, then $06 is added to the register
            - then the four most significant bits are checked. If this more significant digit also happens to be greater than 9 or the C flag is set, then $60 is added.
            - if the second addition was needed, the C flag is set after execution, otherwise it is reset.
            - the N flag is preserved
            - P/V is parity
            - the others flags are altered by definition.
            */
            let sign: Int!
            
            if self.regs.f.bit(N) == 1 {
                sign = -1
            } else {
                sign = 1
            }
            
            if self.regs.a.low > 9 || self.regs.f.bit(H) == 1 {
                self.regs.a = UInt8(Int(self.regs.a) + sign * 0x06)
            }
            
            if self.regs.a.high > 9 || self.regs.f.bit(C) == 1 {
                self.regs.a = UInt8(Int(self.regs.a) + sign * 0x60)
                self.regs.f.setBit(C)
            } else {
                self.regs.f.resetBit(C)
            }
            
            self.regs.f.bit(S, newVal: self.regs.a.bit(7))
            
            if self.regs.a == 0 {
                self.regs.f.setBit(Z)
            } else {
                self.regs.f.resetBit(Z)
            }
            
            if self.regs.a.parity == 0 {
                self.regs.f.setBit(PV) // even parity
            } else {
                self.regs.f.resetBit(PV) // odd parity
            }
        }
        opcodes[0x28] = { // JR Z &00
            switch self.m_cycle {
            case 1:
                self.machine_cycle = .MemoryRead
                self.pins.address_bus = self.regs.pc
                self.regs.pc++
            case 2:
                self.control_reg = self.pins.data_bus // preserve data bus
                if self.regs.f.bit(Z) == 0 {
                    self.machine_cycle = .OpcodeFetch
                } else {
                    self.machine_cycle = .UlaOperation
                }
            default:
                self.machine_cycle = .TimeWait
                if self.t_cycle == 5 {
                    self.regs.pc = UInt16(Int(self.regs.pc) + Int(self.control_reg.comp2))
                    self.machine_cycle = .OpcodeFetch
                }
            }
        }
        opcodes[0x29] = { // ADD HL,HL
            switch self.m_cycle {
            case 1:
                self.machine_cycle = .UlaOperation
            case 2:
                self.machine_cycle = .TimeWait
                if self.t_cycle == 4 {
                    self.machine_cycle = .UlaOperation
                }
            default:
                self.machine_cycle = .TimeWait
                if self.t_cycle == 3 {
                    let hl = self.addressFromPair(self.regs.h, self.regs.l)
                    let result = self.ulaCall16(hl, hl, ulaOp: .Add)
                    self.regs.h = result.high
                    self.regs.l = result.low
                    self.machine_cycle = .OpcodeFetch
                }
            }
        }
        opcodes[0x2A] = { // LD HL,(&0000)
            switch self.m_cycle {
            case 1:
                self.machine_cycle = .MemoryRead
                self.pins.address_bus = self.regs.pc
                self.regs.pc++
            case 2:
                self.control_reg = self.pins.data_bus
                self.pins.address_bus = self.regs.pc
                self.regs.pc++
            case 3:
                self.pins.address_bus = self.addressFromPair(self.pins.data_bus, self.control_reg)
            case 4:
                self.regs.l = self.pins.data_bus
                self.pins.address_bus++
            default:
                self.regs.h = self.pins.data_bus
                self.machine_cycle = .OpcodeFetch
            }
        }
        opcodes[0x2B] = { // DEC HL
            self.machine_cycle = .TimeWait
            
            if self.t_cycle == 6 {
                self.regs.l = self.regs.l &- 1
                self.regs.h = self.regs.l == 0xFF ? self.regs.h &- 1 : self.regs.h
                self.machine_cycle = .OpcodeFetch
            }
        }
        opcodes[0x2C] = { // INC L
            self.regs.l = self.ulaCall(self.regs.l, 1, ulaOp: .Add, ignoreCarry: true)
        }
        opcodes[0x2D] = { // DEC L
            self.regs.l = self.ulaCall(self.regs.l, 1, ulaOp: .Sub, ignoreCarry: true)
        }
        opcodes[0x2E] = { // LD L,&00
            switch self.m_cycle {
            case 1:
                self.machine_cycle = .MemoryRead
                self.pins.address_bus = self.regs.pc
                self.regs.pc++
            default:
                self.regs.l = self.pins.data_bus
                self.machine_cycle = .OpcodeFetch
            }
        }
        opcodes[0x2F] = { // CPL
            self.regs.a = ~self.regs.a
            self.regs.f.setBit(H)
            self.regs.f.setBit(N)
        }
        opcodes[0x30] = { // JR NC &00
            switch self.m_cycle {
            case 1:
                self.machine_cycle = .MemoryRead
                self.pins.address_bus = self.regs.pc
                self.regs.pc++
            case 2:
                self.control_reg = self.pins.data_bus // preserve data bus
                if self.regs.f.bit(C) == 1 {
                    self.machine_cycle = .OpcodeFetch
                } else {
                    self.machine_cycle = .UlaOperation
                }
            default:
                self.machine_cycle = .TimeWait
                if self.t_cycle == 5 {
                    self.regs.pc = UInt16(Int(self.regs.pc) + Int(self.control_reg.comp2))
                    self.machine_cycle = .OpcodeFetch
                }
            }
        }
        opcodes[0x31] = { // LD SP,&0000
            switch self.m_cycle {
            case 1:
                self.machine_cycle = .MemoryRead
                self.pins.address_bus = self.regs.pc
                self.regs.pc++
            case 2:
                self.control_reg = self.pins.data_bus
                self.pins.address_bus = self.regs.pc
                self.regs.pc++
            default:
                self.regs.sp = self.addressFromPair(self.pins.data_bus, self.control_reg)
                self.machine_cycle = .OpcodeFetch
            }
        }
        opcodes[0x32] = { // LD (&0000),A
            switch self.m_cycle {
            case 1:
                self.machine_cycle = .MemoryRead
                self.pins.address_bus = self.regs.pc
                self.regs.pc++
            case 2:
                self.control_reg = self.pins.data_bus
                self.pins.address_bus = self.regs.pc
                self.regs.pc++
            case 3:
                self.pins.address_bus = self.addressFromPair(self.pins.data_bus, self.control_reg)
                self.machine_cycle = .MemoryWrite
                self.pins.data_bus = self.regs.a
            default:
                self.machine_cycle = .OpcodeFetch
            }
        }
        opcodes[0x33] = { // INC SP
            self.machine_cycle = .TimeWait
            
            if self.t_cycle == 6 {
                self.regs.sp = self.regs.sp &+ 1
                self.machine_cycle = .OpcodeFetch
            }
        }
        opcodes[0x34] = { // INC (HL)
            switch self.m_cycle {
            case 1:
                self.pins.address_bus = self.addressFromPair(self.regs.h, self.regs.l)
                self.machine_cycle = .MemoryRead
            case 2:
                self.machine_cycle = .TimeWait
                if self.t_cycle == 4 {
                    self.pins.data_bus = self.ulaCall(self.pins.data_bus, 1, ulaOp: .Add, ignoreCarry: true)
                    self.machine_cycle = .MemoryWrite
                }
            default:
                self.machine_cycle = .OpcodeFetch
            }
        }
        opcodes[0x35] = { // DEC (HL)
            switch self.m_cycle {
            case 1:
                self.pins.address_bus = self.addressFromPair(self.regs.h, self.regs.l)
                self.machine_cycle = .MemoryRead
            case 2:
                self.machine_cycle = .TimeWait
                if self.t_cycle == 4 {
                    self.pins.data_bus = self.ulaCall(self.pins.data_bus, 1, ulaOp: .Sub, ignoreCarry: true)
                    self.machine_cycle = .MemoryWrite
                }
            default:
                self.machine_cycle = .OpcodeFetch
            }
        }
        opcodes[0x36] = { // LD (HL),&00
            switch self.m_cycle {
            case 1:
                self.machine_cycle = .MemoryRead
                self.pins.address_bus = self.regs.pc
                self.regs.pc++
            case 2:
                self.pins.address_bus = self.addressFromPair(self.regs.h, self.regs.l)
                self.machine_cycle = .MemoryWrite
            default:
                self.machine_cycle = .OpcodeFetch
            }
        }
        opcodes[0x37] = { // SCF
            self.regs.f.setBit(C)
            self.regs.f.resetBit(H)
            self.regs.f.resetBit(N)
        }
        opcodes[0x38] = { // JR C &00
            switch self.m_cycle {
            case 1:
                self.machine_cycle = .MemoryRead
                self.pins.address_bus = self.regs.pc
                self.regs.pc++
            case 2:
                self.control_reg = self.pins.data_bus // preserve data bus
                if self.regs.f.bit(C) == 0 {
                    self.machine_cycle = .OpcodeFetch
                } else {
                    self.machine_cycle = .UlaOperation
                }
            default:
                self.machine_cycle = .TimeWait
                if self.t_cycle == 5 {
                    self.regs.pc = UInt16(Int(self.regs.pc) + Int(self.control_reg.comp2))
                    self.machine_cycle = .OpcodeFetch
                }
            }
        }
        opcodes[0x39] = { // ADD HL,SP
            switch self.m_cycle {
            case 1:
                self.machine_cycle = .UlaOperation
            case 2:
                self.machine_cycle = .TimeWait
                if self.t_cycle == 4 {
                    self.machine_cycle = .UlaOperation
                }
            default:
                self.machine_cycle = .TimeWait
                if self.t_cycle == 3 {
                    let hl = self.addressFromPair(self.regs.h, self.regs.l)
                    let result = self.ulaCall16(hl, self.regs.sp, ulaOp: .Add)
                    self.regs.h = result.high
                    self.regs.l = result.low
                    self.machine_cycle = .OpcodeFetch
                }
            }
        }
        opcodes[0x3A] = { // LD A,(&0000)
            switch self.m_cycle {
            case 1:
                self.machine_cycle = .MemoryRead
                self.pins.address_bus = self.regs.pc
                self.regs.pc++
            case 2:
                self.control_reg = self.pins.data_bus
                self.pins.address_bus = self.regs.pc
                self.regs.pc++
            case 3:
                self.pins.address_bus = self.addressFromPair(self.pins.data_bus, self.control_reg)
            default:
                self.regs.a = self.pins.data_bus
                self.machine_cycle = .OpcodeFetch
            }
        }
        opcodes[0x3B] = { // DEC SP
            self.machine_cycle = .TimeWait
            
            if self.t_cycle == 6 {
                self.regs.sp = self.regs.sp &- 1
                self.machine_cycle = .OpcodeFetch
            }
        }
        opcodes[0x3C] = { // INC A
            self.regs.a = self.ulaCall(self.regs.a, 1, ulaOp: .Add, ignoreCarry: true)
        }
        opcodes[0x3D] = { // DEC A
            self.regs.a = self.ulaCall(self.regs.a, 1, ulaOp: .Sub, ignoreCarry: true)
        }
        opcodes[0x3E] = { // LD A,&00
            switch self.m_cycle {
            case 1:
                self.machine_cycle = .MemoryRead
                self.pins.address_bus = self.regs.pc
                self.regs.pc++
            default:
                self.regs.a = self.pins.data_bus
                self.machine_cycle = .OpcodeFetch
            }
        }
        opcodes[0x3F] = { // CCF
            self.regs.f.bit(H, newVal: self.regs.f.bit(C))
            if self.regs.f.bit(C) == 0 {
                self.regs.f.setBit(C)
            } else {
                self.regs.f.resetBit(C)
            }
            self.regs.f.resetBit(N)
        }
        opcodes[0x40] = { // LD B,B
            self.regs.b = self.regs.b
        }
        opcodes[0x41] = { // LD B,C
            self.regs.b = self.regs.c
        }
        opcodes[0x42] = { // LD B,D
            self.regs.b = self.regs.d
        }
        opcodes[0x43] = { // LD B,E
            self.regs.b = self.regs.e
        }
        opcodes[0x44] = { // LD B,H
            self.regs.b = self.regs.h
        }
        opcodes[0x45] = { // LD B,L
            self.regs.b = self.regs.l
        }
        opcodes[0x46] = { // LD B,(HL)
            switch self.m_cycle {
            case 1:
                self.pins.address_bus = self.addressFromPair(self.regs.h, self.regs.l)
                self.machine_cycle = .MemoryRead
            default:
                self.regs.b = self.pins.data_bus
                self.machine_cycle = .OpcodeFetch
            }
        }
        opcodes[0x47] = { // LD B,A
            self.regs.b = self.regs.a
        }
        opcodes[0x48] = { // LD C,B
            self.regs.c = self.regs.b
        }
        opcodes[0x49] = { // LD C,C
            self.regs.c = self.regs.c
        }
        opcodes[0x4A] = { // LD C,D
            self.regs.c = self.regs.d
        }
        opcodes[0x4B] = { // LD C,E
            self.regs.c = self.regs.e
        }
        opcodes[0x4C] = { // LD C,H
            self.regs.c = self.regs.h
        }
        opcodes[0x4D] = { // LD C,L
            self.regs.c = self.regs.l
        }
        opcodes[0x4E] = { // LD C,(HL)
            switch self.m_cycle {
            case 1:
                self.pins.address_bus = self.addressFromPair(self.regs.h, self.regs.l)
                self.machine_cycle = .MemoryRead
            default:
                self.regs.c = self.pins.data_bus
                self.machine_cycle = .OpcodeFetch
            }
        }
        opcodes[0x4F] = { // LD C,A
            self.regs.c = self.regs.a
        }
        opcodes[0x50] = { // LD D,B
            self.regs.d = self.regs.b
        }
        opcodes[0x51] = { // LD D,C
            self.regs.d = self.regs.c
        }
        opcodes[0x52] = { // LD D,D
            self.regs.d = self.regs.d
        }
        opcodes[0x53] = { // LD D,E
            self.regs.d = self.regs.e
        }
        opcodes[0x54] = { // LD D,H
            self.regs.d = self.regs.h
        }
        opcodes[0x55] = { // LD D,L
            self.regs.d = self.regs.l
        }
        opcodes[0x56] = { // LD D,(HL)
            switch self.m_cycle {
            case 1:
                self.pins.address_bus = self.addressFromPair(self.regs.h, self.regs.l)
                self.machine_cycle = .MemoryRead
            default:
                self.regs.d = self.pins.data_bus
                self.machine_cycle = .OpcodeFetch
            }
        }
        opcodes[0x57] = { // LD D,A
            self.regs.d = self.regs.a
        }
        opcodes[0x58] = { // LD E,B
            self.regs.e = self.regs.b
        }
        opcodes[0x59] = { // LD E,C
            self.regs.e = self.regs.c
        }
        opcodes[0x5A] = { // LD E,D
            self.regs.e = self.regs.d
        }
        opcodes[0x5B] = { // LD E,E
            self.regs.e = self.regs.e
        }
        opcodes[0x5C] = { // LD E,H
            self.regs.e = self.regs.h
        }
        opcodes[0x5D] = { // LD E,L
            self.regs.e = self.regs.l
        }
        opcodes[0x5E] = { // LD E,(HL)
            switch self.m_cycle {
            case 1:
                self.pins.address_bus = self.addressFromPair(self.regs.h, self.regs.l)
                self.machine_cycle = .MemoryRead
            default:
                self.regs.e = self.pins.data_bus
                self.machine_cycle = .OpcodeFetch
            }
        }
        opcodes[0x5F] = { // LD E,A
            self.regs.e = self.regs.a
        }
        opcodes[0x60] = { // LD H,B
            self.regs.h = self.regs.b
        }
        opcodes[0x61] = { // LD H,C
            self.regs.h = self.regs.c
        }
        opcodes[0x62] = { // LD H,D
            self.regs.h = self.regs.d
        }
        opcodes[0x63] = { // LD H,E
            self.regs.h = self.regs.e
        }
        opcodes[0x64] = { // LD H,H
            self.regs.h = self.regs.h
        }
        opcodes[0x65] = { // LD H,L
            self.regs.h = self.regs.l
        }
        opcodes[0x66] = { // LD H,(HL)
            switch self.m_cycle {
            case 1:
                self.pins.address_bus = self.addressFromPair(self.regs.h, self.regs.l)
                self.machine_cycle = .MemoryRead
            default:
                self.regs.h = self.pins.data_bus
                self.machine_cycle = .OpcodeFetch
            }
        }
        opcodes[0x67] = { // LD H,A
            self.regs.h = self.regs.a
        }
        opcodes[0x68] = { // LD L,B
            self.regs.l = self.regs.b
        }
        opcodes[0x69] = { // LD L,C
            self.regs.l = self.regs.c
        }
        opcodes[0x6A] = { // LD L,D
            self.regs.l = self.regs.d
        }
        opcodes[0x6B] = { // LD L,E
            self.regs.l = self.regs.e
        }
        opcodes[0x6C] = { // LD L,H
            self.regs.l = self.regs.h
        }
        opcodes[0x6D] = { // LD L,L
            self.regs.l = self.regs.l
        }
        opcodes[0x6E] = { // LD L,(HL)
            switch self.m_cycle {
            case 1:
                self.pins.address_bus = self.addressFromPair(self.regs.h, self.regs.l)
                self.machine_cycle = .MemoryRead
            default:
                self.regs.l = self.pins.data_bus
                self.machine_cycle = .OpcodeFetch
            }
        }
        opcodes[0x6F] = { // LD L,A
            self.regs.l = self.regs.a
        }
        opcodes[0x70] = { // LD (HL),B
            switch self.m_cycle {
            case 1:
                self.pins.address_bus = self.addressFromPair(self.regs.h, self.regs.l)
                self.pins.data_bus = self.regs.b
                self.machine_cycle = .MemoryWrite
            default:
                self.machine_cycle = .OpcodeFetch
            }
        }
        opcodes[0x71] = { // LD (HL),C
            switch self.m_cycle {
            case 1:
                self.pins.address_bus = self.addressFromPair(self.regs.h, self.regs.l)
                self.pins.data_bus = self.regs.c
                self.machine_cycle = .MemoryWrite
            default:
                self.machine_cycle = .OpcodeFetch
            }
        }
        opcodes[0x72] = { // LD (HL),D
            switch self.m_cycle {
            case 1:
                self.pins.address_bus = self.addressFromPair(self.regs.h, self.regs.l)
                self.pins.data_bus = self.regs.d
                self.machine_cycle = .MemoryWrite
            default:
                self.machine_cycle = .OpcodeFetch
            }
        }
        opcodes[0x73] = { // LD (HL),E
            switch self.m_cycle {
            case 1:
                self.pins.address_bus = self.addressFromPair(self.regs.h, self.regs.l)
                self.pins.data_bus = self.regs.e
                self.machine_cycle = .MemoryWrite
            default:
                self.machine_cycle = .OpcodeFetch
            }
        }
        opcodes[0x74] = { // LD (HL),H
            switch self.m_cycle {
            case 1:
                self.pins.address_bus = self.addressFromPair(self.regs.h, self.regs.l)
                self.pins.data_bus = self.regs.h
                self.machine_cycle = .MemoryWrite
            default:
                self.machine_cycle = .OpcodeFetch
            }
        }
        opcodes[0x75] = { // LD (HL),L
            switch self.m_cycle {
            case 1:
                self.pins.address_bus = self.addressFromPair(self.regs.h, self.regs.l)
                self.pins.data_bus = self.regs.l
                self.machine_cycle = .MemoryWrite
            default:
                self.machine_cycle = .OpcodeFetch
            }
        }
        opcodes[0x76] = { // HALT
            return
        }
        opcodes[0x77] = { // LD (HL),A
            switch self.m_cycle {
            case 1:
                self.pins.address_bus = self.addressFromPair(self.regs.h, self.regs.l)
                self.pins.data_bus = self.regs.a
                self.machine_cycle = .MemoryWrite
            default:
                self.machine_cycle = .OpcodeFetch
            }
        }
        opcodes[0x78] = { // LD A,B
            self.regs.a = self.regs.b
        }
        opcodes[0x79] = { // LD A,C
            self.regs.a = self.regs.c
        }
        opcodes[0x7A] = { // LD A,D
            self.regs.a = self.regs.d
        }
        opcodes[0x7B] = { // LD A,E
            self.regs.a = self.regs.e
        }
        opcodes[0x7C] = { // LD A,H
            self.regs.a = self.regs.h
        }
        opcodes[0x7D] = { // LD A,L
            self.regs.a = self.regs.l
        }
        opcodes[0x7E] = { // LD A,(HL)
            switch self.m_cycle {
            case 1:
                self.pins.address_bus = self.addressFromPair(self.regs.h, self.regs.l)
                self.machine_cycle = .MemoryRead
            default:
                self.regs.a = self.pins.data_bus
                self.machine_cycle = .OpcodeFetch
            }
        }
        opcodes[0x7F] = { // LD A,A
            self.regs.a = self.regs.a
        }
        opcodes[0x80] = { // ADD A,B
            self.regs.a = self.ulaCall(self.regs.a, self.regs.b, ulaOp: .Add, ignoreCarry: false)
        }
        opcodes[0x81] = { // ADD A,C
            self.regs.a = self.ulaCall(self.regs.a, self.regs.c, ulaOp: .Add, ignoreCarry: false)
        }
        opcodes[0x82] = { // ADD A,D
            self.regs.a = self.ulaCall(self.regs.a, self.regs.d, ulaOp: .Add, ignoreCarry: false)
        }
        opcodes[0x83] = { // ADD A,E
            self.regs.a = self.ulaCall(self.regs.a, self.regs.d, ulaOp: .Add, ignoreCarry: false)
        }
        opcodes[0x84] = { // ADD A,H
            self.regs.a = self.ulaCall(self.regs.a, self.regs.h, ulaOp: .Add, ignoreCarry: false)
        }
        opcodes[0x85] = { // ADD A,L
            self.regs.a = self.ulaCall(self.regs.a, self.regs.l, ulaOp: .Add, ignoreCarry: false)
        }
        opcodes[0x86] = { // ADD A,(HL)
            switch self.m_cycle {
            case 1:
                self.pins.address_bus = self.addressFromPair(self.regs.h, self.regs.l)
                self.machine_cycle = .MemoryRead
            default:
                self.regs.a = self.ulaCall(self.regs.a, self.pins.data_bus, ulaOp: .Add, ignoreCarry: false)
                self.machine_cycle = .OpcodeFetch
            }
        }
        opcodes[0x87] = { // ADD A,A
            self.regs.a = self.ulaCall(self.regs.a, self.regs.a, ulaOp: .Add, ignoreCarry: false)
        }
        opcodes[0x88] = { // ADC A,B
            self.regs.a = self.ulaCall(self.regs.a, self.regs.b, ulaOp: .Adc, ignoreCarry: false)
        }
        opcodes[0x89] = { // ADC A,C
            self.regs.a = self.ulaCall(self.regs.a, self.regs.c, ulaOp: .Adc, ignoreCarry: false)
        }
        opcodes[0x8A] = { // ADC A,D
            self.regs.a = self.ulaCall(self.regs.a, self.regs.d, ulaOp: .Adc, ignoreCarry: false)
        }
        opcodes[0x8B] = { // ADC A,E
            self.regs.a = self.ulaCall(self.regs.a, self.regs.d, ulaOp: .Adc, ignoreCarry: false)
        }
        opcodes[0x8C] = { // ADC A,H
            self.regs.a = self.ulaCall(self.regs.a, self.regs.h, ulaOp: .Adc, ignoreCarry: false)
        }
        opcodes[0x8D] = { // ADC A,L
            self.regs.a = self.ulaCall(self.regs.a, self.regs.l, ulaOp: .Adc, ignoreCarry: false)
        }
        opcodes[0x8E] = { // ADC A,(HL)
            switch self.m_cycle {
            case 1:
                self.pins.address_bus = self.addressFromPair(self.regs.h, self.regs.l)
                self.machine_cycle = .MemoryRead
            default:
                self.regs.a = self.ulaCall(self.regs.a, self.pins.data_bus, ulaOp: .Adc, ignoreCarry: false)
                self.machine_cycle = .OpcodeFetch
            }
        }
        opcodes[0x8F] = { // ADC A,A
            self.regs.a = self.ulaCall(self.regs.a, self.regs.a, ulaOp: .Adc, ignoreCarry: false)
        }
        opcodes[0x90] = { // SUB A,B
            self.regs.a = self.ulaCall(self.regs.a, self.regs.b, ulaOp: .Sub, ignoreCarry: false)
        }
        opcodes[0x91] = { // SUB A,C
            self.regs.a = self.ulaCall(self.regs.a, self.regs.c, ulaOp: .Sub, ignoreCarry: false)
        }
        opcodes[0x92] = { // SUB A,D
            self.regs.a = self.ulaCall(self.regs.a, self.regs.d, ulaOp: .Sub, ignoreCarry: false)
        }
        opcodes[0x93] = { // SUB A,E
            self.regs.a = self.ulaCall(self.regs.a, self.regs.d, ulaOp: .Sub, ignoreCarry: false)
        }
        opcodes[0x94] = { // SUB A,H
            self.regs.a = self.ulaCall(self.regs.a, self.regs.h, ulaOp: .Sub, ignoreCarry: false)
        }
        opcodes[0x95] = { // SUB A,L
            self.regs.a = self.ulaCall(self.regs.a, self.regs.l, ulaOp: .Sub, ignoreCarry: false)
        }
        opcodes[0x96] = { // SUB A,(HL)
            switch self.m_cycle {
            case 1:
                self.pins.address_bus = self.addressFromPair(self.regs.h, self.regs.l)
                self.machine_cycle = .MemoryRead
            default:
                self.regs.a = self.ulaCall(self.regs.a, self.pins.data_bus, ulaOp: .Sub, ignoreCarry: false)
                self.machine_cycle = .OpcodeFetch
            }
        }
        opcodes[0x97] = { // SBC A,A
            self.regs.a = self.ulaCall(self.regs.a, self.regs.a, ulaOp: .Sub, ignoreCarry: false)
        }
        opcodes[0x98] = { // SBC A,B
            self.regs.a = self.ulaCall(self.regs.a, self.regs.b, ulaOp: .Sbc, ignoreCarry: false)
        }
        opcodes[0x99] = { // SBC A,C
            self.regs.a = self.ulaCall(self.regs.a, self.regs.c, ulaOp: .Sbc, ignoreCarry: false)
        }
        opcodes[0x9A] = { // SBC A,D
            self.regs.a = self.ulaCall(self.regs.a, self.regs.d, ulaOp: .Sbc, ignoreCarry: false)
        }
        opcodes[0x9B] = { // SBC A,E
            self.regs.a = self.ulaCall(self.regs.a, self.regs.d, ulaOp: .Sbc, ignoreCarry: false)
        }
        opcodes[0x9C] = { // SBC A,H
            self.regs.a = self.ulaCall(self.regs.a, self.regs.h, ulaOp: .Sbc, ignoreCarry: false)
        }
        opcodes[0x9D] = { // SBC A,L
            self.regs.a = self.ulaCall(self.regs.a, self.regs.l, ulaOp: .Sbc, ignoreCarry: false)
        }
        opcodes[0x9E] = { // SBC A,(HL)
            switch self.m_cycle {
            case 1:
                self.pins.address_bus = self.addressFromPair(self.regs.h, self.regs.l)
                self.machine_cycle = .MemoryRead
            default:
                self.regs.a = self.ulaCall(self.regs.a, self.pins.data_bus, ulaOp: .Sbc, ignoreCarry: false)
                self.machine_cycle = .OpcodeFetch
            }
        }
        opcodes[0x9F] = { // SBC A,A
            self.regs.a = self.ulaCall(self.regs.a, self.regs.a, ulaOp: .Sbc, ignoreCarry: false)
        }
        opcodes[0xA0] = { // AND B
            self.regs.a = self.ulaCall(self.regs.a, self.regs.b, ulaOp: .And, ignoreCarry: false)
        }
        opcodes[0xA1] = { // AND C
            self.regs.a = self.ulaCall(self.regs.a, self.regs.c, ulaOp: .And, ignoreCarry: false)
        }
        opcodes[0xA2] = { // AND D
            self.regs.a = self.ulaCall(self.regs.a, self.regs.d, ulaOp: .And, ignoreCarry: false)
        }
        opcodes[0xA3] = { // AND E
            self.regs.a = self.ulaCall(self.regs.a, self.regs.e, ulaOp: .And, ignoreCarry: false)
        }
        opcodes[0xA4] = { // AND H
            self.regs.a = self.ulaCall(self.regs.a, self.regs.h, ulaOp: .And, ignoreCarry: false)
        }
        opcodes[0xA5] = { // AND L
            self.regs.a = self.ulaCall(self.regs.a, self.regs.l, ulaOp: .And, ignoreCarry: false)
        }
        opcodes[0xA6] = { // AND (HL)
            switch self.m_cycle {
            case 1:
                self.pins.address_bus = self.addressFromPair(self.regs.h, self.regs.l)
                self.machine_cycle = .MemoryRead
            default:
                self.regs.a = self.ulaCall(self.regs.a, self.pins.data_bus, ulaOp: .And, ignoreCarry: false)
                self.machine_cycle = .OpcodeFetch
            }
        }
        opcodes[0xA7] = { // AND A
            self.regs.a = self.ulaCall(self.regs.a, self.regs.a, ulaOp: .And, ignoreCarry: false)
        }
        opcodes[0xA8] = { // XOR B
            self.regs.a = self.ulaCall(self.regs.a, self.regs.b, ulaOp: .Xor, ignoreCarry: false)
        }
        opcodes[0xA9] = { // XOR C
            self.regs.a = self.ulaCall(self.regs.a, self.regs.c, ulaOp: .Xor, ignoreCarry: false)
        }
        opcodes[0xAA] = { // XOR D
            self.regs.a = self.ulaCall(self.regs.a, self.regs.d, ulaOp: .Xor, ignoreCarry: false)
        }
        opcodes[0xAB] = { // XOR E
            self.regs.a = self.ulaCall(self.regs.a, self.regs.e, ulaOp: .Xor, ignoreCarry: false)
        }
        opcodes[0xAC] = { // XOR H
            self.regs.a = self.ulaCall(self.regs.a, self.regs.h, ulaOp: .Xor, ignoreCarry: false)
        }
        opcodes[0xAD] = { // XOR L
            self.regs.a = self.ulaCall(self.regs.a, self.regs.l, ulaOp: .Xor, ignoreCarry: false)
        }
        opcodes[0xAE] = { // XOR (HL)
            switch self.m_cycle {
            case 1:
                self.pins.address_bus = self.addressFromPair(self.regs.h, self.regs.l)
                self.machine_cycle = .MemoryRead
            default:
                self.regs.a = self.ulaCall(self.regs.a, self.pins.data_bus, ulaOp: .Xor, ignoreCarry: false)
                self.machine_cycle = .OpcodeFetch
            }
        }
        opcodes[0xAF] = { // XOR A
            self.regs.a = self.ulaCall(self.regs.a, self.regs.a, ulaOp: .Xor, ignoreCarry: false)
        }
        opcodes[0xB0] = { // OR B
            self.regs.a = self.ulaCall(self.regs.a, self.regs.b, ulaOp: .Or, ignoreCarry: false)
        }
        opcodes[0xB1] = { // OR C
            self.regs.a = self.ulaCall(self.regs.a, self.regs.c, ulaOp: .Or, ignoreCarry: false)
        }
        opcodes[0xB2] = { // OR D
            self.regs.a = self.ulaCall(self.regs.a, self.regs.d, ulaOp: .Or, ignoreCarry: false)
        }
        opcodes[0xB3] = { // OR E
            self.regs.a = self.ulaCall(self.regs.a, self.regs.e, ulaOp: .Or, ignoreCarry: false)
        }
        opcodes[0xB4] = { // OR H
            self.regs.a = self.ulaCall(self.regs.a, self.regs.h, ulaOp: .Or, ignoreCarry: false)
        }
        opcodes[0xB5] = { // OR L
            self.regs.a = self.ulaCall(self.regs.a, self.regs.l, ulaOp: .Or, ignoreCarry: false)
        }
        opcodes[0xB6] = { // OR (HL)
            switch self.m_cycle {
            case 1:
                self.pins.address_bus = self.addressFromPair(self.regs.h, self.regs.l)
                self.machine_cycle = .MemoryRead
            default:
                self.regs.a = self.ulaCall(self.regs.a, self.pins.data_bus, ulaOp: .Or, ignoreCarry: false)
                self.machine_cycle = .OpcodeFetch
            }
        }
        opcodes[0xB7] = { // OR A
            self.regs.a = self.ulaCall(self.regs.a, self.regs.a, ulaOp: .Or, ignoreCarry: false)
        }
        opcodes[0xB8] = { // CP B
            self.ulaCall(self.regs.a, self.regs.b, ulaOp: .Sub, ignoreCarry: false)
        }
        opcodes[0xB9] = { // CP C
            self.ulaCall(self.regs.a, self.regs.c, ulaOp: .Sub, ignoreCarry: false)
        }
        opcodes[0xBA] = { // CP D
            self.ulaCall(self.regs.a, self.regs.d, ulaOp: .Sub, ignoreCarry: false)
        }
        opcodes[0xBB] = { // CP E
            self.ulaCall(self.regs.a, self.regs.e, ulaOp: .Sub, ignoreCarry: false)
        }
        opcodes[0xBC] = { // CP H
            self.ulaCall(self.regs.a, self.regs.h, ulaOp: .Sub, ignoreCarry: false)
        }
        opcodes[0xBD] = { // CP L
            self.ulaCall(self.regs.a, self.regs.l, ulaOp: .Sub, ignoreCarry: false)
        }
        opcodes[0xBE] = { // CP (HL)
            switch self.m_cycle {
            case 1:
                self.pins.address_bus = self.addressFromPair(self.regs.h, self.regs.l)
                self.machine_cycle = .MemoryRead
            default:
                self.ulaCall(self.regs.a, self.pins.data_bus, ulaOp: .Sub, ignoreCarry: false)
                self.machine_cycle = .OpcodeFetch
            }
        }
        opcodes[0xBF] = { // CP A
            self.ulaCall(self.regs.a, self.regs.a, ulaOp: .Sub, ignoreCarry: false)
        }
        opcodes[0xC0] = { // RET NZ
            switch self.m_cycle {
            case 1:
                if self.regs.f.bit(Z) == 0 {
                    self.pins.address_bus = self.regs.sp
                    self.regs.sp++
                    self.machine_cycle = .MemoryRead
                }
            case 2:
                self.control_reg = self.pins.data_bus
                self.pins.address_bus = self.regs.sp
                self.regs.sp++
            default:
                self.regs.pc = self.addressFromPair(self.pins.data_bus, self.control_reg)
                self.machine_cycle = .OpcodeFetch
            }
        }
        opcodes[0xC1] = { // POP BC
            switch self.m_cycle {
            case 1:
                self.pins.address_bus = self.regs.sp
                self.regs.sp++
                self.machine_cycle = .MemoryRead
            case 2:
                self.regs.c = self.pins.data_bus
                self.pins.address_bus = self.regs.sp
                self.regs.sp++
            default:
                self.regs.b = self.pins.data_bus
                self.machine_cycle = .OpcodeFetch
            }
        }
        opcodes[0xC2] = { // JP NZ &0000
            switch self.m_cycle {
            case 1:
                if self.regs.f.bit(Z) == 0 {
                    self.pins.address_bus = self.regs.pc
                    self.regs.pc++
                    self.machine_cycle = .MemoryRead
                } else {
                    self.regs.pc = self.regs.pc + 2
                }
            case 2:
                self.control_reg = self.pins.data_bus
                self.pins.address_bus = self.regs.pc
                self.regs.pc++
            default:
                self.regs.pc = self.addressFromPair(self.pins.data_bus, self.control_reg)
                self.machine_cycle = .OpcodeFetch
            }
        }
        opcodes[0xC3] = { // JP &0000
            switch self.m_cycle {
            case 1:
                self.pins.address_bus = self.regs.pc
                self.regs.pc++
                self.machine_cycle = .MemoryRead
            case 2:
                self.control_reg = self.pins.data_bus
                self.pins.address_bus = self.regs.pc
                self.regs.pc++
            default:
                self.regs.pc = self.addressFromPair(self.pins.data_bus, self.control_reg)
                self.machine_cycle = .OpcodeFetch
            }
        }
        opcodes[0xC4] = { // CALL NZ &0000
            switch self.m_cycle {
            case 1:
                self.regs.pc = self.regs.pc + 2
                if self.regs.f.bit(Z) == 0 {
                    self.regs.sp--
                    self.pins.address_bus = self.regs.sp
                    self.pins.data_bus = self.regs.pc.high
                    self.machine_cycle = .MemoryWrite
                }
            case 2:
                self.regs.sp--
                self.pins.address_bus = self.regs.sp
                self.pins.data_bus = self.regs.pc.low
            case 3:
                self.machine_cycle = .TimeWait
                if self.t_cycle == 4 {
                    self.regs.pc = self.regs.pc - 2
                    self.pins.address_bus = self.regs.pc
                    self.regs.pc++
                    self.machine_cycle = .MemoryRead
                }
            case 4:
                self.control_reg = self.pins.data_bus
                self.pins.address_bus = self.regs.pc
                self.regs.pc++
            default:
                self.regs.pc = self.addressFromPair(self.pins.data_bus, self.control_reg)
                self.machine_cycle = .OpcodeFetch
            }
        }
        opcodes[0xC5] = { // PUSH BC
            switch self.m_cycle {
            case 1:
                self.machine_cycle = .TimeWait
                if self.t_cycle == 5 {
                    self.regs.sp--
                    self.pins.address_bus = self.regs.sp
                    self.pins.data_bus = self.regs.b
                    self.machine_cycle = .MemoryWrite
                }
            case 2:
                self.regs.sp--
                self.pins.address_bus = self.regs.sp
                self.pins.data_bus = self.regs.c
            default:
                self.machine_cycle = .OpcodeFetch
            }
        }
        opcodes[0xC6] = { // ADD A,&00
            switch self.m_cycle {
            case 1:
                self.pins.address_bus = self.regs.pc
                self.regs.pc++
                self.machine_cycle = .MemoryRead
            default:
                self.regs.a = self.ulaCall(self.regs.a, self.pins.data_bus, ulaOp: .Add, ignoreCarry: false)
                self.machine_cycle = .OpcodeFetch
            }
        }
        opcodes[0xC7] = { // RST &00
            self.rst(0x0000)
        }
        opcodes[0xC8] = { // RET Z
            switch self.m_cycle {
            case 1:
                if self.regs.f.bit(Z) == 1 {
                    self.pins.address_bus = self.regs.sp
                    self.regs.sp++
                    self.machine_cycle = .MemoryRead
                }
            case 2:
                self.control_reg = self.pins.data_bus
                self.pins.address_bus = self.regs.sp
                self.regs.sp++
            default:
                self.regs.pc = self.addressFromPair(self.pins.data_bus, self.control_reg)
                self.machine_cycle = .OpcodeFetch
            }
        }
        opcodes[0xC9] = { // RET
            switch self.m_cycle {
            case 1:
                self.pins.address_bus = self.regs.sp
                self.regs.sp++
                self.machine_cycle = .MemoryRead
            case 2:
                self.control_reg = self.pins.data_bus
                self.pins.address_bus = self.regs.sp
                self.regs.sp++
            default:
                self.regs.pc = self.addressFromPair(self.pins.data_bus, self.control_reg)
                self.machine_cycle = .OpcodeFetch
            }
        }
        opcodes[0xCA] = { // JP Z &0000
            switch self.m_cycle {
            case 1:
                if self.regs.f.bit(Z) == 1 {
                    self.pins.address_bus = self.regs.pc
                    self.regs.pc++
                    self.machine_cycle = .MemoryRead
                } else {
                    self.regs.pc = self.regs.pc + 2
                }
            case 2:
                self.control_reg = self.pins.data_bus
                self.pins.address_bus = self.regs.pc
                self.regs.pc++
            default:
                self.regs.pc = self.addressFromPair(self.pins.data_bus, self.control_reg)
                self.machine_cycle = .OpcodeFetch
            }
        }
        opcodes[0xCB] = { // PREFIX *** CB ***
            self.id_opcode_table = prefix_CB
        }
        opcodes[0xCC] = { // CALL Z &0000
            switch self.m_cycle {
            case 1:
                self.regs.pc = self.regs.pc + 2
                if self.regs.f.bit(Z) == 1 {
                    self.regs.sp--
                    self.pins.address_bus = self.regs.sp
                    self.pins.data_bus = self.regs.pc.high
                    self.machine_cycle = .MemoryWrite
                }
            case 2:
                self.regs.sp--
                self.pins.address_bus = self.regs.sp
                self.pins.data_bus = self.regs.pc.low
            case 3:
                self.machine_cycle = .TimeWait
                if self.t_cycle == 4 {
                    self.regs.pc = self.regs.pc - 2
                    self.pins.address_bus = self.regs.pc
                    self.regs.pc++
                    self.machine_cycle = .MemoryRead
                }
            case 4:
                self.control_reg = self.pins.data_bus
                self.pins.address_bus = self.regs.pc
                self.regs.pc++
            default:
                self.regs.pc = self.addressFromPair(self.pins.data_bus, self.control_reg)
                self.machine_cycle = .OpcodeFetch
            }
        }
        opcodes[0xCD] = { // CALL &0000
            switch self.m_cycle {
            case 1:
                self.regs.pc = self.regs.pc + 2
                self.regs.sp--
                self.pins.address_bus = self.regs.sp
                self.pins.data_bus = self.regs.pc.high
                self.machine_cycle = .MemoryWrite
            case 2:
                self.regs.sp--
                self.pins.address_bus = self.regs.sp
                self.pins.data_bus = self.regs.pc.low
            case 3:
                self.machine_cycle = .TimeWait
                if self.t_cycle == 4 {
                    self.regs.pc = self.regs.pc - 2
                    self.pins.address_bus = self.regs.pc
                    self.regs.pc++
                    self.machine_cycle = .MemoryRead
                }
            case 4:
                self.control_reg = self.pins.data_bus
                self.pins.address_bus = self.regs.pc
                self.regs.pc++
            default:
                self.regs.pc = self.addressFromPair(self.pins.data_bus, self.control_reg)
                self.machine_cycle = .OpcodeFetch
            }
        }
        opcodes[0xCE] = { // ADC A,&00
            switch self.m_cycle {
            case 1:
                self.pins.address_bus = self.regs.pc
                self.regs.pc++
                self.machine_cycle = .MemoryRead
            default:
                self.regs.a = self.ulaCall(self.regs.a, self.pins.data_bus, ulaOp: .Adc, ignoreCarry: false)
                self.machine_cycle = .OpcodeFetch
            }
        }
        opcodes[0xCF] = { // RST &08
            self.rst(0x0008)
        }
        opcodes[0xD0] = { // RET NC
            switch self.m_cycle {
            case 1:
                if self.regs.f.bit(C) == 0 {
                    self.pins.address_bus = self.regs.sp
                    self.regs.sp++
                    self.machine_cycle = .MemoryRead
                }
            case 2:
                self.control_reg = self.pins.data_bus
                self.pins.address_bus = self.regs.sp
                self.regs.sp++
            default:
                self.regs.pc = self.addressFromPair(self.pins.data_bus, self.control_reg)
                self.machine_cycle = .OpcodeFetch
            }
        }
        opcodes[0xD1] = { // POP DE
            switch self.m_cycle {
            case 1:
                self.pins.address_bus = self.regs.sp
                self.regs.sp++
                self.machine_cycle = .MemoryRead
            case 2:
                self.regs.e = self.pins.data_bus
                self.pins.address_bus = self.regs.sp
                self.regs.sp++
            default:
                self.regs.d = self.pins.data_bus
                self.machine_cycle = .OpcodeFetch
            }
        }
        opcodes[0xD2] = { // JP NC &0000
            switch self.m_cycle {
            case 1:
                if self.regs.f.bit(C) == 0 {
                    self.pins.address_bus = self.regs.pc
                    self.regs.pc++
                    self.machine_cycle = .MemoryRead
                } else {
                    self.regs.pc = self.regs.pc + 2
                }
            case 2:
                self.control_reg = self.pins.data_bus
                self.pins.address_bus = self.regs.pc
                self.regs.pc++
            default:
                self.regs.pc = self.addressFromPair(self.pins.data_bus, self.control_reg)
                self.machine_cycle = .OpcodeFetch
            }
        }
        opcodes[0xD3] = { // OUT (&00), A
            switch self.m_cycle {
            case 1:
                self.pins.address_bus = self.regs.pc
                self.regs.pc++
                self.machine_cycle = .MemoryRead
            case 2:
                self.pins.address_bus = self.addressFromPair(self.regs.a, self.pins.data_bus)
                self.pins.data_bus = self.regs.a
                self.machine_cycle = .IoWrite
            default:
                self.machine_cycle = .OpcodeFetch
            }
        }
        opcodes[0xD4] = { // CALL NC &0000
            switch self.m_cycle {
            case 1:
                self.regs.pc = self.regs.pc + 2
                if self.regs.f.bit(C) == 0 {
                    self.regs.sp--
                    self.pins.address_bus = self.regs.sp
                    self.pins.data_bus = self.regs.pc.high
                    self.machine_cycle = .MemoryWrite
                }
            case 2:
                self.regs.sp--
                self.pins.address_bus = self.regs.sp
                self.pins.data_bus = self.regs.pc.low
            case 3:
                self.machine_cycle = .TimeWait
                if self.t_cycle == 4 {
                    self.regs.pc = self.regs.pc - 2
                    self.pins.address_bus = self.regs.pc
                    self.regs.pc++
                    self.machine_cycle = .MemoryRead
                }
            case 4:
                self.control_reg = self.pins.data_bus
                self.pins.address_bus = self.regs.pc
                self.regs.pc++
            default:
                self.regs.pc = self.addressFromPair(self.pins.data_bus, self.control_reg)
                self.machine_cycle = .OpcodeFetch
            }
        }
        opcodes[0xD5] = { // PUSH DE
            switch self.m_cycle {
            case 1:
                self.machine_cycle = .TimeWait
                if self.t_cycle == 5 {
                    self.regs.sp--
                    self.pins.address_bus = self.regs.sp
                    self.pins.data_bus = self.regs.d
                    self.machine_cycle = .MemoryWrite
                }
            case 2:
                self.regs.sp--
                self.pins.address_bus = self.regs.sp
                self.pins.data_bus = self.regs.e
            default:
                self.machine_cycle = .OpcodeFetch
            }
        }
        opcodes[0xD6] = { // SUB A,&00
            switch self.m_cycle {
            case 1:
                self.pins.address_bus = self.regs.pc
                self.regs.pc++
                self.machine_cycle = .MemoryRead
            default:
                self.regs.a = self.ulaCall(self.regs.a, self.pins.data_bus, ulaOp: .Sub, ignoreCarry: false)
                self.machine_cycle = .OpcodeFetch
            }
        }
        opcodes[0xD7] = { // RST &10
            self.rst(0x0010)
        }
        opcodes[0xD8] = { // RET C
            switch self.m_cycle {
            case 1:
                if self.regs.f.bit(C) == 1 {
                    self.pins.address_bus = self.regs.sp
                    self.regs.sp++
                    self.machine_cycle = .MemoryRead
                }
            case 2:
                self.control_reg = self.pins.data_bus
                self.pins.address_bus = self.regs.sp
                self.regs.sp++
            default:
                self.regs.pc = self.addressFromPair(self.pins.data_bus, self.control_reg)
                self.machine_cycle = .OpcodeFetch
            }
        }
        opcodes[0xD9] = { // EXX
            let b = self.regs.b
            let c = self.regs.c
            let d = self.regs.d
            let e = self.regs.e
            let h = self.regs.h
            let l = self.regs.l
            self.regs.b = self.regs.b_
            self.regs.c = self.regs.c_
            self.regs.d = self.regs.d_
            self.regs.e = self.regs.e_
            self.regs.h = self.regs.h_
            self.regs.l = self.regs.l_
            self.regs.b_ = b
            self.regs.c_ = c
            self.regs.d_ = d
            self.regs.e_ = e
            self.regs.h_ = h
            self.regs.l_ = l
            
        }
        opcodes[0xDA] = { // JP C &0000
            switch self.m_cycle {
            case 1:
                if self.regs.f.bit(C) == 1 {
                    self.pins.address_bus = self.regs.pc
                    self.regs.pc++
                    self.machine_cycle = .MemoryRead
                } else {
                    self.regs.pc = self.regs.pc + 2
                }
            case 2:
                self.control_reg = self.pins.data_bus
                self.pins.address_bus = self.regs.pc
                self.regs.pc++
            default:
                self.regs.pc = self.addressFromPair(self.pins.data_bus, self.control_reg)
                self.machine_cycle = .OpcodeFetch
            }
        }
        opcodes[0xDB] = { // IN (&00), A
            switch self.m_cycle {
            case 1:
                self.pins.address_bus = self.regs.pc
                self.regs.pc++
                self.machine_cycle = .MemoryRead
            case 2:
                self.pins.address_bus = self.addressFromPair(self.regs.a, self.pins.data_bus)
                self.machine_cycle = .IoRead
            default:
                self.regs.a = self.pins.data_bus
                self.machine_cycle = .OpcodeFetch
            }
        }
        opcodes[0xDC] = { // CALL C &0000
            switch self.m_cycle {
            case 1:
                self.regs.pc = self.regs.pc + 2
                if self.regs.f.bit(C) == 1 {
                    self.regs.sp--
                    self.pins.address_bus = self.regs.sp
                    self.pins.data_bus = self.regs.pc.high
                    self.machine_cycle = .MemoryWrite
                }
            case 2:
                self.regs.sp--
                self.pins.address_bus = self.regs.sp
                self.pins.data_bus = self.regs.pc.low
            case 3:
                self.machine_cycle = .TimeWait
                if self.t_cycle == 4 {
                    self.regs.pc = self.regs.pc - 2
                    self.pins.address_bus = self.regs.pc
                    self.regs.pc++
                    self.machine_cycle = .MemoryRead
                }
            case 4:
                self.control_reg = self.pins.data_bus
                self.pins.address_bus = self.regs.pc
                self.regs.pc++
            default:
                self.regs.pc = self.addressFromPair(self.pins.data_bus, self.control_reg)
                self.machine_cycle = .OpcodeFetch
            }
        }
        opcodes[0xDD] = { // PREFIX *** DD ***
            self.id_opcode_table = prefix_DD
        }
        opcodes[0xDE] = { // SBC A,&00
            switch self.m_cycle {
            case 1:
                self.pins.address_bus = self.regs.pc
                self.regs.pc++
                self.machine_cycle = .MemoryRead
            default:
                self.regs.a = self.ulaCall(self.regs.a, self.pins.data_bus, ulaOp: .Sbc, ignoreCarry: false)
                self.machine_cycle = .OpcodeFetch
            }
        }
        opcodes[0xDF] = { // RST &18
            self.rst(0x0018)
        }
        opcodes[0xE0] = { // RET PO
            switch self.m_cycle {
            case 1:
                if self.regs.f.bit(PV) == 0 {
                    self.pins.address_bus = self.regs.sp
                    self.regs.sp++
                    self.machine_cycle = .MemoryRead
                }
            case 2:
                self.control_reg = self.pins.data_bus
                self.pins.address_bus = self.regs.sp
                self.regs.sp++
            default:
                self.regs.pc = self.addressFromPair(self.pins.data_bus, self.control_reg)
                self.machine_cycle = .OpcodeFetch
            }
        }
        opcodes[0xE1] = { // POP HL
            switch self.m_cycle {
            case 1:
                self.pins.address_bus = self.regs.sp
                self.regs.sp++
                self.machine_cycle = .MemoryRead
            case 2:
                self.regs.l = self.pins.data_bus
                self.pins.address_bus = self.regs.sp
                self.regs.sp++
            default:
                self.regs.h = self.pins.data_bus
                self.machine_cycle = .OpcodeFetch
            }
        }
        opcodes[0xE2] = { // JP PO &0000
            switch self.m_cycle {
            case 1:
                if self.regs.f.bit(PV) == 0 {
                    self.pins.address_bus = self.regs.pc
                    self.regs.pc++
                    self.machine_cycle = .MemoryRead
                } else {
                    self.regs.pc = self.regs.pc + 2
                }
            case 2:
                self.control_reg = self.pins.data_bus
                self.pins.address_bus = self.regs.pc
                self.regs.pc++
            default:
                self.regs.pc = self.addressFromPair(self.pins.data_bus, self.control_reg)
                self.machine_cycle = .OpcodeFetch
            }
        }
        opcodes[0xE3] = { // EX (SP), HL
            switch self.m_cycle {
            case 1:
                self.pins.address_bus = self.regs.sp
                self.machine_cycle = .MemoryRead
            case 2:
                self.control_reg = self.pins.data_bus
                self.pins.data_bus = self.regs.l
                self.regs.l = self.control_reg
                self.machine_cycle = .MemoryWrite
            case 3:
                self.machine_cycle = .TimeWait
                if self.t_cycle == 4 {
                    self.pins.address_bus = self.regs.sp + 1
                    self.machine_cycle = .MemoryRead
                }
            case 4:
                self.control_reg = self.pins.data_bus
                self.pins.data_bus = self.regs.h
                self.regs.h = self.control_reg
                self.machine_cycle = .MemoryWrite
            default:
                self.machine_cycle = .TimeWait
                if self.t_cycle == 5 {
                    self.machine_cycle = .OpcodeFetch
                }
                
            }
        }
        opcodes[0xE4] = { // CALL PO &0000
            switch self.m_cycle {
            case 1:
                self.regs.pc = self.regs.pc + 2
                if self.regs.f.bit(PV) == 0 {
                    self.regs.sp--
                    self.pins.address_bus = self.regs.sp
                    self.pins.data_bus = self.regs.pc.high
                    self.machine_cycle = .MemoryWrite
                }
            case 2:
                self.regs.sp--
                self.pins.address_bus = self.regs.sp
                self.pins.data_bus = self.regs.pc.low
            case 3:
                self.machine_cycle = .TimeWait
                if self.t_cycle == 4 {
                    self.regs.pc = self.regs.pc - 2
                    self.pins.address_bus = self.regs.pc
                    self.regs.pc++
                    self.machine_cycle = .MemoryRead
                }
            case 4:
                self.control_reg = self.pins.data_bus
                self.pins.address_bus = self.regs.pc
                self.regs.pc++
            default:
                self.regs.pc = self.addressFromPair(self.pins.data_bus, self.control_reg)
                self.machine_cycle = .OpcodeFetch
            }
        }
        
        opcodes[0xE5] = { // PUSH HL
            switch self.m_cycle {
            case 1:
                self.machine_cycle = .TimeWait
                if self.t_cycle == 5 {
                    self.regs.sp--
                    self.pins.address_bus = self.regs.sp
                    self.pins.data_bus = self.regs.h
                    self.machine_cycle = .MemoryWrite
                }
            case 2:
                self.regs.sp--
                self.pins.address_bus = self.regs.sp
                self.pins.data_bus = self.regs.l
            default:
                self.machine_cycle = .OpcodeFetch
            }
        }
        opcodes[0xE6] = { // AND &00
            switch self.m_cycle {
            case 1:
                self.pins.address_bus = self.regs.pc
                self.regs.pc++
                self.machine_cycle = .MemoryRead
            default:
                self.regs.a = self.ulaCall(self.regs.a, self.pins.data_bus, ulaOp: .And, ignoreCarry: false)
                self.machine_cycle = .OpcodeFetch
            }
        }
        opcodes[0xE7] = { // RST &20
            self.rst(0x0020)
        }
        opcodes[0xE8] = { // RET PE
            switch self.m_cycle {
            case 1:
                if self.regs.f.bit(PV) == 1 {
                    self.pins.address_bus = self.regs.sp
                    self.regs.sp++
                    self.machine_cycle = .MemoryRead
                }
            case 2:
                self.control_reg = self.pins.data_bus
                self.pins.address_bus = self.regs.sp
                self.regs.sp++
            default:
                self.regs.pc = self.addressFromPair(self.pins.data_bus, self.control_reg)
                self.machine_cycle = .OpcodeFetch
            }
        }
        opcodes[0xE9] = { // JP (HL)
            self.regs.pc = self.addressFromPair(self.regs.h, self.regs.l)
        }
        opcodes[0xEA] = { // JP PE &0000
            switch self.m_cycle {
            case 1:
                if self.regs.f.bit(PV) == 1 {
                    self.pins.address_bus = self.regs.pc
                    self.regs.pc++
                    self.machine_cycle = .MemoryRead
                } else {
                    self.regs.pc = self.regs.pc + 2
                }
            case 2:
                self.control_reg = self.pins.data_bus
                self.pins.address_bus = self.regs.pc
                self.regs.pc++
            default:
                self.regs.pc = self.addressFromPair(self.pins.data_bus, self.control_reg)
                self.machine_cycle = .OpcodeFetch
            }
        }
        opcodes[0xEB] = { // EX DE, HL
            let d = self.regs.d
            let e = self.regs.e
            self.regs.d = self.regs.h
            self.regs.e = self.regs.l
            self.regs.h = d
            self.regs.l = e
        }
        opcodes[0xEC] = { // CALL PE &0000
            switch self.m_cycle {
            case 1:
                self.regs.pc = self.regs.pc + 2
                if self.regs.f.bit(PV) == 1 {
                    self.regs.sp--
                    self.pins.address_bus = self.regs.sp
                    self.pins.data_bus = self.regs.pc.high
                    self.machine_cycle = .MemoryWrite
                }
            case 2:
                self.regs.sp--
                self.pins.address_bus = self.regs.sp
                self.pins.data_bus = self.regs.pc.low
            case 3:
                self.machine_cycle = .TimeWait
                if self.t_cycle == 4 {
                    self.regs.pc = self.regs.pc - 2
                    self.pins.address_bus = self.regs.pc
                    self.regs.pc++
                    self.machine_cycle = .MemoryRead
                }
            case 4:
                self.control_reg = self.pins.data_bus
                self.pins.address_bus = self.regs.pc
                self.regs.pc++
            default:
                self.regs.pc = self.addressFromPair(self.pins.data_bus, self.control_reg)
                self.machine_cycle = .OpcodeFetch
            }
        }
        opcodes[0xED] = { // PREFIX *** ED ***
            self.id_opcode_table = prefix_ED
        }
        opcodes[0xEE] = { // XOR &00
            switch self.m_cycle {
            case 1:
                self.pins.address_bus = self.regs.pc
                self.regs.pc++
                self.machine_cycle = .MemoryRead
            default:
                self.regs.a = self.ulaCall(self.regs.a, self.pins.data_bus, ulaOp: .Xor, ignoreCarry: false)
                self.machine_cycle = .OpcodeFetch
            }
        }
        opcodes[0xEF] = { // RST &28
            self.rst(0x0028)
        }
        opcodes[0xF0] = { // RET P
            switch self.m_cycle {
            case 1:
                if self.regs.f.bit(S) == 0 {
                    self.pins.address_bus = self.regs.sp
                    self.regs.sp++
                    self.machine_cycle = .MemoryRead
                }
            case 2:
                self.control_reg = self.pins.data_bus
                self.pins.address_bus = self.regs.sp
                self.regs.sp++
            default:
                self.regs.pc = self.addressFromPair(self.pins.data_bus, self.control_reg)
                self.machine_cycle = .OpcodeFetch
            }
        }
        opcodes[0xF1] = { // POP AF
            switch self.m_cycle {
            case 1:
                self.pins.address_bus = self.regs.sp
                self.regs.sp++
                self.machine_cycle = .MemoryRead
            case 2:
                self.regs.f = self.pins.data_bus
                self.pins.address_bus = self.regs.sp
                self.regs.sp++
            default:
                self.regs.a = self.pins.data_bus
                self.machine_cycle = .OpcodeFetch
            }
        }
        opcodes[0xF2] = { // JP P &0000
            switch self.m_cycle {
            case 1:
                if self.regs.f.bit(S) == 0 {
                    self.pins.address_bus = self.regs.pc
                    self.regs.pc++
                    self.machine_cycle = .MemoryRead
                } else {
                    self.regs.pc = self.regs.pc + 2
                }
            case 2:
                self.control_reg = self.pins.data_bus
                self.pins.address_bus = self.regs.pc
                self.regs.pc++
            default:
                self.regs.pc = self.addressFromPair(self.pins.data_bus, self.control_reg)
                self.machine_cycle = .OpcodeFetch
            }
        }
        opcodes[0xF3] = { // DI
            self.regs.IFF1 = false
            self.regs.IFF2 = false
        }
        opcodes[0xF4] = { // CALL P &0000
            switch self.m_cycle {
            case 1:
                self.regs.pc = self.regs.pc + 2
                if self.regs.f.bit(S) == 0 {
                    self.regs.sp--
                    self.pins.address_bus = self.regs.sp
                    self.pins.data_bus = self.regs.pc.high
                    self.machine_cycle = .MemoryWrite
                }
            case 2:
                self.regs.sp--
                self.pins.address_bus = self.regs.sp
                self.pins.data_bus = self.regs.pc.low
            case 3:
                self.machine_cycle = .TimeWait
                if self.t_cycle == 4 {
                    self.regs.pc = self.regs.pc - 2
                    self.pins.address_bus = self.regs.pc
                    self.regs.pc++
                    self.machine_cycle = .MemoryRead
                }
            case 4:
                self.control_reg = self.pins.data_bus
                self.pins.address_bus = self.regs.pc
                self.regs.pc++
            default:
                self.regs.pc = self.addressFromPair(self.pins.data_bus, self.control_reg)
                self.machine_cycle = .OpcodeFetch
            }
        }
        opcodes[0xF5] = { // PUSH AF
            switch self.m_cycle {
            case 1:
                self.machine_cycle = .TimeWait
                if self.t_cycle == 5 {
                    self.regs.sp--
                    self.pins.address_bus = self.regs.sp
                    self.pins.data_bus = self.regs.a
                    self.machine_cycle = .MemoryWrite
                }
            case 2:
                self.regs.sp--
                self.pins.address_bus = self.regs.sp
                self.pins.data_bus = self.regs.f
            default:
                self.machine_cycle = .OpcodeFetch
            }
        }
        opcodes[0xF6] = { // OR &00
            switch self.m_cycle {
            case 1:
                self.pins.address_bus = self.regs.pc
                self.regs.pc++
                self.machine_cycle = .MemoryRead
            default:
                self.regs.a = self.ulaCall(self.regs.a, self.pins.data_bus, ulaOp: .Or, ignoreCarry: false)
                self.machine_cycle = .OpcodeFetch
            }
        }
        opcodes[0xF7] = { // RST &30
            self.rst(0x0030)
        }
        opcodes[0xF8] = { // RET M
            switch self.m_cycle {
            case 1:
                if self.regs.f.bit(S) == 1 {
                    self.pins.address_bus = self.regs.sp
                    self.regs.sp++
                    self.machine_cycle = .MemoryRead
                }
            case 2:
                self.control_reg = self.pins.data_bus
                self.pins.address_bus = self.regs.sp
                self.regs.sp++
            default:
                self.regs.pc = self.addressFromPair(self.pins.data_bus, self.control_reg)
                self.machine_cycle = .OpcodeFetch
            }
        }
        opcodes[0xF9] = { // LD SP, HL
            self.machine_cycle = .TimeWait
            if self.t_cycle == 6 {
                self.regs.sp = self.addressFromPair(self.regs.h, self.regs.l)
                self.machine_cycle = .OpcodeFetch
            }
        }
        opcodes[0xFA] = { // JP M &0000
            switch self.m_cycle {
            case 1:
                if self.regs.f.bit(S) == 1 {
                    self.pins.address_bus = self.regs.pc
                    self.regs.pc++
                    self.machine_cycle = .MemoryRead
                } else {
                    self.regs.pc = self.regs.pc + 2
                }
            case 2:
                self.control_reg = self.pins.data_bus
                self.pins.address_bus = self.regs.pc
                self.regs.pc++
            default:
                self.regs.pc = self.addressFromPair(self.pins.data_bus, self.control_reg)
                self.machine_cycle = .OpcodeFetch
            }
        }
        opcodes[0xFB] = { // EI
            self.regs.IFF1 = true
            self.regs.IFF2 = true
        }
        opcodes[0xFC] = { // CALL M &0000
            switch self.m_cycle {
            case 1:
                self.regs.pc = self.regs.pc + 2
                if self.regs.f.bit(S) == 1 {
                    self.regs.sp--
                    self.pins.address_bus = self.regs.sp
                    self.pins.data_bus = self.regs.pc.high
                    self.machine_cycle = .MemoryWrite
                }
            case 2:
                self.regs.sp--
                self.pins.address_bus = self.regs.sp
                self.pins.data_bus = self.regs.pc.low
            case 3:
                self.machine_cycle = .TimeWait
                if self.t_cycle == 4 {
                    self.regs.pc = self.regs.pc - 2
                    self.pins.address_bus = self.regs.pc
                    self.regs.pc++
                    self.machine_cycle = .MemoryRead
                }
            case 4:
                self.control_reg = self.pins.data_bus
                self.pins.address_bus = self.regs.pc
                self.regs.pc++
            default:
                self.regs.pc = self.addressFromPair(self.pins.data_bus, self.control_reg)
                self.machine_cycle = .OpcodeFetch
            }
        }
        opcodes[0xFD] = { // PREFIX *** FD ***
            self.id_opcode_table = prefix_FD
        }
        opcodes[0xFE] = { // CP &00
            switch self.m_cycle {
            case 1:
                self.pins.address_bus = self.regs.pc
                self.regs.pc++
                self.machine_cycle = .MemoryRead
            default:
                self.ulaCall(self.regs.a, self.pins.data_bus, ulaOp: .Sub, ignoreCarry: false)
                self.machine_cycle = .OpcodeFetch
            }
        }
        opcodes[0xFF] = { // RST &38
            self.rst(0x0038)
        }
    }
}