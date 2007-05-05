/*
	AppController.m
	Copyright (c) 2001-2004, Apple Computer, Inc., all rights reserved.
	Author: Chuck Pisula

	Milestones:
	Initially created 3/1/01

	Application Controller Object, and fsBrowser delegate.
*/

/*
 IMPORTANT:  This Apple software is supplied to you by Apple Computer, Inc. ("Apple") in
 consideration of your agreement to the following terms, and your use, installation, 
 modification or redistribution of this Apple software constitutes acceptance of these 
 terms.  If you do not agree with these terms, please do not use, install, modify or 
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and subject to these 
 terms, Apple grants you a personal, non-exclusive license, under Apple’s copyrights in 
 this original Apple software (the "Apple Software"), to use, reproduce, modify and 
 redistribute the Apple Software, with or without modifications, in source and/or binary 
 forms; provided that if you redistribute the Apple Software in its entirety and without 
 modifications, you must retain this notice and the following text and disclaimers in all 
 such redistributions of the Apple Software.  Neither the name, trademarks, service marks 
 or logos of Apple Computer, Inc. may be used to endorse or promote products derived from 
 the Apple Software without specific prior written permission from Apple. Except as expressly
 stated in this notice, no other rights or licenses, express or implied, are granted by Apple
 herein, including but not limited to any patent rights that may be infringed by your 
 derivative works or by other works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE MAKES NO WARRANTIES, 
 EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, 
 MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS 
 USE AND OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL OR CONSEQUENTIAL 
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS 
 OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, 
 REPRODUCTION, MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED AND 
 WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE), STRICT LIABILITY OR 
 OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import <Foundation/NSTask.h>
#import <Foundation/NSFileHandle.h>
#import "AppController.h"
#import "FSNodeInfo.h"
#import "FSBrowserCell.h"
#import "CSRegex.h"
#import "PathDictionary.h"
#import "Episode.h"
#import "Preferences.h"
#import "ZNLog.h"
#import "RecentShows.h"

#define MAX_VISIBLE_COLUMNS 4

@interface AppController (PrivateUtilities)
- (NSString*)fsPathToColumn:(int)column;
@end

@implementation AppController

- (void)refreshLastAndNextShows:(NSString*)path {
    ZNLogP(TRACE, @"path=%@", path);
    if ([lastShow count] > 0) {
        [lastShowArrayController removeObjects:lastShow];
    }
    if ([nextShow count] > 0) {
        [nextShowArrayController removeObjects:nextShow];
    }
    
    Episode* lastWatchedEpisode = nil;
    BOOL isDirectory = NO;
    [[NSFileManager defaultManager] fileExistsAtPath:(NSString *)path isDirectory:&isDirectory];
    NSString* lastWatchedPath = nil;
    
    if (isDirectory) {
        NSString* lastChoice = [Preferences dictionaryPreference:@"lastChoiceDictionary" forDictionaryKey:path];
        if (lastChoice) {
            lastWatchedEpisode = [[PathDictionary sharedPathDictionary] parseEpisode:lastChoice];
            lastWatchedPath = lastChoice;
        }
    } else {
        lastWatchedEpisode = [[PathDictionary sharedPathDictionary] parseEpisode:path];
        lastWatchedPath = path;
    }
    
    if (lastWatchedEpisode) {
        [lastShowArrayController addObject:lastWatchedEpisode];
        
        NSString* currentBrowserPath = [fsBrowser path];
        NSString* nodePath = [lastWatchedPath substringFromIndex:[[Preferences mediaDirectory] length]];
        ZNLogP(DEBUG, @"nodePath=%@", nodePath);
        [fsBrowser setPath:nodePath];
        int column = [fsBrowser lastColumn];
        
        NSString* nextEpisodeName = [self fetchNextEpisode:lastWatchedEpisode inColumn:column];
        if (nextEpisodeName) {
            NSString* nextEpisodeNodePath = [NSString stringWithFormat:@"%@/%@", [lastWatchedPath stringByDeletingLastPathComponent], nextEpisodeName];
            NSString *nextEpisodeRealPath = [[PathDictionary sharedPathDictionary] pathForKey:nextEpisodeNodePath];
            if (nextEpisodeRealPath) {
                Episode* nextEpisode = [[PathDictionary sharedPathDictionary] parseEpisode:nextEpisodeRealPath];
                if (nextEpisode) {
                    [nextShowArrayController addObject:nextEpisode];
                }
            }
        }
        [fsBrowser setPath:currentBrowserPath];
    }
}

- (NSString*)fetchNextEpisode:(Episode*)lastEpisode inColumn:(int)column {
    
    NSString* nextEpisode = nil;
    
    NSString* attributedLastShowName = [NSString stringWithFormat:@"%dx%d %@", [lastEpisode season], [lastEpisode episode], [lastEpisode episodeName]];
    
    NSMatrix* matrix = [fsBrowser matrixInColumn:column];
    if (matrix) {
        NSArray* cells = [matrix cells];
        if (cells) {
            int i;
            BOOL seenLastEpisode = NO;
            for (i=0; !nextEpisode && i<[cells count]; i++) {
                ZNLogP(DEBUG, @"lastShowName=%@", attributedLastShowName);
                ZNLogP(DEBUG, @"   cell name=%@", [[cells objectAtIndex:i] stringValue]);
                NSString* cellName = [[cells objectAtIndex:i] stringValue];
                if (seenLastEpisode && [@"" compare:cellName] != NSOrderedSame && [attributedLastShowName compare:cellName] != NSOrderedSame) {
                    nextEpisode = [[cells objectAtIndex:i] stringValue];
                } else if ([attributedLastShowName compare:[[cells objectAtIndex:i] stringValue]] == NSOrderedSame) {
                    seenLastEpisode = YES;
                }
            }
        }
    }
    return nextEpisode;
}

- (void)dealloc {
    [directoryContentsCache release];
    [lastShow release];
    [nextShow release];
}

- (void)awakeFromNib {
    ZNLog(TRACE);
        
    directoryContentsCache = [[NSMutableDictionary alloc] init];
    lastShow = [[NSMutableArray alloc] init];
    nextShow = [[NSMutableArray alloc] init];
    
    // Make the browser user our custom browser cell.
    [fsBrowser setCellClass: [FSBrowserCell class]];

    // Tell the browser to send us messages when it is clicked.
    [fsBrowser setTarget: self];
    [fsBrowser setAction: @selector(browserSingleClick:)];
    [fsBrowser setDoubleAction: @selector(browserDoubleClick:)];
    
    [recentShowsTableView setDoubleAction:@selector(recentShowAction:)];
    
    // Configure the number of visible columns (default max visible columns is 1).
    [fsBrowser setMaxVisibleColumns: MAX_VISIBLE_COLUMNS];
    [fsBrowser setMinColumnWidth: NSWidth([fsBrowser bounds])/(float)MAX_VISIBLE_COLUMNS];

    // Prime the browser with an initial load of data.
    [self reloadData: nil];
    
    //[recentShowsTableView setDoubleAction:@selector(recentShowAction:)];
    
    //[[PathDictionary sharedPathDictionary] initEpisodeNames];
    
    [self cleanupPathDb];
    
    /*
    double d = [self recentShowsRefreshInterval];
    recentShowsTimer = [NSTimer scheduledTimerWithTimeInterval:d target:self selector:@selector(updateRecentShows:) userInfo:nil repeats:YES];
    [recentShowsTimer fire];
     */

    [lastShowTableView setDoubleAction:@selector(lastShowAction:)];
    [nextShowTableView setDoubleAction:@selector(nextShowAction:)];
    
    NSString* lastWatchedPath = [Preferences dictionaryPreference:@"lastChoiceDictionary" forDictionaryKey:[Preferences tvShowDirectory]];
    if (lastWatchedPath) {
        NSString* nodePath = [[Preferences tvShowDirectory] substringFromIndex:[[Preferences mediaDirectory] length]];
        
        [fsBrowser setPath:nodePath];
        [self refreshLastAndNextShows:lastWatchedPath];
    }
}

