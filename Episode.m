#import "Episode.h"
#import "ZNLog.h"

@implementation Episode

- (void)dealloc {
    ZNLog(TRACE);
    [properties release];
    properties = nil;
    [super dealloc];
}

+ (Episode*)initEpisode:(NSDictionary*)props {
    ZNLogP(TRACE, @"props=%@", props);
    Episode* episode = [[Episode alloc] init];
    [episode setProperties:props];
    return episode;
}

- (NSDictionary*)properties {
    ZNLog(TRACE);
    return properties;
}

- (void)setProperties:(NSDictionary*)newProperties {
    ZNLogP(TRACE, @"newProperties=%@", newProperties);
    [newProperties retain];
    [properties autorelease];
    properties = newProperties;
}

- (int)season {
    ZNLog(TRACE);
    return [[properties objectForKey:@"season"] intValue];
}

- (int)episode {
    ZNLog(TRACE);
    return [[properties objectForKey:@"episode"] intValue];
}

- (NSString*)episodeName {
    return [properties objectForKey:@"episodeName"];
}

- (NSString*)showName {
    return [properties objectForKey:@"showName"];
}

- (NSString*)filePath {
    return [properties objectForKey:@"filePath"];
}

@end
