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

#define		PROGRAM_STRING  	"sidebarFinagler"
#define		VERSION_STRING		"0.1"
#define		AUTHOR_STRING 		"Anton Stroganov"
#define		OPT_STRING			"vhctr"

/////////////////// Prototypes //////////////////

static void ReadSidebar (NSString *plistPath);
static CFDataRef CreateBookmarkDataWithFileSystemPath(CFAllocatorRef allocator, CFURLRef url, CFURLBookmarkCreationOptions options, CFArrayRef resourcePropertiesToInclude, CFURLRef relativeToURL, CFErrorRef* error);
static void PrintVersion (void);
static void PrintHelp (void);


///////////////// globals ////////////////////

short		noCustomIconCopy = false;
short		noCopyFileCreatorTypes = false;
short		readAlias = false;

////////////////////////////////////////////
// main program function
////////////////////////////////////////////
int main(int argc, const char * argv[])
{

    @autoreleasepool {

        int			rc;
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
                case 'c':
                    noCustomIconCopy = true;
                    break;
                case 't':
                    noCopyFileCreatorTypes = true;
                    break;
                case 'r':
                    readAlias = true;
                    break;
                default: // '?'
                    rc = 1;
                    PrintHelp();
                    return EX_USAGE;
            }
        }
        
        //check if a correct number of arguments was submitted
        if (argc - optind < 1)
        {
            fprintf(stderr,"Too few arguments.\n");
            PrintHelp();
            return EX_USAGE;
        }
        
        //check if sidebar plist to read exists
        if (access(argv[optind], F_OK) == -1)
        {
            perror(argv[optind]);
            return EX_NOINPUT;
        }
        
        ReadSidebar(/*source*/ [NSString stringWithUTF8String:argv[optind]]);

        // insert code here...
        NSLog(@"Hello, World!");
        
    }
    return 0;
}

#pragma mark -

