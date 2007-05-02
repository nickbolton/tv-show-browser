//
//  Preferences.m
//  TvShowBrowser
//
//  Created by Deuce on 4/27/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "Preferences.h"
#import "ZNLog.h"
#import "defaults.h"

@implementation Preferences

static Preferences *sharedPreferences = nil;

+ (Preferences*)sharedPreferences
{
    //ZNLog(TRACE);
    @synchronized(self) {
        if (sharedPreferences == nil) {
            [[self alloc] init]; // assignment not done here
        }
    }
    return sharedPreferences;
}

+ (id)allocWithZone:(NSZone *)zone
{
    //ZNLogP(TRACE, @"zone=%@", zone);
    @synchronized(self) {
        if (sharedPreferences == nil) {
            sharedPreferences = [super allocWithZone:zone];
            [sharedPreferences initializePreferences];
            return sharedPreferences;  // assignment and return on first allocation
        }
    }
    return nil; //on subsequent allocation attempts return nil
}

+ (id)copyWithZone:(NSZone *)zone
{
    //ZNLogP(TRACE, @"zone=%@", zone);
    return self;
}

+ (id)retain
{
    //ZNLog(TRACE);
    return self;
}

+ (unsigned)retainCount
{
    //ZNLog(TRACE);
    return UINT_MAX;  //denotes an object that cannot be released
}

+ (void)release
{
    //ZNLog(TRACE);
    //do nothing
}

+ (id)autorelease
{
    //ZNLog(TRACE);
    return self;
}

- (void)initializePreferences {
    NSDictionary* dict = [NSDictionary dictionaryWithContentsOfFile:
        [@"~/Library/Preferences/TvShowBrowser.plist" 
            stringByExpandingTildeInPath]];
    prefs = [[NSMutableDictionary alloc] init];
    [prefs addEntriesFromDictionary:dict];
    
    defaults = [NSUserDefaults standardUserDefaults];
    
    NSMutableDictionary *appDefs = [NSMutableDictionary dictionary]; 
    
    [appDefs setObject:[@"~/Movies/TvShows" stringByExpandingTildeInPath] 
                forKey:TBS_TvShowDirectory]; 
    [appDefs setObject:[@"~/Movies" stringByExpandingTildeInPath]
                forKey:TBS_MediaDirectory];
    [appDefs setObject:[NSMutableArray arrayWithObjects:@"hdtv",
        @"lol",
        @"xvid",
        @"xor",
        @"fov",
        @"\[?vtv\]?",
        @"fqm",
        @"yestv",
        @"eztv",
        @"proper",
        @"repack",
        @"avi",
        @"dvdrip",
        @"720p",
        @"ws",
        @"hr",
        @"webrip",
        @"divx",
        @"pdtv",
        @"dsr",
        @"dvdscr",
        @"mpg",
        @"mpeg",
        @"dimension",
        @"memetic",
        @"ctu",
        @"mkv",
        @"aerial",
        @"notv",
        @"x264",
        @"saints",
        @"hv",
        @"kyr",
        @"2hd",
        @"2sd",
        @"caph",
        @"bluetv",
        @"fpn",
        @"sorny",
        @"preair",
        @"crimson",
        @"orenji",
        @"loki",
        @"ndr",
        @"rmvb",
        @"asd",
        @"vf",
        @"dontask",
        @"bhd",
        nil]
                forKey:TBS_ReleaseGroupExpressions];
    [appDefs setObject:[NSMutableArray arrayWithObjects:
        @"[sS]([0-9]+)[eE]([0-9]+)(.*)",
        @"([0-9]+)[xX]([0-9]+)(.*)",
        @"([1-9][0-9]?)([0-9][0-9])(.*)",
        nil]
                forKey:TBS_EpisodeExpressions];
    [appDefs setObject:@"http://epguides.com/" 
                forKey:TBS_EpisodeSite];
    [appDefs setObject:[NSMutableArray arrayWithObjects:@"[", @"]", @"(", @")", nil] 
                forKey:TBS_EpisodeFilenameTrimStrings];
    [appDefs setObject:[NSMutableArray arrayWithObjects:@"_", @"-", @".", nil] 
                forKey:TBS_EpisodeFilenameWSStrings];
    [appDefs setObject:[NSMutableArray arrayWithObjects:@"  ", nil] 
                forKey:TBS_EpisodeFilenameWSAll];
    
    [appDefs setObject:@"0.02"
                forKey:TBS_AllowablePercentNullForDownload];
    
    [appDefs setObject:[NSString stringWithFormat:@"%d", ERROR]
                forKey:TBS_LogLevel];
    
    [appDefs setObject:[NSMutableArray arrayWithObjects:@"avi", @"mpg", @"mpeg", nil] 
                forKey:TSB_MediaExtensions]; 
    [appDefs setObject:@"5" 
                forKey:TBS_RecentShowsModifiedTimeMin];
    [appDefs setObject:@"4320" 
                forKey:TBS_RecentShowsModifiedTimeMax];
    [appDefs setObject:@"300.0" 
                forKey:TBS_RecentShowsRefreshInterval];
    
    [defaults registerDefaults:appDefs];
}

