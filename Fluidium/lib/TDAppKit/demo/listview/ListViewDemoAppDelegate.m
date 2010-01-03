//  Copyright 2010 Todd Ditchendorf
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

#import "ListViewDemoAppDelegate.h"
#import "DemoListItemView.h"
#import <TDAppKit/TDAppKit.h>

@implementation ListViewDemoAppDelegate

- (id)init {
    if (self = [super init]) {
        
    }
    return self;
}


- (void)dealloc {
    self.listView = nil;
    [super dealloc];
}


- (void)awakeFromNib {
    listView.displaysTruncatedItems = YES;
    listView.backgroundColor = [NSColor darkGrayColor];
    [listView reloadData];
}


#pragma mark -
#pragma mark TDListViewDataSource

- (NSInteger)numberOfItemsInListView:(TDListView *)tv {
    return 7;
}


- (TDListItemView *)listView:(TDListView *)lv viewForItemAtIndex:(NSInteger)i {
    static NSString *sIdentifier = @"foo";
    
    DemoListItemView *itemView = [listView dequeueReusableItemWithIdentifier:sIdentifier];
    
    if (!itemView) {
        itemView = [[[DemoListItemView alloc] initWithFrame:NSZeroRect reuseIdentifier:sIdentifier] autorelease];
    }
    
    NSColor *color = nil;
    NSString *name = nil;
    
    switch (i) {
        case 0:
            color = [NSColor magentaColor];
            name = @"magenta";
            break;
        case 1:
            color = [NSColor redColor];
            name = @"red";
            break;
        case 2:
            color = [NSColor orangeColor];
            name = @"orange";
            break;
        case 3:
            color = [NSColor yellowColor];
            name = @"yellow";
            break;
        case 4:
            color = [NSColor greenColor];
            name = @"green";
            break;
        case 5:
            color = [NSColor blueColor];
            name = @"blue";
            break;
        case 6:
            color = [NSColor purpleColor];
            name = @"purple";
            break;
        default:
            NSAssert(0, @"unknown row");
            break;
    }
    
    itemView.color = color;
    itemView.name = name;
    itemView.selected = (listView.selectedItemIndex == i);
    
    return itemView;
}


#pragma mark -
#pragma mark TDListViewDelegate

- (CGFloat)listView:(TDListView *)lv extentForItemAtIndex:(NSInteger)i {
    return 60 * (i + 1);
}


- (void)listView:(TDListView *)lv willDisplayView:(TDListItemView *)rv forItemAtIndex:(NSInteger)i {
    
}


- (NSInteger)listView:(TDListView *)lv willSelectItemAtIndex:(NSInteger)i {
    return i;
}


- (void)listView:(TDListView *)lv didSelectItemAtIndex:(NSInteger)i {

}


- (void)listView:(TDListView *)lv emptyAreaWasDoubleClicked:(NSEvent *)evt {
    
}


#pragma mark -
#pragma mark TDListViewDelegate Drag and Drop

- (BOOL)listView:(TDListView *)lv canDragItemAtIndex:(NSUInteger)i withEvent:(NSEvent *)evt {
    return YES;
}

/*
 This method is called after it has been determined that a drag should begin, but before the drag has been started. 
 To refuse the drag, return NO. To start the drag, declare the pasteboard types that you support with -[NSPasteboard declareTypes:owner:], 
 place your data for the items at the given indexes on the pasteboard, and return YES from the method. 
 The drag image and other drag related information will be set up and provided by the view once this call returns YES. 
 You need to implement this method for your list view to be a drag source.
 */
- (BOOL)listView:(TDListView *)lv writeItemAtIndex:(NSUInteger)i toPasteboard:(NSPasteboard *)pboard {
    DemoListItemView *itemView = [listView viewForItemAtIndex:i];
    if (itemView) {
        [pboard declareTypes:[NSArray arrayWithObjects:NSColorPboardType, nil] owner:self];
        [itemView.color writeToPasteboard:pboard];
        return YES;
    } else {
        return NO;
    }
}


@synthesize listView;
@end
