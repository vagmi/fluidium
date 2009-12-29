//
//  TDTableRowViewQueue.h
//  TabsPlugIn
//
//  Created by Todd Ditchendorf on 12/29/09.
//  Copyright 2009 Todd Ditchendorf. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class TDTableRowView;

@interface TDTableRowViewQueue : NSObject {
    NSMutableDictionary *dict;
}

- (BOOL)enqueue:(TDTableRowView *)rv withIdentifier:(NSString *)s;
- (TDTableRowView *)dequeueWithIdentifier:(NSString *)s;
@end
