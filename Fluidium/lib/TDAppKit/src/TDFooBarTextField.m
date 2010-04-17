//
//  TDFooBarTextField.m
//  TDAppKit
//
//  Created by Todd Ditchendorf on 4/9/10.
//  Copyright 2010 Todd Ditchendorf. All rights reserved.
//

#import "TDFooBarTextField.h"
#import "TDFooBarTextFieldCell.h"

@implementation TDFooBarTextField

+ (Class)cellClass {
    return [TDFooBarTextFieldCell class];
}


- (void)dealloc {
    self.bar = nil;
    [super dealloc];
}


- (BOOL)isFlipped {
    return YES;
}

@synthesize bar;
@end
