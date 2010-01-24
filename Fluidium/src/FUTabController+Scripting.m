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

#import "FUTabController+Scripting.h"
#import "FUDocument.h"
#import "FUWindowController.h"
#import "FUNotifications.h"
#import <WebKit/WebKit.h>

#define DEFAULT_DELAY 1.0

@interface FUTabController (ScriptingPrivate)
- (void)suspendExecutionUntilProgressFinishedWithCommand:(NSScriptCommand *)cmd;
- (void)suspendCommand:(NSScriptCommand *)cmd;
- (void)resumeSuspendedCommandAfterDelay:(NSTimeInterval)delay;

- (BOOL)isHTMLDocument:(NSScriptCommand *)cmd;

- (NSMutableArray *)elementsWithTagName:(NSString *)tagName forArguments:(NSDictionary *)args;
- (NSMutableArray *)elementsWithTagName:(NSString *)tagName andValue:(NSString *)attrVal forAttribute:(NSString *)attrName;
//- (NSMutableArray *)elementsWithTagName:(NSString *)tagName andAttributes:(NSDictionary *)attrs;
- (NSMutableArray *)elementsWithTagName:(NSString *)tagName andText:(NSString *)text;
- (NSMutableArray *)elementsForXPath:(NSString *)xpath;
- (NSMutableArray *)elementsFromArray:(NSMutableArray *)els withText:(NSString *)text;
- (NSArray *)arrayFromHTMLCollection:(DOMHTMLCollection *)collection;

- (BOOL)pageTitleEquals:(NSScriptCommand *)cmd;
- (BOOL)hasElementWithId:(NSScriptCommand *)cmd;
- (BOOL)doesntHaveElementWithId:(NSScriptCommand *)cmd;
- (BOOL)containsText:(NSScriptCommand *)cmd;
- (BOOL)doesntContainText:(NSScriptCommand *)cmd;
- (BOOL)containsHTML:(NSScriptCommand *)cmd;
- (BOOL)doesntContainHTML:(NSScriptCommand *)cmd;
- (BOOL)javaScriptEvalsTrue:(NSScriptCommand *)cmd;
- (BOOL)javaScriptEvalsFalse:(NSScriptCommand *)cmd;

- (BOOL)pageContainsText:(NSString *)text;
- (BOOL)pageContainsHTML:(NSString *)HTML;    

@property (nonatomic, retain) NSScriptCommand *suspendedCommand;
@end

@implementation FUTabController (Scripting)

- (FourCharCode)classCode {
    return 'fTab';
}


- (NSScriptObjectSpecifier *)objectSpecifier {
    NSUInteger i = [windowController indexOfTabController:self];
    
    if (NSNotFound == i) {
        return nil;
    } else {
        NSScriptObjectSpecifier *docSpec = [[windowController document] objectSpecifier];
        
        return [[[NSIndexSpecifier alloc] initWithContainerClassDescription:[NSScriptClassDescription classDescriptionForClass:[FUDocument class]]
                                                         containerSpecifier:docSpec 
                                                                        key:@"orderedTabControllers" 
                                                                      index:i] autorelease];
    }
}


- (NSUInteger)orderedIndex {
    return [windowController indexOfTabController:self] + 1;
}


- (BOOL)isSelected {
    return self == [windowController selectedTabController];
}


#pragma mark -
#pragma mark Commands

- (id)handleCloseCommand:(NSCloseCommand *)cmd {
    [windowController removeTabController:self];
    return nil;
}


- (id)handleGoBackCommand:(NSScriptCommand *)cmd {
    [self webGoBack:nil];
    return nil;
}


- (id)handleGoForwardCommand:(NSScriptCommand *)cmd {
    [self webGoForward:nil];
    return nil;
}


- (id)handleReloadCommand:(NSScriptCommand *)cmd {
    [self webReload:nil];
    return nil;
}


- (id)handleStopLoadingCommand:(NSScriptCommand *)cmd {
    [self webStopLoading:nil];
    return nil;
}


- (id)handleGoHomeCommand:(NSScriptCommand *)cmd {
    [self webGoHome:nil];
    return nil;
}


- (id)handleZoomInCommand:(NSScriptCommand *)cmd {
    [self zoomIn:nil];
    return nil;
}


- (id)handleZoomOutCommand:(NSScriptCommand *)cmd {
    [self zoomOut:nil];
    return nil;
}


