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

#import "FUTabController.h"

@interface FUTabController (Scripting)

// Properties
- (NSUInteger)orderedIndex;
- (BOOL)isSelected;

// Commands
- (id)handleCloseCommand:(NSCloseCommand *)cmd;

- (id)handleGoBackCommand:(NSScriptCommand *)cmd;
- (id)handleGoForwardCommand:(NSScriptCommand *)cmd;
- (id)handleGoHomeCommand:(NSScriptCommand *)cmd;
- (id)handleReloadCommand:(NSScriptCommand *)cmd;
- (id)handleStopLoadingCommand:(NSScriptCommand *)cmd;
- (id)handleZoomInCommand:(NSScriptCommand *)cmd;
- (id)handleZoomOutCommand:(NSScriptCommand *)cmd;
- (id)handleActualSizeCommand:(NSScriptCommand *)cmd;

- (id)handleLoadURLCommand:(NSScriptCommand *)cmd;
- (id)handleDoJavaScriptCommand:(NSScriptCommand *)cmd;
- (id)handleClickLinkCommand:(NSScriptCommand *)cmd;
- (id)handleClickButtonCommand:(NSScriptCommand *)cmd;
- (id)handleSetElementValueCommand:(NSScriptCommand *)cmd;
- (id)handleSubmitFormCommand:(NSScriptCommand *)cmd;


- (id)handleAssertCommand:(NSScriptCommand *)cmd;
- (id)handleAssertPageTitleEquals:(NSScriptCommand *)cmd;
- (id)handleAssertHasElementWithIdCommand:(NSScriptCommand *)cmd;
- (id)handleAssertDoesntHaveElementWithIdCommand:(NSScriptCommand *)cmd;
- (id)handleAssertContainsTextCommand:(NSScriptCommand *)cmd;
- (id)handleAssertDoesntContainTextCommand:(NSScriptCommand *)cmd;
- (id)handleAssertContainsHTMLCommand:(NSScriptCommand *)cmd;
- (id)handleAssertDoesntContainHTMLCommand:(NSScriptCommand *)cmd;
- (id)handleAssertJavaScriptEvalsTrueCommand:(NSScriptCommand *)cmd;
- (id)handleAssertJavaScriptEvalsFalseCommand:(NSScriptCommand *)cmd;
@end
