//  Copyright 2009 Todd Ditchendorf
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.

#import "FUBookmarkController.h"
#import "FUBookmark.h"
#import "FUBookmarkWindowController.h"
#import "FUApplication.h"
#import "FUDocumentController.h"
#import "FUUserDefaults.h"
#import "FUWindowController.h" // needed for bookmarkClicked: action
#import "FUUtils.h"
#import "WebKitPrivate.h"
#import "WebIconDatabase+FUAdditions.h"

#define NUM_STATIC_ITEMS 3

NSString *const FUBookmarksChangedNotification = @"FUBookmarksChangedNotification";

@interface FUBookmarkController ()
- (void)setUpBookmarkMenu;
- (void)setUpBookmarks;
- (void)postBookmarksChangedNotification;
@end

@implementation FUBookmarkController

+ (id)instance {    
    static FUBookmarkController *instance = nil;
    @synchronized (self) {
        if (!instance) {
            instance = [[FUBookmarkController alloc] init];
        }
    }
    return instance;
}


- (id)init {
    if (self = [super init]) {
        [self setUpBookmarkMenu];
        [self setUpBookmarks];
    }
    return self;
}


- (void)dealloc {
    self.bookmarks = nil;
    [super dealloc];
}


#pragma mark -
#pragma mark Action

- (IBAction)openBookmarkInNewWindow:(id)sender {
    FUBookmark *b = [sender representedObject];
    NSURLRequest *req = [NSURLRequest requestWithURL:[NSURL URLWithString:b.content]];
    [[FUDocumentController instance] loadRequest:req destinationType:FUDestinationTypeWindow];
}


- (IBAction)openBookmarkInNewTab:(id)sender {
    FUBookmark *b = [sender representedObject];
    NSURLRequest *req = [NSURLRequest requestWithURL:[NSURL URLWithString:b.content]];
    [[FUDocumentController instance] loadRequest:req destinationType:FUDestinationTypeTab];
}


- (IBAction)copyBookmark:(id)sender {
    FUBookmark *b = [sender representedObject];
    FUWriteURLStringAndTitleToPasteboard(b.content, b.title, nil);
}


- (IBAction)deleteBookmark:(id)sender {
    FUBookmark *b = [sender representedObject];
    [self removeBookmark:b];
}


#pragma mark -
#pragma mark Public

- (void)save {
    if (![NSKeyedArchiver archiveRootObject:bookmarks toFile:[[FUApplication instance] bookmarksFilePath]]) {
        NSLog(@"Fluidium.app could not write bookmarks to disk");
    }
}


- (void)appendBookmark:(FUBookmark *)b {
    [bookmarks addObject:b];
    [self performSelector:@selector(postBookmarksChangedNotification) withObject:nil afterDelay:0];
}


- (void)insertBookmark:(FUBookmark *)b atIndex:(NSInteger)i {
    [bookmarks insertObject:b atIndex:i];
    [self performSelector:@selector(postBookmarksChangedNotification) withObject:nil afterDelay:0];
}


- (void)removeBookmark:(FUBookmark *)b {
    [bookmarks removeObject:b];
    [self performSelector:@selector(postBookmarksChangedNotification) withObject:nil afterDelay:0];
}


- (NSMenu *)contextMenuForBookmark:(FUBookmark *)b {
    NSMenu *menu = [[[NSMenu alloc] initWithTitle:@""] autorelease];
    
    NSMenuItem *item = nil;
    item = [[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Open", @"")
                                       action:@selector(bookmarkClicked:) 
                                keyEquivalent:@""] autorelease];
    [item setTarget:nil];
    [item setRepresentedObject:b];
    [item setOnStateImage:nil];
    [menu addItem:item];
    
    item = [[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Open in New Window", @"")
                                       action:@selector(openBookmarkInNewWindow:) 
                                keyEquivalent:@""] autorelease];
    [item setTarget:self];
    [item setRepresentedObject:b];
    [item setOnStateImage:nil];
    [menu addItem:item];
    
    if ([[FUUserDefaults instance] tabbedBrowsingEnabled]) {
        item = [[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Open in New Tab", @"")
                                           action:@selector(openBookmarkInNewTab:) 
                                    keyEquivalent:@""] autorelease];
        [item setTarget:self];
        [item setRepresentedObject:b];
        [item setOnStateImage:nil];
        [menu addItem:item];
    }
    
    [menu addItem:[NSMenuItem separatorItem]];
    
    item = [[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Copy", @"")
                                       action:@selector(copyBookmark:) 
                                keyEquivalent:@""] autorelease];
    [item setTarget:self];
    [item setRepresentedObject:b];
    [item setOnStateImage:nil];
    [menu addItem:item];

    item = [[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Delete", @"")
                                       action:@selector(deleteBookmark:) 
                                keyEquivalent:@""] autorelease];
    [item setTarget:self];
    [item setRepresentedObject:b];
    [item setOnStateImage:nil];
    [menu addItem:item];
    
    return menu;
}


#pragma mark -
#pragma mark Private

- (void)setUpBookmarkMenu {
    NSMenu *bookmarkMenu = [[[NSApp mainMenu] itemWithTitle:NSLocalizedString(@"Bookmarks", @"")] submenu];
    [bookmarkMenu setDelegate:self];
}


- (void)setUpBookmarks {
    NSString *path = [[FUApplication instance] bookmarksFilePath];
    
    BOOL exists, isDir;
    exists = [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir];
    
    if (exists) {
        @try {
            self.bookmarks = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
        } @catch (NSException *e) {
            NSLog(@"Fluidium.app encountered error reading bookmarks on disk!\n%@", [e reason]);
        }
    }
    
    if (!bookmarks) {
        self.bookmarks = [NSMutableArray array];
    }
}


- (void)postBookmarksChangedNotification {
    [self save];
    [[NSNotificationCenter defaultCenter] postNotificationName:FUBookmarksChangedNotification object:nil];
}


#pragma mark -
#pragma mark NSMenuDelegate

- (NSInteger)numberOfItemsInMenu:(NSMenu*)menu {
    return NUM_STATIC_ITEMS + [bookmarks count];
}


- (BOOL)menu:(NSMenu *)menu updateItem:(NSMenuItem *)item atIndex:(NSInteger)index shouldCancel:(BOOL)shouldCancel {
    if (index < NUM_STATIC_ITEMS) {
        return YES;
    }
    
    index -= NUM_STATIC_ITEMS;
    
    FUBookmark *bookmark = [bookmarks objectAtIndex:index];
    
    [item setAction:@selector(bookmarkClicked:)];
    [item setTitle:bookmark.title];
    
    [item setImage:[[WebIconDatabase sharedIconDatabase] faviconForURL:bookmark.content]];
    [item setRepresentedObject:bookmark];
    
    return YES;
}

@synthesize bookmarks;
@end
