import XCTest
import CoreGraphics
import ILFoundation

final class ILFoundationTests: XCTestCase {

    // MARK: - Reference Data and Hashcodes

    // the null and standard test text "The quick brown fox jumps over the lazy dog" as utf8 data
    let nullStringData = Data()
    let quickBrownData = Data("The quick brown fox jumps over the lazy dog".utf8)

    let nullHashes: [HashFunction: String] = [
        .md2: "8350e5a3e24c153df2275c9f80692773",
        .md4: "31d6cfe0d16ae931b73c59d7e0c089c0",
        .md5: "d41d8cd98f00b204e9800998ecf8427e",
        .sha1: "da39a3ee5e6b4b0d3255bfef95601890afd80709",
        .sha2_224: "d14a028c2a3a2bc9476102bb288234c415a2b01f828ea62ac5b3e42f",
        .sha2_256: "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
        .sha2_384: "38b060a751ac96384cd9327eb1b1e36a21fdb71114be07434c0cc7bf63f6e1da274edebfe76f65fbd51ad2f14898b95b",
        .sha2_512: "cf83e1357eefb8bdf1542850d66d8007d620e4050b5715dc83f4a921d36ce9ce47d0d13c5d85f2b0ff8318d2877eec2f63b931bd47417a81a538327af927da3e"
    ]

    let quickHashes: [HashFunction: String] = [
        .md2: "03d85a0d629d2c442e987525319fc471",
        .md4: "1bee69a46ba811185c194762abaeae90",
        .md5: "9e107d9d372bb6826bd81d3542a419d6",
        .sha1: "2fd4e1c67a2d28fced849ee1bb76e7391b93eb12",
        .sha2_224: "730e109bd7a8a32b1cb9d9a09aa2325d2430587ddbc0c38bad911525",
        .sha2_256: "d7a8fbb307d7809469ca9abcb0082e4f8d5651e46d3cdb762d02d0bf37c9e592",
        .sha2_384: "ca737f1014a48f4c0b6dd43cb177b0afd9e5169367544c494011e3317dbf9a509cb1e5dc1e85a941bbee3d7f2afbc9b1",
        .sha2_512: "07e547d9586f6a73f73fbac0435ed76951218fb7d0c8d788a309d785436bbb642e93a252a954f23912547d1e8a3b5ed6e1bfd7097821233fa0538f3db854fee6"
    ]

    // MARK: - Message Digests

    func testNullDigests() {
        for function in HashFunction.allCases {
            XCTAssertEqual(nullStringData.digest(function).hexString, nullHashes[function], function.name)
        }
    }

    func testQuickBrownFoxDigests() {
        for function in HashFunction.allCases {
            XCTAssertEqual(quickBrownData.digest(function).hexString, quickHashes[function], function.name)
            XCTAssertEqual(quickBrownData.digest(function).count, function.digestLength, function.name)
        }
    }

    func testDigestProperties() {
        XCTAssertEqual(quickBrownData.md2.hexString, quickHashes[.md2])
        XCTAssertEqual(quickBrownData.md4.hexString, quickHashes[.md4])
        XCTAssertEqual(quickBrownData.md5.hexString, quickHashes[.md5])
        XCTAssertEqual(quickBrownData.sha1.hexString, quickHashes[.sha1])
        XCTAssertEqual(quickBrownData.sha2_224.hexString, quickHashes[.sha2_224])
        XCTAssertEqual(quickBrownData.sha2_256.hexString, quickHashes[.sha2_256])
        XCTAssertEqual(quickBrownData.sha2_384.hexString, quickHashes[.sha2_384])
        XCTAssertEqual(quickBrownData.sha2_512.hexString, quickHashes[.sha2_512])
    }

    func testIncrementalDigests() {
        for function in HashFunction.allCases {
            var hash = IncrementalHash(function)
            for word in quickBrownData.split(separator: UInt8(ascii: " "), omittingEmptySubsequences: false).enumerated() {
                if word.offset > 0 {
                    hash.update(Data(" ".utf8))
                }
                hash.update(word.element)
            }
            XCTAssertEqual(hash.finalize().hexString, quickHashes[function], function.name)
        }
    }

    // MARK: - Streams

    func testInputStreamDigests() throws {
        for function in HashFunction.allCases {
            XCTAssertEqual(try InputStream(data: quickBrownData).digest(function).hexString, quickHashes[function], function.name)
        }
    }

    func testStreamHasherAllDigests() throws {
        var progress: [Int] = []
        let digests = try StreamHasher.digests(of: InputStream(data: quickBrownData)) { progress.append($0) }
        XCTAssertEqual(digests.count, HashFunction.allCases.count)
        for function in HashFunction.allCases {
            XCTAssertEqual(digests[function]?.hexString, quickHashes[function], function.name)
        }
        XCTAssertEqual(progress, [quickBrownData.count])
    }

