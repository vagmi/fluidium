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

#import "FUBrowsaPreferencesViewController.h"
#import "FUBrowsaPlugIn.h"
#import "FUBrowsaViewController.h"
#import <WebKit/WebKit.h>

NSString *const FUBrowsaUserAgentStringDidChange = @"FUBrowsaUserAgentStringDidChange";

@implementation FUBrowsaPreferencesViewController

- (id)initWithPlugIn:(FUBrowsaPlugIn *)p {
	if ([super initWithNibName:@"FUBrowsaPreferencesView" bundle:[NSBundle bundleForClass:[self class]]]) {
		self.plugIn = p;
	}
	return self;
}


- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];

    self.userAgentPopUpButton = nil;
	self.plugIn = nil;
	[super dealloc];
}


- (void)loadView {
	[super loadView];
}


- (IBAction)showNavbars:(id)sender {
	NSInteger showNavbar = plugIn.showNavBar;
	
	for (FUBrowsaViewController *vc in plugIn.viewControllers) {
		if (1 == showNavbar) {
			[vc showToolbar:sender];
		} else {
			[vc hideToolbar:sender];
		}
	}	
}

@synthesize userAgentPopUpButton;
@synthesize plugIn;
@end
