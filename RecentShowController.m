#import "RecentShowController.h"
#import "Episode.h"

@implementation RecentShowController

- (void)awakeFromNib {
    NSLog(@"hello1");
    recentShows = [[NSMutableArray alloc] init];
    NSLog(@"hello2");
    Episode* episode = [Episode initEpisode:@"/Users/deuce/Movies/TvShows/24/24.608.720p.hdtv.x264-ctu.mkv"
                                   showName:@"24" episodeName:@"8 of 24" season:6 episode:8];
    NSLog(@"hello3");
    [arrayController addObject:episode];
    NSLog(@"hello4");
    episode = [Episode initEpisode:@"/Users/deuce/Movies/TvShows/30 Rock/30.rock.113.hdtv.xvid-lol.avi"
                          showName:@"30 Rock" episodeName:@"13 of 24" season:1 episode:13];
    NSLog(@"hello5");
    [arrayController addObject:episode];
    NSLog(@"hello6");
    episode = [Episode initEpisode:@"/Users/deuce/Movies/TvShows/Bones/bones.211.hdtv.xvid-xor.avi"
                          showName:@"Bones" episodeName:@"11 of 24" season:2 episode:11];
    NSLog(@"hello7");
    [arrayController addObject:episode];
    NSLog(@"hello8");
    
    [tableView setDoubleAction:@selector(episodeAction:)];
}

- (NSMutableArray*)recentShows {
    return recentShows;
}

- (void)setRecentShows:(NSMutableArray*)newArray {
    [newArray retain];
    [recentShows autorelease];
    recentShows = newArray;
}

- (IBAction)episodeAction:(id)tableView {
    NSLog(@"DoubleClick!");
    int episodeRow = [tableView clickedRow];
    if (episodeRow >= 0) {
        NSLog(@"weeee!");
    }
}


@end