    func testStreamHasherLargerThanBuffer() throws {
        let large = Data(repeating: 0x42, count: StreamHasher.bufferSize * 2 + 7)
        var progress: [Int] = []
        let digests = try StreamHasher.digests(of: InputStream(data: large), [.md5, .sha2_256]) { progress.append($0) }
        XCTAssertEqual(digests[.md5], large.md5)
        XCTAssertEqual(digests[.sha2_256], large.sha2_256)
        XCTAssertEqual(progress.last, large.count)
        XCTAssertEqual(progress.count, 3)
    }

    func testStreamHasherEmptyStream() throws {
        let digests = try StreamHasher.digests(of: InputStream(data: nullStringData), [.sha1])
        XCTAssertEqual(digests[.sha1]?.hexString, nullHashes[.sha1])
    }

    func testStreamHasherUnreadableFile() {
        let missing = InputStream(url: URL(fileURLWithPath: "/no/such/file"))!
        XCTAssertThrowsError(try StreamHasher.digests(of: missing, [.md5]))
    }

    // MARK: - Hex

    func testHexRoundTrip() {
        let data = Data([0x00, 0x01, 0x7f, 0x80, 0xfe, 0xff])
        XCTAssertEqual(data.hexString, "00017f80feff")
        XCTAssertEqual(Data(hexString: "00017F80FEFF"), data)
        XCTAssertNil(Data(hexString: "abc"), "odd number of digits")
        XCTAssertNil(Data(hexString: "zz"), "not hex")
        XCTAssertEqual(Data(hexString: ""), Data())
    }

    func testBinaryPropertyList() throws {
        let binary = try PropertyListSerialization.data(fromPropertyList: ["key": "value"], format: .binary, options: 0)
        let xml = try PropertyListSerialization.data(fromPropertyList: ["key": "value"], format: .xml, options: 0)
        XCTAssertTrue(binary.isBinaryPropertyList)
        XCTAssertFalse(xml.isBinaryPropertyList)
    }

    // MARK: - RFC 2397 data: URL Tests

    func testDataURLWithData() throws {
        let exampleData = Data("testDataURLWithData()".utf8)
        let testURL = try XCTUnwrap(URL(dataURLWith: exampleData))
        XCTAssertFalse(testURL.isFileURL)
        XCTAssertTrue(testURL.absoluteString.hasPrefix("data:;base64,"))
        XCTAssertEqual(testURL.dataURLData, exampleData)
        XCTAssertEqual(Data(dataURL: exampleData.dataURL), exampleData)
    }

    func testDataURLEncodings() throws {
        let exampleData = Data("Hello, World!".utf8)
        for encoding in [DataURLEncoding.utf8, .hex, .base64, nil] {
            let url = try XCTUnwrap(URL(dataURLWith: exampleData, mediaType: "text/plain", parameters: ["charset": "UTF-8"], encoding: encoding))
            let contents = try XCTUnwrap(url.dataURLContents)
            XCTAssertEqual(contents.data, exampleData, "\(String(describing: encoding))")
            XCTAssertEqual(contents.mediaType, "text/plain")
            XCTAssertEqual(contents.parameters, ["charset": "UTF-8"])
            XCTAssertEqual(contents.encoding, encoding)
        }
    }

    // `data:,`
    func testNullDataURL() throws {
        let testURL = try XCTUnwrap(URL(string: "data:,"))
        XCTAssertNotNil(testURL.dataURLContents)
        XCTAssertNil(testURL.dataURLData)
    }

    // `data:,0`
    func testSingleByteDataURL() throws {
        let testData = try XCTUnwrap(URL(string: "data:,0")?.dataURLData)
        XCTAssertEqual(testData, Data("0".utf8))
    }

    // data:,Hello%20World
    func testStringDataURL() throws {
        let testData = try XCTUnwrap(URL(string: "data:,Hello%20World")?.dataURLData)
        XCTAssertEqual(testData, Data("Hello World".utf8))
    }

    // data:;hex,EFBBBF
    func testHexDataURL() throws {
        let testData = try XCTUnwrap(URL(string: "data:;hex,EFBBBF")?.dataURLData)
        XCTAssertEqual(testData.hexString.uppercased(), "EFBBBF")
    }

    // base64 encoded "1234567890"
    func testBase64DataURL() throws {
        let testData = try XCTUnwrap(URL(string: "data:application/octet-stream;base64,MTIzNDU2Nzg5MA==")?.dataURLData)
        XCTAssertEqual(String(data: testData, encoding: .utf8), "1234567890")
    }

