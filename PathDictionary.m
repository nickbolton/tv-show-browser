//
//  PathDictionary.m
//  TvShowBrowser
//
//  Created by Deuce on 4/21/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "PathDictionary.h"
#import <Foundation/NSURL.h>
#import "Episode.h"
#import "ZNLog.h"
#import <QTKit/QTMovie.h>
#import <Foundation/NSURL.h>
#import <AppKit/NSMovie.h>
#import "Preferences.h"

@implementation PathDictionary

static PathDictionary *sharedPathDictionary = nil;

- (id) init
{
    ZNLog(TRACE);
    if (self = [super init])
    {
        pathDictionary = [[NSMutableDictionary alloc] init];
        showEpisodeCache = [[NSMutableDictionary alloc] init];
    }
}

- (void)awakeFromNib {
    ZNLog(TRACE);
}

- (void) dealloc
{   
    ZNLog(TRACE);
    [pathDictionary release];
    [showEpisodeCache release];
    [super dealloc];
}

+ (PathDictionary*)sharedPathDictionary
{
    ZNLog(TRACE);
    @synchronized(self) {
        if (sharedPathDictionary == nil) {
            [[self alloc] init]; // assignment not done here
        }
    }
    return sharedPathDictionary;
}

+ (id)allocWithZone:(NSZone *)zone
{
    ZNLogP(TRACE, @"zone=%@", zone);
    @synchronized(self) {
        if (sharedPathDictionary == nil) {
            sharedPathDictionary = [super allocWithZone:zone];
            return sharedPathDictionary;  // assignment and return on first allocation
        }
    }
    return nil; //on subsequent allocation attempts return nil
}

- (id)copyWithZone:(NSZone *)zone
{
    ZNLogP(TRACE, @"zone=%@", zone);
    return self;
}

- (id)retain
{
    ZNLog(TRACE);
    return self;
}

- (unsigned)retainCount
{
    ZNLog(TRACE);
    return UINT_MAX;  //denotes an object that cannot be released
}

- (void)release
{
    ZNLog(TRACE);
    //do nothing
}

- (id)autorelease
{
    ZNLog(TRACE);
    return self;
}

- (NSString*)pathForKey:(NSString*)key {
    ZNLogP(TRACE, @"key=%@", key);
    return [pathDictionary objectForKey:key];
}

- (void)setPath:(NSString*)path forKey:(NSString*)key {
    ZNLogP(TRACE, @"path=%@ key=%@", path, key);
    [pathDictionary setObject:path forKey:key];
}

- (NSDictionary*)episodeForFilename:(NSString*)filename {
    ZNLogP(TRACE, @"filename=%@", filename);
    return [Preferences dictionaryPreference:@"episodeNames" forDictionaryKey:filename];
}

- (void)setEpisode:(NSDictionary*)episode forFilename:(NSString*)filename {
    ZNLogP(TRACE, @"episode=%@ filename=%@", episode, filename);
    [Preferences setPreferenceToDictionary:episode forDictionaryKey:filename forKey:@"episodeNames"];
    //NSLog(@"Setting %@ = %@:\n%@", filename, episodeName, episodeNameDictionary);
}

- (NSString*)fetchShowContents:(NSString*)showName {
    ZNLogP(TRACE, @"showName=%@", showName);
    NSString* contents = [showEpisodeCache objectForKey:showName];
    if (!contents) {
        NSMutableString* showUrl = [[NSMutableString alloc] init];
        [showUrl setString:@"http://epguides.com/"];
        [showUrl appendString:showName];
        [showUrl replaceOccurrencesOfString:@" " withString:@"" options:0 range:[showUrl rangeOfString:showName]];
        
        NSURL* url = [NSURL URLWithString:showUrl];
        contents = [NSString stringWithContentsOfURL:url];
    }
    return contents;
}

