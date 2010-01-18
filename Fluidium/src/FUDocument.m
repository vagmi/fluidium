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

#import "FUDocument.h"
#import "FUWindowController.h"
#import <WebKit/WebKit.h>

@interface FUDocument ()
- (void)webPrintOperationDidRun:(NSPrintOperation *)op success:(BOOL)success contextInfo:(id)dv;
@end

@implementation FUDocument

- (void)dealloc {
    self.windowController = nil;
    [super dealloc];
}


- (NSString *)description {
    return [NSString stringWithFormat:@"<FUDocument %p %@>", self, [[windowController window] title]];
}


#pragma mark -
#pragma mark Cocoa scripting

- (NSScriptObjectSpecifier *)objectSpecifier {
    NSUInteger i = [[NSApp orderedDocuments] indexOfObjectIdenticalTo:self];
    
    if (NSNotFound == i) {
        return nil;
    } else {
        return [[[NSIndexSpecifier alloc] initWithContainerClassDescription:[NSScriptClassDescription classDescriptionForClass:[NSApp class]]
                                                         containerSpecifier:nil 
                                                                        key:@"orderedDocuments" 
                                                                      index:i] autorelease];
    }
}


- (NSArray *)orderedTabControllers {
    NSTabView *tabView = [windowController tabView];
    NSMutableArray *tabs = [NSMutableArray arrayWithCapacity:[tabView numberOfTabViewItems]];
    for (NSTabViewItem *tabItem in [tabView tabViewItems]) {
        [tabs addObject:[tabItem identifier]];
    }
    return [[tabs copy] autorelease];
}


- (NSUInteger)selectedTabIndex {
    return [windowController selectedTabIndex] + 1;
}


- (void)setSelectedTabIndex:(NSUInteger)i {
    [windowController setSelectedTabIndex:i - 1];
}


#pragma mark -
#pragma mark NSDocument

- (NSString *)displayName {
    return [[windowController selectedTabController] title];
}


- (void)makeWindowControllers {
    self.windowController = [[[FUWindowController alloc] init] autorelease];
    [self addWindowController:windowController];
}


- (BOOL)isDocumentEdited {
    return NO;
}


- (BOOL)readFromURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError {        
    if ([typeName isEqualToString:@"webarchive"]) {
        NSData *data = [NSData dataWithContentsOfURL:absoluteURL];
        WebArchive *archive = [[[WebArchive alloc] initWithData:data] autorelease];
        [[[[[self windowController] selectedTabController] webView] mainFrame] loadArchive:archive];
        return YES;
    } else {
        return [super readFromURL:absoluteURL ofType:typeName error:outError];
    }
}


- (BOOL)writeToURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError {
    NSData *archiveData = [[[[[[windowController selectedTabController] webView] mainFrame] dataSource] webArchive] data];
    
    return [archiveData writeToURL:absoluteURL options:0 error:outError];
}


#pragma mark -
#pragma mark Printing

- (void)printDocumentWithSettings:(NSDictionary *)settings showPrintPanel:(BOOL)show delegate:(id)delegate didPrintSelector:(SEL)sel contextInfo:(void *)ctx {
    WebView *wv = [[[self windowController] selectedTabController] webView];
    if (!wv) return;

    id dv = [[[wv mainFrame] frameView] documentView];
    [dv retain]; // retained
    
    NSPrintInfo *printInfo = [self printInfo];
    [printInfo setTopMargin:15];
    [printInfo setBottomMargin:15];
    [printInfo setLeftMargin:15];
    [printInfo setRightMargin:15];
    [printInfo setHorizontallyCentered:NO];
    [printInfo setVerticallyCentered:NO];
    
    // TODO prefs for print bg
    //  WebPreferences *preferences = [webView preferences];
    //    BOOL printBg = [preferences shouldPrintBackgrounds];
    
    NSPrintOperation *op = [NSPrintOperation printOperationWithView:dv printInfo:printInfo];
    [op setShowsPrintPanel:show];
    [op runOperationModalForWindow:[wv window]
                          delegate:self 
                    didRunSelector:@selector(webPrintOperationDidRun:success:contextInfo:) 
                       contextInfo:dv];
}


- (void)webPrintOperationDidRun:(NSPrintOperation *)op success:(BOOL)success contextInfo:(id)dv {
    [dv release]; // released
}

@synthesize windowController;
@end
