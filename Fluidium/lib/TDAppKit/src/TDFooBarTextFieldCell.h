//
//  TDFooBarTextFieldCell.h
//  TDAppKit
//
//  Created by Todd Ditchendorf on 4/10/10.
//  Copyright 2010 Todd Ditchendorf. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class TDFooBarTextView;

@interface TDFooBarTextFieldCell : NSTextFieldCell {
    TDFooBarTextView *fieldEditor;
}

@property (nonatomic, retain) TDFooBarTextView *fieldEditor;
@end
