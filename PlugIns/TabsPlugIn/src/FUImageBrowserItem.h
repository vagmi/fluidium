//
//  FUImageBrowserItem.h
//  TabsPlugIn
//
//  Created by Todd Ditchendorf on 12/25/09.
//  Copyright 2009 Todd Ditchendorf. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface FUImageBrowserItem : NSObject {
    NSString *imageUID;
    NSString *imageRepresentationType;
    id imageRepresentation;
    NSUInteger imageVersion;
    NSString *imageTitle;
    NSString *imageSubtitle;
    BOOL selectable;
}

@property (nonatomic, copy) NSString *imageUID;
@property (nonatomic, assign) NSString *imageRepresentationType;
@property (nonatomic, retain) id imageRepresentation;
@property (nonatomic, assign) NSUInteger imageVersion;
@property (nonatomic, copy) NSString *imageTitle;
@property (nonatomic, copy) NSString *imageSubtitle;
@property (nonatomic, getter=isSelectable) BOOL selectable;
@end
