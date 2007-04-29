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
#import "defaults.h"
#import "Preferences.h"

#define MAX_VISIBLE_COLUMNS 4

@interface AppController (PrivateUtilities)
- (NSString*)fsPathToColumn:(int)column;
- (NSDictionary*)normalFontAttributes;
- (NSDictionary*)boldFontAttributes;
- (NSAttributedString*)attributedInspectorStringForFSNode:(FSNodeInfo*)fsnode;
@end

@implementation AppController

- (double)recentShowsRefreshInterval {
    return [preferences preferenceAsDouble:TBS_RecentShowsRefreshInterval];
}

+(void)initialize 
{ 
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults]; 
    NSMutableDictionary *appDefs = [NSMutableDictionary dictionary]; 
    [appDefs setObject:[NSMutableArray arrayWithObjects:@"avi", @"mpg", @"mpeg", nil] 
                forKey:TSB_MediaExtensions]; 
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
    [appDefs setObject:@"5" 
                forKey:TBS_RecentShowsModifiedTimeMin];
    [appDefs setObject:@"4320" 
                forKey:TBS_RecentShowsModifiedTimeMax];
    [appDefs setObject:@"300.0" 
                forKey:TBS_RecentShowsRefreshInterval];
    
    [appDefs setObject:@"0.02"
                forKey:TBS_AllowablePercentNullForDownload];
    
    [defaults registerDefaults:appDefs];
} 


- (void)awakeFromNib {
    
    preferences = [Preferences sharedPreferences];
        
    recentShows = [[NSMutableArray alloc] init];
    directoryContentsDictionary = [[NSMutableDictionary alloc] init];
    
    //NSLog(@"Initial Preferences:\n%@", preferences);
    
    
    // Make the browser user our custom browser cell.
    [fsBrowser setCellClass: [FSBrowserCell class]];

    // Tell the browser to send us messages when it is clicked.
    [fsBrowser setTarget: self];
    [fsBrowser setAction: @selector(browserSingleClick:)];
    [fsBrowser setDoubleAction: @selector(browserDoubleClick:)];
    
    // Configure the number of visible columns (default max visible columns is 1).
    [fsBrowser setMaxVisibleColumns: MAX_VISIBLE_COLUMNS];
    [fsBrowser setMinColumnWidth: NSWidth([fsBrowser bounds])/(float)MAX_VISIBLE_COLUMNS];

    // Prime the browser with an initial load of data.
    [self reloadData: nil];
    
    [recentShowsTableView setDoubleAction:@selector(recentShowAction:)];
    
    //[[PathDictionary sharedPathDictionary] initEpisodeNames];
    
    double d = [self recentShowsRefreshInterval];
    recentShowsTimer = [NSTimer scheduledTimerWithTimeInterval:d target:self selector:@selector(updateRecentShows:) userInfo:nil repeats:YES];
    [recentShowsTimer fire];

}

- (BOOL)isEpisodeIgnored:(NSString*)path {
    NSMutableArray* array = [preferences arrayPreference:@"ignoredEpisodes"];
    BOOL ans = [array containsObject:path];
    return ans;
}

- (void)setEpisodeIgnored:(NSString*)path {
    [preferences addPreferenceToArray:path forKey:@"ignoredEpisodes" save:NO];
    [preferences removePreferenceFromArray:path forKey:@"completedDownloads"];
}

- (NSString*)mediaDirectory {
    return [preferences preference:TBS_MediaDirectory];
}

- (NSArray*)mediaExtensions {
    return [preferences arrayPreference:TSB_MediaExtensions];
}

- (NSString*)absolutePath:(NSString*)relativePath {
    NSString* mediaDirectory = [self mediaDirectory];
    if (![relativePath compare:mediaDirectory]) return relativePath;
    
    NSMutableString* path = [[NSMutableString alloc] init];
    [path setString:[self mediaDirectory]];
    [path appendString:relativePath];
    return path;
}

- (IBAction)reloadData:(id)sender {
    [fsBrowser loadColumnZero];
}

// ==========================================================
// Browser Delegate Methods.
// ==========================================================

