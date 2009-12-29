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
static NSDictionary *sSelectedTitleAttrs = nil;

@interface NSImage (FUTabAdditions)
- (NSImage *)scaledImageOfSize:(NSSize)size;
@end

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

        sSelectedTitleAttrs = [[NSDictionary alloc] initWithObjectsAndKeys:
                               [NSFont boldSystemFontOfSize:10], NSFontAttributeName,
                               [NSColor whiteColor], NSForegroundColorAttributeName,
                               paraStyle, NSParagraphStyleAttributeName,
                               shadow, NSShadowAttributeName,
                               nil];

        sTitleAttrs = [[NSDictionary alloc] initWithObjectsAndKeys:
                               [NSFont boldSystemFontOfSize:10], NSFontAttributeName,
                               [NSColor colorWithDeviceWhite:.3 alpha:1], NSForegroundColorAttributeName,
                               paraStyle, NSParagraphStyleAttributeName,
                               nil];
    }
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
    NSRect bounds = [self bounds];
    
    // outer round rect
    if (bounds.size.width < 24.0) return; // dont draw anymore when you're really small. looks bad.

    NSRect roundRect = NSInsetRect(bounds, 2.5, 1.5);
    
    NSColor *fillTopColor = nil;
    NSColor *fillBottomColor = nil;
    NSGradient *grad = nil;
    NSColor *strokeColor = nil;
    
    if (model.isSelected) {
        fillTopColor = [NSColor colorWithDeviceRed:134.0/255.0 green:147.0/255.0 blue:169.0/255.0 alpha:1.0];
        fillBottomColor = [NSColor colorWithDeviceRed:108.0/255.0 green:120.0/255.0 blue:141.0/255.0 alpha:1.0];
        strokeColor = [NSColor colorWithDeviceRed:91.0/255.0 green:100.0/255.0 blue:115.0/255.0 alpha:1.0];

        grad = [[[NSGradient alloc] initWithStartingColor:fillTopColor endingColor:fillBottomColor] autorelease];
        
        CGFloat radius = (bounds.size.width < 32) ? 3 : 4;
        FUDrawRoundRect(roundRect, radius, grad, strokeColor, 1);
    }


    // title
    if (bounds.size.width < 40.0) return; // dont draw anymore when you're really small. looks bad.

    NSRect titleRect = NSInsetRect(roundRect, 6, 2);
    titleRect.size.height = 13;
    NSUInteger opts = NSStringDrawingTruncatesLastVisibleLine|NSStringDrawingUsesLineFragmentOrigin;
    NSDictionary *attrs = model.isSelected ? sSelectedTitleAttrs : sTitleAttrs;
    [model.title drawWithRect:titleRect options:opts attributes:attrs];
    

    
    // inner round rect
    if (bounds.size.width < 55.0) return; // dont draw anymore when you're really small. looks bad.

    roundRect = NSInsetRect(roundRect, 4, 4);
    roundRect = NSOffsetRect(roundRect, 0, 12);
    roundRect.size.height -= 10;
    
    NSImage *img = model.image;
    [img setFlipped:[self isFlipped]];

    if (img) {
        NSSize size = [img size];
        NSBitmapImageRep *bitmap = [[img representations] objectAtIndex:0];
        
        fillTopColor = [bitmap colorAtX:7 y:7];
        fillTopColor = fillTopColor ? fillTopColor : [NSColor whiteColor];

        fillBottomColor = [bitmap colorAtX:7 y:size.height - 7];
        fillBottomColor = fillBottomColor ? fillBottomColor : [NSColor whiteColor];
    } else {
        fillTopColor = [NSColor whiteColor];
        fillBottomColor = [NSColor whiteColor];
    }
    grad = [[[NSGradient alloc] initWithStartingColor:fillTopColor endingColor:fillBottomColor] autorelease];
    
    if (model.isSelected) {
        strokeColor = [strokeColor colorWithAlphaComponent:.8];
    } else {
        strokeColor = [NSColor colorWithDeviceWhite:.7 alpha:1];
    }
    FUDrawRoundRect(roundRect, 5, grad, strokeColor, 1);
    
    
    // draw image
    if (bounds.size.width < 64.0) return; // dont draw anymore when you're really small. looks bad.

#define THUMBNAIL_DIFF 6
    NSSize imgSize = roundRect.size;
    imgSize.width = floor(imgSize.width - THUMBNAIL_DIFF);
    imgSize.height = floor(imgSize.height - THUMBNAIL_DIFF);
    
    img = [img scaledImageOfSize:imgSize];
    
    if (!img) return;
    imgSize = [img size];
    NSRect srcRect = NSMakeRect(0, 0, imgSize.width, imgSize.height);
    NSRect destRect = NSOffsetRect(srcRect, floor(roundRect.origin.x + THUMBNAIL_DIFF/2), floor(roundRect.origin.y + THUMBNAIL_DIFF/2));
    [img drawInRect:destRect fromRect:srcRect operation:NSCompositeSourceOver fraction:1];
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
    }
}


- (void)stopObserveringModel:(FUTabModel *)m {
    if (m) {
        [m removeObserver:self forKeyPath:@"image"];
        [m removeObserver:self forKeyPath:@"title"];
    }
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (object == model) {
        [self setNeedsDisplay:YES];
    }
}

@synthesize model;
@end
