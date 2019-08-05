import Foundation

extension LR35902 {
  static let opcodeDescription: [UInt8: Instruction] = [
    0x00: .nop,
    0x01: .ld(.bc, .immediate16),
    0x02: .ld(.bcAddress, .a),
    0x03: .inc(.bc),
    0x04: .inc(.b),
    0x05: .dec(.b),
    0x06: .ld(.b, .immediate8),
    0x07: .rlca,
    0x08: .ld(.immediate16address, .sp),
    0x09: .add(.hl, .bc),
    0x0a: .ld(.a, .bcAddress),
    0x0b: .dec(.bc),
    0x0c: .inc(.c),
    0x0d: .dec(.c),
    0x0e: .ld(.c, .immediate8),
    0x0f: .rrca,

    0x10: .stop,
    0x11: .ld(.de, .immediate16),
    0x12: .ld(.deAddress, .a),
    0x13: .inc(.de),
    0x14: .inc(.d),
    0x15: .dec(.d),
    0x16: .ld(.d, .immediate8),
    0x17: .rla,
    0x18: .jr(.immediate8),
    0x19: .add(.hl, .de),
    0x1a: .ld(.a, .deAddress),
    0x1b: .dec(.de),
    0x1c: .inc(.e),
    0x1d: .dec(.e),
    0x1e: .ld(.e, .immediate8),
    0x1f: .rra,

    0x20: .jr(.nz, .immediate8),
    0x21: .ld(.hl, .immediate16),
    0x22: .ldi(.hlAddress, .a),
    0x23: .inc(.hl),
    0x24: .inc(.h),
    0x25: .dec(.h),
    0x26: .ld(.h, .immediate8),
    0x27: .daa,
    0x28: .jr(.z, .immediate8),
    0x29: .add(.hl, .hl),
    0x2a: .ldi(.a, .hlAddress),
    0x2b: .dec(.hl),
    0x2c: .inc(.l),
    0x2d: .dec(.l),
    0x2e: .ld(.l, .immediate8),
    0x2f: .cpl,

    0x30: .jr(.nc, .immediate8),
    0x31: .ld(.sp, .immediate16),
    0x32: .ldd(.hlAddress, .a),
    0x33: .inc(.sp),
    0x34: .inc(.hlAddress),
    0x35: .dec(.hlAddress),
    0x36: .ld(.hlAddress, .immediate8),
    0x37: .scf,
    0x38: .jr(.c, .immediate8),
    0x39: .add(.hl, .sp),
    0x3a: .ldd(.a, .hlAddress),
    0x3b: .dec(.sp),
    0x3c: .inc(.a),
    0x3d: .dec(.a),
    0x3e: .ld(.a, .immediate8),
    0x3f: .ccf,

    0x40: .ld(.b, .b),
    0x41: .ld(.b, .c),
    0x42: .ld(.b, .d),
    0x43: .ld(.b, .e),
    0x44: .ld(.b, .h),
    0x45: .ld(.b, .l),
    0x46: .ld(.b, .hlAddress),
    0x47: .ld(.b, .a),
    0x48: .ld(.c, .b),
    0x49: .ld(.c, .c),
    0x4a: .ld(.c, .d),
    0x4b: .ld(.c, .e),
    0x4c: .ld(.c, .h),
    0x4d: .ld(.c, .l),
    0x4e: .ld(.c, .hlAddress),
    0x4f: .ld(.c, .a),

    0x50: .ld(.d, .b),
    0x51: .ld(.d, .c),
    0x52: .ld(.d, .d),
    0x53: .ld(.d, .e),
    0x54: .ld(.d, .h),
    0x55: .ld(.d, .l),
    0x56: .ld(.d, .hlAddress),
    0x57: .ld(.d, .a),
    0x58: .ld(.e, .b),
    0x59: .ld(.e, .c),
    0x5a: .ld(.e, .d),
    0x5b: .ld(.e, .e),
    0x5c: .ld(.e, .h),
    0x5d: .ld(.e, .l),
    0x5e: .ld(.e, .hlAddress),
    0x5f: .ld(.e, .a),

    0x60: .ld(.h, .b),
    0x61: .ld(.h, .c),
    0x62: .ld(.h, .d),
    0x63: .ld(.h, .e),
    0x64: .ld(.h, .h),
    0x65: .ld(.h, .l),
    0x66: .ld(.h, .hlAddress),
    0x67: .ld(.h, .a),
    0x68: .ld(.l, .b),
    0x69: .ld(.l, .c),
    0x6a: .ld(.l, .d),
    0x6b: .ld(.l, .e),
    0x6c: .ld(.l, .h),
    0x6d: .ld(.l, .l),
    0x6e: .ld(.l, .hlAddress),
    0x6f: .ld(.l, .a),

    0x70: .ld(.hlAddress, .b),
    0x71: .ld(.hlAddress, .c),
    0x72: .ld(.hlAddress, .d),
    0x73: .ld(.hlAddress, .e),
    0x74: .ld(.hlAddress, .h),
    0x75: .ld(.hlAddress, .l),
    0x76: .halt,
    0x77: .ld(.hlAddress, .a),
    0x78: .ld(.a, .b),
    0x79: .ld(.a, .c),
    0x7a: .ld(.a, .d),
    0x7b: .ld(.a, .e),
    0x7c: .ld(.a, .h),
    0x7d: .ld(.a, .l),
    0x7e: .ld(.a, .hlAddress),
    0x7f: .ld(.a, .a),

    0x80: .add(.b),
    0x81: .add(.c),
    0x82: .add(.d),
    0x83: .add(.e),
    0x84: .add(.h),
    0x85: .add(.l),
    0x86: .add(.hlAddress),
    0x87: .add(.a),
    0x88: .adc(.b),
    0x89: .adc(.c),
    0x8a: .adc(.d),
    0x8b: .adc(.e),
    0x8c: .adc(.h),
    0x8d: .adc(.l),
    0x8e: .adc(.hlAddress),
    0x8f: .adc(.a),

    0x90: .sub(.b),
    0x91: .sub(.c),
    0x92: .sub(.d),
    0x93: .sub(.e),
    0x94: .sub(.h),
    0x95: .sub(.l),
    0x96: .sub(.hlAddress),
    0x97: .sub(.a),
    0x98: .sbc(.b),
    0x99: .sbc(.c),
    0x9a: .sbc(.d),
    0x9b: .sbc(.e),
    0x9c: .sbc(.h),
    0x9d: .sbc(.l),
    0x9e: .sbc(.hlAddress),
    0x9f: .sbc(.a),

    0xa0: .and(.b),
    0xa1: .and(.c),
    0xa2: .and(.d),
    0xa3: .and(.e),
    0xa4: .and(.h),
    0xa5: .and(.l),
    0xa6: .and(.hlAddress),
    0xa7: .and(.a),
    0xa8: .xor(.b),
    0xa9: .xor(.c),
    0xaa: .xor(.d),
    0xab: .xor(.e),
    0xac: .xor(.h),
    0xad: .xor(.l),
    0xae: .xor(.hlAddress),
    0xaf: .xor(.a),

    0xb0: .or(.b),
    0xb1: .or(.c),
    0xb2: .or(.d),
    0xb3: .or(.e),
    0xb4: .or(.h),
    0xb5: .or(.l),
    0xb6: .or(.hlAddress),
    0xb7: .or(.a),
    0xb8: .cp(.b),
    0xb9: .cp(.c),
    0xba: .cp(.d),
    0xbb: .cp(.e),
    0xbc: .cp(.h),
    0xbd: .cp(.l),
    0xbe: .cp(.hlAddress),
    0xbf: .cp(.a),

    0xc0: .retC(.nz),
    0xc1: .pop(.bc),
    0xc2: .jp(.nz, .immediate16),
    0xc3: .jp(.immediate16),
    0xc4: .call(.nz, .immediate16),
    0xc5: .push(.bc),
    0xc6: .add(.immediate8),
    0xc7: .rst(.x00),
    0xc8: .retC(.z),
    0xc9: .ret,
    0xca: .jp(.z, .immediate16),
    0xcb: .cb,
    0xcc: .call(.z, .immediate16),
    0xcd: .call(.immediate16),
    0xce: .adc(.immediate8),
    0xcf: .rst(.x08),

    0xd0: .retC(.nc),
    0xd1: .pop(.de),
    0xd2: .jp(.nc, .immediate16),
    0xd3: .invalid,
    0xd4: .call(.nc, .immediate16),
    0xd5: .push(.de),
    0xd6: .sub(.immediate8),
    0xd7: .rst(.x10),
    0xd8: .retC(.c),
    0xd9: .reti,
    0xda: .jp(.c, .immediate16),
    0xdb: .invalid,
    0xdc: .call(.c, .immediate16),
    0xdd: .invalid,
    0xde: .sbc(.immediate8),
    0xdf: .rst(.x18),

    0xe0: .ld(.ffimmediate8Address, .a),
    0xe1: .pop(.hl),
    0xe2: .ld(.ffccAddress, .a),
    0xe3: .invalid,
    0xe4: .invalid,
    0xe5: .push(.hl),
    0xe6: .and(.immediate8),
    0xe7: .rst(.x20),
    0xe8: .add(.sp, .immediate8),
    0xe9: .jp(.hl),
    0xea: .ld(.immediate16, .a),
    0xeb: .invalid,
    0xec: .invalid,
    0xed: .invalid,
    0xee: .xor(.immediate8),
    0xef: .rst(.x28),

    0xf0: .ld(.a, .ffimmediate8Address),
    0xf1: .pop(.af),
    0xf2: .ld(.a, .ffccAddress),
    0xf3: .di,
    0xf4: .invalid,
    0xf5: .push(.af),
    0xf6: .or(.immediate8),
    0xf7: .rst(.x30),
    0xf8: .ld(.hl, .spPlusImmediate8),
    0xf9: .ld(.sp, .hl),
    0xfa: .ld(.a, .immediate16),
    0xfb: .ei,
    0xfc: .invalid,
    0xfd: .invalid,
    0xfe: .cp(.immediate8),
    0xff: .rst(.x38),
  ]
}
