//  Copyright 2009 Todd Ditchendorf
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.

#import "CRTweetListItem.h"
#import "CRTweet.h"
#import "CRAvatarCache.h"
#import "CRTwitterUtils.h"
#import "CRTextView.h"
#import <TDAppKit/NSBezierPath+TDAdditions.h>

static NSGradient *sBackgroundGradient = nil;
static NSGradient *sByMeBackgroundGradient = nil;
static NSGradient *sMentionsMeBackgroundGradient = nil;

static NSColor *sBorderBottomColor = nil;
static NSColor *sByMeBorderBottomColor = nil;
static NSColor *sMentionsMeBorderBottomColor = nil;

static NSDictionary *sUsernameAttributes = nil;
static NSDictionary *sDateAttributes = nil;

#define BORDER_HEIGHT 1.0

#define AVATAR_X 6.0
#define AVATAR_Y 4.0

#define USERNAME_X 60.0
#define USERNAME_Y 3.0
#define USERNAME_HEIGHT 18.0

#define TEXT_X 57.0
#define TEXT_Y 21.0
#define TEXT_MARGIN_RIGHT 7.0

#define DATE_Y 5.0
#define DATE_WIDTH 68.0
#define DATE_HEIGHT 16.0

#define NSTEXT_VIEW_PADDING_FUDGE 10.0

@implementation CRTweetListItem

