//
//  RecentShows.m
//  TvShowBrowser
//
//  Created by Deuce on 5/1/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "RecentShows.h"
#import "ZNLog.h"
#import "PathDictionary.h"
//#import "UKKQueue.h"
#import "Preferences.h"


@implementation RecentShows

- (void)awakeFromNib {
    ZNLog(DEBUG);
    recentShows = [[NSMutableArray alloc] init];
    
    [recentShowsTableView setDoubleAction:@selector(recentShowAction:)];
    
    
    double d = [Preferences recentShowsRefreshInterval];
    recentShowsTimer = [NSTimer scheduledTimerWithTimeInterval:d target:self selector:@selector(updateRecentShows:) userInfo:nil repeats:YES];
    [recentShowsTimer fire];
    
    /*
    NSString* tvShowDirectory = [Preferences tvShowDirectory];
    UKKQueue* kqueue = [UKKQueue sharedFileWatcher];
    NSLog(@"adding dir=%@", tvShowDirectory);
    [kqueue addPathToQueue:tvShowDirectory];
    NSWorkspace* workspace = [NSWorkspace sharedWorkspace];
    NSNotificationCenter* notificationCenter = [workspace notificationCenter];
    NSArray* notifications = [NSArray arrayWithObjects:
        UKFileWatcherRenameNotification,
        UKFileWatcherWriteNotification,
        UKFileWatcherDeleteNotification,
        UKFileWatcherAttributeChangeNotification,
        UKFileWatcherSizeIncreaseNotification,
        UKFileWatcherLinkCountChangeNotification,
        UKFileWatcherAccessRevocationNotification,
        nil];
    
    NSArray* tvShowSubDirectories = [self tvShowSubDirectories];
    NSEnumerator *pathEnumerator = [tvShowSubDirectories objectEnumerator];
    NSString* subPath;
    NSString* absolutePath;
    NSFileManager* fileManager = [NSFileManager defaultManager];
    BOOL isDirectory = NO;
    
    while ((subPath = [pathEnumerator nextObject])) {
        if ([@".DS_Store" compare:[subPath lastPathComponent]] != NSOrderedSame) {
            absolutePath = [tvShowDirectory stringByAppendingPathComponent:subPath];
            NSLog(@"Adding path to kqueue=%@", absolutePath);
            [kqueue addPathToQueue:absolutePath];
        }
    }
        
    NSEnumerator* notificationsEnumerator = [notifications objectEnumerator];
    NSString* notification;
    
    while ((notification = [notificationsEnumerator nextObject])) {
        NSLog(@"Adding notification=%@", notification);
        [notificationCenter addObserver:self selector:@selector(pollTvShows:) name:notification object:nil];
    }
    */
}

- (NSArray*)tvShowSubDirectories {
    NSFileManager* fileManager = [NSFileManager defaultManager];
    return [fileManager subpathsAtPath:[Preferences tvShowDirectory]];
}

- (void)pollTvShows:(NSNotification *)notification {
    NSLog(@"fileSystemChanged: %@", notification);
}


- (IBAction)ignoreRecent:(id)sender {
    ZNLogP(DEBUG, @"sender=%@", sender);
    NSArray* selection = [recentShowsArrayController selectedObjects];
    
    BOOL modified = NO;
    int i;
    for (i=0; i<[selection count]; i++) {
        Episode* episode = [selection objectAtIndex:i];
        
        [self setEpisodeIgnored:[[episode properties] objectForKey:@"filePath"] save:NO];
        modified = YES;
        [recentShowsArrayController removeObject:episode];
    }
    if (modified) {
        [Preferences save];
    }
}

- (BOOL)isEpisodeIgnored:(NSString*)path {
    ZNLogP(DEBUG, @"path=%@", path);
    NSMutableArray* array = [Preferences arrayPreference:@"ignoredEpisodes"];
    BOOL ans = [array containsObject:path];
    return ans;
}

- (void)setEpisodeIgnored:(NSString*)path save:(BOOL)save {
    ZNLogP(DEBUG, @"path=%@", path);
    [Preferences addPreferenceToArray:path forKey:@"ignoredEpisodes" save:NO];
    [Preferences removePreferenceFromArray:path forKey:@"completedDownloads" save:save];
}

- (void)updateLastChoice:(NSString*)path save:(BOOL)save {
    NSString *parent = [path stringByDeletingLastPathComponent];
    
    NSString* mediaDirectoryParent = [[Preferences mediaDirectory] stringByDeletingLastPathComponent];
    while ( [parent compare:mediaDirectoryParent] ) {
        [Preferences setPreferenceToDictionary:path forDictionaryKey:parent forKey:@"lastChoiceDictionary" save:NO];
        parent = [parent stringByDeletingLastPathComponent];
    }
    if (save) {
        [Preferences save];
    }
}

- (void)removeObject:(Episode*)externalEpisode {
    if (!externalEpisode) return;
    
    Episode* localEpisode = nil;
    NSString* externalFilePath = [externalEpisode filePath];
    NSString* localFilePath = nil;
    
    int i;
    for (i=0; !localEpisode && i<[recentShows count]; i++) {
        localFilePath = [[recentShows objectAtIndex:i] filePath];
        if ([externalFilePath compare:localFilePath] == NSOrderedSame) {
            localEpisode = [recentShows objectAtIndex:i];
        }
    }
    if (localEpisode) {
        [recentShowsArrayController removeObject:localEpisode];
    }
}

