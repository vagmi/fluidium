//
//  CRTweeListItem.h
//  TwitterPlugIn
//
//  Created by Todd Ditchendorf on 1/29/10.
//  Copyright 2010 Todd Ditchendorf. All rights reserved.
//

#import <TDAppKit/TDListItem.h>

@interface CRTweetListItem : TDListItem {
    NSButton *usernameButton;
    NSTextView *textView;
    NSDictionary *tweet;
}

+ (NSString *)reuseIdentifier;

@property (nonatomic, retain) NSButton *usernameButton;
@property (nonatomic, retain) NSTextView *textView;
@property (nonatomic, retain) NSDictionary *tweet;
@property (nonatomic, assign) NSInteger tag;
@end