- (id)handleActualSizeCommand:(NSScriptCommand *)cmd {
    [self actualSize:nil];
    return nil;
}


- (id)handleLoadURLCommand:(NSScriptCommand *)cmd {
    [self suspendExecutionUntilProgressFinishedWithCommand:cmd];

    NSString *s = [cmd directParameter];
    self.URLString = s;
    [self goToLocation:nil];
    return nil;
}


- (id)handleDoJavaScriptCommand:(NSScriptCommand *)cmd {
    NSString *script = [cmd directParameter];
    NSString *result = [webView stringByEvaluatingJavaScriptFromString:script];

    // just put in a little delay for good measure
    [self suspendCommand:cmd];
    [self resumeSuspendedCommandAfterDelay:DEFAULT_DELAY/2];
    
    return [NSAppleEventDescriptor descriptorWithString:result];
}


- (id)handleClickLinkCommand:(NSScriptCommand *)cmd {
    if (![self isHTMLDocument:cmd]) return nil;
    
    DOMHTMLDocument *doc = (DOMHTMLDocument *)[webView mainFrameDocument];
    
    NSDictionary *args = [cmd arguments];
    
    NSMutableArray *els = [self elementsWithTagName:@"a" forArguments:args];
    
    NSMutableArray *anchorEls = [NSMutableArray array];
    for (DOMHTMLElement *el in els) {
        if ([el isKindOfClass:[DOMHTMLAnchorElement class]]) {
            [anchorEls addObject:el];
        }
    }
    
    if (![anchorEls count]) {
        [cmd setScriptErrorNumber:47];
        [cmd setScriptErrorString:[NSString stringWithFormat:@"could not find link element with args: %@", args]];
        return nil;
    }
    
    DOMHTMLAnchorElement *anchorEl = (DOMHTMLAnchorElement *)[anchorEls objectAtIndex:0];
    
    // create DOM click event
    DOMAbstractView *window = [doc defaultView];
    DOMUIEvent *evt = (DOMUIEvent *)[doc createEvent:@"UIEvents"];
    [evt initUIEvent:@"click" canBubble:YES cancelable:YES view:window detail:1];
    
    // register for next page load
    [self suspendExecutionUntilProgressFinishedWithCommand:cmd];
    
    // send event to the anchor
    [anchorEl dispatchEvent:evt];
    
    return nil;
}


- (id)handleClickButtonCommand:(NSScriptCommand *)cmd {
    if (![self isHTMLDocument:cmd]) return nil;
    
    DOMHTMLDocument *doc = (DOMHTMLDocument *)[webView mainFrameDocument];
    
    NSDictionary *args = [cmd arguments];
    
    NSMutableArray *inputEls = [self elementsWithTagName:@"input" forArguments:args];
    for (DOMHTMLElement *el in inputEls) {
        if ([el isKindOfClass:[DOMHTMLInputElement class]]) {
            DOMHTMLInputElement *inputEl = (DOMHTMLInputElement *)el;
            NSString *type = [[el getAttribute:@"type"] lowercaseString];
            if ([type isEqualToString:@"button"] || [type isEqualToString:@"submit"]) {
                
                // register for next page load
                [self suspendExecutionUntilProgressFinishedWithCommand:cmd];
                
                // click
                [inputEl click]; 
                
                return nil;
            }
        }
    }
    
    
    NSMutableArray *buttonEls = [self elementsWithTagName:@"button" forArguments:args];
    for (DOMHTMLElement *el in buttonEls) {
        if ([el isKindOfClass:[DOMHTMLButtonElement class]]) {
            DOMHTMLButtonElement *buttonEl = (DOMHTMLButtonElement *)el;
            
            // create DOM click event
            DOMAbstractView *window = [doc defaultView];
            DOMUIEvent *evt = (DOMUIEvent *)[doc createEvent:@"UIEvents"];
            [evt initUIEvent:@"click" canBubble:YES cancelable:YES view:window detail:1];
            
            // register for next page load
            [self suspendExecutionUntilProgressFinishedWithCommand:cmd];
            
            // send event to the button
            [buttonEl dispatchEvent:evt];
            
            return nil;
        }
    }
    
    [cmd setScriptErrorNumber:47];
    [cmd setScriptErrorString:[NSString stringWithFormat:@"could not find button element with args: %@", args]];
    return nil;
}


