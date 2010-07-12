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
#import "FUWildcardPattern.h"
#import "FUNotifications.h"
#import "FUUtils.h"
#import "DOMDocumentPrivate.h"
#import <WebKit/WebKit.h>
#import <TDAppKit/NSString+TDAdditions.h>

#define DEFAULT_DELAY 1.0

// wait for condition
#define KEY_START_DATE @"FUStartDate"
#define KEY_COMMAND @"FUCommand"
#define DEFAULT_TIMEOUT 60.0

@interface NSObject (FUScripting)
- (void)script_loadURL:(NSString *)s;
@end

@interface FUTabController (ScriptingPrivate)
- (void)resumeSuspendedCommandAfterTabControllerDidFailLoad:(NSNotification *)n;
- (void)resumeSuspendedCommandAfterTabControllerDidFinishLoad:(NSNotification *)n;
- (void)stopObservingLoad;

- (BOOL)isHTMLDocument:(NSScriptCommand *)cmd;

- (NSMutableArray *)elementsWithTagName:(NSString *)tagName forArguments:(NSDictionary *)args;
- (NSMutableArray *)elementsWithTagName:(NSString *)tagName andValue:(NSString *)attrVal forAttribute:(NSString *)attrName;
- (NSMutableArray *)elementsWithTagName:(NSString *)tagName andText:(NSString *)text;
- (NSMutableArray *)elementsForXPath:(NSString *)xpath;
- (DOMElement *)elementForCSSSelector:(NSString *)cssSelector;
- (NSMutableArray *)elementsForCSSSelector:(NSString *)cssSelector;
- (NSMutableArray *)elementsFromArray:(NSMutableArray *)els withText:(NSString *)text;
- (NSMutableArray *)arrayFromNodeList:(DOMNodeList *)list;
- (NSArray *)arrayFromHTMLCollection:(DOMHTMLCollection *)collection;
- (NSArray *)arrayFromHTMLOptionsCollection:(DOMHTMLOptionsCollection *)collection;
- (void)setValue:(NSString *)value forElement:(DOMElement *)el;
- (BOOL)boolForValue:(NSString *)value;
- (BOOL)isRadio:(DOMHTMLElement *)el;
- (BOOL)isMultiSelect:(DOMHTMLElement *)el;
- (BOOL)isCheckbox:(DOMHTMLElement *)el;
    
- (BOOL)titleEquals:(NSString *)cmd;
- (BOOL)statusCodeEquals:(NSInteger)aCode;
- (BOOL)hasElementWithId:(NSString *)cmd;
- (BOOL)hasElementForXPath:(NSString *)xpath;
- (BOOL)containsText:(NSString *)cmd;
- (BOOL)containsHTML:(NSString *)cmd;
- (BOOL)javaScriptEvalsTrue:(NSString *)cmd;

- (BOOL)pageContainsText:(NSString *)text;
- (BOOL)pageContainsHTML:(NSString *)HTML;

- (id)checkWaitForCondition:(NSDictionary *)info;

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
    if ([[self webView] canGoBack]) {
        [self suspendExecutionUntilProgressFinishedWithCommand:cmd];
        [self webGoBack:nil];
    } else {
        [cmd setScriptErrorNumber:kFUScriptErrorNumberCantGoBack];
        [cmd setScriptErrorString:NSLocalizedString(@"The selected tab cannot currently go back.", @"")];
    }

    return nil;
}


- (id)handleGoForwardCommand:(NSScriptCommand *)cmd {
    if ([[self webView] canGoForward]) {
        [self suspendExecutionUntilProgressFinishedWithCommand:cmd];
        [self webGoForward:nil];
    } else {
        [cmd setScriptErrorNumber:kFUScriptErrorNumberCantGoForward];
        [cmd setScriptErrorString:NSLocalizedString(@"The selected tab cannot currently go forward.", @"")];
    }
    
    return nil;
}


- (id)handleReloadCommand:(NSScriptCommand *)cmd {
    if ([[self webView] mainFrameURL]) {
        [self suspendExecutionUntilProgressFinishedWithCommand:cmd];
        [self webReload:nil];
    } else {
        [cmd setScriptErrorNumber:kFUScriptErrorNumberCantReload];
        [cmd setScriptErrorString:NSLocalizedString(@"The selected tab cannot currently reload.", @"")];
    }
    
    return nil;
}


- (id)handleStopLoadingCommand:(NSScriptCommand *)cmd {
    [self suspendExecutionUntilProgressFinishedWithCommand:cmd];
    [self webStopLoading:nil];
    return nil;
}


- (id)handleGoHomeCommand:(NSScriptCommand *)cmd {
    [self suspendExecutionUntilProgressFinishedWithCommand:cmd];
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
    if ([self respondsToSelector:@selector(script_loadURL:)]) {
        [self script_loadURL:s];
    } else {
        [self loadURL:s];
    }
    return nil;
}


