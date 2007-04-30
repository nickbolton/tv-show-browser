/*
 *  Log.h
 *  TvShowBrowser
 *
 *  Created by Deuce on 4/29/07.
 *  Copyright 2007 __MyCompanyName__. All rights reserved.
 *
 */

#include <Carbon/Carbon.h>

#define LOG_LEVEL 3

#define ERROR 0
#define INFO 1
#define DEBUG 2
#define TRACE 3

@interface ZNLog : NSObject {}

+(void)file:(char*)sourceFile level:(int)level function:(char*)functionName lineNumber:(int)lineNumber format:(NSString*)format, ...;
+(void)file:(char*)sourceFile level:(int)level function:(char*)functionName lineNumber:(int)lineNumber;

#define ZNLogP(l,s,...) [ZNLog file:__FILE__ level:l function: (char *)__FUNCTION__ lineNumber:__LINE__ format:(s),##__VA_ARGS__]
#define ZNLog(l) [ZNLog file:__FILE__ level:l function: (char *)__FUNCTION__ lineNumber:__LINE__]

@end

