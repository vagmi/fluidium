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
#import <UMEKit/UMEKit.h>

@class CRTwitterPlugIn;
@class CRTimelineViewController;
@class CRNoAccountsViewController;

@interface CRTwitterPlugInViewController : NSViewController {
    CRTwitterPlugIn *plugIn;
        
    UMETabBarController *tabBarController;

    CRNoAccountsViewController *noAccountsViewController;
    CRTimelineViewController *homeViewController;
    CRTimelineViewController *mentionsViewController;
    
    UMENavigationController *homeNavController;
    UMENavigationController *mentionsNavController;
}

- (void)willAppear;
- (void)didAppear;
- (void)willDisappear;
- (void)didDisappear;

- (void)setUpTimelineAndMentionsIfNecessary;
- (void)setUpTimelineAndMentions;

@property (nonatomic, assign) CRTwitterPlugIn *plugIn;

@property (nonatomic, retain) CRNoAccountsViewController *noAccountsViewController;
@property (nonatomic, retain) UMETabBarController *tabBarController;
@property (nonatomic, retain) CRTimelineViewController *homeViewController;
@property (nonatomic, retain) UMENavigationController *homeNavController;
@property (nonatomic, retain) CRTimelineViewController *mentionsViewController;
@property (nonatomic, retain) UMENavigationController *mentionsNavController;
@end
