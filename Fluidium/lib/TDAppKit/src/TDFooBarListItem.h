//
//  TDFooBarListItem.h
//  TDAppKit
//
//  Created by Todd Ditchendorf on 4/9/10.
//  Copyright 2010 Todd Ditchendorf. All rights reserved.
//

#import <TDAppKit/TDListItem.h>

@interface TDFooBarListItem : TDListItem {
    NSString *labelText;
}

+ (NSString *)reuseIdentifier;
+ (CGFloat)defaultHeight;

@property (nonatomic, copy) NSString *labelText;
@end