// Use lazy initialization, since we don't want to touch the file system too much.
- (int)browser:(NSBrowser *)sender numberOfRowsInColumn:(int)column {
    NSString   *fsNodePath = nil;
    FSNodeInfo *fsNodeInfo = nil;
    
    // Get the absolute path represented by the browser selection, and create a fsnode for the path.
    // Since column represents the column being (lazily) loaded fsNodePath is the path for the last selected cell.
    fsNodePath = [self fsPathToColumn: column];
    fsNodeInfo = [FSNodeInfo nodeWithParent: nil atRelativePath: [self absolutePath:fsNodePath]];
    
    NSArray* directoryContents = [fsNodeInfo visibleSubNodes];
    //[directoryContentsDictionary setObject:directoryContents forKey:[fsNodeInfo absolutePath]];
    return [directoryContents count];
}

- (void)browser:(NSBrowser *)sender willDisplayCell:(id)cell atRow:(int)row column:(int)column {
    NSString   *containingDirPath = nil;
    FSNodeInfo *containingDirNode = nil;
    FSNodeInfo *displayedCellNode = nil;
    NSArray    *directoryContents = nil;
    
    // Get the absolute path represented by the browser selection, and create a fsnode for the path.
    // Since (row,column) represents the cell being displayed, containingDirPath is the path to it's containing directory.
    containingDirPath = [self fsPathToColumn: column];
    containingDirNode = [FSNodeInfo nodeWithParent: nil atRelativePath: [self absolutePath:containingDirPath]];
    
    // Ask the parent for a list of visible nodes so we can get at a FSNodeInfo for the cell being displayed.
    // Then give the FSNodeInfo to the cell so it can determine how to display itself.
    //directoryContents = [directoryContentsDictionary objectForKey:[containingDirNode absolutePath]];
    //if (!directoryContents) {
        directoryContents = [containingDirNode visibleSubNodes];
    //}
    displayedCellNode = [directoryContents objectAtIndex: row];
    
    [cell setAttributedStringValueFromFSNodeInfo: displayedCellNode];
}

// ==========================================================
// Browser Target / Action Methods.
// ==========================================================

- (IBAction)browserSingleClick:(id)sender {
    // Determine the selection and display it's icon and inspector information on the right side of the UI.
    NSImage            *inspectorImage = nil;
    NSAttributedString *attributedString = nil;
    
    if ([[fsBrowser selectedCells] count]==1) {
        NSString *nodePath = [fsBrowser path];
        FSNodeInfo *fsNode = [FSNodeInfo nodeWithParent:nil atRelativePath: [self absolutePath:nodePath]];
        if ([fsNode isDirectory]) {
            NSString* lastChoice = [preferences dictionaryPreference:@"lastChoiceDictionary" forDictionaryKey:nodePath];
            if (lastChoice) {
                [fsBrowser setAction: nil];
                [fsBrowser setDoubleAction: nil];
                
                [fsBrowser browser:fsBrowser selectCellWithString:lastChoice inColumn:([fsBrowser selectedColumn]+1)];
                [fsBrowser setAction: @selector(browserSingleClick:)];
                [fsBrowser setDoubleAction: @selector(browserDoubleClick:)];
            }
        }
        
        attributedString = [self attributedInspectorStringForFSNode: fsNode];
        inspectorImage = [fsNode iconImageOfSize: NSMakeSize(128,128)];
    }
    else if ([[fsBrowser selectedCells] count]>1) {
        attributedString = [[NSAttributedString alloc] initWithString: @"Multiple Selection"];
    }
    else {
	attributedString = [[NSAttributedString alloc] initWithString: @"No Selection"];
    }
    
    [nodeInspector setAttributedStringValue: attributedString];
    [nodeIconWell setImage: inspectorImage];
}

- (IBAction)delete:(id)sender {
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
    NSArray* selection = [recentShowsArrayController selectedObjects];
    
    int i;
    for (i=0; i<[selection count]; i++) {
        Episode* episode = [selection objectAtIndex:i];
        
        [self setEpisodeIgnored:[[episode properties] objectForKey:@"filePath"]];
        [recentShowsArrayController removeObject:episode];
    }
}