+ (void) dealloc
{   
    ZNLog(TRACE);
    [prefs release];
    [super dealloc];
}

+ (void)save {
    [[Preferences sharedPreferences] __save];
}

- (void)__save {
    ZNLog(TRACE);
    ZNLogP(DEBUG, @"Saving preferences:\n%@", prefs);
    [prefs writeToFile:[@"~/Library/Preferences/TvShowBrowser.plist"
        stringByExpandingTildeInPath] atomically: TRUE];
}

- (NSString*)__preference:(NSString*)key {
    ZNLogP(TRACE, @"key=%@", key);
    NSString* p = [prefs objectForKey:key];
    if (!p) {
        p = [defaults objectForKey:key];
        if (p != nil) {
            [self __setPreference:p forKey:key];
        }
    }
    return p;
}

+ (NSString*)preference:(NSString*)key {
    return [[Preferences sharedPreferences] __preference:key];
}

- (void)__setPreference:(NSString*)value forKey:(NSString*)key {
    ZNLogP(TRACE, @"value=%@ key=%@", value, key);
    [self __setPreference:value forKey:key save:YES];
}

+ (void)setPreference:(NSString*)value forKey:(NSString*)key {
    [[Preferences sharedPreferences] __setPreference:value forKey:key];
}

- (void)__setPreference:(NSString*)value forKey:(NSString*)key save:(BOOL)save {
    ZNLogP(TRACE, @"value=%@ key=%@ save=%d", value, key, save);
    [prefs setObject:value forKey:key];
    if (save) {
        [self __save];
    }
}

+ (void)setPreference:(NSString*)value forKey:(NSString*)key save:(BOOL)save {
    [[Preferences sharedPreferences] __setPreference:value forKey:key save:save];
}

- (int)__preferenceAsInt:(NSString*)key {
    ZNLogP(TRACE, @"key=%@", key);
    NSString* pref = [self __preference:key];
    if (pref) {
        return [pref intValue];
    }
    return 0;
}

+ (int)preferenceAsInt:(NSString*)key {
    return [[Preferences sharedPreferences] __preferenceAsInt:key];
}

- (void)__setPreferenceAsInt:(int)value forKey:(NSString*)key {
    ZNLogP(TRACE, @"value=%d key=%@", value, key);
    [self __setPreferenceAsInt:value forKey:key save:YES];
}

+ (void)setPreferenceAsInt:(int)value forKey:(NSString*)key {
    [[Preferences sharedPreferences] __setPreferenceAsInt:value forKey:key];
}

- (void)__setPreferenceAsInt:(int)value forKey:(NSString*)key save:(BOOL)save {
    ZNLogP(TRACE, @"value=%d key=%@ save=%d", value, key, save);
    [self __setPreference:[NSString stringFromFormat:@"%d", value] forKey:key save:save];
}

