//
//  FUTabTableRowView.h
//  TabsPlugIn
//
//  Created by Todd Ditchendorf on 12/28/09.
//  Copyright 2009 Todd Ditchendorf. All rights reserved.
//

#import "TDTableRowView.h"

@interface FUTabTableRowView : TDTableRowView {
    NSImage *thumbnail;
    NSString *title;
    NSString *URLString;
}

@property (nonatomic, retain) NSImage *thumbnail;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *URLString;
@end