- (void)cleanupPathDb {
    ZNLog(TRACE);
    
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    BOOL needToSave = NO;
    NSFileManager* fileManager = [NSFileManager defaultManager];
    
    NSDictionary* dict = [Preferences dictionaryPreferences:@"episodeNames"];
    if (dict) {
        NSArray* keys = [NSArray arrayWithArray:[dict allKeys]];
        if (keys) {
            int i;
            for(i=0; i<[keys count]; i++) {
                NSString* key = [keys objectAtIndex:i];
                NSDictionary* episodeDictionary = [dict objectForKey:key];
                NSString* filePath = [episodeDictionary objectForKey:@"filePath"];
                
                ZNLogP(DEBUG, @"Checking episodeNames filePath=%@", filePath);
                if (filePath && ![fileManager fileExistsAtPath:filePath]) {
                    ZNLogP(DEBUG, @"Removing episodeNames filePath=%@", filePath);
                    [Preferences removePreferenceFromDictionary:@"episodeNames" forDictionaryKey:key save:NO];
                    needToSave = YES;
                }
            }
        }
    }
    
    needToSave = [self cleanUpPathArray:@"ignoredEpisodes"] || needToSave;
    needToSave = [self cleanUpPathDictionary:@"lastChoiceDictionary"] || needToSave;
    
    NSArray* array = [Preferences arrayPreference:@"completedDownloads"];
    if (array) {
        double maxInterval = -([Preferences recentShowsModifiedTimeMax]*60);
        NSDate* maxModificationDate = [[NSDate date] addTimeInterval:maxInterval];
        int i;
        for(i=0; i<[array count]; i++) {
            NSString* filePath = [array objectAtIndex:i];
            
            ZNLogP(DEBUG, @"Checking completedDownloads filePath=%@", filePath);
            NSDictionary *fileAttributes = [fileManager fileAttributesAtPath:filePath traverseLink:YES];
            NSDate *fileModDate = [fileAttributes objectForKey:NSFileModificationDate];
            if (fileModDate && [maxModificationDate compare:fileModDate] == NSOrderedDescending) {
                ZNLogP(DEBUG, @"Removing completedDownloads filePath=%@", filePath);
                [Preferences removePreferenceFromArray:filePath forKey:@"completedDownloads" save:NO];
                needToSave = YES;
            }
        }
    }    
    
    if (needToSave) {
        [Preferences save];
    }
    
    [pool release];
}

