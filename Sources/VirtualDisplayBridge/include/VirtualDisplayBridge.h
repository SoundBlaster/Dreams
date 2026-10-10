#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

NS_ASSUME_NONNULL_BEGIN
/// Experimental, undocumented macOS API. The object owns the display lifetime.
@interface DreamsVirtualDisplay : NSObject
@property(nonatomic, readonly) CGDirectDisplayID displayID;
+ (BOOL)isAvailable;
- (nullable instancetype)initWithWidth:(unsigned int)width
                               height:(unsigned int)height
                                error:(NSError * _Nullable * _Nullable)error;
@end
NS_ASSUME_NONNULL_END
