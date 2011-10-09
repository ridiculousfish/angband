//
//  AngbandScreenSaverView.m
//  AngbandScreenSaver
//
//  Created by Peter Ammon on 10/7/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "AngbandScreenSaverView.h"
#import "AngbandConnection.h"

@implementation AngbandScreenSaverView

- (id)initWithFrame:(NSRect)frame isPreview:(BOOL)isPreview
{
    self = [super initWithFrame:frame isPreview:isPreview];
    return self;
}

- (void)drawRect:(NSRect)dirtyRect {
    [[AngbandConnection connection] drawInRect:[self bounds]];
}

- (void)setConnected:(BOOL)flag {
    if (connected && ! flag) {
        [[AngbandConnection connection] removeView:self];
    } else if (! connected && flag) {
        [[AngbandConnection connection] addView:self];
    }
    connected = flag;
}

- (void)startAnimation
{
    [self setConnected:YES];
    [super startAnimation];
}

- (void)stopAnimation
{
    [self setConnected:NO];
    [super stopAnimation];
}

- (void)animateOneFrame
{
    return;
}

- (BOOL)hasConfigureSheet
{
    return NO;
}

- (NSWindow*)configureSheet
{
    return nil;
}

@end
