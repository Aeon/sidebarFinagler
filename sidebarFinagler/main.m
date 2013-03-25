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

extern CFStringRef kLSSharedFileListSpecialItemIdentifier;
extern CFStringRef kLSSharedFileListItemTargetName;
extern CFStringRef kLSSharedFileListItemManaged;
#define kLSSharedFileListItemTemplateSystemSelector (CFStringRef)((char *)kLSSharedFileListItemTargetName + (3 * 0x40))
#define kLSSharedFileListItemClass (CFStringRef)((char *)kLSSharedFileListItemBeforeFirst + (3 * 0x40))

/////////////////// Prototypes //////////////////

static void ReadSidebar ();
static void WriteSidebar ();
static void ReadSidebarFile (NSString *plistPath);
static void WriteSidebarFile (NSString *plistPath);
static CFDataRef CreateBookmarkDataWithFileSystemPath(CFAllocatorRef allocator, CFURLRef url, CFURLBookmarkCreationOptions options, CFArrayRef resourcePropertiesToInclude, CFURLRef relativeToURL, CFErrorRef* error);
static void PrintVersion (void);
static void PrintHelp (void);


///////////////// globals ////////////////////

short		noCustomIconCopy = false;
short		noCopyFileCreatorTypes = false;
short		writeAlias = false;

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
                case 'w':
                    writeAlias = true;
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
        
        if(writeAlias) {
            WriteSidebar();
//            WriteSidebar(/*destination*/ [NSString stringWithUTF8String:argv[optind]]);
        } else {
            ReadSidebar();
//            ReadSidebar(/*source*/ [NSString stringWithUTF8String:argv[optind]]);
        }
    }
    return 0;
}

#pragma mark -

