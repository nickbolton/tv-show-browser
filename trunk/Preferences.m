//
//  Preferences.m
//  TvShowBrowser
//
//  Created by Deuce on 4/27/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "Preferences.h"
#import "ZNLog.h"

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
            return sharedPreferences;  // assignment and return on first allocation
        }
    }
    return nil; //on subsequent allocation attempts return nil
}

- (id)copyWithZone:(NSZone *)zone
{
    //ZNLogP(TRACE, @"zone=%@", zone);
    return self;
}

- (id)retain
{
    //ZNLog(TRACE);
    return self;
}

- (unsigned)retainCount
{
    //ZNLog(TRACE);
    return UINT_MAX;  //denotes an object that cannot be released
}

- (void)release
{
    //ZNLog(TRACE);
    //do nothing
}

- (id)autorelease
{
    //ZNLog(TRACE);
    return self;
}

- (id) init
{
    //ZNLog(TRACE);
    if (self = [super init])
    {
        NSDictionary* dict = [NSDictionary dictionaryWithContentsOfFile:
            [@"~/Library/Preferences/TvShowBrowser.plist" 
                stringByExpandingTildeInPath]];
        prefs = [[NSMutableDictionary alloc] init];
        [prefs addEntriesFromDictionary:dict];
        
        defaults = [NSUserDefaults standardUserDefaults];
    }
}

- (void) dealloc
{   
    ZNLog(TRACE);
    [prefs release];
    [super dealloc];
}

- (void)save {
    ZNLog(TRACE);
    ZNLogP(DEBUG, @"Saving preferences:\n%@", prefs);
    [prefs writeToFile:[@"~/Library/Preferences/TvShowBrowser.plist"
        stringByExpandingTildeInPath] atomically: TRUE];
}

- (NSString*)preference:(NSString*)key {
    ZNLogP(TRACE, @"key=%@", key);
    NSString* p = [prefs objectForKey:key];
    if (!p) {
        p = [defaults objectForKey:key];
        if (p != nil) {
            [self setPreference:p forKey:key];
        }
    }
    return p;
}

- (void)setPreference:(NSString*)value forKey:(NSString*)key {
    ZNLogP(TRACE, @"value=%@ key=%@", value, key);
    [self setPreference:value forKey:key save:YES];
}

- (void)setPreference:(NSString*)value forKey:(NSString*)key save:(BOOL)save {
    ZNLogP(TRACE, @"value=%@ key=%@ save=%d", value, key, save);
    [prefs setObject:value forKey:key];
    if (save) {
        [self save];
    }
}

- (int)preferenceAsInt:(NSString*)key {
    ZNLogP(TRACE, @"key=%@", key);
    NSString* pref = [self preference:key];
    if (pref) {
        return [pref intValue];
    }
    return 0;
}

- (void)setPreferenceAsInt:(int)value forKey:(NSString*)key {
    ZNLogP(TRACE, @"value=%d key=%@", value, key);
    [self setPreferenceAsInt:value forKey:key save:YES];
}

- (void)setPreferenceAsInt:(int)value forKey:(NSString*)key save:(BOOL)save {
    ZNLogP(TRACE, @"value=%d key=%@ save=%d", value, key, save);
    [self setPreference:[NSString stringFromFormat:@"%d", value] forKey:key save:save];
}

- (double)preferenceAsDouble:(NSString*)key {
    ZNLogP(TRACE, @"key=%@", key);
    NSString* pref = [self preference:key];
    if (pref) {
        return [pref doubleValue];
    }
    return 0.0;
}

- (void)setPreferenceAsDouble:(double)value forKey:(NSString*)key {
    ZNLogP(TRACE, @"value=%f key=%@", value, key);
    [self setPreferenceAsDouble:value forKey:key save:YES];
}

- (void)setPreferenceAsDouble:(double)value forKey:(NSString*)key save:(BOOL)save {
    ZNLogP(TRACE, @"value=%f key=%@ save=%d", value, key, save);
    [self setPreference:[NSString stringFromFormat:@"%f", value] forKey:key save:save];
}

- (BOOL)arrayContains:(NSString*)value forKey:(NSString*)key {
    ZNLogP(TRACE, @"value=%@ key=%@", value, key);
    return [[self arrayPreference:key] containsObject:value];
}

- (NSArray*)arrayPreference:(NSString*)key {
    ZNLogP(TRACE, @"key=%@", key);
    NSArray* array = [prefs objectForKey:key];
    if (!array) {
        array = [defaults objectForKey:key];
        if (array) {
            [self setPreference:array forKey:key];
        }
    }
    return array;
}

