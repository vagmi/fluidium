//
//  FUTabModel.h
//  TabsPlugIn
//
//  Created by Todd Ditchendorf on 12/27/09.
//  Copyright 2009 Todd Ditchendorf. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface FUTabModel : NSObject {
    NSImage *image;
    NSString *title;
    NSString *URLString;
}

@property (nonatomic, retain) NSImage *image;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *URLString;
@end
