/* File: AngbandConnection.h */

/*
 * Copyright (c) 2011 Peter Ammon
 *
 * This software may be copied and distributed for educational, research,
 * and not for profit purposes provided that this copyright and statement
 * are included in all such copies.
 */

#import <Foundation/Foundation.h>

@class AngbandScreenSaverView;

@interface AngbandConnection : NSObject {
@private
    id angbandContext;
    NSConnection *connection;
    CGContextRef bitmapContext;
    const void *sharedBuffer;
    size_t sharedBufferSize;
    int shmemFD;
    BOOL closedFD;
    pid_t childPID;
    
    __strong NSRect *rectsToDisplay;
    size_t rectIndex, rectCapacity;
    
    NSMutableArray *views;
}

+ (AngbandConnection *)connection;

- (void)addView:(AngbandScreenSaverView *)view;
- (void)removeView:(AngbandScreenSaverView *)view;

- (void)drawInRect:(NSRect)rect;

- (void)setPreferences:(NSDictionary *)preferences;

@end
