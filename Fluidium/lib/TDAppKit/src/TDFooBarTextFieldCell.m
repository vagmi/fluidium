//
//  TDFooBarTextFieldCell.m
//  TDAppKit
//
//  Created by Todd Ditchendorf on 4/10/10.
//  Copyright 2010 Todd Ditchendorf. All rights reserved.
//

#import "TDFooBarTextFieldCell.h"
#import "TDFooBarTextField.h"
#import "TDFooBarTextView.h"

@implementation TDFooBarTextFieldCell

- (void)dealloc {
    self.fieldEditor = nil;
    [super dealloc];
}


//- (NSTextView *)fieldEditorForView:(NSView *)v {
//    if (!fieldEditor) {
//        self.fieldEditor = [[[TDFooBarTextView alloc] initWithFrame:NSZeroRect] autorelease];
//        fieldEditor.bar = [(TDFooBarTextField *)v bar];
//    }
//    return fieldEditor; 
//}

@synthesize fieldEditor;
@end
