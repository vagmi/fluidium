//  Copyright 2009 Todd Ditchendorf
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.

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