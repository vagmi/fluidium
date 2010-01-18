//  Copyright 2009 Todd Ditchendorf
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.

#import <Cocoa/Cocoa.h>

@interface FUTabModel : NSObject {
    NSImage *image;
    NSImage *scaledImage;
    NSString *title;
    NSString *URLString;
    NSInteger index;
    CGFloat estimatedProgress;
    BOOL loading;
    BOOL selected;
    NSUInteger changeCount;
}

+ (FUTabModel *)modelWithPlist:(NSDictionary *)plist;

- (NSDictionary *)plist;

- (BOOL)wantsNewImage;

@property (nonatomic, retain) NSImage *image;
@property (nonatomic, retain) NSImage *scaledImage;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *URLString;
@property (nonatomic) NSInteger index;
@property (nonatomic) CGFloat estimatedProgress;
@property (nonatomic, getter=isLoading) BOOL loading;
@property (nonatomic, getter=isSelected) BOOL selected;
@end