- (id)handleDoJavaScriptCommand:(NSScriptCommand *)cmd {
    NSString *script = [cmd directParameter];
    NSString *prefix = @"__FU__";
    script = [NSString stringWithFormat:@"try{\n%@\n}catch(__e){return '%@'+__e;}", script, prefix];
    NSString *result = [webView stringByEvaluatingJavaScriptFromString:script];
    
    BOOL hasPrefix = [result hasPrefix:prefix];
    if (!result || hasPrefix) {
        if (hasPrefix) {
            result = [result substringFromIndex:[prefix length]];
        }
        [cmd setScriptErrorNumber:kFUScriptErrorNumberJavaScriptError];
        NSString *msg = NSLocalizedString(@"JavaScript encountered a fatal error", @"");
        if (result) {
            msg = [msg stringByAppendingFormat:@":\n\n'%@'", result];
        }
        [cmd setScriptErrorString:msg];
        return nil;
    }

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
        [cmd setScriptErrorNumber:kFUScriptErrorNumberElementNotFound];
        [cmd setScriptErrorString:[NSString stringWithFormat:NSLocalizedString(@"Could not find link element with args: %@", @""), args]];
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
    if (![args count]) {
        [cmd setScriptErrorNumber:kFUScriptErrorNumberInvalidArgument];
        [cmd setScriptErrorString:NSLocalizedString(@"The Click HTML Button Command requires an element specifier.", @"")];
        return nil;        
    }
    
    NSMutableArray *inputEls = [self elementsWithTagName:@"input" forArguments:args];
    for (DOMHTMLElement *el in inputEls) {
        if ([el isKindOfClass:[DOMHTMLInputElement class]]) {
            DOMHTMLInputElement *inputEl = (DOMHTMLInputElement *)el;
            NSString *type = [[el getAttribute:@"type"] lowercaseString];
            if ([type isEqualToString:@"button"] || [type isEqualToString:@"image"] || [type isEqualToString:@"submit"]) {
                
                [self suspendCommand:cmd];
                [self resumeSuspendedCommandAfterDelay:DEFAULT_DELAY];
                // register for next page load
                //[self suspendExecutionUntilProgressFinishedWithCommand:cmd];
                
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
    
    [cmd setScriptErrorNumber:kFUScriptErrorNumberElementNotFound];
    [cmd setScriptErrorString:[NSString stringWithFormat:NSLocalizedString(@"Could not find button element with args: %@", @""), args]];
    return nil;
}


- (id)handleSetElementValueCommand:(NSScriptCommand *)cmd {
    if (![self isHTMLDocument:cmd]) return nil;
    
    DOMHTMLDocument *doc = (DOMHTMLDocument *)[webView mainFrameDocument];
    
    NSDictionary *args = [cmd arguments];
    NSString *formName = [args objectForKey:@"formName"];
    NSString *formID = [args objectForKey:@"formID"];
    NSString *formXPath = [args objectForKey:@"formXPath"];
    NSString *formCSSSelector = [args objectForKey:@"formCSSSelector"];
    NSString *name = [args objectForKey:@"name"];
    NSString *identifier = [args objectForKey:@"identifier"];
    NSString *xpath = [args objectForKey:@"xpath"];
    NSString *cssSelector = [args objectForKey:@"cssSelector"];
    NSString *value = [args objectForKey:@"value"];
    
    DOMHTMLFormElement *formEl = nil;
    if ([formName length]) {
//        DOMHTMLCollection *formsCol = [doc forms];
//        NSUInteger formCount = [formsCol length];
//        NSMutableArray *a = [NSMutableArray arrayWithCapacity:formCount];
//        NSUInteger k = 0;
//        for ( ; k < formCount; k++) {
//            DOMHTMLFormElement *fe = (id)[formsCol item:k];
//            NSLog(@"form %@", fe);
//            NSLog(@"name %@", [fe name]);
//            NSLog(@"id %@", [fe getAttribute:@"id"]);
//            NSLog(@"meth %@", [fe method]);
//            [a addObject:fe];
//        }
        formEl = (DOMHTMLFormElement *)[[doc forms] namedItem:formName];
    } else if ([formID length]) {
        NSArray *els = [self elementsWithTagName:@"form" andValue:identifier forAttribute:@"id"];
        if ([els count]) formEl = [els objectAtIndex:0];
    } else if ([formXPath length]) {
        NSArray *els = [self elementsForXPath:formXPath];
        if ([els count]) {
            DOMElement *el = [els objectAtIndex:0];
            if ([el isKindOfClass:[DOMHTMLFormElement class]]) {
                formEl = (DOMHTMLFormElement *)el;
            }
        }
    } else if ([formCSSSelector length]) {
        DOMElement *el = [self elementForCSSSelector:cssSelector];
        if ([el isKindOfClass:[DOMHTMLFormElement class]]) {
            formEl = (DOMHTMLFormElement *)el;
        }
    }
    
    NSMutableArray *foundEls = nil;
    DOMElement *foundEl = nil;
    if ([name length]) {
        if (formEl) {
            NSArray *els = [self arrayFromHTMLCollection:[formEl elements]];
            foundEls = [NSMutableArray array];
            for (DOMHTMLElement *el in els) {
                if ([name isEqualToString:[el getAttribute:@"name"]]) {
                    [foundEls addObject:el];
                }
            }
        } else {
            foundEls = [self elementsForXPath:[NSString stringWithFormat:@"(//*[@name='%@'])[1]", name]];
        }
    } else if ([identifier length]) {
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
    } else if ([xpath length]) {
        NSArray *els = [self elementsForXPath:xpath];
        if ([els count]) foundEl = [els objectAtIndex:0];
    } else if ([cssSelector length]) {
        foundEl = [self elementForCSSSelector:cssSelector];
    } else {
        [cmd setScriptErrorNumber:kFUScriptErrorNumberInvalidArgument];
        [cmd setScriptErrorString:NSLocalizedString(@"The Set HTML Element Value Command requires an element specifier.", @"")];
        return nil;
    }
    
    if (![foundEls count] && foundEl) {
        foundEls = [NSArray arrayWithObject:foundEl];
    }
    
    BOOL setAVal = NO;
    if ([foundEls count]) {
        for (DOMHTMLElement *el in foundEls) {
            if ([self isRadio:el]) {
                if ([[el getAttribute:@"value"] isEqualToString:value]) {
                    setAVal = YES;
                    [self setValue:value forElement:el];
                }
            } else if ([self isMultiSelect:el]) {
                NSArray *dirtyVals = [value componentsSeparatedByString:@","];
                NSMutableArray *cleanVals = [NSMutableArray arrayWithCapacity:[dirtyVals count]];
                for (NSString *v in dirtyVals) {
                    v = [v stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                    if ([v length]) {
                        [cleanVals addObject:v];
                    }
                }
                
                DOMHTMLSelectElement *selectEl = (DOMHTMLSelectElement *)el;
                for (DOMHTMLOptionElement *optEl in [self arrayFromHTMLOptionsCollection:[selectEl options]]) {
                    setAVal = YES;
                    optEl.selected = [cleanVals containsObject:[optEl getAttribute:@"value"]];
                }
                
            } else if ([el isKindOfClass:[DOMHTMLElement class]]) {
                setAVal = YES;
                [self setValue:value forElement:el];
            }
        }
    }
    
    if (setAVal) {
        // just put in a little delay for good measure
        [self suspendCommand:cmd];
        // resume execution
        [self resumeSuspendedCommandAfterDelay:DEFAULT_DELAY];
        
    } else {
        [cmd setScriptErrorNumber:kFUScriptErrorNumberElementNotFound];
        [cmd setScriptErrorString:[NSString stringWithFormat:NSLocalizedString(@"Could not find element with args: %@", @""), args]];
    }
    return nil;
}


- (id)handleSubmitFormCommand:(NSScriptCommand *)cmd {
    if (![self isHTMLDocument:cmd]) return nil;
    
    DOMHTMLDocument *doc = (DOMHTMLDocument *)[webView mainFrameDocument];
    
    NSDictionary *args = [cmd arguments];
    NSString *name = [args objectForKey:@"name"];
    NSString *identifier = [args objectForKey:@"identifier"];
    NSString *xpath = [args objectForKey:@"xpath"];
    NSString *cssSelector = [args objectForKey:@"cssSelector"];
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
    } else if (cssSelector) {
        DOMElement *el = [self elementForCSSSelector:cssSelector];
        if ([el isKindOfClass:[DOMHTMLFormElement class]]) {
            formEl = (DOMHTMLFormElement *)el;
        }
    }
    
    if (!formEl) {
        [cmd setScriptErrorNumber:kFUScriptErrorNumberElementNotFound];
        [cmd setScriptErrorString:[NSString stringWithFormat:NSLocalizedString(@"Could not find form element with specifier: %@", @""), name]];
        return nil;
    }
    
    DOMHTMLCollection *els = [formEl elements];
    
    for (NSString *elName in values) {
        NSString *value = [values objectForKey:elName];
        
        DOMHTMLElement *el = (DOMHTMLElement *)[els namedItem:elName];
        if (!el) {
            [cmd setScriptErrorNumber:kFUScriptErrorNumberElementNotFound];
            [cmd setScriptErrorString:[NSString stringWithFormat:NSLocalizedString(@"Could not find input element with name: «%@» in form named : «%@»", @""), name, elName]];
            return nil;
        }
        [self setValue:value forElement:el];
    }
    
    [self suspendExecutionUntilProgressFinishedWithCommand:cmd];
    
    submittingFromScript = YES;
    [formEl submit];
    
    return nil;
}


- (id)handleAssertCommand:(NSScriptCommand *)cmd {
    if (![self isHTMLDocument:cmd]) return nil;
    
    NSDictionary *args = [cmd arguments];
    
    NSString *titleEquals = [args objectForKey:@"titleEquals"];
    NSString *statusCodeEquals = [args objectForKey:@"statusCodeEquals"];
    NSString *statusCodeNotEqual = [args objectForKey:@"statusCodeNotEqual"];
    NSString *hasElementWithId = [args objectForKey:@"hasElementWithId"];
    NSString *doesntHaveElementWithId = [args objectForKey:@"doesntHaveElementWithId"];
    NSString *hasElementForXPath = [args objectForKey:@"hasElementForXPath"];
    NSString *doesntHaveElementForXPath = [args objectForKey:@"doesntHaveElementForXPath"];
    NSString *containsText = [args objectForKey:@"containsText"];
    NSString *doesntContainText = [args objectForKey:@"doesntContainText"];
    NSString *javaScriptEvalsTrue = [args objectForKey:@"javaScriptEvalsTrue"];
    NSString *javaScriptEvalsFalse = [args objectForKey:@"javaScriptEvalsFalse"];
    
    id result = nil;
    
    if (titleEquals) {
        result = [self handleAssertTitleEqualsCommand:cmd];
    } else if (statusCodeEquals) {
        result = [self handleAssertStatusCodeEqualsCommand:cmd];
    } else if (statusCodeNotEqual) {
        result = [self handleAssertStatusCodeNotEqualCommand:cmd];
    } else if (hasElementWithId) {
        result = [self handleAssertHasElementWithIdCommand:cmd];
    } else if (doesntHaveElementWithId) {
        result = [self handleAssertDoesntHaveElementWithIdCommand:cmd];
    } else if (hasElementForXPath) {
        result = [self handleAssertHasElementForXPathCommand:cmd];
    } else if (doesntHaveElementForXPath) {
        result = [self handleAssertDoesntHaveElementForXPathCommand:cmd];
    } else if (containsText) {
        result = [self handleAssertContainsTextCommand:cmd];
    } else if (doesntContainText) {
        result = [self handleAssertDoesntContainTextCommand:cmd];
    } else if (javaScriptEvalsTrue) {
        result = [self handleAssertJavaScriptEvalsTrueCommand:cmd];
    } else if (javaScriptEvalsFalse) {
        result = [self handleAssertJavaScriptEvalsFalseCommand:cmd];
    }

//    // just put in a little delay for good measure
//    [self suspendCommand:cmd];
//    [self resumeSuspendedCommandAfterDelay:DEFAULT_DELAY/4];
    
    return result;
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
        [cmd setScriptErrorNumber:kFUScriptErrorNumberAssertionFailed];
        [cmd setScriptErrorString:[NSString stringWithFormat:NSLocalizedString(@"Assertion failed in page «%@» \n\nPage title does not equal «%@»", @""), [webView mainFrameURL], aTitle]];
        return nil;
    }
    
    return nil;
}


- (id)handleAssertStatusCodeEqualsCommand:(NSScriptCommand *)cmd {
    NSInteger aCode = [[[cmd arguments] objectForKey:@"statusCodeEquals"] integerValue];
    if (![self statusCodeEquals:aCode]) {
        [cmd setScriptErrorNumber:kFUScriptErrorNumberAssertionFailed];
        [cmd setScriptErrorString:[NSString stringWithFormat:NSLocalizedString(@"Assertion failed in page «%@» \n\nHTTP status code does not equal «%d»", @""), [webView mainFrameURL], aCode]];
        return nil;
    }
    
    return nil;
}


- (id)handleAssertStatusCodeNotEqualCommand:(NSScriptCommand *)cmd {
    NSInteger aCode = [[[cmd arguments] objectForKey:@"statusCodeNotEqual"] integerValue];
    if ([self statusCodeEquals:aCode]) {
        [cmd setScriptErrorNumber:kFUScriptErrorNumberAssertionFailed];
        [cmd setScriptErrorString:[NSString stringWithFormat:NSLocalizedString(@"Assertion failed in page «%@» \n\nHTTP status code equals «%d»", @""), [webView mainFrameURL], aCode]];
        return nil;
    }
    
    return nil;
}


- (id)handleAssertHasElementWithIdCommand:(NSScriptCommand *)cmd {
    NSString *identifier = [[cmd arguments] objectForKey:@"hasElementWithId"];
    if (![self hasElementWithId:identifier]) {
        [cmd setScriptErrorNumber:kFUScriptErrorNumberAssertionFailed];
        [cmd setScriptErrorString:[NSString stringWithFormat:NSLocalizedString(@"Assertion failed in page «%@» \n\nPage does not have element with id «%@»", @""), [webView mainFrameURL], identifier]];
        return nil;
    }

    return nil;
}


- (id)handleAssertDoesntHaveElementWithIdCommand:(NSScriptCommand *)cmd {
    NSString *identifier = [[cmd arguments] objectForKey:@"doesntHaveElementWithId"];
    if ([self hasElementWithId:identifier]) {
        [cmd setScriptErrorNumber:kFUScriptErrorNumberAssertionFailed];
        [cmd setScriptErrorString:[NSString stringWithFormat:NSLocalizedString(@"Assertion failed in page «%@» \n\nPage has element with id «%@»", @""), [webView mainFrameURL], identifier]];
        return nil;
    }

    return nil;
}


- (id)handleAssertHasElementForXPathCommand:(NSScriptCommand *)cmd {
    NSString *xpath = [[cmd arguments] objectForKey:@"hasElementForXPath"];
    if (![self hasElementForXPath:xpath]) {
        [cmd setScriptErrorNumber:kFUScriptErrorNumberAssertionFailed];
        [cmd setScriptErrorString:[NSString stringWithFormat:NSLocalizedString(@"Assertion failed in page «%@» \n\nPage does not have element for XPath «%@»", @""), [webView mainFrameURL], xpath]];
        return nil;
    }
    
    return nil;
}


- (id)handleAssertDoesntHaveElementForXPathCommand:(NSScriptCommand *)cmd {
    NSString *xpath = [[cmd arguments] objectForKey:@"doesntHaveElementForXPath"];
    if ([self hasElementForXPath:xpath]) {
        [cmd setScriptErrorNumber:kFUScriptErrorNumberAssertionFailed];
        [cmd setScriptErrorString:[NSString stringWithFormat:NSLocalizedString(@"Assertion failed in page «%@» \n\nPage has element for XPath «%@»", @""), [webView mainFrameURL], xpath]];
        return nil;
    }
    
    return nil;
}


- (id)handleAssertContainsTextCommand:(NSScriptCommand *)cmd {
    NSString *text = [[cmd arguments] objectForKey:@"containsText"];
    if (![self containsText:text]) {
        [cmd setScriptErrorNumber:kFUScriptErrorNumberAssertionFailed];
        [cmd setScriptErrorString:[NSString stringWithFormat:NSLocalizedString(@"Assertion failed in page «%@» \n\nPage doesn't contain text «%@»", @""), [webView mainFrameURL], text]];
        return nil;
    }

    return nil;
}


- (id)handleAssertDoesntContainTextCommand:(NSScriptCommand *)cmd {
    NSString *text = [[cmd arguments] objectForKey:@"doesntContainText"];
    if ([self containsText:text]) {
        [cmd setScriptErrorNumber:kFUScriptErrorNumberAssertionFailed];
        [cmd setScriptErrorString:[NSString stringWithFormat:NSLocalizedString(@"Assertion failed in page «%@» \n\nPage contains text «%@»", @""), [webView mainFrameURL], text]];
        return nil;
    }

    return nil;
}


- (id)handleAssertContainsHTMLCommand:(NSScriptCommand *)cmd {
    NSString *HTML = [[cmd arguments] objectForKey:@"containsHTML"];
    if (![self containsHTML:HTML]) {
        [cmd setScriptErrorNumber:kFUScriptErrorNumberAssertionFailed];
        [cmd setScriptErrorString:[NSString stringWithFormat:NSLocalizedString(@"Assertion failed in page «%@» \n\nPage doesn't contain HTML «%@»", @""), [webView mainFrameURL], HTML]];
        return nil;
    }

    return nil;
}


- (id)handleAssertDoesntContainHTMLCommand:(NSScriptCommand *)cmd {    
    NSString *HTML = [[cmd arguments] objectForKey:@"doesntContainHTML"];
    if ([self containsHTML:HTML]) {
        [cmd setScriptErrorNumber:kFUScriptErrorNumberAssertionFailed];
        [cmd setScriptErrorString:[NSString stringWithFormat:NSLocalizedString(@"Assertion failed in page «%@» \n\nPage contains HTML «%@»", @""), [webView mainFrameURL], HTML]];
        return nil;
    }
    
    return nil;
}


- (id)handleAssertJavaScriptEvalsTrueCommand:(NSScriptCommand *)cmd {
    NSString *script = [[cmd arguments] objectForKey:@"javaScriptEvalsTrue"];
    if (![self javaScriptEvalsTrue:script]) {
        [cmd setScriptErrorNumber:kFUScriptErrorNumberAssertionFailed];
        [cmd setScriptErrorString:[NSString stringWithFormat:NSLocalizedString(@"Assertion failed in page «%@» \n\nJavaScript doesn't evaluate true \n\n«%@»", @""), [webView mainFrameURL], script]];
        return nil;
    }
    
    return nil;
}


- (id)handleAssertJavaScriptEvalsFalseCommand:(NSScriptCommand *)cmd {
    NSString *script = [[cmd arguments] objectForKey:@"javaScriptEvalsFalse"];
    if ([self javaScriptEvalsTrue:script]) {
        [cmd setScriptErrorNumber:kFUScriptErrorNumberAssertionFailed];
        [cmd setScriptErrorString:[NSString stringWithFormat:NSLocalizedString(@"Assertion failed in page «%@» \n\nJavaScript doesn't evaluate false \n\n«%@»", @""), [webView mainFrameURL], script]];
        return nil;
    }
    
    return nil;
}


#pragma mark - 
#pragma mark Notifications

- (void)suspendExecutionUntilProgressFinishedWithCommand:(NSScriptCommand *)cmd {
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    //    [nc addObserver:self selector:@selector(resumeSuspendedCommandAfterTabControllerProgressDidFinish:) name:FUTabControllerProgressDidFinishNotification object:self];

    [nc addObserver:self selector:@selector(resumeSuspendedCommandAfterTabControllerDidFailLoad:) name:FUTabControllerDidFailLoadNotification object:self];
    [nc addObserver:self selector:@selector(resumeSuspendedCommandAfterTabControllerDidFinishLoad:) name:FUTabControllerDidFinishLoadNotification object:self];

    [self suspendCommand:cmd];
}


- (void)resumeSuspendedCommandAfterTabControllerDidFailLoad:(NSNotification *)n {
    [self stopObservingLoad];
    
    NSString *msg = [[n userInfo] objectForKey:FUErrorDescriptionKey];

    [suspendedCommand setScriptErrorNumber:kFUScriptErrorNumberLoadFailed];    
    [suspendedCommand setScriptErrorString:[NSString stringWithFormat:NSLocalizedString(@"Failed to load URL. Reason: %@", @""), msg]];
    
    [self resumeSuspendedCommandAfterDelay:DEFAULT_DELAY];
}


- (void)resumeSuspendedCommandAfterTabControllerDidFinishLoad:(NSNotification *)n {
    [self stopObservingLoad];
    
    [self resumeSuspendedCommandAfterDelay:DEFAULT_DELAY];
}


- (void)stopObservingLoad {
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:self name:FUTabControllerDidFailLoadNotification object:self];
    [nc removeObserver:self name:FUTabControllerDidFinishLoadNotification object:self];
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
        [cmd setScriptErrorNumber:kFUScriptErrorNumberNotHTMLDocument];
        NSString *s = [NSString stringWithFormat:NSLocalizedString(@"Can only run script on HTML documents. This document is %@.", @""), d ? [d description] : NSLocalizedString(@"empty", @"")];
        [cmd setScriptErrorString:s];
        return NO;
    } else {
        return YES;
    }
}