////////////////////////////////////////
// Read sidebar plist file and output the alias paths
///////////////////////////////////////
static void ReadSidebar (NSString *plistPath) {
    
    NSDictionary *sidebarDict = [NSDictionary dictionaryWithContentsOfFile:plistPath];
    
    //--get parent dictionary/Array named animals which holds the animals dictionary items
    NSDictionary *favoritesList = [[sidebarDict objectForKey:@"favorites"] objectForKey:@"VolumesList"];
    
    NSError * aliasError;

    //---enumerate through the dictionary objects inside the parentDictionary
	for(NSDictionary *favorite in favoritesList) {

//        LSSharedFileListItemRef sflItemRef = (LSSharedFileListItemRef)favorite;
//
//		CFStringRef nameRef = LSSharedFileListItemCopyDisplayName(sflItemRef);
//		CFURLRef urlRef = NULL;
//        UInt32 itemId = LSSharedFileListItemGetID(sflItemRef);
//
//		LSSharedFileListItemResolve(sflItemRef, kLSSharedFileListNoUserInteraction | kLSSharedFileListDoNotMountVolumes, &urlRef, NULL);


        NSString *nameRef = [favorite valueForKey:@"Name"];
//        NSData *aliasData = [favorite valueForKey:@"Alias"];
//        CFDataRef aliasData = (CFDataRef)[favorite valueForKey:@"Alias"];
        CFDataRef aliasData = CFURLCreateBookmarkDataFromAliasRecord(kCFAllocatorDefault, (CFDataRef)[favorite valueForKey:@"Alias"]);

/*
        NSString *testPath = @"/Users/anton/gh/sidebarFnord/bla";
        CFURLRef testUrlRef = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, (CFStringRef)testPath, kCFURLPOSIXPathStyle, true);
        CFDataRef aliasData = CreateBookmarkDataWithFileSystemPath(kCFAllocatorDefault, testUrlRef, kCFBookmarkResolutionWithoutUIMask|kCFBookmarkResolutionWithoutMountingMask, NULL, NULL, NULL);
 */

        CFURLRef aliasUrl = CFURLCreateByResolvingBookmarkData(kCFAllocatorDefault, aliasData, kCFBookmarkResolutionWithoutUIMask|kCFBookmarkResolutionWithoutMountingMask, NULL, NULL, false, NULL);

        
        /*
        CFMutableArrayRef resourcePropertiesToInclude = CFArrayCreateMutable(kCFAllocatorDefault, 0, &kCFTypeArrayCallBacks);
        CFArrayAppendValue(resourcePropertiesToInclude, kCFURLParentDirectoryURLKey);
        CFArrayAppendValue(resourcePropertiesToInclude, kCFURLIsDirectoryKey);
        CFArrayAppendValue(resourcePropertiesToInclude, kCFURLNameKey);
        CFDictionaryRef propertyDict = CFURLCreateResourcePropertiesForKeysFromBookmarkData(kCFAllocatorDefault, resourcePropertiesToInclude, aliasData);
         */
            
//        if ( urlRef == nil ) {
//            NSLog(@"Error decoding alias: %@\n", aliasError);
//            exit(EX_IOERR);
//        }
//        if(aliasUrl != nil) {
            NSLog(@"%@\t%@", (id)nameRef, (id)aliasUrl);
//        }
//        exit(EX_OK);

        //        if ([[favorite valueForKey:@"minAge"] isEqualToNumber:[NSNumber numberWithInt:3]])
//        {
//            [mutableArray addObject:[value valueForKey:@"name"]];
//        }
    }
    
//    LSSharedFileListRef sflRef = LSSharedFileListCreate(kCFAllocatorDefault, kLSSharedFileListFavoriteItems, NULL);

    ///////////////////// Try to create bookmark file for destination ///////////////////
//    aliasError = [NSError alloc];
//    aliasUrl = [NSURL fileURLWithPath:aliasPath];
//    
//    NSLog(@"Trying to read alias file: %@\n", aliasUrl);
//    
//    alias = [NSURL bookmarkDataWithContentsOfURL:aliasUrl
//                                           error:&aliasError];
//    
//    if ( alias == nil ) {
//        NSLog(@"Error reading alias file: %@\n", aliasError);
//        exit(EX_IOERR);
//    }
//    NSLog(@"Alias info: %@\n", alias);
}

static CFDataRef CreateBookmarkDataWithFileSystemPath(CFAllocatorRef allocator, CFURLRef url, CFURLBookmarkCreationOptions options, CFArrayRef resourcePropertiesToInclude, CFURLRef relativeToURL, CFErrorRef* error)
{
    CFDataRef bookmark = NULL;
    CFMutableArrayRef resourceProperties = NULL;
    CFStringRef fileSystemPath;

    // get the file system path
    fileSystemPath = CFURLCopyFileSystemPath(url, kCFURLPOSIXPathStyle);
    if ( fileSystemPath != NULL ) {
        // set kMyFileSystemPathKey as a temporary property on the url
    //    CFURLSetTemporaryResourcePropertyForKey(url, kMyFileSystemPathKey, fileSystemPath);
        
        // copy (we have to make sure it is mutable) or create the resourceProperties directionary
        if ( resourcePropertiesToInclude != NULL ) {
            resourceProperties = CFArrayCreateMutableCopy(allocator, 0, resourcePropertiesToInclude);
        }
        else {
            resourceProperties = CFArrayCreateMutable(kCFAllocatorDefault, 0, &kCFTypeArrayCallBacks);
        }
        if ( resourceProperties != NULL ) {
            // add kMyFileSystemPathKey to the properties to be stored in the bookmark
    //        CFArrayAppendValue(resourceProperties, kMyFileSystemPathKey);
            // create the bookmark data
            bookmark = CFURLCreateBookmarkData (allocator, url, options, resourceProperties, relativeToURL, error );
        }
    }
    return ( bookmark );
}

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
    printf("usage: %s [-%s] [source-file] [target-alias]\n", PROGRAM_STRING, OPT_STRING);
}