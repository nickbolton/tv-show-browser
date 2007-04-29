/* Show */

#import <Cocoa/Cocoa.h>

@interface Episode : NSObject
{
    NSDictionary* properties;
}

+ (Episode*)initEpisode:(NSDictionary*)properties;
- (NSDictionary*)properties;
- (void)setProperties:(NSDictionary*)newProperties;
- (int)season;
- (int)episode;
@end
