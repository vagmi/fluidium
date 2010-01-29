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

#import "FUHandlerController.h"
#import "FUUserDefaults.h"
#import "FUUtils.h"
#import "NSString+FUAdditions.h"

#define KEY_SCHEME @"scheme"
#define KEY_URLSTRING @"URLString"

@implementation FUHandlerController

+ (FUHandlerController *)instance {
    static FUHandlerController *instance = nil;
    @synchronized (self) {
        if (!instance) {
            instance = [[FUHandlerController alloc] init];
        }
    }
    return instance;
}


- (id)init {
    if (self = [super init]) {
        [self loadHandlers];
    }
    return self;
}


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    self.handlers = nil;
    self.lookupTable = nil;
    [super dealloc];
}


- (void)save {
    [[FUUserDefaults instance] setHandlers:handlers];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self loadHandlers]; // sets up the lookupTable again
}


- (void)loadHandlers {
    self.handlers = [NSMutableArray arrayWithArray:[[FUUserDefaults instance] handlers]];
    
    if ([handlers count]) {
        self.lookupTable = [NSMutableDictionary dictionaryWithCapacity:[handlers count]];
        for (NSDictionary *handler in handlers) {
            NSString *scheme = [handler objectForKey:KEY_SCHEME];
            if (scheme) {
                [lookupTable setObject:handler forKey:scheme];
            }
        }
    }
}


- (NSURLRequest *)requestForRequest:(NSURLRequest *)req {
    if (!lookupTable) return req;
    
    NSString *scheme = [[req URL] scheme];
    
    NSDictionary *handler = [lookupTable objectForKey:scheme];
    if (handler) {
        NSString *inURLString = [[[req URL] absoluteString] substringFromIndex:[scheme length] + 1];
        NSString *replacement = [[handler objectForKey:KEY_URLSTRING] stringByAppendingString:inURLString];
        replacement = [replacement stringByEnsuringURLSchemePrefix];
        return [NSURLRequest requestWithURL:[NSURL URLWithString:replacement]];
    } else {
        return req;
    }
}

@synthesize handlers;
@synthesize lookupTable;
@end
