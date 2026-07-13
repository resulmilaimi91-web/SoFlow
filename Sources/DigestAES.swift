import Foundation
import CommonCrypto

public enum DigestAES {
    public static func encrypt(_ plain: Data, key: Data) throws -> String {
        let cipherBytes = try crypt(input: plain, key: key, op: kCCEncrypt)
        return HexParser.bytesToHexString(cipherBytes)
    }

    public static func decrypt(_ cipher: Data, key: Data) throws -> String {
        let plainBytes = try crypt(input: cipher, key: key, op: kCCDecrypt)
        return HexParser.bytesToHexString(plainBytes)
    }

    private static func crypt(input: Data, key: Data, op: Int) throws -> Data {
        var outLen = 0
        var output = Data(count: input.count + kCCBlockSizeAES128)
        let outputCapacity = output.count
        let status = output.withUnsafeMutableBytes { outBytes -> Int32 in
            input.withUnsafeBytes { inBytes -> Int32 in
                key.withUnsafeBytes { keyBytes -> Int32 in
                    CCCrypt(
                        CCOperation(op),
                        CCAlgorithm(kCCAlgorithmAES),
                        CCOptions(kCCOptionECBMode),
                        keyBytes.baseAddress, key.count,
                        nil,
                        inBytes.baseAddress, input.count,
                        outBytes.baseAddress, outputCapacity,
                        &outLen
                    )
                }
            }
        }
        if status != kCCSuccess {
            throw NSError(domain: "DigestAES", code: Int(status))
        }
        output.removeSubrange(outLen..<output.count)
        return output
    }
}
