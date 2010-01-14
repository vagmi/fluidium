//
//  NSString-OFSimpleMatching.h
//  Fluidium
//
//  Created by Todd Ditchendorf on 1/13/10.
//  Copyright 2010 Todd Ditchendorf. All rights reserved.
//

// Copyright 1997-2008 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Id$

#import <Foundation/NSString.h>

#import <CoreFoundation/CFString.h>

@class OFCharacterSet;

@interface NSString (OFSimpleMatching)

+ (BOOL)isEmptyString:(NSString *)string;
// Returns YES if the string is nil or equal to @""

@end
