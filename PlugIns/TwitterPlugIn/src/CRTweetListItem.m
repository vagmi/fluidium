//
//  CRTweeListItem.m
//  TwitterPlugIn
//
//  Created by Todd Ditchendorf on 1/29/10.
//  Copyright 2010 Todd Ditchendorf. All rights reserved.
//

#import "CRTweetListItem.h"

@implementation CRTweetListItem

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


- (void)drawRect:(NSRect)dirtyRect {
    NSRect bounds = [self bounds];
    
    NSEraseRect(bounds);
    
    NSString *username = [tweet objectForKey:@"username"];
    [username drawInRect:NSMakeRect(0, 0, bounds.size.width, 20) withAttributes:nil];
    
    
}

@synthesize tweet;
@end
