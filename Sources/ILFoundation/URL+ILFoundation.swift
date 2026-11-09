import Foundation
import CoreGraphics

// MARK: - RFC 2397 data: URLs

/// The encodings of the data in a `data:` URL
public enum DataURLEncoding: String, Sendable {
    case utf8
    case hex
    case base64
}

/// The parts of a `data:` URL, e.g. `data:text/plain;charset=UTF-8;base64,SGVsbG8=`
public struct DataURLContents: Equatable, Sendable {
    /// the decoded data, nil if the URL has none or it couldn't be decoded
    public var data: Data?
    /// e.g. "text/plain", empty if the URL has none
    public var mediaType: String
    /// e.g. ["charset": "UTF-8"]
    public var parameters: [String: String]
    /// the encoding of the data, nil if it is implicitly percent encoded text
    public var encoding: DataURLEncoding?
}

public extension URL {
    static let dataScheme = "data"

    /// a `data:` URL with the
    /// @param data provided, of the
    /// @param mediaType with the
    /// @param parameters provided, in the
    /// @param encoding provided, or as percent encoded UTF-8 text if it is nil
    init?(dataURLWith data: Data, mediaType: String? = nil, parameters: [String: String] = [:], encoding: DataURLEncoding? = .base64) {
        var header = mediaType ?? ""
        for key in parameters.keys.sorted() {
            header += ";\(key)=\(parameters[key]!)"
        }
        let payload: String
        switch encoding {
        case .base64:
            header += ";base64"
            payload = data.base64EncodedString()
        case .hex:
            header += ";hex"
            payload = data.hexString
        case .utf8:
            header += ";utf8"
            guard let text = String(data: data, encoding: .utf8) else { return nil }
            payload = Self.percentEncoded(text)
        case nil:
            guard let text = String(data: data, encoding: .utf8) else { return nil }
            payload = Self.percentEncoded(text)
        }
        self.init(string: "\(Self.dataScheme):\(header),\(payload)")
    }

    /// the contents of a `data:` URL, or nil if it isn't one
    var dataURLContents: DataURLContents? {
        guard scheme == Self.dataScheme else { return nil }
        let url = absoluteString.dropFirst(Self.dataScheme.count + 1) // "data:"
        let header = url.prefix { $0 != "," }
        let payload = url.dropFirst(header.count + 1)
        var contents = DataURLContents(data: nil, mediaType: "", parameters: [:], encoding: nil)
        for part in header.split(separator: ";") {
            if let encoding = DataURLEncoding(rawValue: String(part)) {
                contents.encoding = encoding
            }
            else if part.contains("/") {
                contents.mediaType = String(part)
            }
            else if let equals = part.firstIndex(of: "=") {
                contents.parameters[String(part[..<equals])] = String(part[part.index(after: equals)...])
            }
        }
        if !payload.isEmpty, let decoded = String(payload).removingPercentEncoding {
            switch contents.encoding {
            case .base64: contents.data = Data(base64Encoded: decoded)
            case .hex: contents.data = Data(hexString: decoded)
            case .utf8, nil: contents.data = Data(decoded.utf8)
            }
        }
        return contents
    }

    /// the decoded data of a `data:` URL, or nil if it isn't one or has none
    var dataURLData: Data? {
        dataURLContents?.data
    }

    /// @returns the
    /// @param text provided percent encoded for a `data:` URL, with any of the
    /// @param reserved characters encoded too, e.g. the commas between x-type values
    static func percentEncoded(_ text: String, reserving reserved: String = "") -> String {
        var allowed = CharacterSet.urlQueryAllowed
        allowed.remove(charactersIn: "%" + reserved)
        return text.addingPercentEncoding(withAllowedCharacters: allowed) ?? text
    }
}

// MARK: - Values in data: URLs

/// A value which can be written in a `data:` URL with an `x-type/…` media type, e.g. `data:x-type/point,1.5,2`
public protocol DataURLConvertible {
    /// the value as a `data:` URL
    var dataURL: URL { get }
    /// the value from a
    /// @param dataURL of its type, or nil if it isn't one
    init?(dataURL: URL)
}

extension URL {
    /// @returns a `data:` URL of the x-type provided with the
    /// @param values provided separated by commas
    static func xTypeURL(_ type: String, _ values: [String]) -> URL {
        URL(string: "\(dataScheme):x-type/\(type),\(values.map { percentEncoded($0, reserving: ",") }.joined(separator: ","))")!
    }

    /// @returns the comma separated values of a `data:` URL of the
    /// @param type provided, or nil if it isn't one
    func xTypeValues(_ type: String) -> [String]? {
        guard scheme == Self.dataScheme else { return nil }
        let url = absoluteString.dropFirst(Self.dataScheme.count + 1)
        let prefix = "x-type/\(type),"
        guard url.hasPrefix(prefix) else { return nil }
        return url.dropFirst(prefix.count).split(separator: ",", omittingEmptySubsequences: false).map {
            String($0).removingPercentEncoding ?? String($0)
        }
    }

    /// @returns the doubles of a `data:` URL of the
    /// @param type provided, if it has the
    /// @param count of values expected
    func xTypeDoubles(_ type: String, count: Int) -> [Double]? {
        guard let values = xTypeValues(type), values.count == count else { return nil }
        let doubles = values.compactMap(Double.init)
        return doubles.count == count ? doubles : nil
    }
}