- (BOOL)cleanUpPathDictionary:(NSString*)key {
    //ZNLogP(TRACE, "key=%@", key);
    BOOL modified = NO;
    NSFileManager* fileManager = [NSFileManager defaultManager];
    NSDictionary* dict = [Preferences dictionaryPreferences:key];
    if (dict) {
        NSArray* keys = [NSArray arrayWithArray:[dict allKeys]];
        if (keys) {
            int i;
            for(i=0; i<[keys count]; i++) {
                NSString* dictionaryKey = [keys objectAtIndex:i];
                NSString* filePath = [dict objectForKey:dictionaryKey];
                ZNLogP(DEBUG, @"Checking %@.%@ filePath=%@", key, dictionaryKey, filePath);
                if (filePath && ![fileManager fileExistsAtPath:filePath]) {
                    ZNLogP(DEBUG, @"Removing %@.%@ filePath=%@", key, dictionaryKey, filePath);
                    [Preferences removePreferenceFromDictionary:key forDictionaryKey:dictionaryKey save:NO];
                    modified = YES;
                }                
            }
        }
    }
    return modified;
}

- (BOOL)cleanUpPathArray:(NSString*)key {
    //ZNLogP(TRACE, "key=%@", key);
    NSFileManager* fileManager = [NSFileManager defaultManager];
    BOOL modified = NO;
    NSArray* array = [NSArray arrayWithArray:[Preferences arrayPreference:key]];
    int i;
    for (i=0; i<[array count]; i++) {
        NSString* filePath = [array objectAtIndex:i];
        ZNLogP(DEBUG, @"Checking %@ filePath=%@", key, filePath);
        if (filePath && ![fileManager fileExistsAtPath:filePath]) {
            ZNLogP(DEBUG, @"Removing %@ filePath=%@", key, filePath);
            [Preferences removePreferenceFromArray:filePath forKey:key save:NO];
            modified = YES;
        }
    }
    return modified;
}

- (BOOL)isEpisodeIgnored:(NSString*)path {
    ZNLogP(TRACE, @"path=%@", path);
    NSMutableArray* array = [Preferences arrayPreference:@"ignoredEpisodes"];
    BOOL ans = [array containsObject:path];
    return ans;
}

- (void)setEpisodeIgnored:(NSString*)path save:(BOOL)save {
    ZNLogP(TRACE, @"path=%@", path);
    [Preferences addPreferenceToArray:path forKey:@"ignoredEpisodes" save:NO];
    [Preferences removePreferenceFromArray:path forKey:@"completedDownloads" save:save];
}

- (NSString*)absolutePath:(NSString*)relativePath {
    ZNLogP(TRACE, @"relativePath=%@", relativePath);
    NSString* mediaDirectory = [Preferences mediaDirectory];
    if (![relativePath compare:mediaDirectory]) return relativePath;
    
    NSMutableString* path = [[NSMutableString alloc] init];
    [path setString:mediaDirectory];
    [path appendString:relativePath];
    return path;
}

- (IBAction)reloadData:(id)sender {
    ZNLog(TRACE);
    [fsBrowser loadColumnZero];
}

- (IBAction)recentShowAction:(id)sender {
    [recentShows recentShowAction:sender];
}

// ==========================================================
// Browser Delegate Methods.
// ==========================================================

