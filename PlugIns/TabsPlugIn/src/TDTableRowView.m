//
//  FUTabsTableViewCell.m
//  TabsPlugIn
//
//  Created by Todd Ditchendorf on 12/28/09.
//  Copyright 2009 Todd Ditchendorf. All rights reserved.
//

#import "TDTableRowView.h"

@implementation TDTableRowView

+ (NSString *)identifier {
    return NSStringFromClass(self);
}


- (id)initWithFrame:(NSRect)frame {
    if (self = [super initWithFrame:frame]) {
        
    }
    return self;
}


- (void)dealloc {
    [super dealloc];
}


- (BOOL)isFlipped {
    return YES;
}

@end