extension Data: DataURLConvertible {
    public var dataURL: URL { URL(dataURLWith: self)! }

    public init?(dataURL: URL) {
        guard let data = dataURL.dataURLData else { return nil }
        self = data
    }
}

extension Date: DataURLConvertible {
    public var dataURL: URL { .xTypeURL("epoch-seconds", ["\(timeIntervalSince1970)"]) }

    public init?(dataURL: URL) {
        guard let seconds = dataURL.xTypeDoubles("epoch-seconds", count: 1) else { return nil }
        self.init(timeIntervalSince1970: seconds[0])
    }
}

extension DateInterval: DataURLConvertible {
    public var dataURL: URL { .xTypeURL("epoch-interval", ["\(start.timeIntervalSince1970)", "\(duration)"]) }

    public init?(dataURL: URL) {
        guard let values = dataURL.xTypeDoubles("epoch-interval", count: 2), values[1] >= 0 else { return nil }
        self.init(start: Date(timeIntervalSince1970: values[0]), duration: values[1])
    }
}

extension CGPoint: DataURLConvertible {
    public var dataURL: URL { .xTypeURL("point", ["\(x)", "\(y)"]) }

    public init?(dataURL: URL) {
        guard let values = dataURL.xTypeDoubles("point", count: 2) else { return nil }
        self.init(x: values[0], y: values[1])
    }
}

extension CGSize: DataURLConvertible {
    public var dataURL: URL { .xTypeURL("size", ["\(width)", "\(height)"]) }

    public init?(dataURL: URL) {
        guard let values = dataURL.xTypeDoubles("size", count: 2) else { return nil }
        self.init(width: values[0], height: values[1])
    }
}

extension CGRect: DataURLConvertible {
    public var dataURL: URL { .xTypeURL("rect", ["\(origin.x)", "\(origin.y)", "\(size.width)", "\(size.height)"]) }

    public init?(dataURL: URL) {
        guard let values = dataURL.xTypeDoubles("rect", count: 4) else { return nil }
        self.init(x: values[0], y: values[1], width: values[2], height: values[3])
    }
}

extension CGVector: DataURLConvertible {
    public var dataURL: URL { .xTypeURL("vector", ["\(dx)", "\(dy)"]) }

    public init?(dataURL: URL) {
        guard let values = dataURL.xTypeDoubles("vector", count: 2) else { return nil }
        self.init(dx: values[0], dy: values[1])
    }
}

extension NSRange: DataURLConvertible {
    public var dataURL: URL { .xTypeURL("range", ["\(location)", "\(length)"]) }

    public init?(dataURL: URL) {
        guard let values = dataURL.xTypeValues("range"), values.count == 2,
              let location = Int(values[0]), let length = Int(values[1]) else { return nil }
        self.init(location: location, length: length)
    }
}

extension Measurement: DataURLConvertible where UnitType == Unit {
    /// e.g. `data:x-type/measure,100.0,cm`
    public var dataURL: URL { .xTypeURL("measure", ["\(value)", unit.symbol]) }

    public init?(dataURL: URL) {
        guard let values = dataURL.xTypeValues("measure"), values.count == 2, let value = Double(values[0]) else { return nil }
        self.init(value: value, unit: Unit(symbol: values[1]))
    }
}

public extension NSRegularExpression {
    /// the expression's pattern as a `data:x-type/regex` URL
    var dataURL: URL { .xTypeURL("regex", [pattern]) }

    /// the expression in a
    /// @param dataURL of the `x-type/regex` type, or nil if it isn't one or the pattern isn't valid
    convenience init?(dataURL: URL) {
        guard let scheme = dataURL.scheme, scheme == URL.dataScheme else { return nil }
        let url = dataURL.absoluteString.dropFirst(URL.dataScheme.count + 1)
        let prefix = "x-type/regex,"
        guard url.hasPrefix(prefix), let pattern = String(url.dropFirst(prefix.count)).removingPercentEncoding else { return nil }
        do {
            try self.init(pattern: pattern)
        }
        catch {
            return nil
        }
    }
}

// MARK: - URNs

public extension UUID {
    /// the UUID as a URN, e.g. `urn:uuid:F81D4FAE-7DEC-11D0-A765-00A0C91E6BF6`
    var urn: URL { URL(string: "urn:uuid:\(uuidString)")! }

    /// the UUID of a
    /// @param urn of the `urn:uuid:` form, or nil if it isn't one
    init?(urn: URL) {
        let parts = urn.absoluteString.split(separator: ":")
        guard parts.count == 3, parts[0] == "urn", parts[1] == "uuid" else { return nil }
        self.init(uuidString: String(parts[2]))
    }
}

// MARK: - Pasteboard URLs

public extension URL {
    /// the URL in the
    /// @param utTypeData of a pasteboard item, e.g. a plist of URL strings, the URL's data representation, or its text
    init?(utTypeData: Data) {
        let plist = try? PropertyListSerialization.propertyList(from: utTypeData, format: nil)
        if let string = (plist as? [Any])?.first as? String ?? plist as? String {
            self.init(string: string)
        }
        else if let string = String(utfData: utTypeData)?.trimmingCharacters(in: .whitespacesAndNewlines), let url = URL(string: string), url.scheme != nil {
            self = url
        }
        else {
            self.init(dataRepresentation: utTypeData, relativeTo: nil)
        }
    }
}
