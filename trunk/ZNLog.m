//
//  Log.m
//  TvShowBrowser
//
//  Created by Deuce on 4/29/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "ZNLog.h"
#import "Preferences.h"

@implementation ZNLog

+ (int)logLevel {
    return [Preferences logLevel];
}

+ (void)file:(char*)sourceFile level:(int)level function:(char*)functionName lineNumber:(int)lineNumber format:(NSString*)format, ...
{
    if ([ZNLog logLevel] < level) return;
    
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    va_list ap;
    NSString *print, *file, *function;
    
    va_start(ap,format);
    file = [[NSString alloc] initWithBytes: sourceFile length: strlen(sourceFile) encoding: NSUTF8StringEncoding];
    
    function = [NSString stringWithCString: functionName];
    print = [[NSString alloc] initWithFormat: format arguments: ap];
    va_end(ap);
    NSLog(@"%@:%d %@; %@", [file lastPathComponent], lineNumber, function, print);
    [print release];
    [file release];
    [pool release];
}

+ (void)file:(char*)sourceFile level:(int)level function:(char*)functionName lineNumber:(int)lineNumber {
    if ([ZNLog logLevel] < level) return;
    
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    NSString *file, *function;
    
    file = [[NSString alloc] initWithBytes: sourceFile length: strlen(sourceFile) encoding: NSUTF8StringEncoding];
    
    function = [NSString stringWithCString: functionName];
    NSLog(@"%@:%d %@", [file lastPathComponent], lineNumber, function);
    [file release];
    [pool release];
    
}

@end