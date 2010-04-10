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
    BOOL selected;
}

+ (NSString *)reuseIdentifier;
+ (CGFloat)defaultHeight;

- (NSRect)labelRectForBounds:(NSRect)bounds;

@property (nonatomic, copy) NSString *labelText;
@property (nonatomic, getter=isSelected) BOOL selected;
@end
