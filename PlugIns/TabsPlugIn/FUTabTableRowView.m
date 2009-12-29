//
//  FUTabTableRowView.m
//  TabsPlugIn
//
//  Created by Todd Ditchendorf on 12/28/09.
//  Copyright 2009 Todd Ditchendorf. All rights reserved.
//

#import "FUTabTableRowView.h"
#import "FUTabModel.h"
#import "FUUtils.h"

static NSDictionary *sTitleAttrs = nil;

@interface FUTabTableRowView ()
- (void)startObserveringModel:(FUTabModel *)m;
- (void)stopObserveringModel:(FUTabModel *)m;
@end

@implementation FUTabTableRowView

+ (void)initialize {
    if ([FUTabTableRowView class] == self) {
        
        NSMutableParagraphStyle *paraStyle = [[[NSParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
        [paraStyle setAlignment:NSCenterTextAlignment];
        [paraStyle setLineBreakMode:NSLineBreakByTruncatingTail];
        
        NSShadow *shadow = [[[NSShadow alloc] init] autorelease];
        [shadow setShadowColor:[NSColor colorWithCalibratedWhite:0 alpha:.4]];
        [shadow setShadowOffset:NSMakeSize(0, -1)];
        [shadow setShadowBlurRadius:0];

        sTitleAttrs = [[NSDictionary alloc] initWithObjectsAndKeys:
                       [NSFont boldSystemFontOfSize:10], NSFontAttributeName,
                       [NSColor whiteColor], NSForegroundColorAttributeName,
                       paraStyle, NSParagraphStyleAttributeName,
                       shadow, NSShadowAttributeName,
                       nil];
    }
}


+ (NSString *)identifier {
    return NSStringFromClass(self);
}


- (id)init {
    return [self initWithFrame:NSZeroRect];
}


- (id)initWithFrame:(NSRect)frame {
    if (self = [super initWithFrame:frame]) {
        
    }
    return self;
}


- (void)dealloc {
    self.model = nil;
    [super dealloc];
}


- (void)drawRect:(NSRect)dirtyRect {
    NSRect rect = [self bounds];
    
    // outer round rect
    if (rect.size.width < 24.0) return; // dont draw anymore when you're really small. looks bad.

    NSRect roundRect = NSInsetRect(rect, 4.5, 4.5);
    
    NSColor *fillTopColor = [NSColor colorWithDeviceRed:134.0/255.0 green:147.0/255.0 blue:169.0/255.0 alpha:1.0];
    NSColor *fillBottomColor = [NSColor colorWithDeviceRed:108.0/255.0 green:120.0/255.0 blue:141.0/255.0 alpha:1.0];
    NSGradient *grad = [[[NSGradient alloc] initWithStartingColor:fillTopColor endingColor:fillBottomColor] autorelease];

    NSColor *strokeColor = [NSColor colorWithDeviceRed:91.0/255.0 green:100.0/255.0 blue:115.0/255.0 alpha:1.0];

    CGFloat radius = (rect.size.width < 32) ? 3 : 5;
    FUDrawRoundRect(roundRect, radius, grad, strokeColor, 1);


    // title
    if (rect.size.width < 40.0) return; // dont draw anymore when you're really small. looks bad.

    NSRect titleRect = NSInsetRect(roundRect, 6, 2);
    titleRect.size.height = 13;
    NSUInteger opts = NSStringDrawingTruncatesLastVisibleLine|NSStringDrawingUsesLineFragmentOrigin;
    [model.title drawWithRect:titleRect options:opts attributes:sTitleAttrs];
    

    
    // inner round rect
    if (rect.size.width < 55.0) return; // dont draw anymore when you're really small. looks bad.

    roundRect = NSInsetRect(roundRect, 4, 4);
    roundRect = NSOffsetRect(roundRect, 0, 12);
    roundRect.size.height -= 10;
    
    grad = [[[NSGradient alloc] initWithStartingColor:[NSColor whiteColor] endingColor:[NSColor whiteColor]] autorelease];
    
    strokeColor = [strokeColor colorWithAlphaComponent:.8];
    FUDrawRoundRect(roundRect, 5, grad, strokeColor, 1);
    
    
    // draw image
    if (rect.size.width < 64.0) return; // dont draw anymore when you're really small. looks bad.

    NSRect imgRect = NSInsetRect(roundRect, 4, 4);
    imgRect.size.height -= 4;
    
    NSImage *img = model.image;
    [img setFlipped:[self isFlipped]];

    NSSize imgSize = [img size];
    [img drawInRect:imgRect fromRect:NSMakeRect(0, 0, imgSize.width, imgSize.height) operation:NSCompositeSourceOver fraction:1];
}


- (void)setModel:(FUTabModel *)m {
    if (m != model) {
        [self stopObserveringModel:model];
        
        [model autorelease];
        model = [m retain];
        
        [self startObserveringModel:model];
    }
}


- (void)startObserveringModel:(FUTabModel *)m {
    if (m) {
        [m addObserver:self forKeyPath:@"image" options:NSKeyValueObservingOptionNew context:NULL];
        [m addObserver:self forKeyPath:@"title" options:NSKeyValueObservingOptionNew context:NULL];
        //    [m addObserver:self forKeyPath:@"URLString" options:0 context:NULL];
    }
}


- (void)stopObserveringModel:(FUTabModel *)m {
    if (m) {
        [m removeObserver:self forKeyPath:@"image"];
        [m removeObserver:self forKeyPath:@"title"];
        //    [m removeObserver:self forKeyPath:@"URLString"];
    }
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (object == model) {
        [self setNeedsDisplay:YES];
    }
}

@synthesize model;
@end
