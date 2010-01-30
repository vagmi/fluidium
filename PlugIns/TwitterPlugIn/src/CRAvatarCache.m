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
#import <TDAppKit/NSImage+TDAdditions.h>

#define KEY_URLSTRING @"URLString"
#define KEY_IMAGE @"image"

#define MAX_CACHE_SIZE 200

const CGFloat kCRAvatarSide = 44.0;
const CGFloat kCRAvatarCornerRadius = 5.0;

NSString *const CRAvatarDidLoadNotification = @"CRAvatarDidLoadNotification";

@interface CRAvatarCache ()
- (void)addAvatarForTweet:(CRTweet *)tweet sender:(id)sender;
- (void)fetch:(NSString *)URLString;
- (void)fetchInBackground:(NSString *)URLString;
- (void)doneFetching:(NSDictionary *)args;

@property (nonatomic, retain) NSMutableDictionary *cache;
@property (nonatomic, retain) NSMutableArray *keyAge;
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
        self.keyAge = [NSMutableArray array];
    }
    return self;
}


- (void)dealloc {
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    
    self.cache = nil;
    [super dealloc];
}


#pragma mark -
#pragma mark Private

- (NSImage *)avatarForTweet:(CRTweet *)tweet sender:(id)sender {
    id obj = nil;
    NSString *URLString = tweet.avatarURLString;

    @synchronized (cache) {
        obj = [cache objectForKey:URLString];
    }
    
    if (!obj) {
        // the avatar is not in the cache. fetch it
        [self addAvatarForTweet:tweet sender:sender];
        return nil;
        
    } else if ([NSNull null] == obj) {
        // the avatar is currently being fetched. do nothing and return nil
        return nil;
        
    } else {
        return obj;
    }
}


#pragma mark -
#pragma mark Private

- (void)addAvatarForTweet:(CRTweet *)tweet sender:(id)sender {
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:sender selector:@selector(avatarDidLoad:) name:CRAvatarDidLoadNotification object:tweet.avatarURLString];

    id obj = [NSNull null];
    NSString *URLString = tweet.avatarURLString;

    NSUInteger count = [keyAge count];
    NSString *evictKey = count ? [keyAge objectAtIndex:0] : nil;

    @synchronized (cache) {
        [cache setObject:obj forKey:URLString];
        [keyAge addObject:URLString];
        if (count >= MAX_CACHE_SIZE) {
            [cache removeObjectForKey:evictKey];
            [keyAge removeObjectAtIndex:0];
            NSLog(@"evicted. cache count: %d, keyAge count: %d", [cache count], [keyAge count]);
        }
    }
    
    [self fetch:URLString];
}


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
    [img setFlipped:YES];
    img = [img scaledImageOfSize:NSMakeSize(kCRAvatarSide, kCRAvatarSide) alpha:1 hiRez:YES cornerRadius:kCRAvatarCornerRadius];


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
@synthesize keyAge;
@end
