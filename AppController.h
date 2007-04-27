//
//  AppController.m
//
//  Copyright (c) 2001-2002, Apple. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CSRegex.h"
#import "FSNodeInfo.h"

@interface AppController : NSObject {
@private
    IBOutlet NSBrowser    *fsBrowser;
    IBOutlet NSImageView  *nodeIconWell;  // Image well showing the selected items icon.
    IBOutlet NSTextField  *nodeInspector; // Text field showing the selected items attributes.
    IBOutlet NSArrayController* recentShowsArrayController;
    IBOutlet NSTableView* recentShowsTableView;
    NSMutableArray* recentShows;
    
    NSMutableDictionary* preferences;
    FSNodeInfo* parent;
}

// Force a reload of column zero and thus, all the data.
- (IBAction)reloadData:(id)sender;

// Methods sent by the browser to us from theBrowser.
- (IBAction)browserSingleClick:(id)sender;
- (IBAction)browserDoubleClick:(id)sender;
- (IBAction)ignoreRecent:(id)sender;


- (NSMutableArray*)recentShows;
- (void)setRecentShows:(NSMutableArray*)newArray;
@end
