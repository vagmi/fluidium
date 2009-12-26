//
//  FUTabsPreferencesViewController.m
//  TabsPlugIn
//
//  Created by Todd Ditchendorf on 12/25/09.
//  Copyright 2009 Todd Ditchendorf. All rights reserved.
//

#import "FUTabsPreferencesViewController.h"

@implementation FUTabsPreferencesViewController

- (id)init {
    return [self initWithNibName:@"FUTabsPreferencesView" bundle:[NSBundle bundleForClass:[self class]]];
}


- (id)initWithNibName:(NSString *)name bundle:(NSBundle *)b {
    if (self = [super initWithNibName:name bundle:b]) {
        
    }
    return self;
}


- (void)dealloc {
    
    [super dealloc];
}

@end
