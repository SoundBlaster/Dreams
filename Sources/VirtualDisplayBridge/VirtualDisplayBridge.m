#import "VirtualDisplayBridge.h"

// Private API declarations based on Chromium's virtual_display_util_mac.mm.
// Copyright 2022 The Chromium Authors. BSD-3-Clause; see THIRD_PARTY_NOTICES.md.
@interface CGVirtualDisplayDescriptor : NSObject
@property(nonatomic) unsigned int vendorID, productID, serialNum, serialNumber;
@property(strong, nonatomic) NSString *name;
@property(nonatomic) CGSize sizeInMillimeters;
@property(nonatomic) unsigned int maxPixelsWide, maxPixelsHigh;
@property(nonatomic) CGPoint redPrimary, greenPrimary, bluePrimary, whitePoint;
@property(strong, nonatomic) id queue;
@end
@interface CGVirtualDisplayMode : NSObject
- (instancetype)initWithWidth:(unsigned int)width height:(unsigned int)height
                  refreshRate:(double)refreshRate;
@end
@interface CGVirtualDisplaySettings : NSObject
@property(strong, nonatomic) NSArray *modes;
@property(nonatomic) unsigned int hiDPI, rotation;
@end
@interface CGVirtualDisplay : NSObject
@property(readonly, nonatomic) unsigned int displayID;
- (instancetype)initWithDescriptor:(CGVirtualDisplayDescriptor *)descriptor;
- (BOOL)applySettings:(CGVirtualDisplaySettings *)settings;
@end

@implementation DreamsVirtualDisplay {
    CGVirtualDisplay *_display;
}
+ (BOOL)isAvailable {
    return NSClassFromString(@"CGVirtualDisplay") &&
        NSClassFromString(@"CGVirtualDisplayDescriptor") &&
        NSClassFromString(@"CGVirtualDisplayMode") &&
        NSClassFromString(@"CGVirtualDisplaySettings");
}
- (instancetype)initWithWidth:(unsigned int)width height:(unsigned int)height
                        error:(NSError **)error {
    if (!(self = [super init])) return nil;
    if (![DreamsVirtualDisplay isAvailable] || width < 640 || height < 480 ||
        width > 3840 || height > 2160) {
        if (error) *error = [NSError errorWithDomain:@"Dreams.VirtualDisplay" code:1
            userInfo:@{NSLocalizedDescriptionKey: @"Virtual display API unavailable or dimensions invalid."}];
        return nil;
    }
    @try {
        CGVirtualDisplayDescriptor *descriptor = [NSClassFromString(@"CGVirtualDisplayDescriptor") new];
        descriptor.name = @"Dreams Agent Workspace";
        descriptor.queue = dispatch_get_main_queue();
        descriptor.vendorID = 0x4452;
        descriptor.productID = 1;
        descriptor.serialNum = arc4random_uniform(UINT32_MAX - 1) + 1;
        descriptor.serialNumber = descriptor.serialNum;
        descriptor.maxPixelsWide = width;
        descriptor.maxPixelsHigh = height;
        descriptor.sizeInMillimeters = CGSizeMake(width * 25.4 / 110, height * 25.4 / 110);
        descriptor.redPrimary = CGPointMake(0.64, 0.33);
        descriptor.greenPrimary = CGPointMake(0.30, 0.60);
        descriptor.bluePrimary = CGPointMake(0.15, 0.06);
        descriptor.whitePoint = CGPointMake(0.3127, 0.3290);
        _display = [[NSClassFromString(@"CGVirtualDisplay") alloc] initWithDescriptor:descriptor];
        CGVirtualDisplaySettings *settings = [NSClassFromString(@"CGVirtualDisplaySettings") new];
        settings.hiDPI = 0;
        settings.rotation = 0;
        settings.modes = @[[[NSClassFromString(@"CGVirtualDisplayMode") alloc] initWithWidth:width height:height refreshRate:60]];
        if (!_display || ![_display applySettings:settings]) {
            _display = nil;
            if (error) *error = [NSError errorWithDomain:@"Dreams.VirtualDisplay" code:2
                userInfo:@{NSLocalizedDescriptionKey: @"WindowServer rejected the virtual display."}];
            return nil;
        }
    } @catch (NSException *exception) {
        _display = nil;
        if (error) *error = [NSError errorWithDomain:@"Dreams.VirtualDisplay" code:3
            userInfo:@{NSLocalizedDescriptionKey: exception.reason ?: @"Private API failure."}];
        return nil;
    }
    return self;
}
- (CGDirectDisplayID)displayID { return _display.displayID; }
@end
