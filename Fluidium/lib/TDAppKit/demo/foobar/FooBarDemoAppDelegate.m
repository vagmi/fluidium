//
//  FooBarDemoAppDelegate.m
//  TDAppKit
//
//  Created by Todd Ditchendorf on 4/9/10.
//  Copyright 2010 Todd Ditchendorf. All rights reserved.
//

#import "FooBarDemoAppDelegate.h"

@implementation FooBarDemoAppDelegate

- (void)dealloc {
    self.data = nil;
    self.fooBar = nil;
    [super dealloc];
}


- (void)awakeFromNib {
    //[[window contentView] setWantsLayer:YES];
    
    self.data = [NSArray arrayWithObjects:
                    @"Alabama", 
                    @"Alaska", 
                    @"Arizona", 
                    @"Arkansas", 
                    @"California", 
                    @"Colorado", 
                    @"Connecticut", 
                    @"Delaware", 
                    @"Florida", 
                    @"Georgia", 
                    @"Hawaii", 
                    @"Idaho", 
                    @"Illinois", 
                    @"Indiana", 
                    @"Iowa", 
                    @"Kansas", 
                    @"Kentucky", 
                    @"Louisiana", 
                    @"Maine", 
                    @"Maryland", 
                    @"Massachusetts", 
                    @"Michigan", 
                    @"Minnesota", 
                    @"Mississippi", 
                    @"Missouri", 
                    @"Montana", 
                    @"Nebraska", 
                    @"Nevada", 
                    @"New Hampshire", 
                    @"New Jersey", 
                    @"New Mexico", 
                    @"New York", 
                    @"North Carolina", 
                    @"North Dakota", 
                    @"Ohio", 
                    @"Oklahoma", 
                    @"Oregon", 
                    @"Pennsylvania", 
                    @"Rhode Island", 
                    @"South Carolina", 
                    @"South Dakota", 
                    @"Tennessee", 
                    @"Texas", 
                    @"Utah", 
                    @"Vermont", 
                    @"Virginia", 
                    @"Washington", 
                    @"West Virginia", 
                    @"Wisconsin", 
                    @"Wyoming", 
                    @"Springfield",
                    @"Indianapolis",
                     @"Des Moines",
                     @"Topeka",
                     @"Frankfort",
                     @"Baton Rouge",
                     @"Augusta",
                     @"Annapolis",
                     @"Boston",
                     @"Lansing",
                     @"St. Paul",
                     @"Jackson",
                     @"Jefferson City",
                     @"Helena",
                     @"Lincoln",
                     @"Carson City",
                     @"New Concord",
                     @"New Trenton",
                     @"New Santa Fe",
                     @"New Albany",
                     @"North Raleigh",
                     @"North Bismarck",
                     @"Columbus",
                     @"Oklahoma City",
                     @"Salem",
                     @"Harrisburg",
                     @"Rhode Providence",
                     @"South Columbia",
                     @"South Pierre",
                     @"Nashville",
                     @"Austin",
                     @"Salt Lake City",
                     @"Montpelier",
                     @"Richmond",
                     @"Olympia",
                     @"West Charleston",
                     @"Madison",
                     @"Cheyenne",
                    nil];
    
}


- (NSArray *)currentData {
    NSString *txt = [[fooBar.textField stringValue] lowercaseString];
    if (![txt length]) return nil;

    NSMutableArray *res = [NSMutableArray array];
    
    for (NSString *state in data) {
        if ([[state lowercaseString] hasPrefix:txt]) {
            [res addObject:state];
        }
    }
    
    return res;
}


#pragma mark -
#pragma mark TDFooBarDataSource

- (NSUInteger)numberOfItemsInFooBar:(TDFooBar *)fb {
    return [[self currentData] count];
}


- (id)fooBar:(TDFooBar *)fb objectAtIndex:(NSUInteger)i {
    return [[self currentData] objectAtIndex:i];
}

@synthesize fooBar;
@synthesize data;
@end
