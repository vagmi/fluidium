//
//  NSString+FUAdditions.h
//  Fluidium
//
//  Created by Todd Ditchendorf on 6/12/09.
//  Copyright 2009 Todd Ditchendorf. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSString (FUAdditions)
- (NSString *)stringByEnsuringURLSchemePrefix;
- (NSString *)stringByTrimmingURLSchemePrefix;
- (BOOL)hasHTTPSchemePrefix;
- (BOOL)hasSupportedSchemePrefix;
@end
