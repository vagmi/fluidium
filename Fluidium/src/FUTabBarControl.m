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

#import "FUTabBarControl.h"
#import "FUDocumentController.h"
#import "FUWindowController.h"
#import "FUTabController.h"

@interface PSMTabBarControl ()
- (id)cellForPoint:(NSPoint)point cellFrame:(NSRectPointer)outFrame;
- (void)closeTabClick:(id)sender;
@end

@interface FUWindowController ()
- (void)tabControllerWasRemovedFromTabBar:(FUTabController *)tc;
- (void)tabControllerWasDroppedOnTabBar:(FUTabController *)tc;
@end

@interface FUTabBarControl ()
- (void)displayContextMenu:(NSTimer *)timer;
- (NSMenu *)contextMenu;
- (FUWindowController *)windowController;
@end

@implementation FUTabBarControl

- (void)dealloc {
    [super dealloc];
}


- (NSString *)description {
    return [NSString stringWithFormat:@"<FUTabBarControl %p (%d tabs) (%@)>", self, [[self representedTabViewItems] count], [[[self tabView] selectedTabViewItem] label]];
}


#pragma mark -
#pragma mark Actions

- (IBAction)reloadTab:(id)sender {
    FUTabController *tc = [[self windowController] tabControllerAtIndex:rightClickCellIndex];
    [tc reload:sender];
}


- (IBAction)moveTabToNewWindow:(id)sender {
    FUWindowController *oldwc = [self windowController];
    FUTabController *tc = [oldwc tabControllerAtIndex:rightClickCellIndex];
    
    NSError *err = nil;
    FUWindowController *newwc = [[[FUDocumentController instance] openUntitledDocumentAndDisplay:YES error:&err] windowController];
    
    if (newwc) {
        [oldwc removeTabController:tc];
        FUTabController *oldtc = [newwc selectedTabController];
        [newwc addTabController:tc];
        [newwc removeTabController:oldtc];
    } else {
        NSLog(@"%@", err);
    }
}


#pragma mark -
#pragma mark Events

- (void)rightMouseDown:(NSEvent *)evt {
    NSPoint mousePt = [self convertPoint:[evt locationInWindow] fromView:nil];
    NSRect cellFrame;
    PSMTabBarCell *cell = [super cellForPoint:mousePt cellFrame:&cellFrame];
    if (cell) {
        rightClickCellIndex = [_cells indexOfObject:cell];
        
        NSTimer *timer = [NSTimer timerWithTimeInterval:0 
                                                 target:self 
                                               selector:@selector(displayContextMenu:) 
                                               userInfo:evt 
                                                repeats:NO];
        [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
    }
}


#pragma mark -
#pragma mark Public

- (FUWindowController *)windowController {
    return (FUWindowController *)[[self window] windowController];
}


#pragma mark -
#pragma mark Private

- (void)displayContextMenu:(NSTimer *)timer {
    NSEvent *evt = [timer userInfo];
    
    NSEvent *click = [NSEvent mouseEventWithType:[evt type] 
                                        location:[evt locationInWindow]
                                   modifierFlags:[evt modifierFlags] 
                                       timestamp:[evt timestamp] 
                                    windowNumber:[evt windowNumber] 
                                         context:[evt context]
                                     eventNumber:[evt eventNumber] 
                                      clickCount:[evt clickCount] 
                                        pressure:[evt pressure]];
    
    [NSMenu popUpContextMenu:[self contextMenu] withEvent:click forView:self];
    [timer invalidate];
}


- (NSMenu *)contextMenu {
    NSTabViewItem *tabViewItem = [tabView tabViewItemAtIndex:rightClickCellIndex];
    NSMenu *menu = [[[NSMenu alloc] initWithTitle:@""] autorelease];
    NSMenuItem *item = nil;
    item = [[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Close Tab", @"")
                                       action:@selector(closeTabClick:) 
                                keyEquivalent:@""] autorelease];
    [item setTarget:self];
    [item setRepresentedObject:tabViewItem];
    [item setOnStateImage:nil];
    [menu addItem:item];
    
    item = [[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Move Tab to New Window", @"")
                                       action:@selector(moveTabToNewWindow:) 
                                keyEquivalent:@""] autorelease];
    [item setTarget:self];
    [item setRepresentedObject:tabViewItem];
    [item setOnStateImage:nil];
    [menu addItem:item];    
    
    FUTabController *tc = [[self windowController] tabControllerAtIndex:rightClickCellIndex];
    
    if ([tc canReload]) {
        [menu addItem:[NSMenuItem separatorItem]];
        
        item = [[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Reload Tab", @"")
                                           action:@selector(reloadTab:) 
                                    keyEquivalent:@""] autorelease];
        [item setTarget:self];
        [item setRepresentedObject:tabViewItem];
        [item setOnStateImage:nil];
        [menu addItem:item];
    }
    
    return menu;
}

@end
