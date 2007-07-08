/* Show */

#import <Cocoa/Cocoa.h>

@interface Episode : NSObject
{
    NSDictionary* properties;
    NSString* episodeDisplayName;
}

+ (Episode*)initEpisode:(NSDictionary*)properties;
- (NSDictionary*)properties;
- (int)season;
- (int)episode;
- (NSString*)episodeName;
- (NSString*)showName;
- (NSString*)filePath;
- (NSString*)episodeDisplayName;
@end
