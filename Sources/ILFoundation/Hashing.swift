import Foundation
import CommonCrypto
import CryptoKit

/// The message digests ILFoundation computes, from the long broken MD2 to SHA-2 512
public enum HashFunction: String, CaseIterable, Sendable {
    /// https://en.wikipedia.org/wiki/MD2_(hash_function)
    case md2
    /// https://en.wikipedia.org/wiki/MD4
    case md4
    /// https://en.wikipedia.org/wiki/MD5
    case md5
    /// https://en.wikipedia.org/wiki/SHA-1
    case sha1
    /// https://en.wikipedia.org/wiki/SHA-2
    case sha2_224
    case sha2_256
    case sha2_384
    case sha2_512

    /// the length of the function's digests in bytes
    public var digestLength: Int {
        switch self {
        case .md2, .md4, .md5: 16
        case .sha1: 20
        case .sha2_224: 28
        case .sha2_256: 32
        case .sha2_384: 48
        case .sha2_512: 64
        }
    }

    /// the name of the function, e.g. "SHA2-256"
    public var name: String {
        switch self {
        case .md2: "MD2"
        case .md4: "MD4"
        case .md5: "MD5"
        case .sha1: "SHA1"
        case .sha2_224: "SHA2-224"
        case .sha2_256: "SHA2-256"
        case .sha2_384: "SHA2-384"
        case .sha2_512: "SHA2-512"
        }
    }

    /// @returns the digest of the
    /// @param data provided
    public func digest(_ data: some DataProtocol) -> Data {
        var hasher = IncrementalHash(self)
        for region in data.regions {
            region.withUnsafeBytes { hasher.update($0) }
        }
        return hasher.finalize()
    }
}

// MARK: -

/// A digest computed a buffer at a time, e.g. as a file is read
public struct IncrementalHash: Sendable {
    public let function: HashFunction
    private var state: State

    private enum State: Sendable {
        case md2(CC_MD2_CTX)
        case md4(CC_MD4_CTX)
        case md5(Insecure.MD5)
        case sha1(Insecure.SHA1)
        case sha2_224(CC_SHA256_CTX)
        case sha2_256(SHA256)
        case sha2_384(SHA384)
        case sha2_512(SHA512)
    }

    public init(_ function: HashFunction) {
        self.function = function
        switch function {
        case .md2:
            var context = CC_MD2_CTX()
            CC_MD2_Init(&context)
            state = .md2(context)
        case .md4:
            var context = CC_MD4_CTX()
            CC_MD4_Init(&context)
            state = .md4(context)
        case .md5: state = .md5(Insecure.MD5())
        case .sha1: state = .sha1(Insecure.SHA1())
        case .sha2_224:
            var context = CC_SHA256_CTX()
            CC_SHA224_Init(&context)
            state = .sha2_224(context)
        case .sha2_256: state = .sha2_256(SHA256())
        case .sha2_384: state = .sha2_384(SHA384())
        case .sha2_512: state = .sha2_512(SHA512())
        }
    }

    /// add the
    /// @param bytes provided to the digest
    public mutating func update(_ bytes: UnsafeRawBufferPointer) {
        guard bytes.count > 0 else { return }
        switch state {
        case .md2(var context):
            CC_MD2_Update(&context, bytes.baseAddress, CC_LONG(bytes.count))
            state = .md2(context)
        case .md4(var context):
            CC_MD4_Update(&context, bytes.baseAddress, CC_LONG(bytes.count))
            state = .md4(context)
        case .md5(var hash):
            hash.update(bufferPointer: bytes)
            state = .md5(hash)
        case .sha1(var hash):
            hash.update(bufferPointer: bytes)
            state = .sha1(hash)
        case .sha2_224(var context):
            CC_SHA224_Update(&context, bytes.baseAddress, CC_LONG(bytes.count))
            state = .sha2_224(context)
        case .sha2_256(var hash):
            hash.update(bufferPointer: bytes)
            state = .sha2_256(hash)
        case .sha2_384(var hash):
            hash.update(bufferPointer: bytes)
            state = .sha2_384(hash)
        case .sha2_512(var hash):
            hash.update(bufferPointer: bytes)
            state = .sha2_512(hash)
        }
    }