+ (void)setPreferenceAsInt:(int)value forKey:(NSString*)key save:(BOOL)save {
    [[Preferences sharedPreferences] __setPreferenceAsInt:value forKey:key save:save];
}

- (double)__preferenceAsDouble:(NSString*)key {
    ZNLogP(TRACE, @"key=%@", key);
    NSString* pref = [self __preference:key];
    if (pref) {
        return [pref doubleValue];
    }
    return 0.0;
}

+ (double)preferenceAsDouble:(NSString*)key {
    return [[Preferences sharedPreferences] __preferenceAsDouble:key];
}

- (void)__setPreferenceAsDouble:(double)value forKey:(NSString*)key {
    ZNLogP(TRACE, @"value=%f key=%@", value, key);
    [self __setPreferenceAsDouble:value forKey:key save:YES];
}

+ (void)setPreferenceAsDouble:(double)value forKey:(NSString*)key {
    [[Preferences sharedPreferences] __setPreferenceAsDouble:value forKey:key];
}

- (void)__setPreferenceAsDouble:(double)value forKey:(NSString*)key save:(BOOL)save {
    ZNLogP(TRACE, @"value=%f key=%@ save=%d", value, key, save);
    [self __setPreference:[NSString stringFromFormat:@"%f", value] forKey:key save:save];
}

+ (void)setPreferenceAsDouble:(double)value forKey:(NSString*)key save:(BOOL)save {
    [[Preferences sharedPreferences] __setPreferenceAsDouble:value forKey:key save:save];
}

- (BOOL)__arrayContains:(NSString*)value forKey:(NSString*)key {
    ZNLogP(TRACE, @"value=%@ key=%@", value, key);
    return [[self __arrayPreference:key] containsObject:value];
}

+ (BOOL)arrayContains:(NSString*)value forKey:(NSString*)key {
    return [[Preferences sharedPreferences] __arrayContains:value forKey:key];
}

- (NSArray*)__arrayPreference:(NSString*)key {
    ZNLogP(TRACE, @"key=%@", key);
    NSArray* array = [prefs objectForKey:key];
    if (!array) {
        array = [defaults objectForKey:key];
        if (array) {
            [self __setPreference:array forKey:key];
        }
    }
    return array;
}

+ (NSArray*)arrayPreference:(NSString*)key {
    return [[Preferences sharedPreferences] __arrayPreference:key];
}

- (void)__addPreferencesToArray:(NSArray*)array forKey:(NSString*)key save:(BOOL)save {
    ZNLogP(TRACE, @"array=%@ key=%@ save=%d", array, key, save);
    if (array) {
        int i;
        @synchronized(self) {
            for (i=0; i<[array count]; i++) {
                [self __addPreferenceToArray:[array objectAtIndex:i] forKey:key save:NO];
            }
        }
        if (save) {
            [self __save];
        }
    }
}

+ (void)addPreferencesToArray:(NSArray*)array forKey:(NSString*)key save:(BOOL)save {
    [[Preferences sharedPreferences] __addPreferencesToArray:array forKey:key save:save];
}

- (void)__addPreferenceToArray:(NSString*)value forKey:(NSString*)key {
    ZNLogP(TRACE, @"value=%@ key=%@", value, key);
    [self __addPreferenceToArray:value forKey:key save:YES];
}

+ (void)addPreferenceToArray:(NSString*)value forKey:(NSString*)key {
    [[Preferences sharedPreferences] __addPreferenceToArray:value forKey:key];
}

- (void)__addPreferenceToArray:(NSString*)value forKey:(NSString*)key save:(BOOL)save {
    ZNLogP(TRACE, @"value=%@ key=%@ save=%d", value, key, save);
    
    @synchronized(self) {
        NSArray* array = [self __arrayPreference:key];
        if ([array containsObject:value]) return;
        
        NSMutableArray* mutableArray = [[NSMutableArray alloc] init];
        
        if (array) {
            [mutableArray addObjectsFromArray:array];
        }
        [prefs setObject:mutableArray forKey:key];
        
        [mutableArray addObject:value];
    }
    if (save) {
        [self __save];
    }
}

