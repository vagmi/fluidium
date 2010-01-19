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

// Actions
- (IBAction)goToLocationScriptAction:(id)sender;
- (IBAction)goBackScriptAction:(id)sender;
- (IBAction)goForwardScriptAction:(id)sender;
- (IBAction)goHomeScriptAction:(id)sender;
- (IBAction)reloadScriptAction:(id)sender;
- (IBAction)stopLoadingScriptAction:(id)sender;
- (IBAction)selectPreviousTabScriptAction:(id)sender;
- (IBAction)selectNextTabScriptAction:(id)sender;
- (IBAction)zoomInScriptAction:(id)sender;
- (IBAction)zoomOutScriptAction:(id)sender;
- (IBAction)actualSizeScriptAction:(id)sender;


// Properties
- (NSUInteger)selectedTabIndex;
- (void)setSelectedTabIndex:(NSUInteger)i;

// Elements
- (NSArray *)orderedTabControllers;

// Commands
// standard
- (id)handleCloseCommand:(NSCloseCommand *)cmd;

// custom
- (id)handleSelectPreviousTabCommand:(NSScriptCommand *)cmd;
- (id)handleSelectNextTabCommand:(NSScriptCommand *)cmd;
- (id)handleGoToLocationCommand:(NSScriptCommand *)cmd;
- (id)handleGoBackCommand:(NSScriptCommand *)cmd;
- (id)handleGoForwardCommand:(NSScriptCommand *)cmd;
- (id)handleGoHomeCommand:(NSScriptCommand *)cmd;
- (id)handleReloadCommand:(NSScriptCommand *)cmd;
- (id)handleStopLoadingCommand:(NSScriptCommand *)cmd;
- (id)handleZoomInCommand:(NSScriptCommand *)cmd;
- (id)handleZoomOutCommand:(NSScriptCommand *)cmd;
- (id)handleActualSizeCommand:(NSScriptCommand *)cmd;

@end
