//
//  TDFooBarListItem.m
//  TDAppKit
//
//  Created by Todd Ditchendorf on 4/9/10.
//  Copyright 2010 Todd Ditchendorf. All rights reserved.
//

#import "TDFooBarListItem.h"

@implementation TDFooBarListItem

+ (NSString *)reuseIdentifier {
    return NSStringFromClass(self);
}


+ (CGFloat)defaultHeight {
    return 20.0;
}


- (id)init {
    return [self initWithFrame:NSZeroRect reuseIdentifier:[[self class] reuseIdentifier]];
}


- (id)initWithFrame:(NSRect)r reuseIdentifier:(NSString *)s {
    if (self = [super initWithFrame:r reuseIdentifier:s]) {
        
    }
    return self;
}


- (void)dealloc {
    self.labelText = nil;
    [super dealloc];
}


- (void)drawRect:(NSRect)dirtyRect {
    [[NSColor redColor] set];
    NSRectFill([self bounds]);
}

@synthesize labelText;
@end
