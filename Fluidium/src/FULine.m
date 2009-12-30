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

#import "FULine.h"

@implementation FULine

- (id)initWithFrame:(NSRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.mainColor = [NSColor darkGrayColor];
        self.nonMainColor = [NSColor grayColor];
    }
    return self;
}


- (void)dealloc {
    self.mainColor = nil;
    self.nonMainColor = nil;
    [super dealloc];
}


- (void)drawRect:(NSRect)dirtyRect {
    NSColor *color = [[self window] isMainWindow] ? mainColor : nonMainColor;
    [color set];
    
    NSRectFill(dirtyRect);
}


- (void)awakeFromNib {
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(windowDidBecomeMain:) name:NSWindowDidBecomeMainNotification object:[self window]];
    [nc addObserver:self selector:@selector(windowDidResignMain:) name:NSWindowDidResignMainNotification object:[self window]];        
}


- (void)windowDidBecomeMain:(NSNotification *)n {
    [self setNeedsDisplay:YES];
}


- (void)windowDidResignMain:(NSNotification *)n {
    [self setNeedsDisplay:YES];
}

@synthesize mainColor;
@synthesize nonMainColor;
@end
