//
//  PathDictionary.h
//  TvShowBrowser
//
//  Created by Deuce on 4/21/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface PathDictionary : NSObject {
    NSMutableDictionary* pathDictionary;
    NSMutableDictionary* episodeNameDictionary;
    NSMutableDictionary* showEpisodeCache;
    NSMutableDictionary* lastChoiceDictionary;
    NSString* tvShowPath;
}

- (NSString*)pathForKey:(NSString*)key;
- (void)setPath:(NSString*)path forKey:(NSString*)key;
- (NSMutableDictionary*)episodeNameDictionary;
- (void)setEpisodeNameDictionary:(NSMutableDictionary*)newDict;
- (NSMutableDictionary*)lastChoiceDictionary;
- (void)setLastChoiceDictionary:(NSMutableDictionary*)newDict;
- (NSString*)episodeNameForFilename:(NSString*)filename;
- (void)setEpisodeName:(NSString*)episodeName forFilename:(NSString*)filename;
- (NSString*)lastChoiceForPath:(NSString*)path;
- (void)setLastChoice:(NSString*)lastChoice forPath:(NSString*)path;
- (BOOL)isTvShowPath:(NSString*)path;
- (NSString*)tvShowPath;
- (void)setTvShowPath:(NSString*)newPath;

- (NSString*)fetchEpisodeNameForShow:(NSString*)show;

@end
