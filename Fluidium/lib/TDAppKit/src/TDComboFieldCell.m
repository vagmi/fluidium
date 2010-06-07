//
//  TDComboFieldCell.m
//  TDAppKit
//
//  Created by Todd Ditchendorf on 6/7/10.
//  Copyright 2010 Todd Ditchendorf. All rights reserved.
//

#import "TDComboFieldCell.h"
#import "TDComboFieldTextView.h"
#import <TDAppKit/TDComboField.h>

@implementation TDComboFieldCell

#if FU_BUILD_TARGET_SNOW_LEOPARD
// for snow leopard
- (NSTextView *)fieldEditorForView:(NSView *)cv {
    if ([cv isMemberOfClass:[TDComboField class]]) {
        return [(TDComboField *)cv fieldEditor];
    } else {
        return [super fieldEditorForView:cv];
    }
}
#endif

@end
