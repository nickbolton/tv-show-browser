//
//  PathDictionary.h
//  TvShowBrowser
//
//  Created by Deuce on 4/21/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Episode.h"


@interface PathDictionary : NSObject {
    NSMutableDictionary* pathDictionary;
    NSMutableDictionary* showEpisodeCache;
    NSArray* episodeExpressions;
    NSArray* releaseGroupExpressions;
}

- (NSString*)pathForKey:(NSString*)key;
- (void)setPath:(NSString*)path forKey:(NSString*)key;
- (NSString*)episodeNameForFilename:(NSString*)filename;
- (void)setEpisodeName:(NSString*)episodeName forFilename:(NSString*)filename;
- (BOOL)isTvShowPath:(NSString*)path;
- (Episode*) parseEpisode:(NSString*)path;

- (NSString*)fetchEpisodeNameForShow:(NSString*)show;

@end