    // data:text/example;foo=bar,
    func testDataURLParameters() throws {
        let contents = try XCTUnwrap(URL(string: "data:text/example;foo=bar,")?.dataURLContents)
        XCTAssertEqual(contents.mediaType, "text/example")
        XCTAssertEqual(contents.parameters, ["foo": "bar"])
        XCTAssertNil(contents.encoding)
        XCTAssertNil(contents.data)
    }

    // data:text/example;foo=bar;hex,FF
    func testDataURLParametersHex() throws {
        let contents = try XCTUnwrap(URL(string: "data:text/example;foo=bar;hex,FF")?.dataURLContents)
        XCTAssertEqual(contents.mediaType, "text/example")
        XCTAssertEqual(contents.parameters, ["foo": "bar"])
        XCTAssertEqual(contents.encoding, .hex)
        XCTAssertEqual(contents.data, Data([0xFF]))
    }

    // data:text/plain;charset=UTF-8;page=21,the%20data:1234,5678
    func testDataURLParametersImplicitEncoding() throws {
        let contents = try XCTUnwrap(URL(string: "data:text/plain;charset=UTF-8;page=21,the%20data:1234,5678")?.dataURLContents)
        XCTAssertEqual(contents.mediaType, "text/plain")
        XCTAssertEqual(contents.parameters, ["charset": "UTF-8", "page": "21"])
        XCTAssertNil(contents.encoding)
        XCTAssertEqual(contents.data, Data("the data:1234,5678".utf8))
    }

    func testNotADataURL() throws {
        let url = try XCTUnwrap(URL(string: "https://istumbler.net/"))
        XCTAssertNil(url.dataURLContents)
        XCTAssertNil(CGPoint(dataURL: url))
        XCTAssertNil(Date(dataURL: url))
    }

    // MARK: - Data X-Type URL Tests

    func testDataURLWithDate() throws {
        let testDate = Date()
        XCTAssertTrue(testDate.dataURL.absoluteString.hasPrefix("data:x-type/epoch-seconds,"))
        let dataDate = try XCTUnwrap(Date(dataURL: testDate.dataURL))
        XCTAssertEqual(testDate.timeIntervalSince1970, dataDate.timeIntervalSince1970, accuracy: 0.000_001)
    }

    func testDataURLWithDateInterval() throws {
        let testInterval = DateInterval(start: Date(), duration: 12345)
        let dataInterval = try XCTUnwrap(DateInterval(dataURL: testInterval.dataURL))
        XCTAssertEqual(testInterval.start.timeIntervalSince1970, dataInterval.start.timeIntervalSince1970, accuracy: 0.000_001)
        XCTAssertEqual(testInterval.duration, dataInterval.duration)
    }

    func testDataURLWithPoint() {
        let testPoint = CGPoint(x: 123.456, y: 789.012)
        XCTAssertEqual(CGPoint(dataURL: testPoint.dataURL), testPoint)
    }

    func testDataURLWithSize() {
        let testSize = CGSize(width: 123.456, height: 789.012)
        XCTAssertEqual(CGSize(dataURL: testSize.dataURL), testSize)
    }

    func testDataURLWithRect() {
        let testRect = CGRect(x: 123.456, y: 789.012, width: 345.678, height: 901.234)
        XCTAssertEqual(CGRect(dataURL: testRect.dataURL), testRect)
        XCTAssertNil(CGRect(dataURL: CGPoint.zero.dataURL), "a point isn't a rect")
    }

    func testDataURLWithVector() {
        let testVector = CGVector(dx: -1.5, dy: 2.25)
        XCTAssertEqual(CGVector(dataURL: testVector.dataURL), testVector)
    }

    func testDataURLWithRange() {
        let testRange = NSRange(location: 123, length: 456)
        XCTAssertEqual(NSRange(dataURL: testRange.dataURL), testRange)
    }

    func testDataURLWithMeasurement() throws {
        let testMeasure = Measurement(value: 123.456, unit: Unit(symbol: "cm"))
        let dataMeasure = try XCTUnwrap(Measurement<Unit>(dataURL: testMeasure.dataURL))
        XCTAssertEqual(dataMeasure.value, testMeasure.value)
        XCTAssertEqual(dataMeasure.unit.symbol, "cm")
    }

    func testDataURLWithRegex() throws {
        let testRegex = try NSRegularExpression(pattern: "^a, b+ [c-d]%$")
        let dataRegex = try XCTUnwrap(NSRegularExpression(dataURL: testRegex.dataURL))
        XCTAssertEqual(dataRegex.pattern, testRegex.pattern)
    }

    func testURNWithUUID() throws {
        let testUUID = UUID()
        XCTAssertTrue(testUUID.urn.absoluteString.hasPrefix("urn:uuid:"))
        XCTAssertEqual(UUID(urn: testUUID.urn), testUUID)
        XCTAssertNil(UUID(urn: try XCTUnwrap(URL(string: "urn:isbn:0451450523"))))
    }

