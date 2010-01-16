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
#import <TDAppKit/TDListItem.h>
#import "TDListItemQueue.h"

#define EXCEPTION_NAME @"TDListViewDataSourceException"
#define DEFAULT_ITEM_EXTENT 44
#define DRAG_RADIUS 20

@interface NSToolbarPoofAnimator
+ (void)runPoofAtPoint:(NSPoint)p;
@end

@interface TDListItem ()
@property (nonatomic) NSUInteger index;
@end

@interface TDListView ()
- (void)layoutItems;
- (void)layoutItemsWhileDragging;
- (NSInteger)indexForItemWhileDraggingAtPoint:(NSPoint)p;
- (TDListItem *)itemWhileDraggingAtIndex:(NSInteger)i;
- (void)draggingSourceDragWillBeginAtIndex:(NSUInteger)i;
- (void)draggingSourceDragDidEnd;

@property (nonatomic, retain) NSMutableArray *items;
@property (nonatomic, retain) TDListItemQueue *queue;
@property (nonatomic, retain) NSEvent *lastMouseDownEvent;
@property (nonatomic, retain) NSMutableArray *itemFrames;
@end

@implementation TDListView

- (id)initWithFrame:(NSRect)frame {
    if (self = [super initWithFrame:frame]) {        
        self.backgroundColor = [NSColor whiteColor];
        self.itemExtent = DEFAULT_ITEM_EXTENT;
        
        self.queue = [[[TDListItemQueue alloc] init] autorelease];
        
        self.displaysClippedItems = YES;
        
        [self setPostsBoundsChangedNotifications:YES];
        
        draggingIndex = -1;
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
    self.items = nil;
    self.queue = nil;
    self.lastMouseDownEvent = nil;
    self.itemFrames = nil;
    [super dealloc];
}


- (void)awakeFromNib {
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(viewBoundsChanged:) name:NSViewBoundsDidChangeNotification object:[self superview]];
}


#pragma mark -
#pragma mark Notifications

- (void)viewBoundsChanged:(NSNotification *)n {
    [self layoutItems];
}


#pragma mark -
#pragma mark Public

- (void)reloadData {
    [self layoutItems];
    [self setNeedsDisplay:YES];
}


- (id)dequeueReusableItemWithIdentifier:(NSString *)s {
    TDListItem *item = [queue dequeueWithIdentifier:s];
    [item prepareForReuse];
    return item;
}


- (NSUInteger)indexForItemAtPoint:(NSPoint)p {
    NSUInteger i = 0;
    for (TDListItem *item in items) {
        if (NSPointInRect(p, [item frame])) {
            return i;
        }
        i++;
    }
    return -1;
}


- (id)itemAtIndex:(NSUInteger)i {
    if (i < 0 || i >= [items count]) return nil;
    
    return [items objectAtIndex:i];
}


- (NSRect)frameForItemAtIndex:(NSUInteger)i {
    return [[self itemAtIndex:i] frame];
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
#pragma mark NSView

- (void)resizeSubviewsWithOldSize:(NSSize)oldBoundsSize {
    [self layoutItems];
}


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
    self.lastMouseDownEvent = evt;
    
    NSInteger i = [self indexForItemAtPoint:p];
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
                if (!draggingItem) {
                    [self draggingSourceDragWillBeginAtIndex:i];
                }
                [self mouseDragged:evt];
                dragging = NO;
                break;
            case NSLeftMouseUp:
                dragging = NO;
                [self draggingSourceDragDidEnd];
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
        dragImg = [delegate listView:self draggingImageForItemAtIndex:draggingIndex withEvent:lastMouseDownEvent offset:&dragOffset];
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
    
    NSPoint p = [self convertPoint:[evt locationInWindow] fromView:nil];
    
    dragOffset.x = dragOffset.x - ([evt locationInWindow].x - [lastMouseDownEvent locationInWindow].x);
    dragOffset.y = dragOffset.y + ([evt locationInWindow].y - [lastMouseDownEvent locationInWindow].y);
    
    p.x -= dragOffset.x;
    p.y -= dragOffset.y;
    
    NSSize ignored = NSZeroSize;
    [self dragImage:dragImg at:p offset:ignored event:evt pasteboard:pboard source:self slideBack:NO];
}


#pragma mark -
#pragma mark DraggingSource

- (NSDragOperation)draggingSourceOperationMaskForLocal:(BOOL)isLocal {
    return isLocal ? localDragOperationMask : nonLocalDragOperationMask;
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
    TDListItem *item = [self itemAtIndex:i];
    NSRect r = [item bounds];
    NSBitmapImageRep *bitmap = [item bitmapImageRepForCachingDisplayInRect:r];
    [item cacheDisplayInRect:r toBitmapImageRep:bitmap];
    
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
        NSPoint p = [item convertPoint:[evt locationInWindow] fromView:nil];
        *dragImageOffset = NSMakePoint(p.x, p.y - NSHeight([item frame]));
    }
    
    return result;
}


