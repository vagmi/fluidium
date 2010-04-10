//
//  FooBarDemoAppDelegate.h
//  TDAppKit
//
//  Created by Todd Ditchendorf on 4/9/10.
//  Copyright 2010 Todd Ditchendorf. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <TDAppKit/TDAppKit.h>

@interface FooBarDemoAppDelegate : NSObject <TDFooBarDataSource> {
    IBOutlet NSWindow *window;
}

@end