- (void)addPreferencesToArray:(NSArray*)array forKey:(NSString*)key save:(BOOL)save {
    ZNLogP(TRACE, @"array=%@ key=%@ save=%d", array, key, save);
    if (array) {
        int i;
        for (i=0; i<[array count]; i++) {
            [self addPreferenceToArray:[array objectAtIndex:i] forKey:key save:NO];
        }
        [self save];
    }
}

- (void)addPreferenceToArray:(NSString*)value forKey:(NSString*)key {
    ZNLogP(TRACE, @"value=%@ key=%@", value, key);
    [self addPreferenceToArray:value forKey:key save:YES];
}

- (void)addPreferenceToArray:(NSString*)value forKey:(NSString*)key save:(BOOL)save {
    ZNLogP(TRACE, @"value=%@ key=%@ save=%d", value, key, save);
    NSArray* array = [self arrayPreference:key];
    if (!array) {
        array = [[NSMutableArray alloc] init];
        [prefs setObject:array forKey:key];
    }
    NSMutableArray* mutableArray;
    if (![array isKindOfClass:[NSMutableArray class]]) {
        mutableArray = [[NSMutableArray alloc] initWithArray:array];
        [prefs setObject:mutableArray forKey:key];
        [array autorelease];
    } else {
        mutableArray = array;
    }
    
    [mutableArray addObject:value];
    if (save) {
        [self save];
    }
}

- (void)removePreferenceFromArray:(NSString*)value forKey:(NSString*)key {
    ZNLogP(TRACE, @"value=%@ key=%@", value, key);
    [self removePreferenceFromArray:value forKey:key save:YES];
}

- (void)removePreferenceFromArray:(NSString*)value forKey:(NSString*)key save:(BOOL)save {
    ZNLogP(TRACE, @"value=%@ key=%@ save=%d", value, key, save);
    NSArray* array = [self arrayPreference:key];
    if (array) {
        NSMutableArray* mutableArray;
        
        if (![array isKindOfClass:[NSMutableArray class]]) {
            mutableArray = [[NSMutableArray alloc] initWithArray:array];
            [prefs setObject:mutableArray forKey:key];
            [array autorelease];            
        } else {
            mutableArray = array;
        }
        
        [mutableArray removeObject:value];
        if (save) {
            [self save];
        }
    }
}

- (NSDictionary*)dictionaryPreferences:(NSString*)key {
    ZNLogP(TRACE, @"key=%@", key);
    return [prefs objectForKey:key];
}

- (NSString*)dictionaryPreference:(NSString*)key forDictionaryKey:(NSString*)dictionaryKey {
    ZNLogP(TRACE, @"key=%@ dictionaryKey=%@", key, dictionaryKey);
    NSDictionary* dictionary = [self dictionaryPreferences:key];
    NSString* value;
    if (dictionary) {
        value = [dictionary objectForKey:dictionaryKey];
    }
    return value;
}

- (void)setPreferenceToDictionary:(NSString*)value forDictionaryKey:(NSString*)dictionaryKey forKey:(NSString*)key {
    ZNLogP(TRACE, @"value=%@ key=%@ dictionaryKey=%@", value, key, dictionaryKey);
    [self setPreferenceToDictionary:value forDictionaryKey:dictionaryKey forKey:key save:YES];
}

- (void)setPreferenceToDictionary:(NSString*)value forDictionaryKey:(NSString*)dictionaryKey forKey:(NSString*)key save:(BOOL)save {
    ZNLogP(TRACE, @"value=%@ key=%@ dictionaryKey=%@ save=%d", value, key, dictionaryKey, save);
    NSDictionary* dictionary = [self dictionaryPreferences:key];
    if (!dictionary) {
        dictionary = [[NSMutableDictionary alloc] init];
        [prefs setObject:dictionary forKey:key];
    }
    NSMutableDictionary* mutableDictionary;
    if (![dictionary isKindOfClass:[NSMutableDictionary class]]) {
        mutableDictionary = [[NSMutableDictionary alloc] initWithDictionary:dictionary];
        [prefs setObject:mutableDictionary forKey:key];
        [dictionary autorelease];
    } else {
        mutableDictionary = dictionary;
    }
    
    [mutableDictionary setObject:value forKey:dictionaryKey];
    if (save) {
        [self save];
    }
}

@end