- (IBAction)browserDoubleClick:(id)sender {
    // Open the file and display it information by calling the single click routine.
    PathDictionary* pathDictionary = [PathDictionary sharedPathDictionary];
    
    NSString *nodePath = [self absolutePath:[fsBrowser path]];
    NSString *realPath = [pathDictionary pathForKey:nodePath];
    if (!realPath) {
        realPath = nodePath;
    }
    
    [self browserSingleClick: sender];
    
    [[NSWorkspace sharedWorkspace] openFile: realPath];
    
    [recentShowsArrayController removeObject:[pathDictionary parseEpisode:realPath]];
    [self setEpisodeIgnored:realPath];
    
    if ([nodePath compare:realPath]) {
        NSString *parent = [realPath stringByDeletingLastPathComponent];
        NSString* lastChoice = [nodePath lastPathComponent];
        
        while ( [parent compare:[self mediaDirectory]] ) {
            [preferences setPreferenceToDictionary:lastChoice forDictionaryKey:parent forKey:@"lastChoiceDictionary" save:NO];
            parent = [parent stringByDeletingLastPathComponent];
        }
        [preferences save];
    }
}

@end

@implementation AppController (PrivateUtilities)

- (NSString*)fsPathToColumn:(int)column {
    NSString *path = nil;
    if(column==0) path = [NSString stringWithFormat:[self mediaDirectory]];
    //if(column==0) path = [NSString stringWithFormat:@"/Users"];
    else path = [fsBrowser pathToColumn: column];
    return path;
}

- (NSDictionary*)normalFontAttributes {
    return [NSDictionary dictionaryWithObject: [NSFont systemFontOfSize:[NSFont systemFontSize]] forKey:NSFontAttributeName];
}

- (NSDictionary*)boldFontAttributes {
    return [NSDictionary dictionaryWithObject: [NSFont boldSystemFontOfSize:[NSFont systemFontSize]] forKey:NSFontAttributeName];
}

- (NSAttributedString*)attributedInspectorStringForFSNode:(FSNodeInfo*)fsnode {
    NSMutableAttributedString *attrString = [[[NSMutableAttributedString alloc] initWithString:@"Name: " attributes:[self boldFontAttributes]] autorelease];
    [attrString appendAttributedString: [[[NSAttributedString alloc] initWithString:[NSString stringWithFormat: @"%@\n", [fsnode lastPathComponent]] attributes:[self normalFontAttributes]] autorelease]];
    [attrString appendAttributedString: [[[NSAttributedString alloc] initWithString:@"Type: " attributes:[self boldFontAttributes]] autorelease]];
    [attrString appendAttributedString: [[[NSAttributedString alloc] initWithString:[NSString stringWithFormat: @"%@\n", [fsnode fsType]] attributes:[self normalFontAttributes]] autorelease]];
    
    if ([fsnode isDirectory] && [[PathDictionary sharedPathDictionary] isTvShowPath:[fsnode absolutePath]]) {
        [attrString appendAttributedString: [[[NSAttributedString alloc] initWithString:@"Last Watched: " attributes:[self boldFontAttributes]] autorelease]];
        [attrString appendAttributedString: [[[NSAttributedString alloc] initWithString:[NSString stringWithFormat: @"%@\n", [preferences dictionaryPreference:@"lastChoiceDictionary" forDictionaryKey:[fsnode absolutePath]]] attributes:[self normalFontAttributes]] autorelease]];
    }
    return attrString;
}

-(BOOL) applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication
{
    return YES;
}

- (void) applicationWillTerminate: (NSNotification *)note
{
    //NSLog(@"Saving preferences:\n%@", preferences);
    //[self writePreferences];
}

- (NSMutableArray*)recentShows {
    return recentShows;
}

- (void)setRecentShows:(NSMutableArray*)newArray {
    [newArray retain];
    [recentShows autorelease];
    recentShows = newArray;
}

