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

#import <Foundation/Foundation.h>

@class FUBrowsaPlugIn;

@interface FUBrowsaPreferencesViewController : NSViewController {
    NSPopUpButton *userAgentPopUpButton;
    NSWindow *editUserAgentSheet;
    
    FUBrowsaPlugIn *plugIn;
    
    // UA
    NSString *userAgentString;
    NSArray *userAgentStrings;
    NSString *defaultUserAgentFormat;
    NSString *editingUserAgentString;    
}

- (id)initWithPlugIn:(FUBrowsaPlugIn *)p;

- (IBAction)showNavBars:(id)sender;

- (IBAction)changeUserAgentString:(id)sender;
- (IBAction)changeUserAgentStringToOther:(id)sender;

- (IBAction)endEditUserAgentSheet:(id)sender;

@property (nonatomic, retain) IBOutlet NSWindow *editUserAgentSheet;
@property (nonatomic, retain) IBOutlet NSPopUpButton *userAgentPopUpButton;
@property (nonatomic, assign) FUBrowsaPlugIn *plugIn; // weakref

// UA
@property (nonatomic, copy) NSString *userAgentString;
@property (nonatomic, copy) NSString *editingUserAgentString;
@end
