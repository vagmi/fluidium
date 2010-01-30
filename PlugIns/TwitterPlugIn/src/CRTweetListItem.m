//
//  CRTweeListItem.m
//  TwitterPlugIn
//
//  Created by Todd Ditchendorf on 1/29/10.
//  Copyright 2010 Todd Ditchendorf. All rights reserved.
//

#import "CRTweetListItem.h"
#import <TDAppKit/NSBezierPath+TDAdditions.h>

static NSGradient *sBackgroundGradient = nil;
static NSGradient *sByMeBackgroundGradient = nil;
static NSGradient *sMentionsMeBackgroundGradient = nil;

static NSColor *sBorderBottomColor = nil;

static NSDictionary *sUsernameAttributes = nil;

@implementation CRTweetListItem

+ (void)initialize {
    if (self == [CRTweetListItem class]) {
        
        NSColor *startColor = [[NSColor colorWithDeviceRed:250.0/255.0 green:250.0/255.0 blue:250.0/255.0 alpha:1] retain];
        NSColor *endColor   = [[NSColor colorWithDeviceRed:233.0/255.0 green:233.0/255.0 blue:233.0/255.0 alpha:1] retain];
        sBackgroundGradient = [[NSGradient alloc] initWithStartingColor:startColor endingColor:endColor];

        sByMeBackgroundGradient = [[NSGradient alloc] initWithStartingColor:[NSColor blackColor] endingColor:[NSColor brownColor]];
        sMentionsMeBackgroundGradient = [[NSGradient alloc] initWithStartingColor:[NSColor blackColor] endingColor:[NSColor blueColor]];

        sBorderBottomColor = [[NSColor colorWithDeviceRed:192.0/255.0 green:192.0/255.0 blue:192.0/255.0 alpha:1] retain];
        
        NSShadow *shadow = [[[NSShadow alloc] init] autorelease];
        [shadow setShadowColor:[NSColor colorWithCalibratedWhite:1 alpha:.51]];
        [shadow setShadowOffset:NSMakeSize(0, -1)];
        [shadow setShadowBlurRadius:0];

        NSMutableParagraphStyle *paraStyle = [[[NSParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
        [paraStyle setAlignment:NSLeftTextAlignment];
        [paraStyle setLineBreakMode:NSLineBreakByTruncatingTail];

        sUsernameAttributes = [[NSDictionary alloc] initWithObjectsAndKeys:
                               [NSColor blackColor], NSForegroundColorAttributeName,
                               shadow, NSShadowAttributeName,
                               [NSFont boldSystemFontOfSize:11], NSFontAttributeName,
                               paraStyle, NSParagraphStyleAttributeName,
                               nil];

    }
}


+ (NSString *)reuseIdentifier {
    return NSStringFromClass(self);
}


- (id)init {
    return [self initWithFrame:NSZeroRect reuseIdentifier:[CRTweetListItem reuseIdentifier]];
}
 

- (id)initWithFrame:(NSRect)frame reuseIdentifier:(NSString *)s {
    if (self = [super init]) {
        
    }
    return self;
}


- (void)dealloc {
    self.tweet = nil;
    [super dealloc];
}


//{
//    avatarURLString = "http://a3.twimg.com/profile_images/579844959/Photo_on_2009-12-17_at_15.46__2_normal.jpg";
//    "created_at" = 2010-01-29 22:16:06 -0800;
//    doesMentionMe = 0;
//    id = 8402242462;
//    isReply = 0;
//    name = "Tim Trueman";
//    text = "This is an interesting idea <a class='url' href='http://www.techcrunch.com/2010/01/29/first-round-capital-entrepreneur-exchange-fund/' onclick='cruz.linkClicked(\"http://www.techcrunch.com/2010/01/29/first-round-capital-entrepreneur-exchange-fund/\"); return false;'>www.techcrunch.com/2010/01/29/fi\U2026</a>";
//    username = timtrueman;
//    writtenByMe = 0;
//}
- (void)drawRect:(NSRect)dirtyRect {
    NSRect bounds = [self bounds];
    
    // bg
    [sBackgroundGradient drawInRect:bounds angle:90];
    
    // border
    [sBorderBottomColor setStroke];
    [NSBezierPath strokeLineFromPoint:NSMakePoint(0, bounds.size.height) toPoint:NSMakePoint(bounds.size.width, bounds.size.height)];
    
    // avatar
    NSBezierPath *roundRect = [NSBezierPath bezierPathWithRoundRect:NSMakeRect(6, 4, 44, 44) radius:8];
    [roundRect fill];
    
    // username
    NSString *username = [tweet objectForKey:@"username"];
    [username drawInRect:NSMakeRect(56, 5, bounds.size.width, 18) withAttributes:sUsernameAttributes];
    
    
}

@synthesize tweet;
@end
