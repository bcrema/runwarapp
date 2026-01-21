#import <Foundation/Foundation.h>

#if __has_attribute(swift_private)
#define AC_SWIFT_PRIVATE __attribute__((swift_private))
#else
#define AC_SWIFT_PRIVATE
#endif

/// The "default_marker_inner" asset catalog image resource.
static NSString * const ACImageNameDefaultMarkerInner AC_SWIFT_PRIVATE = @"default_marker_inner";

/// The "default_marker_inner_stroke" asset catalog image resource.
static NSString * const ACImageNameDefaultMarkerInnerStroke AC_SWIFT_PRIVATE = @"default_marker_inner_stroke";

/// The "default_marker_outer" asset catalog image resource.
static NSString * const ACImageNameDefaultMarkerOuter AC_SWIFT_PRIVATE = @"default_marker_outer";

/// The "default_marker_outer_stroke" asset catalog image resource.
static NSString * const ACImageNameDefaultMarkerOuterStroke AC_SWIFT_PRIVATE = @"default_marker_outer_stroke";

/// The "location-dot-inner" asset catalog image resource.
static NSString * const ACImageNameLocationDotInner AC_SWIFT_PRIVATE = @"location-dot-inner";

/// The "location-dot-outer" asset catalog image resource.
static NSString * const ACImageNameLocationDotOuter AC_SWIFT_PRIVATE = @"location-dot-outer";

#undef AC_SWIFT_PRIVATE