- (void)initEpisodeNames {
    ZNLog(TRACE);
    ZNLogP(DEBUG, @"tvShowPath=%@", [Preferences tvShowDirectory]);
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    NSArray* args = [NSArray arrayWithObjects:[Preferences tvShowDirectory], @"-name", @"*.avi", @"-o", @"-name", @"*.mpg", @"-o", @"-name", @"*.mpeg", nil];
    //NSArray* args = [NSArray arrayWithObjects:tvShowPath, @"-type", @"f", @"-mmin", @"+5", @"-mtime", @"-3", nil];
    int size;
    NSMutableString* result = [[NSMutableString alloc] init];
    [result setString:@""];
    NSPipe *newPipe = [NSPipe pipe];
    NSFileHandle *readHandle = [newPipe fileHandleForReading];
    NSData *inData = nil;
    NSTask* task = [[NSTask alloc] init];
    [task setStandardOutput:newPipe];
    [task setLaunchPath:@"/usr/bin/find"];
    [task setArguments:args];
    //NSTask* task = [NSTask launchedTaskWithLaunchPath:@"/usr/bin/find" arguments:args];
    
    NSMutableString* argsStr = [[NSMutableString alloc] init];
    [argsStr setString:@""];
    
    int i;
    for (i=0; i<[args count]; i++) {
        [argsStr appendString:[args objectAtIndex:i]];
        [argsStr appendString:@" "];
    }
    
    ZNLogP(DEBUG, @"args: %@", argsStr);
    
    [task launch];
    
    while ((inData = [readHandle availableData]) && [inData length]) {
        size = [inData length];
        ZNLogP(DEBUG, @"data size: %d", size);
        char buf[size+1];
        buf[size] = '\0';
        [inData getBytes:buf];
        [result appendFormat:@"%s", buf];
    }
    //NSLog(@"%@", result);
    
    NSArray* paths = [result componentsSeparatedByString:@"\n"];
    
    for (i=0; i<[paths count]; i++) {
        ZNLogP(DEBUG, @"path: #%@#", [paths objectAtIndex:i]);
        [self parseEpisode:[paths objectAtIndex:i]];
    }
    ZNLogP(DEBUG, @"initEpisodeNames Done.");
    [pool release];
}

- (NSString*)episodeContents:(NSString*)showContents forEpisode:(NSString*)episode {
    ZNLogP(TRACE, @"showContents=%@ episode=%@", showContents, episode);
    NSRange startingRange = [showContents rangeOfString:episode];
    if (startingRange.location == NSNotFound) {
        return nil;
    }
    NSRange endingRange = [showContents rangeOfString:@"</a>" options:0 range:NSMakeRange(startingRange.location, [showContents length]-startingRange.location)];
    int start = startingRange.location;
    int length = endingRange.location-startingRange.location+4;
    return [showContents substringWithRange:NSMakeRange(start, length)];
}

- (NSString*)fetchEpisodeNameForShow:(NSString*)showName forSeason:(NSString*)season forEpisode:(NSString*)episode {
    ZNLogP(TRACE, @"showName=%@ season=%@ episode=%@", showName, season, episode);
    NSString* showContents = [self fetchShowContents:showName];
    //NSLog(@"show: %@, showContents: %@", showName, showContents);
    NSMutableString* episodeNamePattern = [[NSMutableString alloc] init];
    [episodeNamePattern setString:@" "];
    [episodeNamePattern appendString:season];
    [episodeNamePattern appendString:@"-"];
    if ([episode intValue] < 10) {
        [episodeNamePattern appendString:@" "];
    }
    [episodeNamePattern appendString:episode];
    NSString* episodeContents = [self episodeContents:showContents forEpisode:episodeNamePattern];
    if (!episodeContents) {
        ZNLogP(ERROR, @"Failed to find episode %@ for show %@", episodeNamePattern, showName);
        return nil;
    }
    
    //NSLog(@"episodeContents: #%@#", episodeContents);
    [episodeNamePattern appendString:@" .*\">(.*)</a>"];
    NSArray* episodeMatches = [episodeContents substringsCapturedByPattern:episodeNamePattern];
    
    NSString* episodeName = nil;
    if ([episodeMatches count] > 0) {
        episodeName = [episodeMatches objectAtIndex:1];
    }
    
    return episodeName;
}

- (BOOL)isTvShowPath:(NSString*)path {
    ZNLogP(TRACE, @"path=%@", path);
    int loc = [path rangeOfString:[Preferences tvShowDirectory]].location;
    return loc != NSNotFound;
}

+ (NSString*)buildCaseInsensitiveExpression:(NSString*)s {
    ZNLogP(TRACE, @"s=%@", s);
    NSMutableString* exp = [[NSMutableString alloc] init];
    int i;
    NSString* c;
    NSRange range;
    range.length = 1;
    
    for (i=0; i<[s length]; i++) {
        range.location = i;
        c = [s substringWithRange:range];
        //NSLog(@"c: %@ %d", c, [c characterAtIndex:0]);
        if (([c characterAtIndex:0] >= 65 && [c characterAtIndex:0] <= 90) ||
            ([c characterAtIndex:0] >= 97 && [c characterAtIndex:0] <= 122)) {
            [exp appendString:@"["];
            [exp appendString:[c lowercaseString]];
            [exp appendString:[c uppercaseString]];
            [exp appendString:@"]"];
        } else {
            [exp appendString:c];
        }
    }
    return exp;
}

