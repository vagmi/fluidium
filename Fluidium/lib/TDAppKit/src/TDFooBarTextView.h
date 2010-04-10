//
//  TDFooBarTextView.h
//  TDAppKit
//
//  Created by Todd Ditchendorf on 4/10/10.
//  Copyright 2010 Todd Ditchendorf. All rights reserved.
//

#import <TDAppKit/TDFooBar.h>

@interface TDFooBarTextView : NSTextView {
    TDFooBar *bar;
}

@property (nonatomic, assign) TDFooBar *bar;
@end
