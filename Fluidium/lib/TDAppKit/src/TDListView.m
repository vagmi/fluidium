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

#import <TDAppKit/TDListView.h>
#import <TDAppKit/TDListItemView.h>
#import "TDListItemViewQueue.h"

#define EXCEPTION_NAME @"TDListViewDataSourceException"
#define DEFAULT_ITEM_EXTENT 44

@interface TDListItemView ()
@property (nonatomic) NSUInteger index;
@end

@interface TDListView ()
- (void)layoutItems;
- (void)viewBoundsDidChange:(NSNotification *)n;

@property (nonatomic, retain) NSMutableArray *listItemViews;
@property (nonatomic, retain) TDListItemViewQueue *queue;
@end

@implementation TDListView

- (id)initWithFrame:(NSRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [NSColor whiteColor];
        self.itemExtent = DEFAULT_ITEM_EXTENT;
        
        self.listItemViews = [NSMutableArray array];
        self.queue = [[[TDListItemViewQueue alloc] init] autorelease];
        
        [self setPostsBoundsChangedNotifications:YES];
        
        [self setDraggingSourceOperationMask:NSDragOperationEvery forLocal:YES];
        [self setDraggingSourceOperationMask:NSDragOperationNone forLocal:NO];
    }
    return self;
}


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    self.scrollView = nil;
    self.dataSource = nil;
    self.delegate = nil;
    self.backgroundColor = nil;
    self.listItemViews = nil;
    self.queue = nil;
    [super dealloc];
}


- (void)awakeFromNib {
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(viewBoundsDidChange:) name:NSViewFrameDidChangeNotification object:[self superview]];
    [nc addObserver:self selector:@selector(viewBoundsDidChange:) name:NSViewBoundsDidChangeNotification object:[self superview]];
}


#pragma mark -
#pragma mark Notifications

- (void)viewBoundsDidChange:(NSNotification *)n {
    [self layoutItems];
}


#pragma mark -
#pragma mark Public

- (void)reloadData {
    [self layoutItems];
    [self setNeedsDisplay:YES];
}


- (id)dequeueReusableItemWithIdentifier:(NSString *)s {
    TDListItemView *itemView = [queue dequeueWithIdentifier:s];
    [itemView prepareForReuse];
    return itemView;
}


- (NSInteger)indexForItemAtPoint:(NSPoint)p {
    NSInteger i = 0;
    for (TDListItemView *itemView in listItemViews) {
        if (NSPointInRect(p, [itemView frame])) {
            return itemView.index;
        }
        i++;
    }
    return NSNotFound;
}


- (TDListItemView *)viewForItemAtIndex:(NSUInteger)i {
    for (TDListItemView *itemView in listItemViews) {
        if (itemView.index == i) {
            return itemView;
        }
    }
    
    return nil;
}


- (NSRect)frameForItemAtIndex:(NSUInteger)i {
    return [[self viewForItemAtIndex:i] frame];
}


- (void)setSelectedItemIndex:(NSInteger)i {
    if (i != selectedItemIndex) {
        if (delegate && [delegate respondsToSelector:@selector(listView:willSelectItemAtIndex:)]) {
            if (-1 == [delegate listView:self willSelectItemAtIndex:i]) {
                return;
            }
        }
        
        selectedItemIndex = i;
        [self reloadData];
        
        if (delegate && [delegate respondsToSelector:@selector(listView:didSelectItemAtIndex:)]) {
            [delegate listView:self didSelectItemAtIndex:i];
        }
    }
}


- (BOOL)isPortrait {
    return TDListViewOrientationPortrait == orientation;
}


- (BOOL)isLandscape {
    return TDListViewOrientationLandscape == orientation;
}


#pragma mark -
#pragma mark Drag and Drop

- (NSDragOperation)draggingSourceOperationMaskForLocal:(BOOL)isLocal {
    return isLocal ? localDragOperationMask : nonLocalDragOperationMask;
    //return (NSDragOperationMove|NSDragOperationDelete);
}


- (void)setDraggingSourceOperationMask:(NSDragOperation)mask forLocal:(BOOL)localDestination {
    if (localDestination) {
        localDragOperationMask = mask;
    } else {
        nonLocalDragOperationMask = mask;
    }
}


- (NSImage *)draggingImageForItemAtIndex:(NSInteger)i withEvent:(NSEvent *)evt offset:(NSPointPointer)dragImageOffset {
    TDListItemView *itemView = [self viewForItemAtIndex:i];
    NSRect r = [itemView frame];
    NSBitmapImageRep *bitmap = [self bitmapImageRepForCachingDisplayInRect:r];
    [self cacheDisplayInRect:r toBitmapImageRep:bitmap];

    NSSize imgSize = [bitmap size];
    NSImage *img = [[[NSImage alloc] initWithSize:imgSize] autorelease];
    [img addRepresentation:bitmap];

    if (dragImageOffset) {
        NSPoint p = NSMakePoint(imgSize.width / 2, imgSize.height / 2);
        *dragImageOffset = p;
    }
    
    return img;
}


- (void)mouseDragged:(NSEvent *)evt {
    NSLog(@"%s", _cmd);
    NSPasteboard *pboard = [NSPasteboard pasteboardWithName:NSDragPboard];
    
    NSPoint p = [self convertPoint:[evt locationInWindow] fromView:nil];
    NSUInteger i = [self indexForItemAtPoint:p];
    
    p = NSZeroPoint;
    NSImage *dragImage = [self draggingImageForItemAtIndex:i withEvent:evt offset:&p];
    NSPoint dragPosition = [self convertPoint:[evt locationInWindow] fromView:nil];

    dragPosition.x -= p.x;
    dragPosition.y += p.y;

    [self dragImage:dragImage
                 at:dragPosition
             offset:NSZeroSize
              event:evt
         pasteboard:pboard
             source:self
          slideBack:NO];
}


