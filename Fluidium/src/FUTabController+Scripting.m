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
    NSDictionary *args = [cmd arguments];
    
    NSString *identifier = [args objectForKey:@"identifier"];
    NSString *text = [args objectForKey:@"text"];
    
    DOMDocument *d = [webView mainFrameDocument];
    if (![d isKindOfClass:[DOMHTMLDocument class]]) {
        return nil;
    }
    
    DOMHTMLDocument *doc = (DOMHTMLDocument *)d;

    DOMElement *el = nil;
    if ([identifier length]) {
        el = [doc getElementById:identifier];
    } else if ([text length]) {
        text = [text lowercaseString];
        
		DOMNodeList *anchorEls = [doc getElementsByTagName:@"a"];
        
        NSUInteger i = 0;
        NSUInteger count = [anchorEls length];
		for ( ; i < count; i++) {
			DOMHTMLElement *currEl = (DOMHTMLElement *)[anchorEls item:i];
            NSString *txt = [currEl innerText];
			if ([text length] && [[txt lowercaseString] isEqualToString:text]) {
				el = currEl;
                break;
			}
		}
    }
    
    if (![el isKindOfClass:[DOMHTMLAnchorElement class]]) {
        return nil;
    }
    
    DOMHTMLAnchorElement *anchorEl = (DOMHTMLAnchorElement *)el;
    NSString *href = [anchorEl href];
    if ([href length]) {
        self.URLString = href;
        [self goToLocation:self];
    }
    return nil;
}

@end
