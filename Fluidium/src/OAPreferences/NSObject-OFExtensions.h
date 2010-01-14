//
//  NSObject-OFExtensions.h
//  Fluidium
//
//  Created by Todd Ditchendorf on 1/13/10.
//  Copyright 2010 Todd Ditchendorf. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSObject (OFExtensions)
+ (NSBundle *)bundle;
- (NSString *)shortDescription;
@end
