//
//  TDFooBarListItem.m
//  TDAppKit
//
//  Created by Todd Ditchendorf on 4/9/10.
//  Copyright 2010 Todd Ditchendorf. All rights reserved.
//

#import "TDFooBarListItem.h"

#define LABEL_MARGIN_X 5.0
#define LABEL_MARGIN_Y 5.0

static NSDictionary *sLabelAttributes = nil;
static NSDictionary *sHighlightedLabelAttributes = nil;

@implementation TDFooBarListItem

+ (void)initialize {
    if (self == [TDFooBarListItem class]) {
        
        NSShadow *shadow = [[[NSShadow alloc] init] autorelease];
        [shadow setShadowColor:[NSColor colorWithCalibratedWhite:1 alpha:.51]];
        [shadow setShadowOffset:NSMakeSize(0, -1)];
        [shadow setShadowBlurRadius:0];
        
        NSMutableParagraphStyle *paraStyle = [[[NSParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
        [paraStyle setAlignment:NSLeftTextAlignment];
        [paraStyle setLineBreakMode:NSLineBreakByTruncatingTail];
        
        sLabelAttributes = [[NSDictionary alloc] initWithObjectsAndKeys:
                            [NSColor blackColor], NSForegroundColorAttributeName,
                            shadow, NSShadowAttributeName,
                            [NSFont boldSystemFontOfSize:12], NSFontAttributeName,
                            paraStyle, NSParagraphStyleAttributeName,
                            nil];
        
        sHighlightedLabelAttributes = [[NSDictionary alloc] initWithObjectsAndKeys:
                                       [NSColor colorWithDeviceRed:0 green:99.0/255.0 blue:248.0/255.0 alpha:1], NSForegroundColorAttributeName,
                                       shadow, NSShadowAttributeName,
                                       [NSFont boldSystemFontOfSize:12], NSFontAttributeName,
                                       paraStyle, NSParagraphStyleAttributeName,
                                       nil];
        
    }
}


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
    
    NSRect bounds = [self bounds];
    [labelText drawInRect:[self labelRectForBounds:bounds] withAttributes:sLabelAttributes];
}


- (NSRect)labelRectForBounds:(NSRect)bounds {
    return NSMakeRect(LABEL_MARGIN_X, LABEL_MARGIN_Y, bounds.size.width - (LABEL_MARGIN_X * 2), 16.0);
}

@synthesize labelText;
@end
