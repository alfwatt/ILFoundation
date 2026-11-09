import Foundation

// MARK: - Byte Order Marks

public extension String.Encoding {
    /// the byte order mark of the UTF encodings with a byte order, or nil for other encodings,
    /// Foundation writes `.utf16` and `.utf32` with a mark in the platform's byte order
    var byteOrderMark: Data? {
        switch self {
        case .utf8: Data([0xEF, 0xBB, 0xBF])
        case .utf16BigEndian: Data([0xFE, 0xFF])
        case .utf16LittleEndian: Data([0xFF, 0xFE])
        case .utf32BigEndian: Data([0x00, 0x00, 0xFE, 0xFF])
        case .utf32LittleEndian: Data([0xFF, 0xFE, 0x00, 0x00])
        default: nil
        }
    }

    /// @returns the UTF encoding of the
    /// @param data provided from its byte order mark, or UTF-8 if it hasn't got one
    static func utf(of data: Data) -> String.Encoding {
        // UTF-32LE before UTF-16LE, their marks start with the same two bytes
        let marked: [String.Encoding] = [.utf8, .utf32BigEndian, .utf32LittleEndian, .utf16BigEndian, .utf16LittleEndian]
        return marked.first { data.starts(with: $0.byteOrderMark!) } ?? .utf8
    }

    /// @returns the encoding of the
    /// @param data provided and the string it decodes to, detected by Foundation, allowing lossy conversion,
    /// with the byte order of UTF-16 and UTF-32 from its byte order mark, or nil if it couldn't be decoded
    static func detected(in data: Data) -> (encoding: String.Encoding, string: String)? {
        var converted: NSString?
        let raw = NSString.stringEncoding(for: data, encodingOptions: [.allowLossyKey: true],
                                          convertedString: &converted, usedLossyConversion: nil)
        guard raw != 0, let converted else { return nil }
        var encoding = String.Encoding(rawValue: raw)
        if encoding == .utf16 || encoding == .utf32 { // the byte order
            let marked = utf(of: data)
            if marked != .utf8 {
                encoding = marked
            }
        }
        return (encoding, converted as String)
    }
}

// MARK: - Decoding

public extension String {
    /// decode the
    /// @param utfData provided in the UTF encoding of its byte order mark, or UTF-8
    init?(utfData: Data) {
        self.init(data: utfData, encoding: .utf(of: utfData))
    }

    /// decode the
    /// @param data provided in the encoding Foundation detects, or as hex if it can't be decoded
    init(detecting data: Data) {
        self = String.Encoding.detected(in: data)?.string ?? data.hexString
    }

    /// decode a string from the
    /// @param utTypeData of a pasteboard item, e.g. a keyed archive or plist of strings, or text
    init?(utTypeData: Data) {
        if utTypeData.isBinaryPropertyList {
            let plist = try? PropertyListSerialization.propertyList(from: utTypeData, format: nil)
            if let archive = plist as? [String: Any], let string = (archive["$objects"] as? [Any])?.last as? String {
                self = string // a keyed archive of a string
            }
            else if let string = (plist as? [Any])?.first as? String {
                self = string
            }
            else {
                return nil
            }
        }
        else {
            self.init(detecting: utTypeData)
        }
    }

    /// the string in the
    /// @param encoding provided, after its byte order mark, or nil if the string can't be encoded
    func data(byteOrderMarked encoding: String.Encoding) -> Data? {
        guard let encoded = data(using: encoding) else { return nil }
        guard let mark = encoding.byteOrderMark, !encoded.starts(with: mark) else { return encoded }
        return mark + encoded
    }

    /// the string split into lines of at most
    /// @param maxLength characters
    func lines(maxLength: Int) -> [String] {
        guard maxLength > 0 else { return [self] }
        var lines: [String] = []
        var start = startIndex
        while start < endIndex {
            let end = index(start, offsetBy: maxLength, limitedBy: endIndex) ?? endIndex
            lines.append(String(self[start..<end]))
            start = end
        }
        return lines
    }
}

// MARK: - UTF-8 Error Detection and Correction

// https://athenstean.com/blog/detecing-fixing-encoding-problems-nsstring/

public extension String {
    /// the string, if all of it is UTF-8 which was decoded as Windows-1252 or Latin-1, decoded as UTF-8
    private var decodedMisreadUTF8: String? {
        for misread in [String.Encoding.windowsCP1252, .isoLatin1] {
            if let bytes = data(using: misread, allowLossyConversion: false),
               let decoded = String(data: bytes, encoding: .utf8), decoded != self {
                return decoded
            }
        }
        return nil
    }

    /// does the string have UTF-8 decoded as Windows-1252 or Latin-1, e.g. "Ã¤" for "ä"?
    var containsUTF8Errors: Bool {
        if decodedMisreadUTF8 != nil {
            return true
        }
        let units = Array(utf16)
        for index in units.indices.dropLast() {
            let next = units[index + 1]
            if units[index] == 0xC2 && (0xA0...0xBF).contains(next) { // degree signs and the like
                return true
            }
            if units[index] == 0xC3 && (0x80...0xBF).contains(next) { // umlauts and accents
                return true
            }
        }
        return false
    }

    /// the string with UTF-8 decoded as Windows-1252 or Latin-1 corrected, e.g. "Ã¤" to "ä", and stray byte order
    /// marks removed, the whole string if it can be, otherwise the Latin-1 pairs in it
    func cleaningUTF8Errors() -> String {
        if let decoded = decodedMisreadUTF8 {
            return decoded.replacingOccurrences(of: "\u{FEFF}", with: "")
        }
        let units = Array(utf16)
        var cleaned: [UInt16] = []
        cleaned.reserveCapacity(units.count)
        var index = 0
        while index < units.count {
            let unit = units[index]
            let next = index + 1 < units.count ? units[index + 1] : nil
            if unit == 0xC2, let next, (0xA0...0xBF).contains(next) {
                cleaned.append(next)
                index += 2
            }
            else if unit == 0xC3, let next, (0x80...0xBF).contains(next) {
                cleaned.append(0x40 + next)
                index += 2
            }
            else if unit == 0xEF, index + 2 < units.count, units[index + 1] == 0xBB, units[index + 2] == 0xBF {
                index += 3 // a byte order mark
            }
            else {
                cleaned.append(unit)
                index += 1
            }
        }
        return String(decoding: cleaned, as: UTF16.self)
    }
}