- (NSMutableArray *)elementsWithTagName:(NSString *)tagName forArguments:(NSDictionary *)args {
    NSString *xpath = [args objectForKey:@"xpath"];
    NSString *cssSelector = [args objectForKey:@"cssSelector"];
    NSString *identifier = [args objectForKey:@"identifier"];
    NSString *name = [args objectForKey:@"name"];
    NSString *text = [[args objectForKey:@"text"] lowercaseString];
    
    BOOL hasXPath = [xpath length];
    BOOL hasCSSSelector = [cssSelector length];
    BOOL hasIdentifier = [identifier length];
    BOOL hasName = [name length];
    BOOL hasText = [text length];
    
    NSMutableArray *els = nil;
    if (hasXPath) {
        els = [self elementsForXPath:xpath];
    } else if (hasCSSSelector) {
        els = [self elementsForCSSSelector:cssSelector];
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
            
            if (count) {
                for ( ; i < count; i++) {
                    DOMNode *node = [nodes snapshotItem:i];
                    if ([node isKindOfClass:[DOMHTMLElement class]]) {
                        [result addObject:node];
                    }
                }
            } else {
                // this is a hack cuz sometimes the xpath `(//form)[1]` doesnt work. dunno why
                SEL sel = NULL;
                NSString *formsPrefix = @"(//form)[";
                NSString *linksPrefix = @"(//*[href])[";
                //NSString *anchorsPrefix = @"(//a)[";
                //NSString *imagesPrefix = @"(//img)[";
                
                NSString *prefix = nil;
                if ([xpath hasPrefix:formsPrefix]) {
                    prefix = formsPrefix;
                    sel = @selector(forms);
                } else if ([xpath hasPrefix:linksPrefix]) {
                    prefix = linksPrefix;
                    sel = @selector(links);
//                } else if ([xpath hasPrefix:anchorsPrefix]) {
//                    prefix = anchorsPrefix;
//                    sel = @selector(anchors);
//                } else if ([xpath hasPrefix:imagesPrefix]) {
//                    prefix = imagesPrefix;
//                    sel = @selector(images);
                }

                if (prefix && [xpath hasSuffix:@"]"]) {
                    NSScanner *scanner = [NSScanner scannerWithString:xpath];
                    if ([scanner scanUpToCharactersFromSet:[NSCharacterSet decimalDigitCharacterSet] intoString:nil]) {
                        NSInteger idx;
                        if ([scanner scanInteger:&idx]) {
                            [result addObject:[[(DOMHTMLDocument *)doc performSelector:sel] item:idx]];
                        }
                    }
                }
            }
        } @catch (NSException *e) {
            NSLog(@"error evaling XPath: %@", [e reason]);
            return nil;
        }
    }
    
    return result;
}


