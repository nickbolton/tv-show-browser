//
//  AppController.m
//
//  Copyright (c) 2001-2002, Apple. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CSRegex.h"
#import "FSNodeInfo.h"
#import "RecentShows.h"

@interface AppController : NSObject {
@private
    IBOutlet NSBrowser    *fsBrowser;
    IBOutlet NSArrayController* lastShowArrayController;
    IBOutlet NSArrayController* nextShowArrayController;
    IBOutlet NSTableView* recentShowsTableView;
    IBOutlet NSTableView* lastShowTableView;
    IBOutlet NSTableView* nextShowTableView;
    IBOutlet RecentShows* recentShows;
    
    //NSMutableArray* recentShows;
    NSMutableDictionary* directoryContentsDictionary;
    NSMutableArray* lastShow;
    NSMutableArray* nextShow;
    
    FSNodeInfo* parent;
    //NSTimer* recentShowsTimer;
}

// Force a reload of column zero and thus, all the data.
- (IBAction)reloadData:(id)sender;

// Methods sent by the browser to us from theBrowser.
- (IBAction)browserSingleClick:(id)sender;
- (IBAction)browserDoubleClick:(id)sender;
- (IBAction)recentShowAction:(id)sender;
- (IBAction)ignoreRecent:(id)sender;


- (NSMutableArray*)lastShow;
- (void)setLastShow:(NSMutableArray*)newArray;
- (NSMutableArray*)nextShow;
- (void)setNextShow:(NSMutableArray*)newArray;

@end
