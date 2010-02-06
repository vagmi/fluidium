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
#import <objc/runtime.h>
#import <WebKit/WebKit.h>

//
#import "FUActivation.h"
#import "WebViewPrivate.h"
#import "NSAppleEventDescriptor+FUAdditions.h"
#import "NSAppleEventDescriptor+NDAppleScriptObject.h"

#define DEFAULT_DELAY 1.0

// wait for condition
#define KEY_START_DATE @"FUStartDate"
#define KEY_COMMAND @"FUCommand"
#define DEFAULT_TIMEOUT 60.0

typedef enum {
    WebNavigationTypePlugInRequest = WebNavigationTypeOther + 1
} WebExtraNavigationType;

@interface FUWindowController ()
- (void)handleCommandClick:(FUActivation *)act URL:(NSString *)s;
@end

@interface FUTabController (ScriptingPrivate)
- (BOOL)shouldHandleRequest:(NSURLRequest *)inReq;

- (void)script_submitForm:(NSURLRequest *)req withActionInfo:(NSDictionary *)info;

- (BOOL)isHTMLDocument:(NSScriptCommand *)cmd;

- (NSMutableArray *)elementsWithTagName:(NSString *)tagName forArguments:(NSDictionary *)args;
- (NSMutableArray *)elementsWithTagName:(NSString *)tagName andValue:(NSString *)attrVal forAttribute:(NSString *)attrName;
- (NSMutableArray *)elementsWithTagName:(NSString *)tagName andText:(NSString *)text;
- (NSMutableArray *)elementsForXPath:(NSString *)xpath;
- (NSMutableArray *)elementsFromArray:(NSMutableArray *)els withText:(NSString *)text;
- (NSArray *)arrayFromHTMLCollection:(DOMHTMLCollection *)collection;
- (void)setValue:(NSString *)value forElement:(DOMElement *)el;
- (BOOL)boolForValue:(NSString *)value;

- (BOOL)titleEquals:(NSString *)cmd;
- (BOOL)hasElementWithId:(NSString *)cmd;
- (BOOL)containsText:(NSString *)cmd;
- (BOOL)containsHTML:(NSString *)cmd;
- (BOOL)javaScriptEvalsTrue:(NSString *)cmd;

- (BOOL)pageContainsText:(NSString *)text;
- (BOOL)pageContainsHTML:(NSString *)HTML;

- (id)checkWaitForCondition:(NSDictionary *)info;

@property (nonatomic, retain) NSScriptCommand *suspendedCommand;
@end

@implementation FUTabController (Scripting)

+ (void)initialize {
    if ([FUTabController class] == self) {
        
        Method old = class_getInstanceMethod(self, @selector(loadURL:));
        Method new = class_getInstanceMethod(self, @selector(script_loadURL:));
        method_exchangeImplementations(old, new);
        
    }
}

    
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
#pragma mark Web Recording

- (void)webView:(WebView *)wv decidePolicyForNavigationAction:(NSDictionary *)info request:(NSURLRequest *)req frame:(WebFrame *)frame decisionListener:(id <WebPolicyDecisionListener>)listener {
    if (![self shouldHandleRequest:req]) {
        [listener ignore];
        return;
    }
    
    WebNavigationType navType = [[info objectForKey:WebActionNavigationTypeKey] integerValue];
    
    if ([WebView _canHandleRequest:req]) {
        
        NSString *s = [[req URL] absoluteString];

        switch (navType) {
            case WebNavigationTypeOther:
            case WebNavigationTypeBackForward:
            case WebNavigationTypeReload:
                [listener use];
                break;
            case WebNavigationTypeLinkClicked:
            {
                FUActivation *act = [FUActivation activationFromWebActionInfo:info];
                if (act.isCommandKeyPressed) {
                    [listener ignore];
                    [windowController handleCommandClick:act URL:s];
                } else {
                    [listener ignore];
                    [self loadURL:s];
                }
            }
                break;
            case WebNavigationTypeFormSubmitted:
            case WebNavigationTypeFormResubmitted:
                [listener ignore];
                [self script_submitForm:req withActionInfo:info];
//                [listener use];
                break;
            default:
                break;
        }
                     
    } else if (WebNavigationTypePlugInRequest == navType) {
        [listener use];
    } else {
        // A file URL shouldn't fall through to here, but if it did, it would be a security risk to open it.
        if (![[req URL] isFileURL]) {
            [[NSWorkspace sharedWorkspace] openURL:[req URL]];
        }
        [listener ignore];
    }
}


