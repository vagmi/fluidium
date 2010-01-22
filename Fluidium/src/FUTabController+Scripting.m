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
#import <WebKit/WebKit.h>

@interface FUTabController (ScriptingPrivate)
- (NSMutableArray *)elementsWithTagName:(NSString *)tagName forArguments:(NSDictionary *)args;
- (NSMutableArray *)elementsWithTagName:(NSString *)tagName andValue:(NSString *)attrVal forAttribute:(NSString *)attrName;
//- (NSMutableArray *)elementsWithTagName:(NSString *)tagName andAttributes:(NSDictionary *)attrs;
- (NSMutableArray *)elementsWithTagName:(NSString *)tagName andText:(NSString *)text;
- (NSMutableArray *)elementsForXPath:(NSString *)xpath;
- (NSMutableArray *)elementsFromArray:(NSMutableArray *)els withText:(NSString *)text;
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

- (id)handleLoadURLCommand:(NSScriptCommand *)cmd {
    NSString *s = [cmd directParameter];
    self.URLString = s;
    [self goToLocation:nil];
    return nil;
}


- (id)handleDoJavaScriptCommand:(NSScriptCommand *)cmd {
    NSString *script = [cmd directParameter];
    NSString *result = [webView stringByEvaluatingJavaScriptFromString:script];
    return [NSAppleEventDescriptor descriptorWithString:result];
}


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


- (id)handleClickLinkCommand:(NSScriptCommand *)cmd {
    DOMDocument *d = [webView mainFrameDocument];
    if (![d isKindOfClass:[DOMHTMLDocument class]]) {
        [cmd setScriptErrorNumber:47];
        [cmd setScriptErrorString:[NSString stringWithFormat:@"can only run script on HTML documents. this document is %@", d]];
        return nil;
    }

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
    
    NSString *href = [[anchorEl absoluteLinkURL] absoluteString];
    if ([href length]) {
        self.URLString = href;
        [self goToLocation:self];
    } else {
        [cmd setScriptErrorNumber:47];
        [cmd setScriptErrorString:@"found link element with no href"];
    }
    
    return nil;
}


- (id)handleClickButtonCommand:(NSScriptCommand *)cmd {
    DOMDocument *d = [webView mainFrameDocument];
    if (![d isKindOfClass:[DOMHTMLDocument class]]) {
        return nil;
    }
    
    DOMHTMLDocument *doc = (DOMHTMLDocument *)d;

    NSDictionary *args = [cmd arguments];
    
    NSMutableArray *inputEls = [self elementsWithTagName:@"input" forArguments:args];
    for (DOMHTMLElement *el in inputEls) {
        if ([el isKindOfClass:[DOMHTMLInputElement class]]) {
            DOMHTMLInputElement *inputEl = (DOMHTMLInputElement *)el;
            NSString *type = [[el getAttribute:@"type"] lowercaseString];
            if ([type isEqualToString:@"button"] || [type isEqualToString:@"submit"]) {
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
            
            // send it to the button
            [buttonEl dispatchEvent:evt];
            return nil;
        }
    }
    
    [cmd setScriptErrorNumber:47];
    [cmd setScriptErrorString:[NSString stringWithFormat:@"could not find button element with args: %@", args]];
    return nil;
}


#pragma mark - 
#pragma mark ScriptingPrivate

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
        
        if ([[currText lowercaseString] isEqualToString:text]) {
            [result addObject:el];
        }
    }
    
    return result;
}

@end