- (DOMElement *)elementForCSSSelector:(NSString *)cssSelector {
    DOMElement *result = nil;
    
    if ([cssSelector length]) {
        @try {
            DOMDocument *doc = [webView mainFrameDocument];
            result = [doc querySelector:cssSelector];
            
        } @catch (NSException *e) {
            NSLog(@"error evaling CSS selector: %@", [e reason]);
            return nil;
        }
    }
    
    return result;
}


- (NSMutableArray *)elementsForCSSSelector:(NSString *)cssSelector {
    NSMutableArray *result = nil;
    
    if ([cssSelector length]) {
        @try {
            DOMDocument *doc = [webView mainFrameDocument];
            DOMNodeList *list = [doc querySelectorAll:cssSelector];
            result = [self arrayFromNodeList:list];
            
        } @catch (NSException *e) {
            NSLog(@"error evaling CSS selector: %@", [e reason]);
            return nil;
        }
    }
    
    return result;
}


- (NSMutableArray *)elementsWithTagName:(NSString *)tagName andValue:(NSString *)attrVal forAttribute:(NSString *)attrName {
    NSMutableArray *result = [NSMutableArray array];
    
    DOMHTMLDocument *doc = (DOMHTMLDocument *)[webView mainFrameDocument];
    NSArray *els = [self arrayFromNodeList:[doc getElementsByTagName:tagName]];
    
    for (DOMHTMLElement *el in els) {
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
    NSMutableArray *els = [self arrayFromNodeList:[doc getElementsByTagName:tagName]];
    NSMutableArray *result = [self elementsFromArray:els withText:text];

    return result;
}


- (NSMutableArray *)elementsFromArray:(NSMutableArray *)els withText:(NSString *)text {
    NSMutableArray *result = [NSMutableArray array];

    text = [[text lowercaseString] stringByReplacingWhitespaceWithStars];
    FUWildcardPattern *pattern = [FUWildcardPattern patternWithString:text];
    
    for (DOMHTMLElement *el in els) {
        NSString *currText = nil;
        if ([el isKindOfClass:[DOMHTMLInputElement class]]) {
            currText = [el getAttribute:@"value"];
        } else {
            currText = [el textContent];
        }
        
        currText = [currText stringByReplacingOccurrencesOfString:@"&nbsp;" withString:@" "];
        currText = [[currText lowercaseString] stringByReplacingWhitespaceWithStars];
        
//        if ([[ms lowercaseString] isEqualToString:text]) {
        if ([pattern isMatch:currText]) {
            [result addObject:el];
        }
        
    }
    
    return result;
}


- (NSArray *)arrayFromNodeList:(DOMNodeList *)list {
    NSUInteger count = [list length];
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:count];
    
    NSUInteger i = 0;
    for ( ; i < count; i++) {
        [result addObject:[list item:i]];
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


- (NSArray *)arrayFromHTMLOptionsCollection:(DOMHTMLOptionsCollection *)collection {
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
        if ([self isCheckbox:inputEl]) {
            [inputEl setAttribute:@"checked" value:(boolValue ? @"checked" : nil)];
            [inputEl setValue:(boolValue ? value : @"")];
            return;
        } else if ([self isRadio:inputEl]) {
            [inputEl setAttribute:@"checked" value:(boolValue ? @"checked" : nil)];
            [inputEl setValue:(boolValue ? value : @"")];
            return;
        }
    }
    [el setValue:value];
    
}


- (BOOL)isRadio:(DOMHTMLElement *)el {
    return [el isKindOfClass:[DOMHTMLInputElement class]] && [@"radio" isEqualToString:[el getAttribute:@"type"]];
}


- (BOOL)isCheckbox:(DOMHTMLElement *)el {
    return [el isKindOfClass:[DOMHTMLInputElement class]] && [@"checkbox" isEqualToString:[el getAttribute:@"type"]];
}


- (BOOL)isMultiSelect:(DOMHTMLElement *)el {
    if ([el isKindOfClass:[DOMHTMLSelectElement class]]) {
        DOMHTMLSelectElement *selEl = (DOMHTMLSelectElement *)el;
        return selEl.multiple;
    }
    return NO;
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
    //BOOL result = [[webView mainFrameTitle] isEqualToString:aTitle];

    //aTitle = [NSString stringWithFormat:@"*%@*", aTitle];
    FUWildcardPattern *pattern = [FUWildcardPattern patternWithString:aTitle];
    BOOL result = [pattern isMatch:[webView mainFrameTitle]];

    return result;
}


- (BOOL)statusCodeEquals:(NSInteger)aCode {
    NSURLResponse *res = [[[webView mainFrame] dataSource] response];
    if ([res isKindOfClass:[NSURLResponse class]]) {
        NSHTTPURLResponse *httpRes = (NSHTTPURLResponse *)res;
        BOOL result = [httpRes statusCode] == aCode;
        return result;
    } else {
        return NO;
    }
}


- (BOOL)hasElementWithId:(NSString *)identifier {
    DOMHTMLDocument *doc = (DOMHTMLDocument *)[webView mainFrameDocument];
    DOMElement *el = [doc getElementById:identifier];
    
    BOOL result = (el != nil);
    return result;
}


- (BOOL)hasElementForXPath:(NSString *)xpath {
    NSArray *els = [self elementsForXPath:xpath];
    BOOL result = ([els count] > 0);
    return result;
}


- (BOOL)containsText:(NSString *)text {    
    DOMHTMLDocument *doc = (DOMHTMLDocument *)[webView mainFrameDocument];
    NSString *allText = [[doc body] textContent];
    
//    NSRange r = [allText rangeOfString:text];
//    BOOL containsText = NSNotFound != r.location;
    
    text = [NSString stringWithFormat:@"*%@*", text];
    FUWildcardPattern *pattern = [FUWildcardPattern patternWithString:text];
    BOOL containsText = [pattern isMatch:allText];
    
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
//        [cmd setScriptErrorNumber:kFUScriptErrorNumberTimeout];
//        [cmd setScriptErrorString:[NSString stringWithFormat:@"conditions were not met before tiemout: «%@» in page : «%@»", args, [webView mainFrameURL]]];
        done = YES;
    } else {
        
        NSString *titleEquals = [args objectForKey:@"titleEquals"];
        NSString *hasElementWithId = [args objectForKey:@"hasElementWithId"];
        NSString *doesntHaveElementWithId = [args objectForKey:@"doesntHaveElementForXPath"];
        NSString *hasElementForXPath = [args objectForKey:@"hasElementWithId"];
        NSString *doesntHaveElementForXPath = [args objectForKey:@"doesntHaveElementForXPath"];
        NSString *containsText = [args objectForKey:@"containsText"];
        NSString *doesntContainText = [args objectForKey:@"doesntContainText"];
        NSString *javaScriptEvalsTrue = [args objectForKey:@"javaScriptEvalsTrue"];
        NSString *javaScriptEvalsFalse = [args objectForKey:@"javaScriptEvalsFalse"];
        
        BOOL titleEqualsDone = YES;
        BOOL hasElementWithIdDone = YES;
        BOOL doesntHaveElementWithIdDone = YES;
        BOOL hasElementForXPathDone = YES;
        BOOL doesntHaveElementForXPathDone = YES;
        BOOL containsTextDone = YES;
        BOOL doesntContainTextDone = YES;
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
        if (hasElementForXPath) {
            hasElementForXPathDone = [self hasElementForXPath:hasElementForXPath];
        }
        if (doesntHaveElementForXPath) {
            doesntHaveElementForXPathDone = ![self hasElementForXPath:doesntHaveElementForXPath];
        }
        if (containsText) {
            containsTextDone = [self containsText:containsText];
        }
        if (doesntContainText) {
            doesntContainTextDone = ![self containsText:doesntContainText];
        }
        if (javaScriptEvalsTrue) {
            javaScriptEvalsTrueDone = [self javaScriptEvalsTrue:javaScriptEvalsTrue];
        }
        if (javaScriptEvalsFalse) {
            javaScriptEvalsFalseDone = ![self javaScriptEvalsTrue:javaScriptEvalsFalse];
        }
        
        done = (titleEqualsDone && hasElementWithIdDone && doesntHaveElementWithIdDone &&
                hasElementForXPathDone && doesntHaveElementForXPathDone && containsTextDone && 
                doesntContainTextDone && javaScriptEvalsTrueDone && javaScriptEvalsFalseDone);
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