- (NSString*)parseEpisodeName:(NSString*)junk {
    ZNLogP(TRACE, @"junk=%@", junk);
    int i;
    
    int pos = [junk length];
    
    NSArray* exps = [PathDictionary expressions];
    
    for (i=0; i<[exps count]; i++) {
        //NSLog(@"expression: %@", [expressions objectAtIndex:i]);
        NSString* substr = [junk substringMatchedByPattern:[exps objectAtIndex:i]];
        if (substr) {
            NSRange range = [junk rangeOfString:substr];
            if (range.location < pos) {
                pos = range.location;
            }
        }
    }
    
    NSRange range = NSMakeRange(0, pos);
    NSString* episodeName = [junk substringWithRange:range];
    
    NSMutableString* name = [[NSMutableString alloc] init];
    [name appendString:episodeName];
    
    exps = [Preferences whitespaceExpressions];
    for (i=0; i<[exps count]; i++) {
        [name replaceOccurrencesOfString:[exps objectAtIndex:i] withString:@" " options:0 range:NSMakeRange(0, [name length]) ];
    }
    
    while ([name rangeOfString:@"  "].location != NSNotFound){
        [name replaceOccurrencesOfString:@"  " withString:@" " options:0 range:NSMakeRange(0, [name length]) ];
    }
    
    episodeName = [name stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    return episodeName;
}

- (NSString*)trimFilename:(NSString*)filename {
    ZNLogP(TRACE, @"filename=%@", filename);
    int i;
    
    NSMutableString* junk = [[NSMutableString alloc] init];
    [junk setString:filename];
    
    NSArray* exps = [Preferences releaseGroupExpressions];
    
    for (i=0; i<[exps count]; i++) {
        NSString* substr = [junk substringMatchedByPattern:[exps objectAtIndex:i]];
        if (substr) {
            [junk replaceOccurrencesOfString:substr withString:@"" options:0 range:NSMakeRange(0, [junk length]) ];
        }
    }
    
    exps = [Preferences whitespaceExpressions];
    for (i=0; i<[exps count]; i++) {
        [junk replaceOccurrencesOfString:[exps objectAtIndex:i] withString:@"" options:0 range:NSMakeRange(0, [junk length]) ];
    }
    
    while ([junk rangeOfString:@"  "].location != NSNotFound){
        [junk replaceOccurrencesOfString:@"  " withString:@" " options:0 range:NSMakeRange(0, [junk length]) ];
    }
    
    return [junk stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
}

- (Episode*) parseEpisode:(NSString*)path {
    ZNLogP(DEBUG, @"path=%@", path);
    
    NSString* fileName = [path lastPathComponent];
    NSDictionary* episode = [self episodeForFilename:fileName];
    if (episode) {
        return [Episode initEpisode:episode];
    }
    
    NSString* showName;
    if ([self isTvShowPath:path]) {
        int numShowDirectoryComponents = [[[Preferences tvShowDirectory] pathComponents] count];
        NSArray* components = [path pathComponents];
        
        if ([components count] > numShowDirectoryComponents) {
            showName = [components objectAtIndex:numShowDirectoryComponents];
        }
    }
    
    int seasonNumber = -1;
    NSString* episodeName = nil;
    NSArray* exps = [Preferences episodeExpressions];
    //NSString* fileName = [NSString stringWithString:name];
    
    NSString* trimmedFilename = [self trimFilename:fileName];
    
    
    
    int i;
    for (i=0; seasonNumber < 0 && i<[exps count]; i++) {
        
        NSString* exp = [exps objectAtIndex:i];
        NSArray* matches = [trimmedFilename substringsCapturedByPattern:exp];
        if ([matches count] > 0) {
            seasonNumber = [[matches objectAtIndex:1] intValue];
            int episodeNumber = [[matches objectAtIndex:2] intValue];
            NSString* junk = [[matches objectAtIndex:3] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            NSString* seasonStr = [[NSString alloc] initWithFormat:@"%d", seasonNumber];
            NSString* episodeStr = [[NSString alloc] initWithFormat:@"%d", episodeNumber];
            
            NSString* externalEpisodeName = [self fetchEpisodeNameForShow:showName forSeason:seasonStr forEpisode:episodeStr];
                        
            if (externalEpisodeName) {
                episodeName = externalEpisodeName;
            } else {
                episodeName = junk;
            }
            
            //NSLog(@"filePath: %@", path);
            //NSLog(@"season: %@", seasonStr);
            //NSLog(@"episode: %@", episodeStr);
            //NSLog(@"showName: %@", showName);
            //NSLog(@"episodeName: %@", episodeName);
            NSArray* keys = [NSArray arrayWithObjects:@"filePath", @"season", @"episode", @"showName", @"episodeName", nil];
            NSArray* values = [NSArray arrayWithObjects:path, seasonStr, episodeStr, showName, episodeName, nil];
            episode = [NSMutableDictionary dictionaryWithObjects:values forKeys:keys];
        }
    }
    if (episode) {
        [self setEpisode:episode forFilename:fileName];
    }
    return [Episode initEpisode:episode];
}


@end
