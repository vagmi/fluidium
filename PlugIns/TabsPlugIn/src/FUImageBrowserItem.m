//
//  FUImageBrowserItem.m
//  TabsPlugIn
//
//  Created by Todd Ditchendorf on 12/25/09.
//  Copyright 2009 Todd Ditchendorf. All rights reserved.
//

#import "FUImageBrowserItem.h"
#import <Quartz/Quartz.h>

@implementation FUImageBrowserItem

- (id)init {
    if (self = [super init]) {
        CFUUIDRef UUID = CFUUIDCreate(NULL);
        self.imageUID = [(id)CFUUIDCreateString(NULL, UUID) autorelease];
        CFRelease(UUID);
        
        self.imageRepresentationType = IKImageBrowserNSBitmapImageRepresentationType;
        self.selectable = YES;
        self.imageVersion = 0;
    }
    return self;
}


- (void)dealloc {
    self.imageUID = nil;
    self.imageRepresentationType = nil;
    self.imageRepresentation = nil;
    self.imageTitle = nil;
    self.imageSubtitle = nil;
    [super dealloc];
}


- (NSString *)description {
    return [NSString stringWithFormat:@"<FUImageBrowserItem %p %@>", self, imageTitle];
}


- (void)setImageRepresentation:(id)img {
    if (img != imageRepresentation) {
        [imageRepresentation autorelease];
        imageRepresentation = [img retain];
        
        self.imageVersion = ++imageVersion;
    }
}

@synthesize imageUID;
@synthesize imageRepresentationType;
@synthesize imageRepresentation;
@synthesize imageVersion;
@synthesize imageTitle;
@synthesize imageSubtitle;
@synthesize selectable;
@end