static void ReadSidebar () {
//    LSSharedFileListRef sflRef = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
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

//    LSSharedFileListRef sflRef = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
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
// Read sidebar plist file and output the alias paths
///////////////////////////////////////
static void ReadSidebarFile (NSString *plistPath) {
    
    NSDictionary *sidebarDict = [NSDictionary dictionaryWithContentsOfFile:plistPath];
    
    //--get parent dictionary/Array which holds the favorites
    NSArray *favoritesList = [[sidebarDict objectForKey:@"favorites"] objectForKey:@"VolumesList"];

    //---enumerate through the dictionary objects inside the parentDictionary
	for(NSDictionary *favorite in favoritesList) {

        NSString *nameRef = [favorite valueForKey:@"Name"];

        // use CFURL stuff instead of BDAlias
        // because this lets us resolve the alias without triggering
        // user interaction/mount failure popups due to being able to use
        // kCFBookmarkResolutionWithoutUIMask | kCFBookmarkResolutionWithoutMountingMask
        CFDataRef aliasData = CFURLCreateBookmarkDataFromAliasRecord(kCFAllocatorDefault, (CFDataRef)[favorite valueForKey:@"Alias"]);
        CFURLRef aliasUrl = CFURLCreateByResolvingBookmarkData(kCFAllocatorDefault, aliasData, kCFBookmarkResolutionWithoutUIMask|kCFBookmarkResolutionWithoutMountingMask, NULL, NULL, false, NULL);
       
        if(aliasUrl != nil) {
            NSString *aliasPath = [(NSString*)CFURLCopyFileSystemPath(aliasUrl, kCFURLPOSIXPathStyle) autorelease];
//            if([[NSFileManager defaultManager] fileExistsAtPath:aliasPath]) {
            
            NSLog(@"%@\n", [[favorite objectForKey:@"CustomItemProperties"] valueForKey:@"com.apple.LSSharedFileList.TemplateSystemSelector"]);
            
                printf("%s\t%s\n", [nameRef UTF8String], [aliasPath UTF8String]);
//                [updatedFavorites addObject:favorite];
//            }
//
//            NSLog(@"%@ -> %@", (id)nameRef, (id)aliasPath);
        }
        /*
        BDAlias *bdAliasData = [BDAlias aliasWithData:[favorite valueForKey:@"Alias"]];

        NSString *fullPath = [bdAliasData fullPath];
        if(fullPath != nil) {            
            NSLog(@"bdalias: %@ -> %@", (id)nameRef, (id)[bdAliasData fullPath]);
        }
         */
        if(aliasUrl) CFRelease(aliasUrl);
        CFRelease(aliasData);
    }
}

#pragma mark -

////////////////////////////////////////
// Read list of names/destinations from stdin and add them to specified plist
///////////////////////////////////////
static void WriteSidebarFile (NSString *plistPath) {

    NSError *backupError;

    // back up the destination plist just in case
    NSString *backupPath = [NSString stringWithFormat:@"%@.bak", plistPath];

    [[NSFileManager defaultManager] copyItemAtPath:plistPath toPath:backupPath error:&backupError];
    
    if(backupError != nil) {
        NSLog(@"Error backing up plist: %@\n", backupError);
    }
    
    NSFileHandle *input = [NSFileHandle fileHandleWithStandardInput];
    NSData *inputData = [NSData dataWithData:[input readDataToEndOfFile]];
    NSString *inputString = [[[NSString alloc] initWithData:inputData encoding:NSUTF8StringEncoding] autorelease];
    NSArray *newFavorites = [inputString componentsSeparatedByString:@"\n"];

	for(id line in newFavorites) {
        if([line length] > 0) {
            NSArray *favoriteData = [line componentsSeparatedByString:@"\t"];
            NSString *nameRef = [favoriteData objectAtIndex:0];
            NSString *pathRef = [favoriteData objectAtIndex:1];

            BDAlias *newAlias = [BDAlias aliasWithPath:pathRef];
            
            NSLog(@"Adding link named %@ at path %@\n", nameRef, pathRef);
        }
    }

    return;

    NSDictionary *sidebarDict = [NSDictionary dictionaryWithContentsOfFile:plistPath];
    
    //--get parent dictionary/Array which holds the favorites
    NSArray *favoritesList = [[sidebarDict objectForKey:@"favorites"] objectForKey:@"VolumesList"];
    NSMutableArray *updatedFavorites;
    
//    LSSharedFileListInsertItemURL
    
    //---enumerate through the dictionary objects inside the parentDictionary
	for(NSDictionary *favorite in favoritesList) {
        
        NSString *nameRef = [favorite valueForKey:@"Name"];
        
        // use CFURL stuff instead of BDAlias
        // because this lets us resolve the alias without triggering
        // user interaction/mount failure popups due to being able to use
        // kCFBookmarkResolutionWithoutUIMask | kCFBookmarkResolutionWithoutMountingMask
        CFDataRef aliasData = CFURLCreateBookmarkDataFromAliasRecord(kCFAllocatorDefault, (CFDataRef)[favorite valueForKey:@"Alias"]);
        CFURLRef aliasUrl = CFURLCreateByResolvingBookmarkData(kCFAllocatorDefault, aliasData, kCFBookmarkResolutionWithoutUIMask|kCFBookmarkResolutionWithoutMountingMask, NULL, NULL, false, NULL);
        
        if(aliasUrl != nil) {
            NSString *aliasPath = (NSString*)CFURLCopyFileSystemPath(aliasUrl, kCFURLPOSIXPathStyle);
            //            if([[NSFileManager defaultManager] fileExistsAtPath:aliasPath]) {
            printf("%s\t%s\n", [nameRef UTF8String], [aliasPath UTF8String]);
            //                [updatedFavorites addObject:favorite];
            //            }
            //
            //            NSLog(@"%@ -> %@", (id)nameRef, (id)aliasPath);
        }
        /*
         BDAlias *bdAliasData = [BDAlias aliasWithData:[favorite valueForKey:@"Alias"]];
         
         NSString *fullPath = [bdAliasData fullPath];
         if(fullPath != nil) {
         NSLog(@"bdalias: %@ -> %@", (id)nameRef, (id)[bdAliasData fullPath]);
         }
         */
    }
}

#pragma mark -

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