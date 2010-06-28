//
//  FakeDocument.m
//  Fluidium
//
//  Created by Todd Ditchendorf on 6/27/10.
//  Copyright 2010 Todd Ditchendorf. All rights reserved.
//

#import "FakeDocument.h"
#import "FUDocumentController.h"
#import "FUWindowController.h"
#import "FUTabController.h"
#import "FUWebView.h"
//#import "FakeWorkflow.h"
//#import "FakeViewController.h"
#import <WebKit/WebKit.h>

#define FAKE_WORKFLOW_TYPENAME @"Fake Workflow"

@interface NSObject (FakeCompilerWarnings)
- (id)workflowController;
- (id)workflow;
- (NSData *)archivedData;
- (void)setWorkflow:(id)workflow;
- (id)initWithData:(NSData *)data error:(NSError **)outErr;
@end

@interface FUDocumentController (FakeAdditions)

@end

@implementation FUDocumentController (FakeAdditions)

- (NSString *)defaultType {
    return FAKE_WORKFLOW_TYPENAME;
}

@end

@interface FUDocument ()
- (void)webPrintOperationDidRun:(NSPrintOperation *)op success:(BOOL)success contextInfo:(id)dv;
@end

@implementation FUDocument

- (void)dealloc {
    self.windowController = nil;
    self.workflow = nil;
    [super dealloc];
}


- (NSString *)description {
    return [NSString stringWithFormat:@"<FUDocument %p %@>", self, [[windowController window] title]];
}


- (void)windowControllerDidShowVisiblePlugIns:(FUWindowController *)wc {
    if (wc == [self windowController]) {
        id /*FakeViewController **/vc = /*(FakeViewController *)*/[wc plugInViewControllerForPlugInIdentifier:@"com.fakeapp.FakePlugIn"];
        [[vc workflowController] setWorkflow:workflow];
    }
}


#pragma mark -
#pragma mark NSDocument

//- (NSString *)displayName {
//    return [NSString stringWithFormat:@"%@ – %@", [super displayName], [[windowController selectedTabController] title]];
//}


- (void)makeWindowControllers {
    self.windowController = [[[FUWindowController alloc] init] autorelease];
    [self addWindowController:windowController];
}


//- (BOOL)isDocumentEdited {
//    return NO;
//}


//- (BOOL)readFromURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outErr {
//    if ([typeName isEqualToString:@"webarchive"]) {
//        NSData *data = [NSData dataWithContentsOfURL:absoluteURL];
//        WebArchive *archive = [[[WebArchive alloc] initWithData:data] autorelease];
//        [[[[[self windowController] selectedTabController] webView] mainFrame] loadArchive:archive];
//        return YES;
//    } else {
//        return [super readFromURL:absoluteURL ofType:typeName error:outErr];
//    }
//}
//
//
//- (BOOL)writeToURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outErr {
//    if ([typeName isEqualToString:@"webarchive"]) {
//        NSData *archiveData = [[[[[[windowController selectedTabController] webView] mainFrame] dataSource] webArchive] data];
//    
//        return [archiveData writeToURL:absoluteURL options:0 error:outErr];
//    } else {
//        return [super writeToURL:absoluteURL ofType:typeName error:outErr];
//    }
//}


- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outErr {
    if ([typeName isEqualToString:FAKE_WORKFLOW_TYPENAME]) {
        
        self.workflow = [[[NSClassFromString(@"FakeWorkflow") alloc] initWithData:data error:outErr] autorelease];
        
        if (workflow) {
            return YES;
        } else {
            return NO;
        }
    } else {
        return [super readFromData:data ofType:typeName error:outErr];
    }
}


- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outErr {
    if ([typeName isEqualToString:FAKE_WORKFLOW_TYPENAME]) {
        
        FUWindowController *wc = [self windowController];
        id /*FakeViewController **/vc = /*(FakeViewController *)*/[wc plugInViewControllerForPlugInIdentifier:@"com.fakeapp.FakePlugIn"];
        id wf = [[vc workflowController] workflow];
        
        return [wf archivedData];
    } else {
        return [super dataOfType:typeName error:outErr];
    }
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
@synthesize workflow;
@end