+ (void)addPreferenceToArray:(NSString*)value forKey:(NSString*)key save:(BOOL)save {
    [[Preferences sharedPreferences] __addPreferenceToArray:value forKey:key save:save];
}

- (void)__removePreferenceFromArray:(NSString*)value forKey:(NSString*)key {
    ZNLogP(TRACE, @"value=%@ key=%@", value, key);
    [self __removePreferenceFromArray:value forKey:key save:YES];
}

+ (void)removePreferenceFromArray:(NSString*)value forKey:(NSString*)key {
    [[Preferences sharedPreferences] __removePreferenceFromArray:value forKey:key];
}

- (void)__removePreferenceFromArray:(NSString*)value forKey:(NSString*)key save:(BOOL)save {
    ZNLogP(TRACE, @"value=%@ key=%@ save=%d", value, key, save);
    
    @synchronized(self) {
        NSArray* array = [self __arrayPreference:key];
        NSMutableArray* mutableArray = [[NSMutableArray alloc] init];
        
        if (array) {
            [mutableArray addObjectsFromArray:array];
        }
        [prefs setObject:mutableArray forKey:key];
        
        [mutableArray removeObject:value];
    }
    if (save) {
        [self __save];
    }
}

+ (void)removePreferenceFromArray:(NSString*)value forKey:(NSString*)key save:(BOOL)save {
    [[Preferences sharedPreferences] __removePreferenceFromArray:value forKey:key save:save];
}

- (NSDictionary*)__dictionaryPreferences:(NSString*)key {
    ZNLogP(TRACE, @"key=%@", key);
    return [prefs objectForKey:key];
}

+ (NSDictionary*)dictionaryPreferences:(NSString*)key {
    return [[Preferences sharedPreferences] __dictionaryPreferences:key];
}

- (NSString*)__dictionaryPreference:(NSString*)key forDictionaryKey:(NSString*)dictionaryKey {
    ZNLogP(TRACE, @"key=%@ dictionaryKey=%@", key, dictionaryKey);
    NSDictionary* dictionary = [self __dictionaryPreferences:key];
    NSString* value;
    if (dictionary) {
        value = [dictionary objectForKey:dictionaryKey];
    }
    return value;
}

+ (NSString*)dictionaryPreference:(NSString*)key forDictionaryKey:(NSString*)dictionaryKey {
    return [[Preferences sharedPreferences] __dictionaryPreference:key forDictionaryKey:dictionaryKey];
}

- (void)__removePreferenceFromDictionary:(NSString*)key forDictionaryKey:(NSString*)dictionaryKey {
    ZNLogP(TRACE, @"key=%@ dictionaryKey=%@", key, dictionaryKey);
    [self __removePreferenceFromDictionary:key forDictionaryKey:dictionaryKey save:YES];
}

+ (void)removePreferenceFromDictionary:(NSString*)key forDictionaryKey:(NSString*)dictionaryKey {
    [[Preferences sharedPreferences] __removePreferenceFromDictionary:key forDictionaryKey:dictionaryKey];
}

- (void)__removePreferenceFromDictionary:(NSString*)key forDictionaryKey:(NSString*)dictionaryKey save:(BOOL)save {
    ZNLogP(TRACE, @"key=%@ dictionaryKey=%@ save=%d", key, dictionaryKey, save);
    
    @synchronized(self) {
        NSDictionary* dictionary = [self __dictionaryPreferences:key];
        NSMutableDictionary* mutableDictionary = [[NSMutableDictionary alloc] init];
        
        if (dictionary) {
            [mutableDictionary addEntriesFromDictionary:dictionary];
        }
        [prefs setObject:mutableDictionary forKey:key];
        
        [mutableDictionary removeObjectForKey:dictionaryKey];
    }
    if (save) {
        [self __save];
    }
}

