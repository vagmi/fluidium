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

#import <Cocoa/Cocoa.h>

@class FUBookmark;

extern NSString *const FUBookmarksChangedNotification;

@interface FUBookmarkController : NSObject 
#if defined(MAC_OS_X_VERSION_10_6) && (MAC_OS_X_VERSION_MIN_REQUIRED >= MAC_OS_X_VERSION_10_6)
<NSMenuDelegate>
#endif
{
    NSMutableArray *bookmarks;
}

+ (id)instance;

- (IBAction)openBookmarkInNewWindow:(id)sender;
- (IBAction)openBookmarkInNewTab:(id)sender;
- (IBAction)copyBookmark:(id)sender;
- (IBAction)deleteBookmark:(id)sender;
- (IBAction)editBookmarkTitle:(id)sender;
- (IBAction)editBookmarkContent:(id)sender;

- (void)save;

- (void)appendBookmark:(FUBookmark *)b;
- (void)insertBookmark:(FUBookmark *)b atIndex:(NSInteger)i;
- (void)removeBookmark:(FUBookmark *)b;

- (NSMenu *)contextMenuForBookmark:(FUBookmark *)b;

@property (nonatomic, retain) NSMutableArray *bookmarks;
@end
