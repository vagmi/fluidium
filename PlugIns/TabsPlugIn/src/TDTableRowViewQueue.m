//
//  TDTableRowViewQueue.m
//  TabsPlugIn
//
//  Created by Todd Ditchendorf on 12/29/09.
//  Copyright 2009 Todd Ditchendorf. All rights reserved.
//

#import "TDTableRowViewQueue.h"
#import "TDTableRowView.h"s

@interface TDTableRowViewQueue ()
@property (nonatomic, retain) NSMutableDictionary *dict;
@end

@implementation TDTableRowViewQueue

- (id)init {
    if (self = [super init]) {
        self.dict = [NSMutableDictionary dictionary];
    }
    return self;
}


- (void)dealloc {
    self.dict = nil;
    [super dealloc];
}


- (NSString *)description {
    return [NSString stringWithFormat:@"<TDTableRowViewQueue %p %@>", self, dict];
}


- (BOOL)enqueue:(TDTableRowView *)rv withIdentifier:(NSString *)s {
    NSMutableSet *set = [dict objectForKey:s];
    if (!set) {
        set = [NSMutableSet set];
        [dict setObject:set forKey:s];
    }
    
    if ([set containsObject:rv]) {
        return NO;
    } else {
        [set addObject:rv];
        return YES;
    }
}


- (TDTableRowView *)dequeueWithIdentifier:(NSString *)s {
    TDTableRowView *rv = nil;
    
    NSMutableSet *set = [dict objectForKey:s];
    if (set) {
        NSAssert([set count], @"empty sets should be removed");
        rv = [[[set anyObject] retain] autorelease];
        [set removeObject:rv];
        
        if (![set count]) {
            [dict removeObjectForKey:s];
        }
    }
    
    return rv;
}

@synthesize dict;
@end



