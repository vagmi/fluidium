//
//  TDFooBarTextView.m
//  TDAppKit
//
//  Created by Todd Ditchendorf on 4/10/10.
//  Copyright 2010 Todd Ditchendorf. All rights reserved.
//

#import "TDFooBarTextView.h"

@interface TDFooBar ()
- (void)textWasInserted:(id)insertString;
@end

@implementation TDFooBarTextView

- (id)initWithFrame:(NSRect)r {
    if (self = [super initWithFrame:r]) {

    }
    return self;
}


- (void)dealloc {
    self.bar = nil;
    [super dealloc];
}


- (BOOL)isFieldEditor {
    return YES;
}


- (void)moveUp:(id)sender {
    [bar moveUp:sender];
}


- (void)moveDown:(id)sender {
    [bar moveDown:sender];
}


- (void)insertText:(id)insertString {
    [super insertText:insertString];
    [bar textWasInserted:insertString];
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

@synthesize bar;
@end