+ (void)removePreferenceFromDictionary:(NSString*)key forDictionaryKey:(NSString*)dictionaryKey save:(BOOL)save {
    [[Preferences sharedPreferences] __removePreferenceFromDictionary:key forDictionaryKey:dictionaryKey save:save];
}

- (void)__setPreferenceToDictionary:(NSString*)value forDictionaryKey:(NSString*)dictionaryKey forKey:(NSString*)key {
    ZNLogP(TRACE, @"value=%@ key=%@ dictionaryKey=%@", value, key, dictionaryKey);
    [self __setPreferenceToDictionary:value forDictionaryKey:dictionaryKey forKey:key save:YES];
}

+ (void)setPreferenceToDictionary:(NSString*)value forDictionaryKey:(NSString*)dictionaryKey forKey:(NSString*)key {
    [[Preferences sharedPreferences] __setPreferenceToDictionary:value forDictionaryKey:dictionaryKey forKey:key];
}

- (void)__setPreferenceToDictionary:(NSString*)value forDictionaryKey:(NSString*)dictionaryKey forKey:(NSString*)key save:(BOOL)save {
    ZNLogP(TRACE, @"value=%@ key=%@ dictionaryKey=%@ save=%d", value, key, dictionaryKey, save);
    
    @synchronized(self) {
        NSDictionary* dictionary = [self __dictionaryPreferences:key];
        NSMutableDictionary* mutableDictionary = [[NSMutableDictionary alloc] init];
        
        if (dictionary) {
            [mutableDictionary addEntriesFromDictionary:dictionary];
        }
        [prefs setObject:mutableDictionary forKey:key];
        
        [mutableDictionary setObject:value forKey:dictionaryKey];
    }
    if (save) {
        [self __save];
    }
    
}

+ (void)setPreferenceToDictionary:(NSString*)value forDictionaryKey:(NSString*)dictionaryKey forKey:(NSString*)key save:(BOOL)save {
    [[Preferences sharedPreferences] __setPreferenceToDictionary:value forDictionaryKey:dictionaryKey forKey:key save:save];
}

+ (NSString*)mediaDirectory {
    ZNLog(TRACE);
    return [Preferences preference:TBS_MediaDirectory];
}

+ (NSString*)tvShowDirectory {
    ZNLog(TRACE);
    return [Preferences preference:TBS_TvShowDirectory];
}

+ (void)setTvShowDirectory:(NSString*)newPath {
    ZNLogP(TRACE, @"newPath=%@", newPath);
    [Preferences setPreference:newPath forKey:TBS_TvShowDirectory];
}

+ (NSArray*)episodeExpressions {
    ZNLog(TRACE);
    return [Preferences arrayPreference:TBS_EpisodeExpressions];
}

+ (NSArray*)releaseGroupExpressions {
    ZNLog(TRACE);
    return [Preferences arrayPreference:TBS_ReleaseGroupExpressions];
}

+ (double)recentShowsRefreshInterval {
    ZNLog(DEBUG);
    return [Preferences preferenceAsDouble:TBS_RecentShowsRefreshInterval];
}

+ (int)recentShowsModifiedTimeMin {
    ZNLog(DEBUG);
    return [Preferences preferenceAsInt:TBS_RecentShowsModifiedTimeMin];
}

+ (int)recentShowsModifiedTimeMax {
    ZNLog(DEBUG);
    return [Preferences preferenceAsInt:TBS_RecentShowsModifiedTimeMax];
}

+ (double)allowableIncomplete {
    ZNLog(DEBUG);
    return [Preferences preferenceAsDouble:TBS_AllowablePercentNullForDownload];
}

+ (NSArray*)mediaExtensions {
    ZNLog(TRACE);
    return [Preferences arrayPreference:TSB_MediaExtensions];
}

+ (int)logLevel {
    ZNLog(DEBUG);
    return [Preferences preferenceAsDouble:TBS_LogLevel];
}

@end
