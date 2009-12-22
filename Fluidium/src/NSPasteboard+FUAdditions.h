//
//  NSPasteboard+FUAdditions.h
//  Fluidium
//
//  Created by Todd Ditchendorf on 12/22/09.
//  Copyright 2009 Todd Ditchendorf. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSPasteboard (FUAdditions)
- (BOOL)hasURLs;
- (BOOL)hasWebURLs;
@end
