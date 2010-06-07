//
//  TDFooBarTextView.h
//  TDAppKit
//
//  Created by Todd Ditchendorf on 4/10/10.
//  Copyright 2010 Todd Ditchendorf. All rights reserved.
//

#import <TDAppKit/TDComboField.h>

@interface TDFooBarTextView : NSTextView {
    TDComboField *bar;
}

@property (nonatomic, assign) TDComboField *bar;
@end