- (void)draggedImage:(NSImage *)image endedAt:(NSPoint)endPointInScreen operation:(NSDragOperation)op {
    // screen origin is lower left
    endPointInScreen.x += dragOffset.x;
    endPointInScreen.y -= dragOffset.y;

    // window origin is lower left
    NSPoint endPointInWin = [[self window] convertScreenToBase:endPointInScreen];

    // get frame of visible portion of list view in window coords
    NSRect dropZone = [self convertRect:[self visibleRect] toView:nil];
    
    if (!NSPointInRect(endPointInWin, dropZone)) {
        [NSToolbarPoofAnimator runPoofAtPoint:endPointInScreen];
    }

    [self layoutItems];

    [self draggingSourceDragDidEnd];
}


#pragma mark -
#pragma mark NSDraggingDestination

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)dragInfo {
    self.itemFrames = [NSMutableArray arrayWithCapacity:[items count]];
    for (TDListItem *item in items) {
        [itemFrames addObject:[NSValue valueWithRect:[item frame]]];
    }
    
    NSPasteboard *pboard = [dragInfo draggingPasteboard];
    NSDragOperation srcMask = [dragInfo draggingSourceOperationMask];
    
    if ([[pboard types] containsObject:NSColorPboardType]) {
        if (srcMask & NSDragOperationMove) {
            return NSDragOperationMove;
        }
    }

    return NSDragOperationNone;
}


/* TODO if the destination responded to draggingEntered: but not to draggingUpdated: the return value from draggingEntered: should be used */
- (NSDragOperation)draggingUpdated:(id <NSDraggingInfo>)dragInfo {
    if (!delegate || ![delegate respondsToSelector:@selector(listView:validateDrop:proposedIndex:dropOperation:)]) {
        return NSDragOperationNone;
    }
    
    NSDragOperation dragOp = NSDragOperationNone;
    
    NSPoint locInWin = [dragInfo draggingLocation];
    NSPoint locInList = [self convertPoint:locInWin fromView:nil];
    dropIndex = [self indexForItemWhileDraggingAtPoint:locInList];
    
    NSUInteger itemCount = [items count];
    if (dropIndex < 0 || dropIndex > itemCount) {
        dropIndex = itemCount;
    }

    TDListItem *item = [self itemWhileDraggingAtIndex:dropIndex];
    NSPoint locInItem = [item convertPoint:locInWin fromView:nil];

    NSRect itemBounds = [item bounds];
    NSRect front, back;
    
    if (self.isPortrait) {
        front = NSMakeRect(itemBounds.origin.x, itemBounds.origin.y, itemBounds.size.width, itemBounds.size.height / 3);
        back = NSMakeRect(itemBounds.origin.x, ceil(itemBounds.size.height * .66), itemBounds.size.width, itemBounds.size.height / 3);
    } else {
        front = NSMakeRect(itemBounds.origin.x, itemBounds.origin.y, itemBounds.size.width / 3, itemBounds.size.height);
        back = NSMakeRect(ceil(itemBounds.size.width * .66), itemBounds.origin.y, itemBounds.size.width / 3, itemBounds.size.height);
    }
    
    dropOp = TDListViewDropOn;
    if (draggingItem && NSPointInRect(locInItem, front)) {
        // if p is in the first 1/3 of the item change the op to DropBefore
        dropOp = TDListViewDropBefore;
        
    } else if (draggingItem && NSPointInRect(locInItem, back)) {
        // if p is in the last 1/3 of the item view change op to DropBefore and increment index
        dropIndex++;
        dropOp = TDListViewDropBefore;
    } else {
        // if p is in the middle 1/3 of the item view leave as DropOn
    }    

    if (delegate && [delegate respondsToSelector:@selector(listView:validateDrop:proposedIndex:dropOperation:)]) {
        dragOp = [delegate listView:self validateDrop:dragInfo proposedIndex:&dropIndex dropOperation:&dropOp];
    }
    
    //NSLog(@"over: %@. Drop %@ : %d", item, dropOp == TDListViewDropOn ? @"On" : @"Before", dropIndex);

    [self layoutItemsWhileDragging];
    
    return dragOp;
}


- (BOOL)performDragOperation:(id <NSDraggingInfo>)dragInfo {
    for (TDListItem *item in items) {
        [item setHidden:NO];
    }
    if (dropIndex > draggingIndex) {
        dropIndex--;
    }
    self.itemFrames = nil;
    if (delegate && [delegate respondsToSelector:@selector(listView:acceptDrop:index:dropOperation:)]) {
        return [delegate listView:self acceptDrop:dragInfo index:dropIndex dropOperation:dropOp];
    } else {
        return NO;
    }
}


