//
//  Adapted very slightly from BWTransparentScrollView.m
//  BWToolkit
//
//  Created by Brandon Walkin (www.brandonwalkin.com)
//  All code is provided under the New BSD license.
//

#import "TDScrollView.h"
#import "TDScroller.h"

@implementation TDScrollView

- (id)initWithCoder:(NSCoder *)decoder {
    if (self = [super initWithCoder:decoder]) {
		//if ([self respondsToSelector:@selector(ibTester)] == NO)
        //[self setDrawsBackground:NO];
	}
	return self;
}


+ (Class)_verticalScrollerClass {
	return [TDScroller class];
}

@end