- (IBAction)recentShowAction:(id)sender {
    ZNLogP(DEBUG, @"sender=%@", sender);
    int episodeRow = -1;
    
    if ([sender isKindOfClass:[NSTableView class]]) {
        episodeRow = [recentShowsTableView clickedRow];
    } else {
        episodeRow = [recentShowsTableView selectedRow];
    }
    
    if (episodeRow >= 0) {
        NSArray* array = [recentShowsArrayController arrangedObjects];
        Episode* episode = [array objectAtIndex:episodeRow];
        NSString* filePath = [[episode properties] objectForKey:@"filePath"];
        //NSLog(@"episode: %@ watched: %d", [episode filePath], [self isShowWatched:filePath]);
        [[NSWorkspace sharedWorkspace] openFile:filePath ];
        [recentShowsArrayController removeObject:episode];
        [self setEpisodeIgnored:filePath save:NO];
        
        [self updateLastChoice:filePath save:NO];
        [appController refreshLastAndNextShows:filePath];
        
        NSString* browserPath = [filePath substringFromIndex:[[Preferences mediaDirectory] length]];
        [[appController browser] setPath:browserPath];
        
        [Preferences save];
    }
}

- (NSMutableArray*)recentShows {
    ZNLog(DEBUG);
    return recentShows;
}

- (void)setRecentShows:(NSMutableArray*)newArray {
    ZNLogP(DEBUG, @"newArray=%@", newArray);
    [newArray retain];
    [recentShows autorelease];
    recentShows = newArray;
}

- (void)updateRecentShows:(NSTimer*)theTimer {
    ZNLogP(DEBUG, @"theTimer=%@", theTimer);
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    NSArray* mediaExtensions = [Preferences mediaExtensions];
    int minInterval = [Preferences recentShowsModifiedTimeMin];
    int maxInterval = [Preferences recentShowsModifiedTimeMax];
    NSArray* timeArgs = [NSArray arrayWithObjects:[Preferences tvShowDirectory], @"-type", @"f", @"-mmin", [NSString stringWithFormat:@"+%d", minInterval], @"-mmin", [NSString stringWithFormat:@"-%d", maxInterval], nil];
    NSMutableArray* args = [[NSMutableArray alloc] init];
    [args addObjectsFromArray:timeArgs];
    
    [args addObject:@"("];
    int i;
    for (i=0; i<[mediaExtensions count]; i++) {
        if (i>0) {
            [args addObject:@"-o"];
        }
        [args addObject:@"-name"];
        [args addObject:[[NSString stringWithString:@"*."] stringByAppendingString:[mediaExtensions objectAtIndex:i]]];
    }
    [args addObject:@")"];
    
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
    
    for (i=0; i<[args count]; i++) {
        [argsStr appendString:[args objectAtIndex:i]];
        [argsStr appendString:@" "];
    }
    
    ZNLogP(DEBUG, @"args: %@", argsStr);
    [task launch];
    
    while ((inData = [readHandle availableData]) && [inData length]) {
        size = [inData length];
        //NSLog(@"data size: %d", size);
        char buf[size+1];
        buf[size] = '\0';
        [inData getBytes:buf];
        [result appendFormat:@"%s", buf];
    }
    ZNLogP(DEBUG, @"%@", result);
    
    if ([recentShows count] > 0) {
        [recentShowsArrayController removeObjects:recentShows];
    }
    NSArray* paths = [result componentsSeparatedByString:@"\n"];
    
    BOOL modified = NO;
        
    for (i=0; i<[paths count]; i++) {
        NSString* path = [paths objectAtIndex:i];
        //NSLog(@"path: #%@#", path);
        BOOL prefsModified = NO;
        BOOL isIgnored = [self isEpisodeIgnored:path];
        BOOL isComplete = [self isDownloadComplete:path forceCheck:YES modified:&prefsModified];
        modified = modified || prefsModified;
        if (path && [path compare:@""] && !isIgnored && isComplete) {
            Episode* episode = [[PathDictionary sharedPathDictionary] parseEpisode:path];
            if (episode) {
                //NSLog(@"episode:\n%@", [episode properties]);
                [recentShowsArrayController addObject:episode];
            }
        }
        
    }
    
    if (modified) {
        [Preferences save];
    }
    [pool release];
}

- (BOOL)isDownloadComplete:(NSString*)filePath forceCheck:(BOOL)forceCheck modified:(BOOL*)modified {
    ZNLogP(DEBUG, @"filePath=%@", filePath);
    if (modified) *modified = NO;
    if ([Preferences arrayContains:filePath forKey:@"completedDownloads"]) return YES;
    
    if (forceCheck) {
        NSData* data = [[NSFileManager defaultManager] contentsAtPath:filePath];
        const char* buf = [data bytes];
        long zeroByteCount = 0;
        
        int i;
        for (i=0; i<[data length]; i++) {
            if (*(buf+i) == '\0') zeroByteCount++;
        }
        
        double percentIncomplete = (double)zeroByteCount/(double)[data length];
        double allowableIncomplete = [Preferences allowableIncomplete]/100.0;
        if (percentIncomplete < allowableIncomplete) {
            [Preferences addPreferenceToArray:filePath forKey:@"completedDownloads" save:NO];
            if (modified) *modified = YES;
            return YES;
        }
    }
    return NO;
}


@end
