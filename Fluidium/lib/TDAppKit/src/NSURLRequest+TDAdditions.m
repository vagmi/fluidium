//  Copyright 2010 Todd Ditchendorf
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

#import <TDAppKit/NSURLRequest+TDAdditions.h>

@implementation NSURLRequest (TDAdditions)

- (NSDictionary *)formValues {
    NSMutableString *contentType = [NSMutableString stringWithString:[[self valueForHTTPHeaderField:@"Content-type"] lowercaseString]];
    CFStringTrimWhitespace((CFMutableStringRef)contentType);
    
    NSMutableDictionary *formValues = nil;

    if ([contentType isEqualToString:@"application/x-www-form-urlencoded"]) {
        
        NSString *body = [[[NSString alloc] initWithData:[self HTTPBody] encoding:NSUTF8StringEncoding] autorelease];

        // text=foo&more=&password=&select=one
        NSArray *pairs = [body componentsSeparatedByString:@"&"];
        for (NSString *pair in pairs) {
            NSRange r = [pair rangeOfString:@"="];
            if (NSNotFound != r.location) {
                NSString *name = [pair substringToIndex:r.location];
                NSString *value = [pair substringFromIndex:r.location + r.length];
                value = value ? value : @"";
                if (!formValues) {
                    formValues = [NSMutableDictionary dictionary];
                }
                [formValues setObject:value forKey:name];
            }
        }
    }
    
    return formValues;
}

@end
