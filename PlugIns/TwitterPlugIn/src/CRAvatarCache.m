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

#import "CRAvatarCache.h"
#import "CRTweet.h"

#define KEY_URLSTRING @"URLString"
#define KEY_IMAGE @"image"

NSString *const CRAvatarDidLoadNotification = @"CRAvatarDidLoadNotification";

@interface CRAvatarCache ()
- (void)fetch:(NSString *)URLString;
- (void)fetchInBackground:(NSString *)URLString;
- (void)doneFetching:(NSDictionary *)args;

@property (nonatomic, retain) NSMutableDictionary *cache;
@end

@implementation CRAvatarCache

+ (CRAvatarCache *)instance {
    static CRAvatarCache *instance = nil;
    @synchronized (self) {
        if (!instance) {
            instance = [[CRAvatarCache alloc] init];
        }
    }
    return instance;
}


- (id)init {
    if (self = [super init]) {
        self.cache = [NSMutableDictionary dictionary];
    }
    return self;
}


- (void)dealloc {
    self.cache = nil;
    self.connection = nil;
    [super dealloc];
}


#pragma mark -
#pragma mark Private

- (void)addAvatarForTweet:(CRTweet *)tweet {
    NSString *URLString = tweet.avatarURLString;
    [cache setObject:[NSNull null] forKey:URLString];
    
    [self fetch:URLString];
}


- (NSImage *)avatarForTweet:(CRTweet *)tweet {
    id obj = nil;
    NSString *URLString = tweet.avatarURLString;

    @synchronized (cache) {
        obj = [cache objectForKey:URLString];
    }
    
    if ([NSNull null] == obj) {
        return nil;
    } else {
        return obj;
    }
}


#pragma mark -
#pragma mark Private

- (void)fetch:(NSString *)URLString {
    [NSThread detachNewThreadSelector:@selector(fetchInBackground:) toTarget:self withObject:URLString];
}


- (void)fetchInBackground:(NSString *)URLString {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    NSURLRequest *req = [NSURLRequest requestWithURL:[NSURL URLWithString:URLString]];

    NSError *err = nil;
    NSData *data = [NSURLConnection sendSynchronousRequest:req returningResponse:nil error:&err];

    if (!data) {
        NSLog(@"error fetching avatar: %@", err);
    }
    
    NSImage *img = [[[NSImage alloc] initWithData:data] autorelease];

    [self doneFetching:[NSDictionary dictionaryWithObjectsAndKeys:img, KEY_IMAGE, URLString, KEY_URLSTRING, nil]];
    
    [pool release];
}


- (void)doneFetching:(NSDictionary *)args {
    if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(doneFetching:) withObject:args waitUntilDone:NO];
        return;
    }
    
    NSString *URLString = [args objectForKey:KEY_URLSTRING];
    NSImage *img = [args objectForKey:KEY_IMAGE];
    
    @synchronized (cache) {
        [cache setObject:img forKey:URLString];
    }
    
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:CRAvatarDidLoadNotification object:URLString];
}

@synthesize cache;
@end
