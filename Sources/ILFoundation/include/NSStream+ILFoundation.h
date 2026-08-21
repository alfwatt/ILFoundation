#import <Foundation/Foundation.h>

#if __has_include(<ILFoundation/ILHashable.h>)
#import <ILFoundation/ILHashable.h>
#else
#import "ILHashable.h"
#endif

NS_ASSUME_NONNULL_BEGIN

// MARK: -

typedef NS_ENUM(NSInteger, ILHashingFunction) {
    ILHashingFunctionMD2,
    ILHashingFunctionMD4,
    ILHashingFunctionMD5,
    ILHashingFunctionSHA1,
    ILHashingFunctionSHA2_224,
    ILHashingFunctionSHA2_256,
    ILHashingFunctionSHA2_384,
    ILHashingFunctionSHA2_512
    // TODO: ILHashingFunctionSHA3_224;
    // TODO: ILHashingFunctionSHA3_256;
    // TODO: ILHashingFunctionSHA3_384;
    // TODO: ILHashingFunctionSHA3_512;
    // TODO: ILHashingFunctionSkein_256_256;
    // TODO: ILHashingFunctionSkein_512_256;
    // TODO: ILHashingFunctionSkein_512_512;
};

// MARK: -

/// Implements the `ILHashable` methods on an `NSInputStream` by performing a blocking read of the
/// entire stream. Not reccomended for long streams, as it will block the calling thread until the entire stream is
/// read and hashed.
///
@interface NSInputStream (ILFoundation) <ILHashable>

@end

// MARK: -

/// Wraps an input stream, forwarning events to the delegate, can be queried for the hash once self.bytesAreAvailable is NO
///
/// Usage: NSImputStream -> ILHashingHashingInputStream
///
/// Create an NSInputStream from any source, pass it to the contstructor if the ILHashingInputStream with the hashing function you want to use
/// To get multiple hashes chain ILHashingHashingInputStreams
///
@interface ILHashingInputStream : NSInputStream <NSStreamDelegate>

/// Create a new ILHashingInputStream with the InputStream and hashing function provided
+ (ILHashingInputStream*) hashingStream:(NSInputStream*) dataStream withFunction:(ILHashingFunction)function;

- (instancetype) initWithInputStream:(NSInputStream*) dataStream hashFunction:(ILHashingFunction)function;

/// Upstream NSInputStream to read data from
@property(readonly) NSInputStream* inputStream;

/// Hashing function to use for this input stream
@property(readonly) ILHashingFunction hashFunction;

/// The stream hash is avaiable when the stream is completely read
@property(readonly, nullable) NSData* streamHash;

/// Synchronously read the stream to the end and return the hash
- (nullable NSData*) readToEndAndHash;

@end

// MARK: -

/// Wraps and output stream, forwarding events to the delegate, can be queried for the hash once
///
@interface ILHashingOutputStream : NSOutputStream <NSStreamDelegate>

/// Create a new ILHashingOutputStream with the OutputStream and hashing function provided
+ (ILHashingOutputStream*) hashingStream:(NSOutputStream*) dataStream withFunction:(ILHashingFunction)function;

- (instancetype) initWithOutputStream:(NSOutputStream*) dataStream hashFunction:(ILHashingFunction)function;

/// Downstream NSOutputStream to send data to
@property(readonly) NSOutputStream* outputStream;

/// Hashing function to use for this output stream
@property(readonly) ILHashingFunction hashFunction;

/// The stream hash is avaiable when the stream is completely read
@property(readonly) NSData* streamHash;

@end

NS_ASSUME_NONNULL_END
