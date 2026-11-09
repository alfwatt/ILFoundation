# ILFoundation <a id="ILFoundation"></a>

ILFoundation: Swift extensions to Foundation for macOS, iOS, tvOS, watchOS and visionOS.

From [iStumbler Labs](https://istumbler.net/labs/).


## Contents <a id="contents"></a>

- [Goals](#goals)
- [Extensions](#extensions)
- [To Do Items](#todo)
- [Version History](#versions)
- [MIT License](#license)


## Goals <a id="goals"></a>

ILFoundation adds message digests of data and streams, UTF detection and hex encoding of data and strings,
and [RFC 2397](https://www.rfc-editor.org/rfc/rfc2397) `data:` URLs.

ILFoundation supports the [CardView](https://github.com/iStumblerLabs/CardView) and
[Soup](https://github.com/iStumblerLabs/Soup) frameworks.


## Extensions <a id="extensions"></a>

- [`Hashing`](./Sources/ILFoundation/Hashing.swift)
  - `HashFunction`: MD2, MD4, MD5, SHA1 and SHA2 224, 256, 384 and 512, `digest(_:)` of any data
  - `IncrementalHash`: a digest computed a buffer at a time
  - `StreamHasher`: several digests of a stream, read once, with progress, e.g. all the digests of a large file
  - `Data.md5`, `Data.sha2_256`… and `Data.digest(_:)`, `InputStream.digest(_:)`

- [`Data+ILFoundation`](./Sources/ILFoundation/Data+ILFoundation.swift)
  - `hexString` and `init?(hexString:)`
  - `isBinaryPropertyList`

- [`String+ILFoundation`](./Sources/ILFoundation/String+ILFoundation.swift)
  - `String.Encoding.utf(of:)` the UTF encoding of data from its byte order mark,
    `String.Encoding.detected(in:)` the encoding Foundation detects, and `byteOrderMark`
  - `init?(utfData:)`, `init(detecting:)` and `init?(utTypeData:)` for pasteboard data
  - `data(byteOrderMarked:)`
  - `containsUTF8Errors` and `cleaningUTF8Errors()`, for UTF-8 decoded as Windows-1252 or Latin-1,
    with code from [Athenstean](https://athenstean.com/blog/detecing-fixing-encoding-problems-nsstring/)
  - `lines(maxLength:)`

- [`URL+ILFoundation`](./Sources/ILFoundation/URL+ILFoundation.swift)
  - `URL(dataURLWith:mediaType:parameters:encoding:)` and `dataURLContents`, `dataURLData` for `data:` URLs
    in the `utf8`, `hex` and `base64` encodings
  - `DataURLConvertible`: `dataURL` and `init?(dataURL:)` with `data:x-type/…` URLs for `Data`, `Date`,
    `DateInterval`, `CGPoint`, `CGSize`, `CGRect`, `CGVector`, `NSRange` and `Measurement<Unit>`,
    and `NSRegularExpression`
  - `UUID.urn` and `UUID(urn:)` for UUID URNs
  - `URL(utTypeData:)` for pasteboard data with the UTType `public.url`


## To Do Items <a id="todo"></a>

- SHA3 and Skein hash functions
- `data:` URLs for predicates and sort descriptors


## Version History <a id="versions"></a>

- `2.0.0`: Breaking API changes, ILFoundation is written in Swift
    - Requires macOS 14, iOS 17, tvOS 17, watchOS 10 or visionOS 26
    - `ILFoundationSwift` is merged into `ILFoundation`
    - `StreamHasher` replaces the `ILHashingInputStream` subclasses
    - Encoding detection checks UTF-32LE before UTF-16LE, their byte order marks start with the same bytes
    - UTF-8 errors are corrected from Windows-1252 as well as Latin-1
    - `x-type` values are written with full precision

| 1.x | 2.0 |
| --- | --- |
| `ILHashable`, `NSData.md5`… | `Data.md5`…, `Data.digest(_:)`, `HashFunction.digest(_:)` |
| `NSInputStream.md5`… | `InputStream.digest(_:)` |
| `ILHashingInputStream`, `ILHashingFunction`, `-readToEndAndHash` | `StreamHasher.digests(of:_:progress:)`, `HashFunction`, `IncrementalHash` |
| `+hexStringWithData:`, `-initHexStringWithData:`, `NSData.hexString` | `Data.hexString`, `Data(hexString:)` |
| `-isBinaryPlistData` | `Data.isBinaryPropertyList` |
| `+UTFEncodingOfData:` | `String.Encoding.utf(of:)` |
| `+stringEncodingOfData:convertedString:` | `String.Encoding.detected(in:)` |
| `+stringWithUTFData:`, `-initWithUTFData:` | `String(utfData:)` |
| `-initWithData:` | `String(detecting:)` |
| `+stringWithUTTypeData:` | `String(utTypeData:)` |
| `-dataWithByteOrderUTFEncoding:`, `ILUTF8BOMMagic`… | `String.data(byteOrderMarked:)`, `String.Encoding.byteOrderMark` |
| `-containsUTF8Errors`, `-stringByCleaningUTF8Errors` | `String.containsUTF8Errors`, `String.cleaningUTF8Errors()` |
| `-linesWithMaxLen:` | `String.lines(maxLength:)` |
| `+dataURLWithData:…`, `-URLData`, `-URLDataWithMediaType:…` | `URL(dataURLWith:…)`, `URL.dataURLData`, `URL.dataURLContents` |
| `+dataURLWithPoint:`, `+pointWithDataURL:`… | `CGPoint.dataURL`, `CGPoint(dataURL:)`… |
| `+dataURLWithDate:interval:` | `DateInterval.dataURL` |
| `+URNWithUUID:`, `+UUIDWithURL:` | `UUID.urn`, `UUID(urn:)` |
| `+URLWithUTTypeData:` | `URL(utTypeData:)` |

- `1.2.0`: [11 April 2026](https://github.com/alfwatt/ILFoundation/releases/tag/1.2.0)
    - better nullability
    - Add `stringEncodingOfData:convertedString:`
    - Add `-isBinaryPlistData`
    - Changed swift package url https://github.com/alfwatt/ILFoundation

- `1.1.0`: [20 April 2025](https://github.com/alfwatt/ILFoundation/releases/tag/1.1.0)
    - Added UTF8 Error detection and correction code from [Athenstean](https://athenstean.com/blog/detecing-fixing-encoding-problems-nsstring/)
    - Improved Swift Interface <- this is a breaking change, but the major version is not incremented
    - Adds `Data:x-type/...` URLs for Date, Intervals, Points, Sizes, Rects, Ranges, Vectors, Measures, and Regex objects
    - Adds UUID URNs
    - Fixes iOS build by removing NSPoint

- `1.0`: [26 February 2025](https://github.com/alfwatt/ILFoundation/releases/tag/1.0.0)
    - Forked from KitBridge, added NSData hash code functions


## Using ILFoundation in your App

- Clone the latest sources: `git clone https://github.com/iStumblerLabs/ILFoundation.git`
  near or inside your application's project directory
- Drag `ILFoundation.xcodproj` into your project
- include the `ILFoundation.framework` in your applications `Resources/Frameworks` directory
    - link the appropriate version of `ILFoundation.framework` to all the targets which use it


## Swift Package <a id="spm"></a>

A Swift Package is defined in `Package.swift` for projects using Swift Package Manager,
you can include the following URL in your project to use it:

    https://github.com/alfwatt/ILFoundation

## License <a id="license"></a>

    The MIT License (MIT)

    Copyright © 2017-2026 Alf Watt <alf@istumbler.net>

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.
