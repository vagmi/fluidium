//
//  CRTwitterUtils.h
//  TwitterPlugIn
//
//  Created by Todd Ditchendorf on 10/17/09.
//  Copyright 2009 Todd Ditchendorf. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NSDictionary *CRDefaultStatusAttributes();
NSDictionary *CRLinkStatusAttributes();
NSAttributedString *CRDefaultAttributedStatus(NSString *inStatus);
NSAttributedString *CRAttributedStatus(NSString *inStatus, NSArray **outMentions);

NSString *CRMarkedUpStatus(NSString *inStatus, NSArray **outMentions);

NSString *CRDefaultProfileImageURLString();
NSURL *CRDefaultProfileImageURL();
NSImage *CRDefaultProfileImage();
NSString *CRFormatDateString(NSString *s);
NSString *CRFormatDate(NSDate *inDate);

NSString *CRStringByTrimmingCruzPrefixFromURL(NSURL *URL);
NSString *CRStringByTrimmingCruzPrefixFromString(NSString *s);