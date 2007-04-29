/*
	FSNodeInfo.m
	Copyright (c) 2001-2004, Apple Computer, Inc., all rights reserved.
	Author: Chuck Pisula

	Milestones:
	Initially created 3/1/01

	Encapsulates information about a file or directory.
*/

/*
 IMPORTANT:  This Apple software is supplied to you by Apple Computer, Inc. ("Apple") in
 consideration of your agreement to the following terms, and your use, installation, 
 modification or redistribution of this Apple software constitutes acceptance of these 
 terms.  If you do not agree with these terms, please do not use, install, modify or 
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and subject to these 
 terms, Apple grants you a personal, non-exclusive license, under Apple�s copyrights in 
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

#import "FSNodeInfo.h"
#import "PathDictionary.h"

@implementation FSNodeInfo 

+ (FSNodeInfo*)nodeWithParent:(FSNodeInfo*)parent atRelativePath:(NSString *)path {
    return [[[FSNodeInfo alloc] initWithParent:parent atRelativePath:path] autorelease];
}

- (id)initWithParent:(FSNodeInfo*)parent atRelativePath:(NSString*)path {    
    self = [super init];
    if (self==nil) return nil;
    
    parentNode = parent;
    relativePath = [path retain];
    
    NSString* tvShowPath = [[PathDictionary sharedPathDictionary] tvShowPath];
    if ([[self absolutePath] rangeOfString:tvShowPath].location != NSNotFound) {
        int numShowDirectoryComponents = [[tvShowPath pathComponents] count];
        NSArray* components = [[self absolutePath] pathComponents];
        if ([components count] > numShowDirectoryComponents) {
            showName = [components objectAtIndex:numShowDirectoryComponents];
        }
    }
    return self;
}

- (void)dealloc {
    // parentNode is not released since we never retained it.
    [relativePath release];
    relativePath = nil;
    parentNode = nil;
    [super dealloc];
}

- (NSArray *)subNodes {
    NSString       *subNodePath = nil;
    NSEnumerator   *subNodePaths = [[[NSFileManager defaultManager] directoryContentsAtPath: [self absolutePath]] objectEnumerator];
    NSMutableArray *subNodes = [NSMutableArray array];
    
    while ((subNodePath=[subNodePaths nextObject])) {
        FSNodeInfo *node = [FSNodeInfo nodeWithParent:self atRelativePath: subNodePath];
        [subNodes addObject: node];
    }
    return subNodes;
}

int tvShowSorter(id n1, id n2, void *context) {
    FSNodeInfo* node1 = n1;
    FSNodeInfo* node2 = n2;
    PathDictionary* pathDictionary = [PathDictionary sharedPathDictionary];
    
    Episode* e1 = [pathDictionary parseEpisode:[n1 absolutePath]];
    Episode* e2 = [pathDictionary parseEpisode:[n2 absolutePath]];
    
    if ([e1 season] < [e2 season]) {
        return NSOrderedAscending;
    } else if ([e1 season] > [e2 season]) {
        return NSOrderedDescending;
    } else if ([e1 episode] < [e2 episode]) {
        return NSOrderedAscending;
    } else if ([e1 episode] > [e2 episode]) {
        return NSOrderedDescending;
    } else {
        return NSOrderedSame;
    }
}

- (NSArray *)visibleSubNodes {
    FSNodeInfo     *subNode = nil;
    NSEnumerator   *allSubNodes = [[self subNodes] objectEnumerator];
    NSMutableArray *visibleSubNodes = [NSMutableArray array];
    
    int fileCount = 0;
    while ((subNode=[allSubNodes nextObject])) {
        if ([subNode isVisible]) {
            [visibleSubNodes addObject: subNode];
            if (![subNode isDirectory]) {
                fileCount++;
            }
        }
    }
    if (((fileCount*100)/[visibleSubNodes count]) > 90 && [[PathDictionary sharedPathDictionary] isTvShowPath:[self absolutePath]]) {
        NSLog(@"sorting tv shows: %@", [self absolutePath]);
        return [visibleSubNodes sortedArrayUsingFunction:tvShowSorter context:NULL];
    }
    NSLog(@"NOT SORTING: %@", [self absolutePath]);
    return visibleSubNodes;
}

- (BOOL)isLink {
    NSDictionary *fileAttributes = [[NSFileManager defaultManager] fileAttributesAtPath:[self absolutePath] traverseLink:NO];
    return [[fileAttributes objectForKey:NSFileType] isEqualToString:NSFileTypeSymbolicLink];
}

- (BOOL)isDirectory {
    BOOL isDir = NO;
    BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:[self absolutePath] isDirectory:&isDir];
    return (exists && isDir);
}

- (BOOL)isReadable {
    return [[NSFileManager defaultManager] isReadableFileAtPath: [self absolutePath]];
}

- (BOOL)isVisible {
    // Make this as sophisticated for example to hide more files you don't think the user should see!
    NSString *lastPathComponent = [self lastPathComponent];
    return ([lastPathComponent length] ? ([lastPathComponent characterAtIndex:0]!='.') : NO);
}

- (NSString*)fsType {
    if ([self isDirectory]) return @"Directory";
    else return @"Non-Directory";
}

- (NSString*)lastPathComponent {
    return [relativePath lastPathComponent];
}

- (NSString*)absolutePath {
    NSString *result = relativePath;
    if(parentNode!=nil) {
        NSString *parentAbsPath = [parentNode absolutePath];
        if ([parentAbsPath isEqualToString: @"/"]) parentAbsPath = @"";
        result = [NSString stringWithFormat: @"%@/%@", parentAbsPath, relativePath];
    }
    return result;
}

- (NSString*)showName {
    return showName;
}

- (NSImage*)iconImageOfSize:(NSSize)size {
    NSString *path = [self absolutePath];
    NSImage *nodeImage = nil;
    
    nodeImage = [[NSWorkspace sharedWorkspace] iconForFile:path];
    if (!nodeImage) {
        // No icon for actual file, try the extension.
        nodeImage = [[NSWorkspace sharedWorkspace] iconForFileType:[path pathExtension]];
    }
    [nodeImage setSize: size];
    
    if ([self isLink]) {
        NSImage *arrowImage = [NSImage imageNamed: @"FSIconImage-LinkArrow"];
        NSImage *nodeImageWithArrow = [[[NSImage alloc] initWithSize: size] autorelease];
        
	[arrowImage setScalesWhenResized: YES];
	[arrowImage setSize: size];
	
        [nodeImageWithArrow lockFocus];
	[nodeImage compositeToPoint:NSZeroPoint operation:NSCompositeCopy];
        [arrowImage compositeToPoint:NSZeroPoint operation:NSCompositeSourceOver];
        [nodeImageWithArrow unlockFocus];
	
	nodeImage = nodeImageWithArrow;
    }
    
    if (nodeImage==nil) {
        nodeImage = [NSImage imageNamed:@"FSIconImage-Default"];
    }
    
    return nodeImage;
}

@end
