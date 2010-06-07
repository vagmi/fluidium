//
//  TDFooBarTextView.m
//  TDAppKit
//
//  Created by Todd Ditchendorf on 4/10/10.
//  Copyright 2010 Todd Ditchendorf. All rights reserved.
//

#import "TDComboFieldTextView.h"

@interface TDComboField ()
- (void)textWasInserted:(id)insertString;
@end

@implementation TDComboFieldTextView

- (id)initWithFrame:(NSRect)r {
    if (self = [super initWithFrame:r]) {

    }
    return self;
}


- (void)dealloc {
    self.comboField = nil;
    [super dealloc];
}


- (BOOL)isFieldEditor {
    return YES;
}


- (void)moveUp:(id)sender {
    [comboField moveUp:sender];
}


- (void)moveDown:(id)sender {
    [comboField moveDown:sender];
}


- (void)insertText:(id)insertString {
    [super insertText:insertString];
    [comboField textWasInserted:insertString];
}


//- (void)pageDown:(id)sender {
//    
//}
//
//
//- (void)moveToEndOfDocument:(id)sender {
//    
//}
//
//
//- (void)moveToEndOfLine:(id)sender {
//    
//}
//
//
//- (void)moveWordForward:(id)sender {
//    
//}
//
//
//- (void)moveWordRight:(id)sender {
//    
//}
//
//
//- (void)scrollPageDown:(id)sender {
//    
//}
//
//
//- (void)scrollLineUp:(id)sender {
//    
//}
//
//
//- (void)scrollLineDown:(id)sender {
//    
//}

@synthesize comboField;
@end
