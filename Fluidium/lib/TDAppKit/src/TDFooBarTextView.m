//
//  TDFooBarTextView.m
//  TDAppKit
//
//  Created by Todd Ditchendorf on 4/10/10.
//  Copyright 2010 Todd Ditchendorf. All rights reserved.
//

#import "TDFooBarTextView.h"

@interface TDFooBar ()
- (BOOL)insertText:(id)insertString;
@end

@implementation TDFooBarTextView

- (void)dealloc {
    self.bar = nil;
    [super dealloc];
}


- (BOOL)isFlipped {
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

    if (![bar insertText:insertString]) {
    }
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
