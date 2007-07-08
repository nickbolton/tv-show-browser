#import "Episode.h"
#import "ZNLog.h"

@implementation Episode

- (void)dealloc {
    ZNLog(TRACE);
    [properties release];
    [episodeDisplayName release];
    episodeDisplayName = nil;
    properties = nil;
    [super dealloc];
}

+ (Episode*)initEpisode:(NSDictionary*)props {
    ZNLogP(TRACE, @"props=%@", props);
    Episode* episode = [[Episode alloc] init];
    [props retain];
    [episode setProperties:props];
    return episode;
}

- (NSDictionary*)properties {
    ZNLog(TRACE);
    return properties;
}

- (void)setProperties:(NSDictionary*)newProperties {
    [newProperties retain];
    [properties release];
    properties = newProperties;
    episodeDisplayName = [NSString stringWithFormat:@"%dx%d %@", [self season], [self episode], [self episodeName]];
    [episodeDisplayName retain];
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

- (NSString*)episodeDisplayName {
    return episodeDisplayName;
}

// remove observing messages

- (void)addObserver:(NSObject *)anObserver forKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options context:(void *)context {
}

- (void)removeObserver:(NSObject *)anObserver forKeyPath:(NSString *)keyPath {
}

@end
