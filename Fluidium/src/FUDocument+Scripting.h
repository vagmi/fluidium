//  Copyright 2010 Todd Ditchendorf
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

#import "FUDocument.h"

@class FUTabController;

@interface FUDocument (Scripting)

// Properties
@property (nonatomic, assign) NSUInteger selectedTabIndex;
@property (nonatomic, retain) FUTabController *selectedTabController;

// Elements
- (NSArray *)orderedTabControllers;

// Commands
- (id)handleNewTabCommand:(NSScriptCommand *)cmd;
- (id)handleCloseTabCommand:(NSScriptCommand *)cmd;

- (id)handleCloseCommand:(NSCloseCommand *)cmd;

- (id)handleSelectPreviousTabCommand:(NSScriptCommand *)cmd;
- (id)handleSelectNextTabCommand:(NSScriptCommand *)cmd;
- (id)handleGoToLocationCommand:(NSScriptCommand *)cmd;
- (id)handleGoBackCommand:(NSScriptCommand *)cmd;
- (id)handleGoForwardCommand:(NSScriptCommand *)cmd;
- (id)handleReloadCommand:(NSScriptCommand *)cmd;
- (id)handleStopLoadingCommand:(NSScriptCommand *)cmd;
- (id)handleGoHomeCommand:(NSScriptCommand *)cmd;
- (id)handleZoomInCommand:(NSScriptCommand *)cmd;
- (id)handleZoomOutCommand:(NSScriptCommand *)cmd;
- (id)handleActualSizeCommand:(NSScriptCommand *)cmd;
@end
