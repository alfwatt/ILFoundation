import Foundation

public extension Data {
    /// the data as lowercase hexadecimal, two digits for each byte
    var hexString: String {
        let digits = Array("0123456789abcdef".utf8)
        var hex = [UInt8]()
        hex.reserveCapacity(count * 2)
        for byte in self {
            hex.append(digits[Int(byte >> 4)])
            hex.append(digits[Int(byte & 0x0f)])
        }
        return String(decoding: hex, as: UTF8.self)
    }

    /// the data in the
    /// @param hexString provided, two digits for each byte in either case, or nil if it isn't hex
    init?(hexString: some StringProtocol) {
        let digits = Array(hexString.utf8)
        guard digits.count.isMultiple(of: 2) else { return nil }
        var bytes = [UInt8]()
        bytes.reserveCapacity(digits.count / 2)
        var index = 0
        while index < digits.count {
            guard let high = Self.hexValue(digits[index]), let low = Self.hexValue(digits[index + 1]) else { return nil }
            bytes.append(high << 4 | low)
            index += 2
        }
        self.init(bytes)
    }

    private static func hexValue(_ digit: UInt8) -> UInt8? {
        switch digit {
        case UInt8(ascii: "0")...UInt8(ascii: "9"): digit - UInt8(ascii: "0")
        case UInt8(ascii: "a")...UInt8(ascii: "f"): digit - UInt8(ascii: "a") + 10
        case UInt8(ascii: "A")...UInt8(ascii: "F"): digit - UInt8(ascii: "A") + 10
        default: nil
        }
    }

    /// the magic number at the start of binary property lists, "bplist00"
    static let binaryPropertyListMagic = Data("bplist00".utf8)

    /// is the data a binary property list?
    var isBinaryPropertyList: Bool {
        starts(with: Self.binaryPropertyListMagic)
    }
}
