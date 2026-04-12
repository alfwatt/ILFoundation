
# ILFoundation <a id="ILFoundation"></a>

ILFoundation: Extensions to the Foundation framework for iOS and macOS development.

From [iStumbler Labs](https://istumbler.net/labs/).


## Contents <a id="contents"></a>

- [Goals](#goals)
- [Support](#support)
- [Categories](#categories)
- [Swift](#swift)
- [To Do Items](#todo)
- [Version History](#versions)
- [MIT License](#license)


## Goals <a id="goals"></a>

ILFoundation adds UTF8 and hex string encoding to NSString, 
adds [RFC 2397](https://www.rfc-editor.org/rfc/rfc2397) `data:` URL support to NSURL,
and adds `ILHashable` and `ILHashingInputStream` for calculating hashs on Data and Streams

ILFoundation supports the [CardView](https://github.com/iStumblerLabs/CardView) and 
[Soup](https://github.com/iStumblerLabs/Soup) frameworks.


## Categories <a id="categories"></a>

Categories are defined on Foundation classes to provide extensions for text processing and working with data urls.

- [`ILHashable`](./Sources/ILFoundation/include/ILHashable.h)
  - Adds: methods for generating Message Digest and Secure Hashes from objects 

- [`NSData+ILFoundation`](./Sources/ILFoundation/include/NSData+ILFoundation.h)
  - Adds: `ILHashable` methods to `NSData`

- [`NSStream+ILFoundation`](./Sources/ILFoundation/include/NSStream+ILFoundation.h)
  - Adds: `ILHashable` methods to `NSInputStream`
  - Adds: `ILHasingInputStream` class to wrap `NSInputStream` objects and generate hash codes

- [`NSString+ILFoundation`](./Sources/ILFoundation/include/NSString+ILFoundation.h)
  - Adds: `+UTFEncodingOfData:` to auto-detect UTF formatted strings
  - Adds: `+stringWithUTFData:` and `-initWithUTFData:`
  - Adds: `-dataWithByteOrderUTFEncoding:`
  - Adds: `+hexStringWithData:` to generate hex output from NSData
  - Adds: `-initHexStringWithData:`
  - Adds: `-linesWithMaxLen:` to split a long string (hex or otherwise) into lines of a maximum length
  
- [`NSURL+ILFoundation`](./Sources/ILFoundation/include/NSURL+ILFoundation.h) Adds methods for working with [RFC 2397](https://www.rfc-editor.org/rfc/rfc2397) `data:` URLs:
  - Adds: `+dataURLWithData:` and `+dataURLwithData:mediaType:parameters:contentEncoding:` for genrating `data:` URLs
  - Adds: `-URLData` and `-URLDataWithMediaType:parameters:contentEncoding:` for parsing `data:` URLs
      - Supports `utf8`, `hex`, and `base64` encodings
  - Adds `Data:x-type/...` URLs for:
    - Date - `+dataURLWithDate:` and `+dateWithDataURL:` 
    - Intervals - `+dataURLWithDate:interval:` and `+dateWithDataURL:interval:` 
    - Points - `+dataURLWithPoint:` and `+pointWithDataURL:`
    - Sizes - `+dataURLWithSize:` and `+sizeWithDataURL:`
    - Rects - `+dataURLWithRect:` and `+rectWithDataURL:`
    - Ranges - `+dataURLWithRange:` and `+rangeWithDataURL:`
    - Vectors - `+dataURLWithVector:` and `+vectorWithDataURL:`
    - Measures - `+dataURLWithMeasure:` and `+measureWithDataURL:`
    - Regex - `+dataURLWithRegex:` and `+regexWithDataURL:`
  - Adds `+URNWithUUID:` and `+UUIDWithURL:` for UUID URNs
  - Adds: `+URLWithUTTypeData:` for unpacking URLs from pasteboard data with UTType `public.url`


## To Do Items <a id="todo"></a>

- implement ILHashingOutputStream
- implement SHA3 and Skein Hash functions
- implement `+dataURLWithPredicate:`... and `+dataURLWithSort:`... in NSURL


## Version History <a id="versions"></a>

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