// Use lazy initialization, since we don't want to touch the file system too much.
- (int)browser:(NSBrowser *)sender numberOfRowsInColumn:(int)column {
    ZNLogP(ERROR, @"sender=%@ column=%d", sender, column);
    NSString   *fsNodePath = nil;
    FSNodeInfo *fsNodeInfo = nil;
    
    // Get the absolute path represented by the browser selection, and create a fsnode for the path.
    // Since column represents the column being (lazily) loaded fsNodePath is the path for the last selected cell.
    fsNodePath = [self fsPathToColumn: column];
    fsNodeInfo = [FSNodeInfo nodeWithParent: nil atRelativePath: [self absolutePath:fsNodePath]];
    
    NSArray* directoryContents = [fsNodeInfo visibleSubNodes];
    [directoryContentsCache removeAllObjects];
    return [directoryContents count];
}

- (void)browser:(NSBrowser *)sender willDisplayCell:(id)cell atRow:(int)row column:(int)column {
    ZNLogP(TRACE, @"sender=%@ cell=%@ row=%d column=%d", sender, cell, row, column);
    NSString   *containingDirPath = nil;
    FSNodeInfo *containingDirNode = nil;
    FSNodeInfo *displayedCellNode = nil;
    NSArray    *directoryContents = nil;
    
    // Get the absolute path represented by the browser selection, and create a fsnode for the path.
    // Since (row,column) represents the cell being displayed, containingDirPath is the path to it's containing directory.
    containingDirPath = [self fsPathToColumn: column];
    
    // Ask the parent for a list of visible nodes so we can get at a FSNodeInfo for the cell being displayed.
    // Then give the FSNodeInfo to the cell so it can determine how to display itself.
    directoryContents = [directoryContentsCache objectForKey:containingDirPath];
    if (!directoryContents) {
        containingDirNode = [FSNodeInfo nodeWithParent: nil atRelativePath: [self absolutePath:containingDirPath]];
        directoryContents = [containingDirNode visibleSubNodes];
        [directoryContentsCache setObject:directoryContents forKey:containingDirPath];
        ZNLogP(DEBUG, @"directoryContents(%@)=%@", containingDirPath, directoryContents);
    } else {
        ZNLogP(DEBUG, @"cached directoryContents(%@)=%@", containingDirPath, directoryContents);
    }
    displayedCellNode = [directoryContents objectAtIndex: row];
    
    [cell setAttributedStringValueFromFSNodeInfo: displayedCellNode];
}

// ==========================================================
// Browser Target / Action Methods.
// ==========================================================

- (IBAction)browserSingleClick:(id)sender {
    ZNLogP(TRACE, @"sender=%@", sender);

    if ([[fsBrowser selectedCells] count]==1) {
        NSString *nodePath = [fsBrowser path];
        NSString *realPath = [[Preferences mediaDirectory] stringByAppendingPathComponent:nodePath];
        ZNLogP(DEBUG, @"nodePath=%@ realPath=%@", nodePath, realPath);
        
        BOOL isDirectory = NO;
        [[NSFileManager defaultManager] fileExistsAtPath:(NSString *)realPath isDirectory:&isDirectory];
        
        if (isDirectory) {
            [self refreshLastAndNextShows:realPath];
        }
    }
    else if ([[fsBrowser selectedCells] count]>1) {
    }
    else {
    }
}

- (IBAction)delete:(id)sender {
    ZNLogP(TRACE, @"sender=%@", sender);
    PathDictionary* pathDictionary = [PathDictionary sharedPathDictionary];
    NSString *nodePath = [self absolutePath:[fsBrowser path]];
    NSString *realPath = [pathDictionary pathForKey:nodePath];
    if (!realPath) {
        realPath = nodePath;
    }
    [[NSFileManager defaultManager] removeFileAtPath:realPath handler:nil];
    [fsBrowser reloadColumn:[fsBrowser lastColumn]];
}

- (IBAction)ignoreRecent:(id)sender {
    [recentShows ignoreRecent:sender];
}

- (IBAction)play:(id)sender {
    ZNLogP(TRACE, @"sender=%@", sender);
    
    NSWindow* window = [recentShowsTableView window];
    NSResponder* firstResponder = [window firstResponder];
    NSLog(@"firstResponder=%@", firstResponder);
    
    if (firstResponder == recentShowsTableView) {
        [recentShows recentShowAction:sender];
    } else if (firstResponder == lastShowTableView) {
        [self lastShowAction:sender];
    } else if (firstResponder == nextShowTableView) {
        [self nextShowAction:sender];
    } else {
        [self browserDoubleClick:sender];
    }
}

