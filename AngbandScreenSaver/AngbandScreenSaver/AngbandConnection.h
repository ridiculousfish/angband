//
//  AngbandConnection.h
//  AngbandScreenSaver
//
//  Created by Peter Ammon on 10/7/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

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