//- (void)draggedImage:(NSImage *)image endedAt:(NSPoint)endPoint operation:(NSDragOperation)op {
//    NSPoint p = [[bookmarkBar window] convertScreenToBase:endPoint];
//    CGFloat delta = ICON_SIDE / 2;
//    p.x += delta;
//    p.y += delta;
//
//    if (!NSPointInRect(p, [bookmarkBar frame])) {
//        endPoint.x += delta;
//        endPoint.y += delta;
//        [NSToolbarPoofAnimator runPoofAtPoint:endPoint];
//    }
//
//    [bookmarkBar finishedDraggingButton];
//}
//

#pragma mark -
#pragma mark NSView

- (BOOL)isFlipped {
    return YES;
}


- (BOOL)acceptsFirstResponder {
    return YES;
}


- (void)mouseDown:(NSEvent *)evt {
    [super mouseDown:evt];
    
    NSPoint pInWin = [evt locationInWindow];
    NSPoint p = [self convertPoint:pInWin fromView:nil];
    
    NSInteger i = [self indexForItemAtPoint:p];
    if (NSNotFound == i) {
        if ([evt clickCount] > 1) {
            if (delegate && [delegate respondsToSelector:@selector(listView:emptyAreaWasDoubleClicked:)]) {
                [delegate listView:self emptyAreaWasDoubleClicked:evt];
            }
        }
    } else {
        self.selectedItemIndex = i;
    }

//    BOOL keepOn = YES;
//    NSInteger radius = 20;
//    NSRect r = NSMakeRect(pInWin.x - radius, pInWin.y - radius, radius * 2, radius * 2);
//    
//    while (keepOn) {
//        evt = [[self window] nextEventMatchingMask:NSLeftMouseUpMask|NSLeftMouseDraggedMask];
//        
//        switch ([evt type]) {
//            case NSLeftMouseDragged:
//                if (NSPointInRect([evt locationInWindow], r)) {
//                    break;
//                }
//                [self mouseDragged:evt];
//                keepOn = NO;
//                break;
//            case NSLeftMouseUp:
//                keepOn = NO;
//                [super mouseDown:evt];
//                break;
//            default:
//                break;
//        }
//    }
}


- (void)drawRect:(NSRect)dirtyRect {
    [backgroundColor set];
    NSRectFill(dirtyRect);
}


#pragma mark -
#pragma mark Private

- (NSRect)visibleRect {
    return [[self superview] bounds];
}


// TODO make -resizeSubviewsWithOldSize: ???
- (void)layoutItems {
    if (!dataSource) {
        [NSException raise:EXCEPTION_NAME format:@"TDListView must have a dataSource before doing layout"];
    }

    NSEnumerator *e = [listItemViews reverseObjectEnumerator];
    TDListItemView *itemView = nil;
    while (itemView = [e nextObject]) {
        [queue enqueue:itemView];
        [itemView removeFromSuperview];
        [listItemViews removeLastObject];
    }
    
    NSRect viewportRect = [self visibleRect];
    BOOL isPortrait = self.isPortrait;
    
    CGFloat x = itemMargin;
    CGFloat y = 0;
    CGFloat w = isPortrait ? viewportRect.size.width : 0;
    CGFloat h = isPortrait ? 0 : viewportRect.size.height;
    
    NSInteger c = [dataSource numberOfItemsInListView:self];
    BOOL respondsToExtentForItem = (delegate && [delegate respondsToSelector:@selector(listView:extentForItemAtIndex:)]);
    
    NSInteger i = 0;
    for ( ; i < c; i++) {
        // determine item frame
        NSInteger extent = respondsToExtentForItem ? [delegate listView:self extentForItemAtIndex:i] : itemExtent;
        if (isPortrait) {
            h = extent;
        } else {
            w = extent;
        }
        NSRect itemFrame = NSMakeRect(x, y, w, h);
        
        // if the item is visible...
        BOOL isItemVisible = NO;
        if (displaysTruncatedItems) {
            isItemVisible = NSIntersectsRect(viewportRect, itemFrame);
        } else {
            isItemVisible = NSContainsRect(viewportRect, itemFrame);
        }

        if (isItemVisible) {
            TDListItemView *itemView = [dataSource listView:self viewForItemAtIndex:i];
            if (!itemView) {
                [NSException raise:EXCEPTION_NAME format:@"nil list item view returned for index: %d by: %@", i, dataSource];
            }
            [itemView setFrame:NSMakeRect(x, y, w, h)];
            itemView.index = i;            
            [self addSubview:itemView];
            [listItemViews addObject:itemView];
        }

        if (isPortrait) {
            y += extent + itemMargin; // add height for next row
        } else {
            x += extent + itemMargin;
        }
    }
    
    NSRect frame = [self frame];
    if (isPortrait) {
        y = y < viewportRect.size.height ? viewportRect.size.height : y;
        frame.size.height = y;
    } else {
        x = x < viewportRect.size.width ? viewportRect.size.width : x;
        frame.size.width = x;
    }
    [self setFrame:frame];
    
    //NSLog(@"%s my bounds: %@, viewport bounds: %@", _cmd, NSStringFromRect([self bounds]), NSStringFromRect([superview bounds]));
    //NSLog(@"view count: %d, queue count: %d", [listItemViews count], [queue count]);
}

@synthesize scrollView;
@synthesize dataSource;
@synthesize delegate;
@synthesize backgroundColor;
@synthesize itemExtent;
@synthesize itemMargin;
@synthesize selectedItemIndex;
@synthesize orientation;
@synthesize listItemViews;
@synthesize queue;
@synthesize displaysTruncatedItems;
@end