- (id)handleSetElementValueCommand:(NSScriptCommand *)cmd {
    if (![self isHTMLDocument:cmd]) return nil;
    
    // just put in a little delay for good measure
    [self suspendCommand:cmd];

    DOMHTMLDocument *doc = (DOMHTMLDocument *)[webView mainFrameDocument];
    
    NSDictionary *args = [cmd arguments];
    NSString *formName = [args objectForKey:@"formName"];
    NSString *formID = [args objectForKey:@"formID"];
    NSString *formXPath = [args objectForKey:@"formXPath"];
    NSString *name = [args objectForKey:@"name"];
    NSString *identifier = [args objectForKey:@"identifier"];
    NSString *xpath = [args objectForKey:@"xpath"];
    NSString *value = [args objectForKey:@"value"];
    
    DOMHTMLFormElement *formEl = nil;
    if (formName) {
        formEl = (DOMHTMLFormElement *)[[doc forms] namedItem:name];
    } else if (formID) {
        NSArray *els = [self elementsWithTagName:@"form" andValue:identifier forAttribute:@"id"];
        if ([els count]) formEl = [els objectAtIndex:0];
    } else if (formXPath) {
        NSArray *els = [self elementsForXPath:formXPath];
        if ([els count]) {
            formEl = [els objectAtIndex:0];
            if (![formEl isKindOfClass:[DOMHTMLFormElement class]]) {
                formEl = nil;
            }
        }
    }
    
    DOMElement *foundEl = nil;
    if (name) {
        if (formEl) {
            foundEl = (DOMElement *)[[formEl elements] namedItem:name];
        }
    } else if (identifier) {
        NSArray *els = nil;
        if (formEl) {
            els = [self arrayFromHTMLCollection:[formEl elements]];
            for (DOMElement *el in els) {
                if ([[el getAttribute:@"id"] isEqualToString:@"identifier"]) {
                    foundEl = el;
                    break;
                }
            }
        } else {
            foundEl = [doc getElementById:identifier]; // use getElementById: here cuz we have no tagName
        }
    } else if (xpath) {
        NSArray *els = [self elementsForXPath:xpath];
        if ([els count]) foundEl = [els objectAtIndex:0];
    }
    
    if (foundEl && [foundEl isKindOfClass:[DOMHTMLElement class]]) {
        [foundEl setValue:value];
    }

    // resume execution
    [self resumeSuspendedCommandAfterDelay:DEFAULT_DELAY];
    
    return nil;
}


- (id)handleSubmitFormCommand:(NSScriptCommand *)cmd {
    if (![self isHTMLDocument:cmd]) return nil;
    
    DOMHTMLDocument *doc = (DOMHTMLDocument *)[webView mainFrameDocument];
    
    NSDictionary *args = [cmd arguments];
    NSString *name = [args objectForKey:@"name"];
    NSString *identifier = [args objectForKey:@"identifier"];
    NSString *xpath = [args objectForKey:@"xpath"];
    NSDictionary *values = [args objectForKey:@"values"];
    
    DOMHTMLFormElement *formEl = nil;
    if (name) {
        formEl = (DOMHTMLFormElement *)[[doc forms] namedItem:name];
    } else if (identifier) {
        NSArray *els = [self elementsWithTagName:@"form" andValue:identifier forAttribute:@"id"];
        if ([els count]) formEl = [els objectAtIndex:0];
    } else if (xpath) {
        NSArray *els = [self elementsForXPath:xpath];
        for (DOMHTMLElement *el in els) {
            if ([el isKindOfClass:[DOMHTMLFormElement class]]) {
                formEl = (DOMHTMLFormElement *)el;
                break;
            }
        }
    }
    
    if (!formEl) {
        [cmd setScriptErrorNumber:47];
        [cmd setScriptErrorString:[NSString stringWithFormat:@"could not find form with name: %@", name]];
        return nil;
    }
    
    DOMHTMLCollection *els = [formEl elements];
    
    for (NSString *elName in values) {
        NSString *value = [values objectForKey:elName];
        
        DOMHTMLElement *el = (DOMHTMLElement *)[els namedItem:elName];
        if (!el) {
            [cmd setScriptErrorNumber:47];
            [cmd setScriptErrorString:[NSString stringWithFormat:@"could not find input element with name: %@ in form named : %@", name, elName]];
            return nil;
        }
        [el setValue:value];
    }
    
    [self suspendExecutionUntilProgressFinishedWithCommand:cmd];
    
    [formEl submit];
    
    return nil;
}