- (void)script_loadURL:(NSString *)s {
    NSAppleEventDescriptor *someAE = [NSAppleEventDescriptor appleEventForFluidiumEventID:'Load'];
    NSAppleEventDescriptor *tcDesc = [[self objectSpecifier] descriptor];
    [someAE setDescriptor:[NSAppleEventDescriptor descriptorWithString:s] forKeyword:keyDirectObject];
    [someAE setParamDescriptor:tcDesc forKeyword:'tPrm'];
    [someAE sendToOwnProcess];
}


- (void)script_submitForm:(NSURLRequest *)req withActionInfo:(NSDictionary *)info {
    NSAppleEventDescriptor *someAE = [NSAppleEventDescriptor appleEventForFluidiumEventID:'Sbmt'];
    NSAppleEventDescriptor *tcDesc = [[self objectSpecifier] descriptor];
    [someAE setDescriptor:tcDesc forKeyword:keyDirectObject];
    
    DOMHTMLFormElement *formEl = [info objectForKey:@"WebActionFormKey"];
    [someAE setParamDescriptor:[NSAppleEventDescriptor descriptorWithString:[formEl getAttribute:@"name"]] forKeyword:'Name'];
    
    NSMutableString *contentType = [NSMutableString stringWithString:[[req valueForHTTPHeaderField:@"Content-type"] lowercaseString]];
    CFStringTrimWhitespace((CFMutableStringRef)contentType);
    
    if ([contentType isEqualToString:@"application/x-www-form-urlencoded"]) {

        NSMutableDictionary *formValues = [NSMutableDictionary dictionary];

        NSString *body = [[[NSString alloc] initWithData:[req HTTPBody] encoding:NSUTF8StringEncoding] autorelease];
        // text=foo&more=&password=&select=one
        NSArray *pairs = [body componentsSeparatedByString:@"&"];
        for (NSString *pair in pairs) {
            NSRange r = [pair rangeOfString:@"="];
            if (NSNotFound != r.location) {
                NSString *name = [pair substringToIndex:r.location];
                NSString *value = [pair substringFromIndex:r.location + r.length];
                value = value ? value : @"";
                [formValues setObject:value forKey:name];
            }
        }

        // must turn dictionary into NSAppleEventDescriptor
        NSAppleEventDescriptor *formValuesDesc = [NSAppleEventDescriptor descriptorWithDictionary:formValues];
        [someAE setParamDescriptor:formValuesDesc forKeyword:'Vals'];
   }
    
    [someAE sendToOwnProcess];
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
    [self script_loadURL:s];
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
        formEl = (DOMHTMLFormElement *)[[doc forms] namedItem:formName];
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
                if ([[el getAttribute:@"id"] isEqualToString:identifier]) {
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
        [self setValue:value forElement:foundEl];
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
        [self setValue:value forElement:el];
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
        [self handleAssertTitleEqualsCommand:cmd];
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


- (id)handleWaitForConditionCommand:(NSScriptCommand *)cmd {
    if (![self isHTMLDocument:cmd]) return nil;

    // suspend
    [self suspendCommand:cmd];

    NSMutableDictionary *info = [NSMutableDictionary dictionaryWithCapacity:2];
    [info setObject:cmd forKey:KEY_COMMAND];
    [info setObject:[NSDate date] forKey:KEY_START_DATE];

    [self checkWaitForCondition:info];

    return nil;
} 


- (id)handleAssertTitleEqualsCommand:(NSScriptCommand *)cmd {
    NSString *aTitle = [[cmd arguments] objectForKey:@"titleEquals"];
    if (![self titleEquals:aTitle]) {
        [cmd setScriptErrorNumber:47];
        [cmd setScriptErrorString:[NSString stringWithFormat:@"assertion failed in page «%@»: \npage title does not equal «%@»", [webView mainFrameURL], aTitle]];
        return nil;
    }
    
    return nil;
}


- (id)handleAssertHasElementWithIdCommand:(NSScriptCommand *)cmd {
    NSString *identifier = [[cmd arguments] objectForKey:@"hasElementWithId"];
    if (![self hasElementWithId:identifier]) {
        [cmd setScriptErrorNumber:47];
        [cmd setScriptErrorString:[NSString stringWithFormat:@"assertion failed in page «%@»: \npage does not have element with id «%@»", [webView mainFrameURL], identifier]];
        return nil;
    }

    return nil;
}


- (id)handleAssertDoesntHaveElementWithIdCommand:(NSScriptCommand *)cmd {
    NSString *identifier = [[cmd arguments] objectForKey:@"doesntHaveElementWithId"];
    if ([self hasElementWithId:identifier]) {
        [cmd setScriptErrorNumber:47];
        [cmd setScriptErrorString:[NSString stringWithFormat:@"assertion failed in page «%@»: \npage has element with id «%@»", [webView mainFrameURL], identifier]];
        return nil;
    }

    return nil;
}


- (id)handleAssertContainsTextCommand:(NSScriptCommand *)cmd {
    NSString *text = [[cmd arguments] objectForKey:@"containsText"];
    if (![self containsText:text]) {
        [cmd setScriptErrorNumber:47];
        [cmd setScriptErrorString:[NSString stringWithFormat:@"assertion failed in page «%@»: \npage doesn't contain text «%@»", [webView mainFrameURL], text]];
        return nil;
    }

    return nil;
}


- (id)handleAssertDoesntContainTextCommand:(NSScriptCommand *)cmd {
    NSString *text = [[cmd arguments] objectForKey:@"doesntContainText"];
    if ([self containsText:text]) {
        [cmd setScriptErrorNumber:47];
        [cmd setScriptErrorString:[NSString stringWithFormat:@"assertion failed in page «%@»: \npage contains text «%@»", [webView mainFrameURL], text]];
        return nil;
    }

    return nil;
}


- (id)handleAssertContainsHTMLCommand:(NSScriptCommand *)cmd {
    NSString *HTML = [[cmd arguments] objectForKey:@"containsHTML"];
    if (![self containsHTML:HTML]) {
        [cmd setScriptErrorNumber:47];
        [cmd setScriptErrorString:[NSString stringWithFormat:@"assertion failed in page «%@»: \npage doesn't contain HTML «%@»", [webView mainFrameURL], HTML]];
        return nil;
    }

    return nil;
}


- (id)handleAssertDoesntContainHTMLCommand:(NSScriptCommand *)cmd {    
    NSString *HTML = [[cmd arguments] objectForKey:@"doesntContainHTML"];
    if ([self containsHTML:HTML]) {
        [cmd setScriptErrorNumber:47];
        [cmd setScriptErrorString:[NSString stringWithFormat:@"assertion failed in page «%@»: \npage contains HTML «%@»", [webView mainFrameURL], HTML]];
        return nil;
    }
    
    return nil;
}


- (id)handleAssertJavaScriptEvalsTrueCommand:(NSScriptCommand *)cmd {
    NSString *script = [[cmd arguments] objectForKey:@"javaScriptEvalsTrue"];
    if (![self javaScriptEvalsTrue:script]) {
        [cmd setScriptErrorNumber:47];
        [cmd setScriptErrorString:[NSString stringWithFormat:@"assertion failed in page «%@»: \nJavaScript doesn't evaluate true «%@»", [webView mainFrameURL], script]];
        return nil;
    }
    
    return nil;
}


- (id)handleAssertJavaScriptEvalsFalseCommand:(NSScriptCommand *)cmd {
    NSString *script = [[cmd arguments] objectForKey:@"javaScriptEvalsFalse"];
    if ([self javaScriptEvalsTrue:script]) {
        [cmd setScriptErrorNumber:47];
        [cmd setScriptErrorString:[NSString stringWithFormat:@"assertion failed in page «%@»: \nJavaScript doesn't evaluate false «%@»", [webView mainFrameURL], script]];
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


- (void)setValue:(NSString *)value forElement:(DOMElement *)el {
    if ([el isKindOfClass:[DOMHTMLInputElement class]]) {
        DOMHTMLInputElement *inputEl = (DOMHTMLInputElement *)el;
        
        BOOL boolValue = [self boolForValue:value];
        NSString *type = [inputEl type];
        if ([@"checkbox" isEqualToString:type]) {
            [inputEl setAttribute:@"checked" value:(boolValue ? @"checked" : nil)];
            [inputEl setValue:(boolValue ? value : @"")];
            return;
        } else if ([@"radio" isEqualToString:type]) {
            [inputEl setAttribute:@"checked" value:(boolValue ? @"checked" : nil)];
            [inputEl setValue:(boolValue ? value : @"")];
            return;
        }
    }
    [el setValue:value];
    
}


- (BOOL)boolForValue:(NSString *)value {
    value = [value lowercaseString];
    if (![value length] || [value isEqualToString:@"no"] || [value isEqualToString:@"false"] || [value isEqualToString:@"0"]) {
        return NO;
    } else {
        return YES;
    }
}


#pragma mark -

- (BOOL)titleEquals:(NSString *)aTitle {
    BOOL result = [[webView mainFrameTitle] isEqualToString:aTitle];
    return result;
}


- (BOOL)hasElementWithId:(NSString *)identifier {
    DOMHTMLDocument *doc = (DOMHTMLDocument *)[webView mainFrameDocument];
    DOMElement *el = [doc getElementById:identifier];

    BOOL result = (el != nil);
    return result;
}


- (BOOL)containsText:(NSString *)text {
    DOMHTMLDocument *doc = (DOMHTMLDocument *)[webView mainFrameDocument];
    NSString *allText = [[doc body] textContent];
    
    NSRange r = [allText rangeOfString:text];
    BOOL containsText = NSNotFound != r.location;
    
    return containsText;
}


- (BOOL)containsHTML:(NSString *)HTML {
    NSString *allHTML = [self documentSource];
    
    NSRange r = [allHTML rangeOfString:HTML];
    BOOL containsHTML = NSNotFound != r.location;
    
    return containsHTML;
}


- (BOOL)javaScriptEvalsTrue:(NSString *)script {
    BOOL result = [[webView stringByEvaluatingJavaScriptFromString:script] boolValue];
    return result;
}


- (id)checkWaitForCondition:(NSDictionary *)info {
    NSScriptCommand *cmd = [info objectForKey:KEY_COMMAND];
    NSDictionary *args = [cmd arguments];
    
    BOOL done = NO;
    NSTimeInterval timeout = DEFAULT_TIMEOUT;
    NSNumber *n = [args objectForKey:@"timeout"];
    if (n) {
        timeout = [n floatValue];
    }
    
    NSDate *startDate = [info objectForKey:KEY_START_DATE];
    NSAssert(startDate, @"should be a date");
    if (fabs([startDate timeIntervalSinceNow]) > timeout) {
//        [cmd setScriptErrorNumber:47];
//        [cmd setScriptErrorString:[NSString stringWithFormat:@"conditions were not met before tiemout: «%@» in page : «%@»", args, [webView mainFrameURL]]];
        done = YES;
    } else {
        
        NSString *titleEquals = [args objectForKey:@"titleEquals"];
        NSString *hasElementWithId = [args objectForKey:@"hasElementWithId"];
        NSString *doesntHaveElementWithId = [args objectForKey:@"doesntHaveElementWithId"];
        NSString *containsText = [args objectForKey:@"containsText"];
        NSString *doesntContainText = [args objectForKey:@"doesntContainText"];
        NSString *containsHTML = [args objectForKey:@"containsHTML"];
        NSString *doesntContainHTML = [args objectForKey:@"doesntContainHTML"];
        NSString *javaScriptEvalsTrue = [args objectForKey:@"javaScriptEvalsTrue"];
        NSString *javaScriptEvalsFalse = [args objectForKey:@"javaScriptEvalsFalse"];
        
        BOOL titleEqualsDone = YES;
        BOOL hasElementWithIdDone = YES;
        BOOL doesntHaveElementWithIdDone = YES;
        BOOL containsTextDone = YES;
        BOOL doesntContainTextDone = YES;
        BOOL containsHTMLDone = YES;
        BOOL doesntContainHTMLDone = YES;
        BOOL javaScriptEvalsTrueDone = YES;
        BOOL javaScriptEvalsFalseDone = YES;
        
        if (titleEquals) {
            titleEqualsDone = [self titleEquals:titleEquals];
        }
        if (hasElementWithId) {
            hasElementWithIdDone = [self hasElementWithId:hasElementWithId];
        }
        if (doesntHaveElementWithId) {
            doesntHaveElementWithIdDone = ![self hasElementWithId:doesntHaveElementWithId];
        }
        if (containsText) {
            containsTextDone = [self containsText:containsText];
        }
        if (doesntContainText) {
            doesntContainTextDone = ![self containsText:doesntContainText];
        }
        if (containsHTML) {
            containsHTMLDone = [self containsHTML:containsHTML];
        }
        if (doesntContainHTML) {
            doesntContainHTMLDone = ![self containsHTML:doesntContainHTML];
        }
        if (javaScriptEvalsTrue) {
            javaScriptEvalsTrueDone = [self javaScriptEvalsTrue:javaScriptEvalsTrue];
        }
        if (javaScriptEvalsFalse) {
            javaScriptEvalsFalseDone = ![self javaScriptEvalsTrue:javaScriptEvalsFalse];
        }
        
        done = (titleEqualsDone && hasElementWithIdDone && doesntHaveElementWithIdDone &&
                containsTextDone && doesntContainTextDone && containsHTMLDone && 
                doesntContainHTMLDone && javaScriptEvalsTrueDone && javaScriptEvalsFalseDone);
    }
    
    if (!done) {
        [self performSelector:@selector(checkWaitForCondition:) withObject:info afterDelay:2];
    } else {
        // just put in a little delay for good measure
        [self resumeSuspendedCommandAfterDelay:DEFAULT_DELAY/4];
    }
    
    return nil;
}

@end