    // MARK: - Pasteboard Data

    func testURLWithUTTypeData() throws {
        let url = try XCTUnwrap(URL(string: "https://istumbler.net/labs/infocard.html"))
        XCTAssertEqual(URL(utTypeData: Data(url.absoluteString.utf8)), url)
        let plist = try PropertyListSerialization.data(fromPropertyList: [url.absoluteString], format: .binary, options: 0)
        XCTAssertEqual(URL(utTypeData: plist), url)
        XCTAssertEqual(URL(utTypeData: url.dataRepresentation), url)
    }

    func testStringWithUTTypeData() throws {
        XCTAssertEqual(String(utTypeData: Data("plain text".utf8)), "plain text")
        let archive = try NSKeyedArchiver.archivedData(withRootObject: "archived text" as NSString, requiringSecureCoding: true)
        XCTAssertEqual(String(utTypeData: archive), "archived text")
        let plist = try PropertyListSerialization.data(fromPropertyList: ["first", "second"], format: .binary, options: 0)
        XCTAssertEqual(String(utTypeData: plist), "first")
    }

    // MARK: - UTF Detection

    func testUTF8EncodingDetection() {
        XCTAssertEqual(String.Encoding.utf(of: Data("UTF-8".utf8)), .utf8)
        XCTAssertEqual(String.Encoding.utf(of: "UTF-8".data(byteOrderMarked: .utf8)!), .utf8)
    }

    func testUTF16EncodingDetection() throws {
        let utf16Data = try XCTUnwrap("UTF-16".data(using: .utf16)) // Foundation writes its byte order mark
        XCTAssertEqual(String.Encoding.utf(of: utf16Data), .utf16LittleEndian)
        XCTAssertEqual(String(utfData: utf16Data)?.trimmingCharacters(in: CharacterSet(charactersIn: "\u{FEFF}")), "UTF-16")
    }

    func testUTF16BEDetection() throws {
        let data = try XCTUnwrap("UTF-16BE".data(byteOrderMarked: .utf16BigEndian))
        XCTAssertTrue(data.starts(with: [0xFE, 0xFF]))
        XCTAssertEqual(String.Encoding.utf(of: data), .utf16BigEndian)
        XCTAssertNotNil(String(utfData: data))
    }

    func testUTF16LEDetection() throws {
        let data = try XCTUnwrap("UTF-16LE".data(byteOrderMarked: .utf16LittleEndian))
        XCTAssertEqual(String.Encoding.utf(of: data), .utf16LittleEndian)
        XCTAssertNotNil(String(utfData: data))
    }

    func testUTF32BEDetection() throws {
        let data = try XCTUnwrap("UTF-32BE".data(byteOrderMarked: .utf32BigEndian))
        XCTAssertEqual(String.Encoding.utf(of: data), .utf32BigEndian)
        XCTAssertNotNil(String(utfData: data))
    }

    func testUTF32LEDetection() throws {
        let data = try XCTUnwrap("UTF-32LE".data(byteOrderMarked: .utf32LittleEndian))
        XCTAssertEqual(String.Encoding.utf(of: data), .utf32LittleEndian, "not UTF-16LE, its mark is a prefix of UTF-32LE's")
        XCTAssertNotNil(String(utfData: data))
    }

    func testDetectedEncoding() throws {
        let latin1 = try XCTUnwrap("Grüße".data(using: .isoLatin1))
        let detected = try XCTUnwrap(String.Encoding.detected(in: latin1))
        XCTAssertEqual(detected.string, "Grüße")
        XCTAssertEqual(String(detecting: Data("plain".utf8)), "plain")
    }

    // MARK: - UTF8 Error Detection and Correction

    func testUTF8ErrorDetection() {
        XCTAssertTrue("Ã„ Ã¤ Ã– Ã¶ Ãœ Ã¼ ÃŸ".containsUTF8Errors)
        XCTAssertFalse("Ä ä Ö ö Ü ü ß".containsUTF8Errors)
    }

    func testUTF8ErrorCorrection() {
        let cleaned = "Ã„ Ã¤ Ã– Ã¶ Ãœ Ã¼ ÃŸ".cleaningUTF8Errors()
        XCTAssertFalse(cleaned.containsUTF8Errors)
        XCTAssertEqual(cleaned, "Ä ä Ö ö Ü ü ß")
    }

    // MARK: - Lines

    func testLinesWithMaxLength() {
        let lines = "1234567890123456789012345678901234567".lines(maxLength: 5)
        XCTAssertEqual(lines.count, 8)
        XCTAssertEqual(lines.joined(), "1234567890123456789012345678901234567")
        for line in lines {
            XCTAssertTrue((1...5).contains(line.count))
        }
        XCTAssertEqual("".lines(maxLength: 5), [])
    }
}
