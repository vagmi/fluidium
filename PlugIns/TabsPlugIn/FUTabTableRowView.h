//
//  FUTabTableRowView.h
//  TabsPlugIn
//
//  Created by Todd Ditchendorf on 12/28/09.
//  Copyright 2009 Todd Ditchendorf. All rights reserved.
//

#import "TDTableRowView.h"

@class FUTabModel;

@interface FUTabTableRowView : TDTableRowView {
    FUTabModel *model;
}

+ (NSString *)identifier;

@property (nonatomic, retain) FUTabModel *model;
@end
