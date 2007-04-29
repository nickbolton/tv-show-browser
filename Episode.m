#import "Episode.h"

@implementation Episode

- (void)dealloc {
    [properties release];
    properties = nil;
    [super dealloc];
}

+ (Episode*)initEpisode:(NSDictionary*)props {
    Episode* episode = [[Episode alloc] init];
    [episode setProperties:props];
    return episode;
}

- (NSDictionary*)properties {
    return properties;
}

- (void)setProperties:(NSDictionary*)newProperties {
    [newProperties retain];
    [properties autorelease];
    properties = newProperties;
}

- (int)season {
    return [[properties objectForKey:@"season"] intValue];
}

- (int)episode {
    return [[properties objectForKey:@"episode"] intValue];
}

@end
