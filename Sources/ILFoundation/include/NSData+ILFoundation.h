#import <Foundation/Foundation.h>

#if __has_include(<ILFoundation/ILHashable.h>)
#import <ILFoundation/ILHashable.h>
#else
#import "ILHashable.h"
#endif

NS_ASSUME_NONNULL_BEGIN

@interface NSData (ILFoundation) <ILHashable>

/// lowercase hex string representing this data
@property(nonatomic,readonly) NSString* hexString;
@property(nonatomic,readonly) BOOL isBinaryPlistData;

@end

NS_ASSUME_NONNULL_END