- (IBAction)browserDoubleClick:(id)sender {
    ZNLogP(TRACE, @"sender=%@", sender);
    // Open the file and display it information by calling the single click routine.
    PathDictionary* pathDictionary = [PathDictionary sharedPathDictionary];
    
    NSString *nodePath = [self absolutePath:[fsBrowser path]];
    NSString *realPath = [pathDictionary pathForKey:nodePath];
    if (!realPath) {
        realPath = nodePath;
    }
    
    [self browserSingleClick: sender];
    
    [[NSWorkspace sharedWorkspace] openFile: realPath];
    
    [recentShows removeObject:[pathDictionary parseEpisode:realPath]];
    [self setEpisodeIgnored:realPath save:NO];
    
    if ([nodePath compare:realPath]) {
        [self updateLastChoice:realPath save:NO];
        [self refreshLastAndNextShows:realPath];
    }
    
    [Preferences save];
}

- (NSBrowser*)browser {
    return fsBrowser;
}

@end

@implementation AppController (PrivateUtilities)

- (NSString*)fsPathToColumn:(int)column {
    ZNLogP(TRACE, @"column=%d", column);
    NSString *path = nil;
    NSString* mediaDirectory = [Preferences mediaDirectory];
    if(column==0) path = [NSString stringWithFormat:mediaDirectory];
    else path = [fsBrowser pathToColumn: column];
    return path;
}

-(BOOL) applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication
{
    ZNLogP(TRACE, @"theApplication=%@", theApplication);
    return YES;
}

- (void) applicationWillTerminate: (NSNotification *)note
{
    ZNLogP(TRACE, @"note=%@", note);
}

- (NSMutableArray*)lastShow {
    ZNLog(TRACE);
    return lastShow;
}

- (void)setLastShow:(NSMutableArray*)newArray {
    ZNLogP(TRACE, @"newArray=%@", newArray);
    [newArray retain];
    [lastShow autorelease];
    lastShow = newArray;    
}

- (NSMutableArray*)nextShow {
    ZNLog(TRACE);
    return nextShow;
}

- (void)setNextShow:(NSMutableArray*)newArray {
    ZNLogP(TRACE, @"newArray=%@", newArray);
    [newArray retain];
    [nextShow autorelease];
    nextShow = newArray;    
}

- (void)updateLastChoice:(NSString*)path save:(BOOL)save {
    NSString *parent = [path stringByDeletingLastPathComponent];
    
    while ( [parent compare:[Preferences mediaDirectory]] ) {
        [Preferences setPreferenceToDictionary:path forDictionaryKey:parent forKey:@"lastChoiceDictionary" save:NO];
        parent = [parent stringByDeletingLastPathComponent];
    }
    if (save) {
        [Preferences save];
    }
}

- (IBAction)nextShowAction:(id)sender {
    ZNLogP(TRACE, @"sender=%@", sender);
    int episodeRow = -1;
    
    if ([sender isKindOfClass:[NSTableView class]]) {
        episodeRow = [lastShowTableView clickedRow];
    } else {
        episodeRow = [lastShowTableView selectedRow];
    }
    
    if (episodeRow >= 0) {
        NSArray* array = [nextShowArrayController arrangedObjects];
        Episode* episode = [array objectAtIndex:episodeRow];
        NSString* filePath = [[episode properties] objectForKey:@"filePath"];
        //NSLog(@"episode: %@ watched: %d", [episode filePath], [self isShowWatched:filePath]);
        [[NSWorkspace sharedWorkspace] openFile:filePath ];
        
        [recentShows removeObject:episode];
        [self setEpisodeIgnored:filePath save:NO];
        
        [self updateLastChoice:filePath save:NO];
        [Preferences save];
        [self refreshLastAndNextShows:filePath];
    }
}

- (IBAction)lastShowAction:(id)sender {
    ZNLogP(TRACE, @"sender=%@", sender);
    int episodeRow = -1;
    
    if ([sender isKindOfClass:[NSTableView class]]) {
        episodeRow = [lastShowTableView clickedRow];
    } else {
        episodeRow = [lastShowTableView selectedRow];
    }
    if (episodeRow >= 0) {
        NSArray* array = [lastShowArrayController arrangedObjects];
        Episode* episode = [array objectAtIndex:episodeRow];
        NSString* filePath = [[episode properties] objectForKey:@"filePath"];
        //NSLog(@"episode: %@ watched: %d", [episode filePath], [self isShowWatched:filePath]);
        [[NSWorkspace sharedWorkspace] openFile:filePath ];
        [recentShows removeObject:episode];
        [self setEpisodeIgnored:filePath save:NO];
    }
}

@end