- (id)handleAssertCommand:(NSScriptCommand *)cmd {
    if (![self isHTMLDocument:cmd]) return nil;
    
    NSDictionary *args = [cmd arguments];
    
    NSString *titleEquals = [args objectForKey:@"titleEquals"];
    NSString *hasElementWithId = [args objectForKey:@"hasElementWithId"];
    NSString *doesntHaveElementWithId = [args objectForKey:@"doesntHaveElementWithId"];
    NSString *containsText = [args objectForKey:@"containsText"];
    NSString *doesntContainText = [args objectForKey:@"doesntContainText"];
    NSString *containsHTML = [args objectForKey:@"containsHTML"];
    NSString *doesntContainHTML = [args objectForKey:@"doesntContainHTML"];
    NSString *javaScriptEvalsTrue = [args objectForKey:@"javaScriptEvalsTrue"];
    NSString *javaScriptEvalsFalse = [args objectForKey:@"javaScriptEvalsFalse"];
    
    if (titleEquals) {
        [self handleAssertPageTitleEqualsCommand:cmd];
    }
    if (hasElementWithId) {
        [self handleAssertHasElementWithIdCommand:cmd];
    }
    if (doesntHaveElementWithId) {
        [self handleAssertDoesntHaveElementWithIdCommand:cmd];
    }
    if (containsText) {
        [self handleAssertContainsTextCommand:cmd];
    }
    if (doesntContainText) {
        [self handleAssertDoesntContainTextCommand:cmd];
    }
    if (containsHTML) {
        [self handleAssertContainsHTMLCommand:cmd];
    }
    if (doesntContainHTML) {
        [self handleAssertDoesntContainHTMLCommand:cmd];
    }
    if (javaScriptEvalsTrue) {
        [self handleAssertJavaScriptEvalsTrueCommand:cmd];
    }
    if (javaScriptEvalsFalse) {
        [self handleAssertJavaScriptEvalsFalseCommand:cmd];
    }

    // just put in a little delay for good measure
    [self suspendCommand:cmd];
    [self resumeSuspendedCommandAfterDelay:DEFAULT_DELAY/4];
    
    return nil;
}


- (id)handleAssertPageTitleEqualsCommand:(NSScriptCommand *)cmd {
    if (![self pageTitleEquals:cmd]) {
        [cmd setScriptErrorNumber:47];
        [cmd setScriptErrorString:[NSString stringWithFormat:@"assertion failed in page «%@»: \npage title does not equal «%@»", [webView mainFrameURL], [[cmd arguments] objectForKey:@"titleEquals"]]];
        return nil;
    }
    
    return nil;
}


- (id)handleAssertHasElementWithIdCommand:(NSScriptCommand *)cmd {
    if (![self hasElementWithId:cmd]) {
        [cmd setScriptErrorNumber:47];
        [cmd setScriptErrorString:[NSString stringWithFormat:@"assertion failed in page «%@»: \npage does not have element with id «%@»", [webView mainFrameURL], [[cmd arguments] objectForKey:@"hasElementWithId"]]];
        return nil;
    }

    return nil;
}


- (id)handleAssertDoesntHaveElementWithIdCommand:(NSScriptCommand *)cmd {
    if (![self doesntHaveElementWithId:cmd]) {
        [cmd setScriptErrorNumber:47];
        [cmd setScriptErrorString:[NSString stringWithFormat:@"assertion failed in page «%@»: \npage has element with id «%@»", [webView mainFrameURL], [[cmd arguments] objectForKey:@"doesntHaveElementWithId"]]];
        return nil;
    }

    return nil;
}


- (id)handleAssertContainsTextCommand:(NSScriptCommand *)cmd {
    if (![self containsText:cmd]) {
        [cmd setScriptErrorNumber:47];
        [cmd setScriptErrorString:[NSString stringWithFormat:@"assertion failed in page «%@»: \npage doesn't contain text «%@»", [webView mainFrameURL], [[cmd arguments] objectForKey:@"containsText"]]];
        return nil;
    }

    return nil;
}


