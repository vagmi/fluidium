//
//  NSString-OFReplacement.h
//  Fluidium
//
//  Created by Todd Ditchendorf on 1/13/10.
//  Copyright 2010 Todd Ditchendorf. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSString (OFReplacement)

- (NSString *)stringByRemovingPrefix:(NSString *)prefix;
- (NSString *)stringByRemovingSuffix:(NSString *)suffix;
@end