    /// add the
    /// @param data provided to the digest
    public mutating func update(_ data: some DataProtocol) {
        for region in data.regions {
            region.withUnsafeBytes { update($0) }
        }
    }

    /// @returns the digest of everything added to it
    public func finalize() -> Data {
        var digest = Data(count: function.digestLength)
        switch state {
        case .md2(var context):
            digest.withUnsafeMutableBytes { _ = CC_MD2_Final($0.bindMemory(to: UInt8.self).baseAddress, &context) }
        case .md4(var context):
            digest.withUnsafeMutableBytes { _ = CC_MD4_Final($0.bindMemory(to: UInt8.self).baseAddress, &context) }
        case .md5(let hash): digest = Data(hash.finalize())
        case .sha1(let hash): digest = Data(hash.finalize())
        case .sha2_224(var context):
            digest.withUnsafeMutableBytes { _ = CC_SHA224_Final($0.bindMemory(to: UInt8.self).baseAddress, &context) }
        case .sha2_256(let hash): digest = Data(hash.finalize())
        case .sha2_384(let hash): digest = Data(hash.finalize())
        case .sha2_512(let hash): digest = Data(hash.finalize())
        }
        return digest
    }
}

// MARK: -

/// Computes several digests of a stream, reading it once, e.g. all the digests of a large file
public struct StreamHasher: Sendable {
    /// the size of the buffer the stream is read with
    public static let bufferSize = 64 * 1024

    private var hashes: [IncrementalHash]

    public init(_ functions: some Sequence<HashFunction>) {
        hashes = functions.map(IncrementalHash.init)
    }

    /// add the
    /// @param bytes provided to every digest
    public mutating func update(_ bytes: UnsafeRawBufferPointer) {
        for index in hashes.indices {
            hashes[index].update(bytes)
        }
    }

    /// @returns the digests of everything added
    public func finalize() -> [HashFunction: Data] {
        Dictionary(uniqueKeysWithValues: hashes.map { ($0.function, $0.finalize()) })
    }

    /// @returns the digests of everything read from the
    /// @param stream provided, which is opened and closed, with the
    /// @param functions provided, calling
    /// @param progress with the number of bytes read so far after each buffer
    /// @throws the stream's error if reading it fails
    public static func digests(of stream: InputStream, _ functions: some Sequence<HashFunction> = HashFunction.allCases,
                               progress: ((Int) -> Void)? = nil) throws -> [HashFunction: Data] {
        var hasher = StreamHasher(functions)
        var buffer = [UInt8](repeating: 0, count: bufferSize)
        var bytesRead = 0
        stream.open()
        defer { stream.close() }
        while true {
            let count = stream.read(&buffer, maxLength: buffer.count)
            if count < 0 {
                throw stream.streamError ?? CocoaError(.fileReadUnknown)
            }
            if count == 0 {
                break
            }
            buffer.withUnsafeBytes { hasher.update(UnsafeRawBufferPointer(rebasing: $0[0..<count])) }
            bytesRead += count
            progress?(bytesRead)
        }
        return hasher.finalize()
    }
}

// MARK: -

public extension Data {
    /// @returns the digest of the data with the
    /// @param function provided
    func digest(_ function: HashFunction) -> Data {
        function.digest(self)
    }

    var md2: Data { digest(.md2) }
    var md4: Data { digest(.md4) }
    var md5: Data { digest(.md5) }
    var sha1: Data { digest(.sha1) }
    var sha2_224: Data { digest(.sha2_224) }
    var sha2_256: Data { digest(.sha2_256) }
    var sha2_384: Data { digest(.sha2_384) }
    var sha2_512: Data { digest(.sha2_512) }
}

public extension InputStream {
    /// @returns the digest of everything read from the stream with the
    /// @param function provided, the stream is opened and closed
    /// @throws the stream's error if reading it fails
    func digest(_ function: HashFunction) throws -> Data {
        try StreamHasher.digests(of: self, [function])[function]!
    }
}
