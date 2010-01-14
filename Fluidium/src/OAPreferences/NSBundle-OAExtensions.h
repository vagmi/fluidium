//
//  NSBundle-OAExtensions.h
//  Fluidium
//
//  Created by Todd Ditchendorf on 1/14/10.
//  Copyright 2010 Todd Ditchendorf. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSBundle (OAExtensions)
- (void)loadNibNamed:(NSString *)nibName owner:(id <NSObject>)owner;
// Raises an exception if unable to load successfully
@end
