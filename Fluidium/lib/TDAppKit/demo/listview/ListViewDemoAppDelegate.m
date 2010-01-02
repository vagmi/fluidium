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
    [listView reloadData];
}


#pragma mark -
#pragma mark TDListViewDataSource

- (NSInteger)numberOfItemsInListView:(TDListView *)tv {
    return 7;
}


- (TDListItemView *)listView:(TDListView *)lv viewForItemAtIndex:(NSInteger)i {
    static NSString *sIdentifier = @"foo";
    
    DemoListItemView *itemView = [listView dequeueReusableItemViewWithIdentifier:sIdentifier];
    
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
    
    return itemView;
}


#pragma mark -
#pragma mark TDListViewDelegate

- (CGFloat)listView:(TDListView *)lv extentForItemAtIndex:(NSInteger)i {
    return 100;
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

@synthesize listView;
@end
