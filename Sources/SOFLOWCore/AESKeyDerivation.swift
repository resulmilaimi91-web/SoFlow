import Foundation

public enum AESKeyDerivation {
    public static let masterKey: Data = Data([
        0x30, 0x57, 0x2F, 0x52, 0x36, 0x4B, 0x3F, 0x47,
        0x30, 0x50, 0x41, 0x58, 0x11, 0x63, 0x2D, 0x2B
    ])

    public static func encryptParser(_ parserHex: String, padLength: Int = 32) throws -> String {
        guard padLength % 32 == 0 else {
            throw AESKeyDerivationError.badPadLength(padLength)
        }
        let padded = padRightWithZeros(parserHex, to: padLength)
        let plain = Data(hexString: padded) ?? Data()
        guard plain.count % 16 == 0, plain.count > 0 else {
            throw AESKeyDerivationError.badInputLength(plain.count)
        }
        return try DigestAES.encrypt(plain, key: masterKey)
    }

    public static func decryptToHex(_ cipherHex: String) throws -> String {
        let ct = Data(hexString: cipherHex) ?? Data()
        guard ct.count % 16 == 0, ct.count > 0 else {
            throw AESKeyDerivationError.badInputLength(ct.count)
        }
        return try DigestAES.decrypt(ct, key: masterKey)
    }

    public static func padRightWithZeros(_ s: String, to length: Int) -> String {
        if s.count >= length { return s }
        return s + String(repeating: "0", count: length - s.count)
    }
}

public enum AESKeyDerivationError: Error, CustomStringConvertible {
    case badPadLength(Int)
    case badInputLength(Int)

    public var description: String {
        switch self {
        case .badPadLength(let n): return "padLength must be a multiple of 32; got \(n)"
        case .badInputLength(let n): return "input must be non-empty multiple of 16 bytes; got \(n)"
        }
    }
}

extension Data {
    init?(hexString: String) {
        let s = hexString.count % 2 == 1 ? "0" + hexString : hexString
        var bytes = [UInt8]()
        bytes.reserveCapacity(s.count / 2)
        var i = s.startIndex
        while i < s.endIndex {
            let next = s.index(i, offsetBy: 2)
            guard let byte = UInt8(s[i..<next], radix: 16) else { return nil }
            bytes.append(byte)
            i = next
        }
        self = Data(bytes)
    }
}