- (IBAction)recentShowAction:(id)tableView {
    int episodeRow = [tableView clickedRow];
    if (episodeRow >= 0) {
        NSArray* array = [recentShowsArrayController arrangedObjects];
        Episode* episode = [array objectAtIndex:episodeRow];
        NSString* filePath = [[episode properties] objectForKey:@"filePath"];
        //NSLog(@"episode: %@ watched: %d", [episode filePath], [self isShowWatched:filePath]);
        [[NSWorkspace sharedWorkspace] openFile:filePath ];
        [recentShowsArrayController removeObject:episode];
        [self setEpisodeIgnored:filePath];
    }
}

+ (void)spawnCheckNewShowsThread {
    [NSThread detachNewThreadSelector:@selector(CheckNewShows:) toTarget:[AppController class] withObject:nil];
}

- (int)recentShowsModifiedTimeMin {
    NSString* minStr = [preferences preference:TBS_RecentShowsModifiedTimeMin];
    if (!minStr) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        minStr = [defaults objectForKey:TBS_RecentShowsModifiedTimeMin];
        [preferences setPreference:minStr forKey:TBS_RecentShowsModifiedTimeMin];
    }
    return [minStr intValue];
}

- (int)recentShowsModifiedTimeMax {
    NSString* maxStr = [preferences preference:TBS_RecentShowsModifiedTimeMax];
    if (!maxStr) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        maxStr = [defaults objectForKey:TBS_RecentShowsModifiedTimeMax];
        [preferences setPreference:maxStr forKey:TBS_RecentShowsModifiedTimeMax];
    }
    return [maxStr intValue];
}

- (void)updateRecentShows:(NSTimer*)theTimer {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    NSLog(@"Thread, yo!");
    NSArray* mediaExtensions = [self mediaExtensions];
    NSArray* timeArgs = [NSArray arrayWithObjects:[[PathDictionary sharedPathDictionary] tvShowPath], @"-type", @"f", @"-mmin", [NSString stringWithFormat:@"+%d", [self recentShowsModifiedTimeMin]], @"-mmin", [NSString stringWithFormat:@"-%d", [self recentShowsModifiedTimeMax]], nil];
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
    
    NSLog(@"args: %@", argsStr);
    [task launch];
    
    while ((inData = [readHandle availableData]) && [inData length]) {
        size = [inData length];
        NSLog(@"data size: %d", size);
        char buf[size+1];
        buf[size] = '\0';
        [inData getBytes:buf];
        [result appendFormat:@"%s", buf];
    }
    //NSLog(@"%@", result);
    
    if ([recentShows count] > 0) {
        [recentShowsArrayController removeObjects:recentShows];
    }
    NSArray* paths = [result componentsSeparatedByString:@"\n"];
    
    id obj = [recentShowsArrayController content];
    
    for (i=0; i<[paths count]; i++) {
        NSString* path = [paths objectAtIndex:i];
        NSLog(@"path: #%@#", path);
        if (path && [path compare:@""] && ![self isEpisodeIgnored:path] && [self isDownloadComplete:path] ) {
            Episode* episode = [[PathDictionary sharedPathDictionary] parseEpisode:path];
            if (episode) {
            NSLog(@"episode:\n%@", [episode properties]);
            [recentShowsArrayController addObject:episode];
            }
        }
        
    }
    [pool release];
}

- (double)allowableIncomplete {
    return [preferences preferenceAsDouble:TBS_AllowablePercentNullForDownload];
}

- (BOOL)isDownloadComplete:(NSString*)filePath {
    if ([preferences arrayContains:filePath forKey:@"completedDownloads"]) return YES;
    
    NSData* data = [[NSFileManager defaultManager] contentsAtPath:filePath];
    const char* buf = [data bytes];
    long zeroByteCount = 0;
    
    int i;
    for (i=0; i<[data length]; i++) {
        if (*(buf+i) == '\0') zeroByteCount++;
    }
    
    double percentIncomplete = (double)zeroByteCount/(double)[data length];
    double allowableIncomplete = [self allowableIncomplete];
    if (percentIncomplete < allowableIncomplete) {
        [preferences addPreferenceToArray:filePath forKey:@"completedDownloads"];
        return YES;
    }
    return NO;
}




@end

