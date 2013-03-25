//
//  main.m
//  sidebarFinagler
//
//  Created by Anton Stroganov on 3/23/13.
//  Copyright (c) 2013 Aeontech. All rights reserved.
//

#include <stdlib.h>
#include <stdio.h>
#include <sysexits.h>

#import <Foundation/Foundation.h>
#import <CoreServices/CoreServices.h>
#import <CoreFoundation/CoreFoundation.h>
#import <Security/Authorization.h>

#define		PROGRAM_STRING  	"sidebarFinagler"
#define		VERSION_STRING		"0.1"
#define		AUTHOR_STRING 		"Anton Stroganov"
#define		OPT_STRING			"vhw"

/////////////////// Prototypes //////////////////

static void ReadSidebar ();
static void WriteSidebar ();
static void PrintVersion (void);
static void PrintHelp (void);


///////////////// globals ////////////////////

short		writeMode = false;

////////////////////////////////////////////
// main program function
////////////////////////////////////////////
int main(int argc, const char * argv[])
{

    @autoreleasepool {

        int			optch;
        static char	optstring[] = OPT_STRING;
        
        while ( (optch = getopt(argc, (char * const *)argv, optstring)) != -1)
        {
            switch(optch)
            {
                case 'v':
                    PrintVersion();
                    return EX_OK;
                    break;
                case 'h':
                    PrintHelp();
                    return EX_OK;
                    break;
                case 'w':
                    writeMode = true;
                    break;
                default: // '?'
                    PrintHelp();
                    return EX_USAGE;
            }
        }
        
        if(writeMode) {
            WriteSidebar();
        } else {
            ReadSidebar();
        }
    }
    return 0;
}

#pragma mark -

static void ReadSidebar () {
    LSSharedFileListRef sflRef = LSSharedFileListCreate(NULL, kLSSharedFileListFavoriteItems, NULL);

    UInt32 seed;

    if(!sflRef) {
        NSLog(@"No list!");
        exit(EX_IOERR);
    }

    NSArray *list = [(NSArray *)LSSharedFileListCopySnapshot(sflRef, &seed) autorelease];

    for(NSObject *object in list) {
        LSSharedFileListItemRef sflItemRef = (LSSharedFileListItemRef)object;

        CFStringRef nameRef = LSSharedFileListItemCopyDisplayName(sflItemRef);

        CFURLRef urlRef = NULL;
        LSSharedFileListItemResolve(sflItemRef, kLSSharedFileListNoUserInteraction | kLSSharedFileListDoNotMountVolumes, &urlRef, NULL);
    
        NSString *aliasPath = [(NSString*)CFURLCopyFileSystemPath(urlRef, kCFURLPOSIXPathStyle) autorelease];

        UInt32 itemId = LSSharedFileListItemGetID(sflItemRef);
        
        printf("%i\t%s\t%s\n", itemId, [(NSString*)nameRef UTF8String], [aliasPath UTF8String]);
        
        CFRelease(urlRef);
        CFRelease(nameRef);
    }
}

#pragma mark -

static void WriteSidebar () {

    LSSharedFileListRef sflRef = LSSharedFileListCreate(NULL, kLSSharedFileListFavoriteItems, NULL);

    // set up authorization so we can modify the shared list correctly
    AuthorizationRef auth = NULL;
    AuthorizationCreate(NULL, kAuthorizationEmptyEnvironment, kAuthorizationFlagDefaults, &auth);
    LSSharedFileListSetAuthorization(sflRef, auth);

    UInt32 seed;
    
    if(!sflRef) {
        NSLog(@"No list!");
        exit(EX_IOERR);
    }
    
    NSFileHandle *input = [NSFileHandle fileHandleWithStandardInput];
    NSData *inputData = [NSData dataWithData:[input readDataToEndOfFile]];
    NSString *inputString = [[[NSString alloc] initWithData:inputData encoding:NSUTF8StringEncoding] autorelease];

    NSMutableArray *newFavorites = [[[NSMutableArray alloc] init] autorelease];

    NSArray *lines = [inputString componentsSeparatedByString:@"\n"];

    // parse stdin into a data structure
	for(id line in lines) {
        if([line length] > 0) {
            NSArray *favoriteData = [line componentsSeparatedByString:@"\t"];
            
            [newFavorites addObject:@{
                @"itemId": [favoriteData objectAtIndex:0],
                @"name": [favoriteData objectAtIndex:1],
                @"path": [(NSString*)[favoriteData objectAtIndex:2] stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]]
             }];
        }
    }

    NSArray *list = [(NSArray *)LSSharedFileListCopySnapshot(sflRef, &seed) autorelease];
    
    LSSharedFileListItemRef sflItemBeforeRef = (LSSharedFileListItemRef)kLSSharedFileListItemBeforeFirst;
    
    for(NSObject *object in list) {
        LSSharedFileListItemRef sflItemRef = (LSSharedFileListItemRef)object;
        CFStringRef nameRef = LSSharedFileListItemCopyDisplayName(sflItemRef);        
        UInt32 itemId = LSSharedFileListItemGetID(sflItemRef);
        
        for (NSDictionary *newItem in newFavorites) {
            if(itemId == [[newItem objectForKey:@"itemId"] intValue]) {
                NSString * newName = [newItem objectForKey:@"name"];
                NSURL * newPath = [NSURL fileURLWithPath:[newItem objectForKey:@"path"]];
                
                NSLog(@"Updating link id %i named %@ with new name %@ and new path %@\n", itemId, nameRef, newName, [newItem objectForKey:@"path"]);

                // insert updated item
                LSSharedFileListItemRef addedItem = LSSharedFileListInsertItemURL(sflRef,
                                                                                  sflItemBeforeRef,
                                                                                  (CFStringRef)newName,
                                                                                  NULL,
                                                                                  (CFURLRef)newPath,
                                                                                  NULL,
                                                                                  NULL
                                                                              );
                
                
                if(addedItem != nil) {
                    NSLog(@"Added new item %@\n", addedItem);
                    CFRelease(addedItem);

                    // delete old item
                    LSSharedFileListItemRemove(sflRef, sflItemRef);
                } else {
                    NSLog(@"Failed to add new item for %@\n", newPath);
                }
            }
        }

        sflItemBeforeRef = sflItemRef;
        CFRelease(nameRef);
    }
	CFRelease(sflRef);
}

#pragma mark -

////////////////////////////////////////
// Print version and author to stdout
///////////////////////////////////////

static void PrintVersion (void)
{
    printf("%s version %s by %s\n", PROGRAM_STRING, VERSION_STRING, AUTHOR_STRING);
}

////////////////////////////////////////
// Print help string to stdout
///////////////////////////////////////

static void PrintHelp (void)
{
    printf("usage: %s [OPTION]\n\n", PROGRAM_STRING);
    printf("               output the current sidebar list suitable for editing\n");
    printf("  -w           read new list of sidebar favorites from STDIN to replace existing\n");
    printf("  -v           version\n");
    printf("  -h           this help\n");
}