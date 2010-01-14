//
//  NSArray-OFExtensions.h
//  Fluidium
//
//  Created by Todd Ditchendorf on 1/13/10.
//  Copyright 2010 Todd Ditchendorf. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSArray (OFExtensions)
//- (NSUInteger)indexOfObjectIdenticalTo:(id)anObject;
- (NSUInteger)indexOfObject: (id) anObject identical:(BOOL)requireIdentity inArraySortedUsingFunction:(NSComparisonResult (*)(id, id, void *))comparator context:(void *)context;
- (NSUInteger)indexWhereObjectWouldBelong:(id)anObject inArraySortedUsingFunction:(NSComparisonResult (*)(id, id, void *))comparator context:(void *)context;

- (BOOL)containsObjectIdenticalTo:(id)anObject;
@end