- (id)handleAssertDoesntContainTextCommand:(NSScriptCommand *)cmd {
    if (![self doesntContainText:cmd]) {
        [cmd setScriptErrorNumber:47];
        [cmd setScriptErrorString:[NSString stringWithFormat:@"assertion failed in page «%@»: \npage contains text «%@»", [webView mainFrameURL], [[cmd arguments] objectForKey:@"doesntContainText"]]];
        return nil;
    }

    return nil;
}


- (id)handleAssertContainsHTMLCommand:(NSScriptCommand *)cmd {
    if (![self containsHTML:cmd]) {
        [cmd setScriptErrorNumber:47];
        [cmd setScriptErrorString:[NSString stringWithFormat:@"assertion failed in page «%@»: \npage doesn't contain HTML «%@»", [webView mainFrameURL], [[cmd arguments] objectForKey:@"containsHTML"]]];
        return nil;
    }

    return nil;
}


- (id)handleAssertDoesntContainHTMLCommand:(NSScriptCommand *)cmd {    
    if (![self doesntContainHTML:cmd]) {
        [cmd setScriptErrorNumber:47];
        [cmd setScriptErrorString:[NSString stringWithFormat:@"assertion failed in page «%@»: \npage contains HTML «%@»", [webView mainFrameURL], [[cmd arguments] objectForKey:@"doesntContainHTML"]]];
        return nil;
    }
    
    return nil;
}


- (id)handleAssertJavaScriptEvalsTrueCommand:(NSScriptCommand *)cmd {
    if (![self javaScriptEvalsTrue:cmd]) {
        [cmd setScriptErrorNumber:47];
        [cmd setScriptErrorString:[NSString stringWithFormat:@"assertion failed in page «%@»: \nJavaScript doesn't evaluate true «%@»", [webView mainFrameURL], [[cmd arguments] objectForKey:@"javaScriptEvalsTrue"]]];
        return nil;
    }
    
    return nil;
}


- (id)handleAssertJavaScriptEvalsFalseCommand:(NSScriptCommand *)cmd {
    if (![self javaScriptEvalsFalse:cmd]) {
        [cmd setScriptErrorNumber:47];
        [cmd setScriptErrorString:[NSString stringWithFormat:@"assertion failed in page «%@»: \nJavaScript doesn't evaluate false «%@»", [webView mainFrameURL], [[cmd arguments] objectForKey:@"javaScriptEvalsFalse"]]];
        return nil;
    }
    
    return nil;
}


#pragma mark - 
#pragma mark Notifications

- (void)suspendExecutionUntilProgressFinishedWithCommand:(NSScriptCommand *)cmd {
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(tabControllerProgressDidFinish:) name:FUTabControllerProgressDidFinishNotification object:self];

    [self suspendCommand:cmd];
}


- (void)tabControllerProgressDidFinish:(NSNotification *)n {
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:self name:FUTabControllerProgressDidFinishNotification object:self];
    
    [self resumeSuspendedCommandAfterDelay:DEFAULT_DELAY];
}


- (void)suspendCommand:(NSScriptCommand *)cmd {
    self.suspendedCommand = cmd;
    [cmd suspendExecution];    
}


- (void)resumeSuspendedCommandAfterDelay:(NSTimeInterval)delay {
    // resume page applescript
    NSScriptCommand *cmd = [[suspendedCommand retain] autorelease];
    self.suspendedCommand = nil;
    
    [cmd performSelector:@selector(resumeExecutionWithResult:) withObject:nil afterDelay:delay];
}


#pragma mark - 
#pragma mark ScriptingPrivate

- (BOOL)isHTMLDocument:(NSScriptCommand *)cmd {
    DOMDocument *d = [webView mainFrameDocument];
    if (![d isKindOfClass:[DOMHTMLDocument class]]) {
        [cmd setScriptErrorNumber:47];
        [cmd setScriptErrorString:[NSString stringWithFormat:@"can only run script on HTML documents. this document is %@", d]];
        return NO;
    } else {
        return YES;
    }
}