#pragma mark -
#pragma mark Private

// TODO remove
- (NSRect)visibleRect {
    return [[self superview] bounds];
}


- (void)layoutItems {
    if (!dataSource) {
        [NSException raise:EXCEPTION_NAME format:@"TDListView must have a dataSource before doing layout"];
    }

    for (TDListItem *item in items) {
        [queue enqueue:item];
        [item removeFromSuperview];
    }
    
    self.items = [NSMutableArray array];
    
    NSRect viewportRect = [self visibleRect];
    BOOL isPortrait = self.isPortrait;
    
    CGFloat x = itemMargin;
    CGFloat y = 0;
    CGFloat w = isPortrait ? viewportRect.size.width : 0;
    CGFloat h = isPortrait ? 0 : viewportRect.size.height;
    
    NSInteger c = [dataSource numberOfItemsInListView:self];
    BOOL respondsToExtentForItem = (delegate && [delegate respondsToSelector:@selector(listView:extentForItemAtIndex:)]);
    
    //[NSAnimationContext beginGrouping];
    //[[NSAnimationContext currentContext] setDuration:0];
    
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
            TDListItem *item = [dataSource listView:self viewForItemAtIndex:i];
            if (!item) {
                [NSException raise:EXCEPTION_NAME format:@"nil list item view returned for index: %d by: %@", i, dataSource];
            }
            //[[item animator] setFrame:NSMakeRect(x, y, w, h)];
            [item setFrame:NSMakeRect(x, y, w, h)];
            [self addSubview:item];
            [items addObject:item];
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
    
    //[NSAnimationContext endGrouping];

    [self setFrame:frame];
    
    //NSLog(@"%s my bounds: %@, viewport bounds: %@", _cmd, NSStringFromRect([self bounds]), NSStringFromRect([superview bounds]));
    //NSLog(@"view count: %d, queue count: %d", [items count], [queue count]);
}


- (void)layoutItemsWhileDragging {
    if (!draggingItem) {
        return;
    }
    
    NSUInteger itemCount = [items count];
    TDListItem *item = nil;
    
    //[NSAnimationContext beginGrouping];
    //[[NSAnimationContext currentContext] setDuration:.075];
    
    CGFloat extent = 0;
    NSUInteger i = 0;
    for ( ; i <= itemCount; i++) {
        item = [self itemAtIndex:i];
        NSRect frame = [item frame];
        if (self.isLandscape) {
            frame.origin.x = extent;
        } else {
            frame.origin.y = extent;
        }
        
        [item setHidden:i == draggingIndex];
        
        if (i >= dropIndex) {
            if (self.isPortrait) {
                frame.origin.y += draggingExtent;
            } else {
                frame.origin.x += draggingExtent;
            }
        }
        
        //[[item animator] setFrame:frame];
        [item setFrame:frame];
        if (i != draggingIndex) {
            extent += self.isPortrait ? frame.size.height : frame.size.width;
        }
    }

    //[NSAnimationContext endGrouping];
}


- (NSInteger)indexForItemWhileDraggingAtPoint:(NSPoint)p {
    if (!draggingItem) {
        return [self indexForItemAtPoint:p];
    }
    
    NSInteger i = 0;
    for (NSValue *v in itemFrames) {
        if (NSPointInRect(p, [v rectValue])) {
            if (i >= draggingIndex) {
                return i + 1;
            } else {
                return i;
            }
        }
        i++;
    }
    return -1;
}


- (TDListItem *)itemWhileDraggingAtIndex:(NSInteger)i {
    TDListItem *item = [self itemAtIndex:i];
    if (item == draggingItem) {
        TDListItem *nextItem = [self itemAtIndex:i + 1];
        item = nextItem ? nextItem : item;
    }
    if (!item) {
        item = (i < 0) ? [items objectAtIndex:0] : [items lastObject];
    }
    return item;
}


- (void)draggingSourceDragWillBeginAtIndex:(NSUInteger)i {
    draggingIndex = i;
    draggingItem = [self itemAtIndex:i];
    draggingExtent = self.isPortrait ? NSHeight([draggingItem frame]) : NSWidth([draggingItem frame]);                    
}


- (void)draggingSourceDragDidEnd {
    draggingIndex = -1;
    draggingExtent = 0;
    draggingItem = nil;
}

@synthesize scrollView;
@synthesize dataSource;
@synthesize delegate;
@synthesize backgroundColor;
@synthesize itemExtent;
@synthesize itemMargin;
@synthesize selectedItemIndex;
@synthesize orientation;
@synthesize items;
@synthesize queue;
@synthesize displaysClippedItems;
@synthesize lastMouseDownEvent;
@synthesize itemFrames;
@end
