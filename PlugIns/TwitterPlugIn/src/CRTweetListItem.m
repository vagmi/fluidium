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
static NSDictionary *sTextAttributes = nil;

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
        
        sTextAttributes    = [[NSDictionary alloc] initWithObjectsAndKeys:
                               [NSColor blackColor], NSForegroundColorAttributeName,
                               [NSFont systemFontOfSize:10], NSFontAttributeName,
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
        self.usernameButton = [[[NSButton alloc] initWithFrame:NSZeroRect] autorelease];
        [usernameButton setBordered:NO];
        [self addSubview:usernameButton];
        
        self.textView = [[[NSTextView alloc] initWithFrame:NSZeroRect] autorelease];
        [textView setDrawsBackground:NO];
        [self addSubview:textView];
    }
    return self;
}


- (void)dealloc {
    self.usernameButton = nil;
    self.tweet = nil;
    [super dealloc];
}


- (void)resizeSubviewsWithOldSize:(NSSize)oldSize {
    //[super resizeSubviewsWithOldSize:oldSize];

    NSRect bounds = [self bounds];

#define USERNAME_X 54.0
#define USERNAME_Y 2.0
#define USERNAME_HEIGHT 18.0
#define USERNAME_MARGIN_RIGHT 72.0

#define TEXT_X 52.0
#define TEXT_Y 22.0
#define TEXT_MARGIN_RIGHT 7.0

    [usernameButton setFrame:NSMakeRect(USERNAME_X, USERNAME_Y, bounds.size.width - (USERNAME_X + USERNAME_MARGIN_RIGHT), USERNAME_HEIGHT)];
    [textView setFrame:NSMakeRect(TEXT_X, TEXT_Y, bounds.size.width - (USERNAME_X + TEXT_MARGIN_RIGHT), 60)];
    
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
    NSBezierPath *roundRect = [NSBezierPath bezierPathWithRoundRect:NSMakeRect(6, 4, 44, 44) radius:7];
    [roundRect fill];
    
    // username
    //NSString *username = [tweet objectForKey:@"username"];
    //    [username drawInRect:NSMakeRect(56, 5, bounds.size.width, 18) withAttributes:sUsernameAttributes];
    
    // text
//    NSString *text = [tweet objectForKey:@"text"];
//    [text drawInRect:NSMakeRect(56, 22, 240, 60) withAttributes:sTextAttributes];
}


- (void)setTweet:(NSDictionary *)d {
    if (d != tweet) {
        [tweet autorelease];
        tweet = [d retain];
        
        if (tweet) {
            NSString *username = [tweet objectForKey:@"username"];
            if (username) {
                NSAttributedString *title = [[[NSAttributedString alloc] initWithString:username attributes:sUsernameAttributes] autorelease];
                [usernameButton setAttributedTitle:title];
            }
            
            NSString *text = [tweet objectForKey:@"text"];
            if (text) {
                [[textView textStorage] setAttributedString:[[[NSAttributedString alloc] initWithString:text attributes:sTextAttributes] autorelease]];
            }
        }
    }
}

@synthesize usernameButton;
@synthesize textView;
@synthesize tweet;
@end
