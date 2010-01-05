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
#define DRAG_RADIUS 20

@interface NSToolbarPoofAnimator
+ (void)runPoofAtPoint:(NSPoint)p;
@end

@interface TDListItemView ()
@property (nonatomic) NSUInteger index;
@end

@interface TDListView ()
- (void)layoutItems;
- (void)superviewRectDidChange:(NSNotification *)n;

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
        
        self.displaysClippedItems = YES;
        
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
    [nc addObserver:self selector:@selector(superviewRectDidChange:) name:NSViewFrameDidChangeNotification object:[self superview]];
    [nc addObserver:self selector:@selector(superviewRectDidChange:) name:NSViewBoundsDidChangeNotification object:[self superview]];
}


#pragma mark -
#pragma mark Notifications

- (void)superviewRectDidChange:(NSNotification *)n {
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
    return -1;
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
        if (-1 != i) { // dont consult delegate if we are deselecting
            if (delegate && [delegate respondsToSelector:@selector(listView:willSelectItemAtIndex:)]) {
                if (-1 == [delegate listView:self willSelectItemAtIndex:i]) {
                    return;
                }
            }
        }
        
        selectedItemIndex = i;
        [self reloadData];
        
        if (selectedItemIndex > -1 && delegate && [delegate respondsToSelector:@selector(listView:didSelectItemAtIndex:)]) {
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
#pragma mark DraggingSource

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


- (BOOL)ignoreModifierKeysWhileDragging {
    return YES;
}


- (NSImage *)draggingImageForItemAtIndex:(NSInteger)i withEvent:(NSEvent *)evt offset:(NSPointPointer)dragImageOffset {
    TDListItemView *itemView = [self viewForItemAtIndex:i];
    NSRect r = [itemView bounds];
    NSBitmapImageRep *bitmap = [itemView bitmapImageRepForCachingDisplayInRect:r];
    [itemView cacheDisplayInRect:r toBitmapImageRep:bitmap];
    
    NSSize imgSize = [bitmap size];
    NSImage *img = [[[NSImage alloc] initWithSize:imgSize] autorelease];
    [img addRepresentation:bitmap];
    
    NSImage *result = [[[NSImage alloc] initWithSize:imgSize] autorelease];
    [result lockFocus];
    NSGraphicsContext *currentContext = [NSGraphicsContext currentContext];
    NSImageInterpolation savedInterpolation = [currentContext imageInterpolation];
    [currentContext setImageInterpolation:NSImageInterpolationHigh];
    [img drawInRect:NSMakeRect(0, 0, imgSize.width, imgSize.height) fromRect:NSMakeRect(0, 0, imgSize.width, imgSize.height) operation:NSCompositeSourceOver fraction:.5];
    [currentContext setImageInterpolation:savedInterpolation];
    [result unlockFocus];

    if (dragImageOffset) {
        NSPoint p = [itemView convertPoint:[evt locationInWindow] fromView:nil];
        *dragImageOffset = NSMakePoint(p.x, NSHeight([itemView frame]) - p.y);
    }
    
    return result;
}


- (void)draggedImage:(NSImage *)image endedAt:(NSPoint)endPointInScreen operation:(NSDragOperation)op {
    // screen origin is lower left
    endPointInScreen.x += dragOffset.x;
    endPointInScreen.y += dragOffset.y;

    // window origin is lower left
    NSPoint endPointInWin = [[self window] convertScreenToBase:endPointInScreen];

    // get frame of visible portion of list view in window coords
    NSRect dropZone = [self convertRect:[self visibleRect] toView:nil];
    
    if (!NSPointInRect(endPointInWin, dropZone)) {
        [NSToolbarPoofAnimator runPoofAtPoint:endPointInScreen];
    }
}



#pragma mark -
#pragma mark NSDraggingDestination

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)dragInfo {
    NSPasteboard *pboard = [dragInfo draggingPasteboard];
    NSDragOperation srcMask = [dragInfo draggingSourceOperationMask];
    
    if ([[pboard types] containsObject:NSColorPboardType]) {
        if (srcMask & NSDragOperationMove) {
            return NSDragOperationMove;
        }
    }

    return NSDragOperationNone;
}


/* if the destination responded to draggingEntered: but not to draggingUpdated: the return value from draggingEntered: is used */
- (NSDragOperation)draggingUpdated:(id <NSDraggingInfo>)dragInfo {
    if (!delegate || ![delegate respondsToSelector:@selector(listView:validateDrop:proposedIndex:dropOperation:)]) {
        return NSDragOperationNone;
    }
    
    NSDragOperation dragOp = NSDragOperationNone;
    
    NSPoint locInWin = [dragInfo draggingLocation];
    NSPoint locInList = [self convertPoint:locInWin fromView:nil];
    dropIndex = [self indexForItemAtPoint:locInList];
    TDListItemView *itemView = [self viewForItemAtIndex:dropIndex];
    NSPoint locInItem = [itemView convertPoint:locInWin fromView:nil];

    NSRect itemBounds = [itemView bounds];
    NSRect front, back;
    
    if (self.isPortrait) {
        front = NSMakeRect(itemBounds.origin.x, itemBounds.origin.y, itemBounds.size.width, itemBounds.size.height / 3);
        back = NSMakeRect(itemBounds.origin.x, ceil(itemBounds.size.height * .66), itemBounds.size.width, itemBounds.size.height / 3);
    } else {
        front = NSMakeRect(itemBounds.origin.x, itemBounds.origin.y, itemBounds.size.width / 3, itemBounds.size.height);
        back = NSMakeRect(ceil(itemBounds.size.width * .66), itemBounds.origin.y, itemBounds.size.width / 3, itemBounds.size.height);
    }
    
    dropOp = TDListViewDropOn;
    if (NSPointInRect(locInItem, front)) {
        // if p is in the first 1/3 of the itemView change the op to DropBefore
        dropOp = TDListViewDropBefore;
        
    } else if (NSPointInRect(locInItem, back)) {
        // if p is in the last 1/3 of the item view change op to DropBefore and increment index
        dropIndex++;
        dropOp = TDListViewDropBefore;
    } else {
        // if p is in the middle 1/3 of the item view leave as DropOn
    }    

    if (delegate && [delegate respondsToSelector:@selector(listView:validateDrop:proposedIndex:dropOperation:)]) {
        dragOp = [delegate listView:self validateDrop:dragInfo proposedIndex:&dropIndex dropOperation:&dropOp];
    }

    //NSLog(@"over: %@. Drop %@ : %d", itemView, dropOp == TDListViewDropOn ? @"On" : @"Before", dropIndex);

    return dragOp;
}


- (BOOL)performDragOperation:(id <NSDraggingInfo>)dragInfo {
    if (delegate && [delegate respondsToSelector:@selector(listView:acceptDrop:index:dropOperation:)]) {
        return [delegate listView:self acceptDrop:dragInfo index:dropIndex dropOperation:dropOp];
    } else {
        return NO;
    }
}


#pragma mark -
#pragma mark NSView

- (BOOL)isFlipped {
    return YES;
}


- (BOOL)acceptsFirstResponder {
    return YES;
}


- (void)drawRect:(NSRect)dirtyRect {
    [backgroundColor set];
    NSRectFill(dirtyRect);
}


#pragma mark -
#pragma mark NSResponder

- (void)mouseDown:(NSEvent *)evt {
    [super mouseDown:evt];
    
    NSPoint locInWin = [evt locationInWindow];
    NSPoint p = [self convertPoint:locInWin fromView:nil];
    lastMouseDownLocationInList = p;
    
    NSInteger i = [self indexForItemAtPoint:p];
    draggingIndex = i;
    if (-1 == i) {
        if ([evt clickCount] > 1) {
            if (delegate && [delegate respondsToSelector:@selector(listView:emptyAreaWasDoubleClicked:)]) {
                [delegate listView:self emptyAreaWasDoubleClicked:evt];
            }
        }
    } else {
        self.selectedItemIndex = i;
    }

    // this adds support for click-to-select + drag all in one click. 
    // otherwise you have to click once to select and then click again to begin a drag, which sux.
    BOOL dragging = YES;
    NSInteger radius = DRAG_RADIUS;
    NSRect r = NSMakeRect(locInWin.x - radius, locInWin.y - radius, radius * 2, radius * 2);
    
    while (dragging) {
        evt = [[self window] nextEventMatchingMask:NSLeftMouseUpMask|NSLeftMouseDraggedMask];
        
        switch ([evt type]) {
            case NSLeftMouseDragged:
                if (NSPointInRect([evt locationInWindow], r)) {
                    break;
                }
                [self mouseDragged:evt];
                dragging = NO;
                break;
            case NSLeftMouseUp:
                dragging = NO;
                [super mouseDown:evt];
                break;
            default:
                break;
        }
    }
}


- (void)mouseDragged:(NSEvent *)evt {
    // have to get the image before calling any delegate methods... they may rearrange or remove views which would cause us to have the wrong image
    dragOffset = NSZeroPoint;
    NSImage *dragImg = nil;
    if (delegate && [delegate respondsToSelector:@selector(listView:draggingImageForItemAtIndex:withEvent:offset:)]) {
        dragImg = [delegate listView:self draggingImageForItemAtIndex:draggingIndex withEvent:evt offset:&dragOffset];
    } else {
        dragImg = [self draggingImageForItemAtIndex:draggingIndex withEvent:evt offset:&dragOffset];
    }

    BOOL canDrag = YES;
    if (delegate && [delegate respondsToSelector:@selector(listView:canDragItemAtIndex:withEvent:)]) {
        canDrag = [delegate listView:self canDragItemAtIndex:draggingIndex withEvent:evt];
    }
    if (!canDrag) return;
    
    NSPasteboard *pboard = [NSPasteboard pasteboardWithName:NSDragPboard];

    canDrag = NO;
    if (delegate && [delegate respondsToSelector:@selector(listView:writeItemAtIndex:toPasteboard:)]) {
        canDrag = [delegate listView:self writeItemAtIndex:draggingIndex toPasteboard:pboard];
    }
    if (!canDrag) return;
    
    self.selectedItemIndex = -1;
    
    NSPoint p = lastMouseDownLocationInList;
    p.x -= dragOffset.x;
    p.y += dragOffset.y;
    
    [self dragImage:dragImg at:p offset:NSZeroSize event:evt pasteboard:pboard source:self slideBack:NO];
}


#pragma mark -
#pragma mark Private

// TODO remove
- (NSRect)visibleRect {
    return [[self superview] bounds];
}


// TODO make -resizeSubviewsWithOldSize: ???
//- (void)resizeSubviewsWithOldSize:(NSSize)oldBoundsSize
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
        if (displaysClippedItems) {
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
@synthesize displaysClippedItems;
@end
