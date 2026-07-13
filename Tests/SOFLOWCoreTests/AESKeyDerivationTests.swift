import XCTest
@testable import SOFLOWCore

final class AESKeyDerivationTests: XCTestCase {
    func testMasterKeyLength() {
        XCTAssertEqual(AESKeyDerivation.masterKey.count, 16)
    }

    func testEncryptDecryptRoundTrip() throws {
        let hex = "D706A0000100"
        let encrypted = try AESKeyDerivation.encryptParser(hex, padLength: 32)
        let decrypted = try AESKeyDerivation.decryptToHex(encrypted)
        XCTAssertEqual(decrypted.prefix(hex.count), hex.prefix(hex.count))
    }

    func testPadRightWithZeros() {
        XCTAssertEqual(AESKeyDerivation.padRightWithZeros("AB", to: 32), "AB" + String(repeating: "0", count: 30))
        XCTAssertEqual(AESKeyDerivation.padRightWithZeros("ABCDEF1234567890", to: 32).count, 32)
    }

    func testHexToBytes() {
        let data = HexParser.hexToBytes("AABB")
        XCTAssertEqual(data.count, 2)
        XCTAssertEqual(data[0], 0xAA)
        XCTAssertEqual(data[1], 0xBB)
    }

    func testBytesToHexString() {
        let data = Data([0xDE, 0xAD, 0xBE, 0xEF])
        XCTAssertEqual(HexParser.bytesToHexString(data), "DEADBEEF")
    }

    func testChecksum() {
        let result = HexParser.checksum("D706A0000100", beginByte: 1, byteCount: 4)
        XCTAssertEqual(result.count, 2)
    }
}
