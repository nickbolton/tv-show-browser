//
//  RecentShows.h
//  TvShowBrowser
//
//  Created by Deuce on 5/1/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import	<Carbon/Carbon.h>
#import <Cocoa/Cocoa.h>
#import "Episode.h"
#import <sys/param.h>

@interface RecentShows : NSObject {
    IBOutlet NSArrayController* recentShowsArrayController;
    IBOutlet NSTableView* recentShowsTableView;
    IBOutlet id appController;
    NSMutableArray* recentShows;
    NSTimer* recentShowsTimer;
}

- (void)updateRecentShows:(NSTimer*)theTimer;
- (IBAction)ignoreRecent:(id)sender;
- (void)removeObject:(Episode*)episode;
- (IBAction)refreshRecentShows:(id)sender;

@end