+ (void)initialize {
    if (self == [CRTweetListItem class]) {
        
        NSColor *topColor = [NSColor colorWithDeviceRed:250.0/255.0 green:250.0/255.0 blue:250.0/255.0 alpha:1];
        NSColor *botColor = [NSColor colorWithDeviceRed:233.0/255.0 green:233.0/255.0 blue:233.0/255.0 alpha:1];
        sBackgroundGradient = [[NSGradient alloc] initWithStartingColor:topColor endingColor:botColor];

        topColor = [NSColor colorWithDeviceRed:227.0/255.0 green:224.0/255.0 blue:219.0/255.0 alpha:1];
        botColor = [NSColor colorWithDeviceRed:201.0/255.0 green:195.0/255.0 blue:185.0/255.0 alpha:1];
        sByMeBackgroundGradient = [[NSGradient alloc] initWithStartingColor:topColor endingColor:botColor];

        topColor = [NSColor colorWithDeviceRed:222.0/255.0 green:231.0/255.0 blue:241.0/255.0 alpha:1];
        botColor = [NSColor colorWithDeviceRed:202.0/255.0 green:213.0/255.0 blue:232.0/255.0 alpha:1];
        sMentionsMeBackgroundGradient = [[NSGradient alloc] initWithStartingColor:topColor endingColor:botColor];

        sBorderBottomColor = [[NSColor colorWithDeviceRed:192.0/255.0 green:192.0/255.0 blue:192.0/255.0 alpha:1] retain];
        sByMeBorderBottomColor = [[NSColor colorWithDeviceRed:150.0/255.0 green:150.0/255.0 blue:150.0/255.0 alpha:1] retain];
        sMentionsMeBorderBottomColor = [[NSColor colorWithDeviceRed:170.0/255.0 green:170.0/255.0 blue:170.0/255.0 alpha:1] retain];
        
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
                               [NSFont boldSystemFontOfSize:12], NSFontAttributeName,
                               paraStyle, NSParagraphStyleAttributeName,
                               nil];
        
        paraStyle = [[[NSParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
        [paraStyle setAlignment:NSRightTextAlignment];
        [paraStyle setLineBreakMode:NSLineBreakByTruncatingTail];

        sDateAttributes = [[NSDictionary alloc] initWithObjectsAndKeys:
                           [NSColor grayColor], NSForegroundColorAttributeName,
                           [NSFont systemFontOfSize:9], NSFontAttributeName,
                           paraStyle, NSParagraphStyleAttributeName,
                           nil];
    }
}


+ (NSString *)reuseIdentifier {
    return NSStringFromClass(self);
}


+ (NSDictionary *)textAttributes {
    return CRDefaultStatusAttributes();
}


+ (CGFloat)defaultHeight {
    return USERNAME_HEIGHT + (AVATAR_Y * 2) + BORDER_HEIGHT;
}


+ (CGFloat)minimumHeight {
    return kCRAvatarSide + (AVATAR_Y * 2) + BORDER_HEIGHT;
}


+ (CGFloat)horizontalTextMargins {
    return TEXT_X + TEXT_MARGIN_RIGHT + NSTEXT_VIEW_PADDING_FUDGE; // needs fudge for default padding in NSTextView
}


+ (CGFloat)minimumWidthForDrawingAgo {
    return AVATAR_X + kCRAvatarSide + DATE_WIDTH + TEXT_MARGIN_RIGHT;
}


+ (CGFloat)minimumWidthForDrawingText {
    return [CRTweetListItem minimumWidthForDrawingAgo] - (kCRAvatarSide + 10);
}


- (id)init {
    return [self initWithFrame:NSZeroRect reuseIdentifier:[CRTweetListItem reuseIdentifier]];
}
 

- (id)initWithFrame:(NSRect)frame reuseIdentifier:(NSString *)s {
    if (self = [super initWithFrame:frame reuseIdentifier:s]) {
        NSLog(@"creating new");
        self.avatarButton = [[[NSButton alloc] initWithFrame:NSMakeRect(AVATAR_X, AVATAR_Y, kCRAvatarSide, kCRAvatarSide)] autorelease];
        [avatarButton setBordered:NO];
        [avatarButton setTitle:nil];
        [self addSubview:avatarButton];

        self.usernameButton = [[[NSButton alloc] initWithFrame:NSZeroRect] autorelease];
        [usernameButton setBordered:NO];
        [self addSubview:usernameButton];
        
        self.textView = [[[CRTextView alloc] initWithFrame:NSZeroRect] autorelease];
        [textView setDrawsBackground:NO];
        [textView setEditable:NO];
        [self addSubview:textView];
    }
    return self;
}


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    self.avatarButton = nil;
    self.usernameButton = nil;
    self.tweet = nil;
    [super dealloc];
}


#pragma mark -
#pragma mark NSView

- (void)resizeSubviewsWithOldSize:(NSSize)oldSize {
    NSRect bounds = [self bounds];

    [usernameButton setFrame:NSMakeRect(USERNAME_X, USERNAME_Y, bounds.size.width - (USERNAME_X + DATE_WIDTH + TEXT_MARGIN_RIGHT), USERNAME_HEIGHT)];

    CGFloat textHeight = NSHeight([textView bounds]);
    [textView setFrame:NSMakeRect(TEXT_X, TEXT_Y, bounds.size.width - (TEXT_X + TEXT_MARGIN_RIGHT), textHeight)];
}


- (void)drawRect:(NSRect)dirtyRect {
    NSRect bounds = [self bounds];
    
    NSGradient *bgGradient = sBackgroundGradient;
    NSColor *borderBottomColor = sBorderBottomColor;
    
    if (tweet.isByMe) {
        bgGradient = sByMeBackgroundGradient;
        borderBottomColor = sByMeBorderBottomColor;
    } else if (tweet.isMentionMe) {
        bgGradient = sMentionsMeBackgroundGradient;
        borderBottomColor = sMentionsMeBorderBottomColor;
    }
    
    // bg
    [bgGradient drawInRect:bounds angle:90];
    
    // border
    [borderBottomColor setStroke];
    [NSBezierPath strokeLineFromPoint:NSMakePoint(0, bounds.size.height) toPoint:NSMakePoint(bounds.size.width, bounds.size.height)];
    
    // avatar
//    NSImage *img = [[CRAvatarCache instance] avatarForTweet:tweet sender:self];
//    if (img) {
//        NSSize imgSize = [img size];
//        [img drawAtPoint:NSMakePoint(AVATAR_X, AVATAR_Y) fromRect:NSMakeRect(0, 0, imgSize.width, imgSize.height) operation:NSCompositeSourceOver fraction:1];
//    } else {
        [sBorderBottomColor setFill];
        [[NSBezierPath bezierPathWithRoundRect:NSMakeRect(AVATAR_X, AVATAR_Y, kCRAvatarSide, kCRAvatarSide) radius:kCRAvatarCornerRadius] fill];
//    }
    
    // ago
    if (bounds.size.width > [CRTweetListItem minimumWidthForDrawingAgo]) { // dont draw if too small
        [tweet.ago drawInRect:NSMakeRect(bounds.size.width - (DATE_WIDTH + TEXT_MARGIN_RIGHT), DATE_Y, DATE_WIDTH, DATE_HEIGHT) withAttributes:sDateAttributes];
    }
    
    BOOL hideUsername = bounds.size.width < [CRTweetListItem minimumWidthForDrawingText] + (kCRAvatarSide * 2);
    [usernameButton setHidden:hideUsername];

    BOOL hideText = bounds.size.width < [CRTweetListItem minimumWidthForDrawingText] + kCRAvatarSide + 26;
    [textView setHidden:hideText];
}


#pragma mark -
#pragma mark Notifications

- (void)avatarDidLoad:(NSNotification *)n {
    [avatarButton setImage:[[CRAvatarCache instance] avatarForTweet:tweet sender:self]];
    [avatarButton setNeedsDisplay:YES];
    [self setNeedsDisplay:YES];
}


#pragma mark -
#pragma mark Properties

- (void)setTweet:(CRTweet *)newTweet {
    if (newTweet != tweet) {
        [tweet autorelease];
        tweet = [newTweet retain];
        
        if (tweet) {
            NSImage *img = [[CRAvatarCache instance] avatarForTweet:tweet sender:self];
            if (img) {
                [avatarButton setImage:img];
                [avatarButton setNeedsDisplay:YES];
            }
                
            NSString *s = tweet.username;
            if (![s length]) s = @"";
            NSAttributedString *title = [[[NSAttributedString alloc] initWithString:s attributes:sUsernameAttributes] autorelease];
            [usernameButton setAttributedTitle:title];
            
            if (tweet.attributedText) {
                [[textView textStorage] setAttributedString:tweet.attributedText];
                [textView sizeToFit];
                
                // descenders are being clipped.
                NSRect r = [textView frame];
                r.size.height += 2;
                [textView setFrame:r];
            }
        }
    }
}


- (NSInteger)tag {
    return [usernameButton tag];
}


- (void)setTag:(NSInteger)tag {
    [usernameButton setTag:tag];
}

@synthesize avatarButton;
@synthesize usernameButton;
@synthesize textView;
@synthesize tweet;
@end
