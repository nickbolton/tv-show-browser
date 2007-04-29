//
//  Preferences.h
//  TvShowBrowser
//
//  Created by Deuce on 4/27/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface Preferences : NSObject {
    NSMutableDictionary* prefs;
    NSUserDefaults* defaults;
}

+ (Preferences*)sharedPreferences;

- (void)save;

- (NSString*)preference:(NSString*)key;
- (void)setPreference:(NSString*)value forKey:(NSString*)key;
- (void)setPreference:(NSString*)value forKey:(NSString*)key save:(BOOL)save;

- (int)preferenceAsInt:(NSString*)key;
- (void)setPreferenceAsInt:(int)value forKey:(NSString*)key;
- (void)setPreferenceAsInt:(int)value forKey:(NSString*)key save:(BOOL)save;

- (double)preferenceAsDouble:(NSString*)key;
- (void)setPreferenceAsDouble:(double)value forKey:(NSString*)key;
- (void)setPreferenceAsDouble:(double)value forKey:(NSString*)key save:(BOOL)save;

- (NSArray*)arrayPreference:(NSString*)key;
- (BOOL)arrayContains:(NSString*)value forKey:(NSString*)key;
- (void)addPreferenceToArray:(NSString*)value forKey:(NSString*)key;
- (void)removePreferenceFromArray:(NSString*)value forKey:(NSString*)key;
- (void)addPreferencesToArray:(NSArray*)array forKey:(NSString*)key save:(BOOL)save;
- (void)addPreferenceToArray:(NSString*)value forKey:(NSString*)key save:(BOOL)save;
- (void)removePreferenceFromArray:(NSString*)value forKey:(NSString*)key save:(BOOL)save;

- (NSDictionary*)dictionaryPreferences:(NSString*)key;
- (NSString*)dictionaryPreference:(NSString*)key forDictionaryKey:(NSString*)dictionaryKey;
- (void)setPreferenceToDictionary:(NSString*)value forDictionaryKey:(NSString*)dictionaryKey forKey:(NSString*)key;
- (void)setPreferenceToDictionary:(NSString*)value forDictionaryKey:(NSString*)dictionaryKey forKey:(NSString*)key save:(BOOL)save;

@end