- (NSMutableArray *)elementsWithTagName:(NSString *)tagName forArguments:(NSDictionary *)args {
    NSString *xpath = [args objectForKey:@"xpath"];
    NSString *identifier = [args objectForKey:@"identifier"];
    NSString *name = [args objectForKey:@"name"];
    NSString *text = [[args objectForKey:@"text"] lowercaseString];
    
    BOOL hasXPath = [xpath length];
    BOOL hasIdentifier = [identifier length];
    BOOL hasName = [name length];
    BOOL hasText = [text length];
    
    NSMutableArray *els = nil;
    if (hasXPath) {
        els = [self elementsForXPath:xpath];
    } else if (hasIdentifier && hasText) {
        els = [self elementsWithTagName:tagName andValue:identifier forAttribute:@"id"];
        els = [self elementsFromArray:els withText:text];
    } else if (hasName && hasText) {
        els = [self elementsWithTagName:tagName andValue:name forAttribute:@"name"];
        els = [self elementsFromArray:els withText:text];
    } else if (hasIdentifier) {
        // dont use getElementById:. not good enough for real-world html where multiple els with same id can exist
        els = [self elementsWithTagName:tagName andValue:identifier forAttribute:@"id"];
    } else if (hasName) {
        els = [self elementsWithTagName:tagName andValue:name forAttribute:@"name"];
    } else if (hasText) {
        els = [self elementsWithTagName:tagName andText:text];
    }
    
    return els;
}


- (NSMutableArray *)elementsForXPath:(NSString *)xpath {
    NSMutableArray *result = [NSMutableArray array];

    if ([xpath length]) {
        @try {
            DOMDocument *doc = [webView mainFrameDocument];
            DOMXPathResult *nodes = [doc evaluate:xpath contextNode:doc resolver:nil type:DOM_ORDERED_NODE_SNAPSHOT_TYPE inResult:nil];

            NSUInteger i = 0;
            NSUInteger count = [nodes snapshotLength];
            for ( ; i < count; i++) {
                DOMNode *node = [nodes snapshotItem:i];
                if ([node isKindOfClass:[DOMHTMLElement class]]) {
                    [result addObject:node];
                }
            }
        } @catch (NSException *e) {
            NSLog(@"error evaling XPath: %@", [e reason]);
            return nil;
        }
    }
    
    return result;
}


- (NSMutableArray *)elementsWithTagName:(NSString *)tagName andValue:(NSString *)attrVal forAttribute:(NSString *)attrName {
    NSMutableArray *result = [NSMutableArray array];
    
    DOMHTMLDocument *doc = (DOMHTMLDocument *)[webView mainFrameDocument];
    DOMNodeList *els = [doc getElementsByTagName:tagName];
    
    NSUInteger i = 0;
    NSUInteger count = [els length];
    for ( ; i < count; i++) {
        DOMHTMLElement *el = (DOMHTMLElement *)[els item:i];
        NSString *val = [el getAttribute:attrName];
        if (val && [val isEqualToString:attrVal]) {
            [result addObject:el];
        }
    }
    
    return result;
}


//- (NSMutableArray *)elementsWithTagName:(NSString *)tagName andAttributes:(NSDictionary *)attrs {
//    NSMutableArray *result = [NSMutableArray array];
//    
//    DOMHTMLDocument *doc = (DOMHTMLDocument *)[webView mainFrameDocument];
//    DOMNodeList *els = [doc getElementsByTagName:tagName];
//    
//    NSUInteger i = 0;
//    NSUInteger count = [els length];
//    for ( ; i < count; i++) {
//        DOMHTMLElement *el = (DOMHTMLElement *)[els item:i];
//        
//        BOOL matches = YES;
//
//        for (NSString *attrName in attrs) {
//            NSString *val = [el getAttribute:attrName];
//            NSString *attrVal = [attrs objectForKey:attrName];
//            if (![val isEqualToString:attrVal]) {
//                matches = NO;
//                break;
//            }
//        }
//        
//        if (matches) {
//            [result addObject:el];
//        }
//    }
//    
//    return result;
//}


- (NSMutableArray *)elementsWithTagName:(NSString *)tagName andText:(NSString *)text {
    text = [text lowercaseString];
    
    DOMHTMLDocument *doc = (DOMHTMLDocument *)[webView mainFrameDocument];
    DOMNodeList *nodeList = [doc getElementsByTagName:tagName];
    
    NSUInteger count = [nodeList length];
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:count];

    NSUInteger i = 0;
    for ( ; i < count; i++) {
        [result addObject:[nodeList item:i]];
    }

    result = [self elementsFromArray:result withText:text];

    return result;
}


