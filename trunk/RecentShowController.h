/* RecentShowController */

#import <Cocoa/Cocoa.h>

@interface RecentShowController : NSObject
{
    IBOutlet NSArrayController* arrayController;
    IBOutlet NSTableView* tableView;
    NSMutableArray* recentShows;
}

- (NSMutableArray*)recentShows;
- (void)setRecentShows:(NSMutableArray*)newArray;
@end
