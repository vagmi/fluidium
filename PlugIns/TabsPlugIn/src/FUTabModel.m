//
//  FUTabModel.m
//  TabsPlugIn
//
//  Created by Todd Ditchendorf on 12/27/09.
//  Copyright 2009 Todd Ditchendorf. All rights reserved.
//

#import "FUTabModel.h"

@implementation FUTabModel

- (void)dealloc {
    self.image = nil;
    self.title = nil;
    self.URLString = nil;
    [super dealloc];
}

@synthesize image;
@synthesize title;
@synthesize URLString;
@end