- (NSMutableArray *)elementsFromArray:(NSMutableArray *)els withText:(NSString *)text {
    NSMutableArray *result = [NSMutableArray array];
    
    for (DOMHTMLElement *el in els) {
        NSString *currText = nil;
        if ([el isKindOfClass:[DOMHTMLInputElement class]]) {
            currText = [el getAttribute:@"value"];
        } else {
            currText = [el textContent];
        }
        
        NSMutableString *ms = [[currText mutableCopy] autorelease];
        CFStringTrimWhitespace((CFMutableStringRef)ms);
        
        if ([[ms lowercaseString] isEqualToString:text]) {
            [result addObject:el];
        }
    }
    
    return result;
}


- (NSArray *)arrayFromHTMLCollection:(DOMHTMLCollection *)collection {
    NSUInteger count = [collection length];
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:count];

    NSUInteger i = 0;
    for ( ; i < count; i++) {
        [result addObject:[collection item:i]];
    }
    
    return result;
}


#pragma mark -

- (BOOL)pageTitleEquals:(NSScriptCommand *)cmd {
    NSDictionary *args = [cmd arguments];
    NSString *expectedTitle = [args objectForKey:@"titleEquals"];
    
    BOOL result = [[webView mainFrameTitle] isEqualToString:expectedTitle];
    return result;
}


- (BOOL)hasElementWithId:(NSScriptCommand *)cmd {
    NSDictionary *args = [cmd arguments];
    NSString *identifier = [args objectForKey:@"hasElementWithId"];
    
    DOMHTMLDocument *doc = (DOMHTMLDocument *)[webView mainFrameDocument];
    DOMElement *el = [doc getElementById:identifier];

    return (el != nil);
}


- (BOOL)doesntHaveElementWithId:(NSScriptCommand *)cmd {
    NSDictionary *args = [cmd arguments];
    NSString *identifier = [args objectForKey:@"doesntHaveElementWithId"];
    
    DOMHTMLDocument *doc = (DOMHTMLDocument *)[webView mainFrameDocument];
    DOMElement *el = [doc getElementById:identifier];

    return (el == nil);
}


- (BOOL)containsText:(NSScriptCommand *)cmd {
    NSDictionary *args = [cmd arguments];
    NSString *text = [args objectForKey:@"containsText"];
    return [self pageContainsText:text];
}


- (BOOL)doesntContainText:(NSScriptCommand *)cmd {
    NSDictionary *args = [cmd arguments];
    NSString *text = [args objectForKey:@"doesntContainText"];
    return ![self pageContainsText:text];
}


- (BOOL)containsHTML:(NSScriptCommand *)cmd {
    NSDictionary *args = [cmd arguments];
    NSString *HTML = [args objectForKey:@"containsHTML"];
    return [self pageContainsHTML:HTML];
}


- (BOOL)doesntContainHTML:(NSScriptCommand *)cmd {
    NSDictionary *args = [cmd arguments];
    NSString *HTML = [args objectForKey:@"doesntContainHTML"];
    
    return ![self pageContainsHTML:HTML];
}


- (BOOL)javaScriptEvalsTrue:(NSScriptCommand *)cmd {
    NSDictionary *args = [cmd arguments];
    NSString *script = [args objectForKey:@"javaScriptEvalsTrue"];
    
    BOOL result = [[webView stringByEvaluatingJavaScriptFromString:script] boolValue];
    return result;
}


- (BOOL)javaScriptEvalsFalse:(NSScriptCommand *)cmd {
    NSDictionary *args = [cmd arguments];
    NSString *script = [args objectForKey:@"javaScriptEvalsFalse"];
    
    BOOL result = [[webView stringByEvaluatingJavaScriptFromString:script] boolValue];
    return !result;
}


#pragma mark -

- (BOOL)pageContainsText:(NSString *)text {
    DOMHTMLDocument *doc = (DOMHTMLDocument *)[webView mainFrameDocument];
    NSString *allText = [[doc body] textContent];
    
    NSRange r = [allText rangeOfString:text];
    BOOL containsText = NSNotFound != r.location;
    
    return containsText;
}


- (BOOL)pageContainsHTML:(NSString *)HTML {
    NSString *allHTML = [self documentSource];
    
    NSRange r = [allHTML rangeOfString:HTML];
    BOOL containsHTML = NSNotFound != r.location;
    
    return containsHTML;
}

@end
