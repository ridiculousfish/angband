/* File: AngbandScreenSaverView.m */

/*
 * Copyright (c) 2011 Peter Ammon
 *
 * This software may be copied and distributed for educational, research,
 * and not for profit purposes provided that this copyright and statement
 * are included in all such copies.
 */

#import "AngbandScreenSaverView.h"
#import "AngbandConnection.h"
#import "FontMenu.h"

@implementation AngbandScreenSaverView

- (id)initWithFrame:(NSRect)frame isPreview:(BOOL)isPreview
{
    self = [super initWithFrame:frame isPreview:isPreview];
    [self setAnimationTimeInterval:-1]; //prevent ScreenSaver from trying to animate us
    return self;
}

- (void)drawRect:(NSRect)dirtyRect {
    [[AngbandConnection connection] drawInRect:[self bounds]];
}

- (void)setConnected:(BOOL)flag {
    if (connected != flag) {
        connected = flag;
        if (! connected) {
            [[AngbandConnection connection] removeView:self];
        } else {
            [[AngbandConnection connection] addView:self];
        }
    }
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

- (BOOL)hasConfigureSheet {
    return YES;
}

- (NSUserDefaults *)defaults {
    return [ScreenSaverDefaults defaultsForModuleWithName:[[NSBundle bundleForClass:[self class]] bundleIdentifier]];
}

- (void)synchronizeAnimationSpeedDescriptionWithSlider {
    double newAnimationSpeed = round([animationSpeedSlider doubleValue]);
    
    NSString *string;
    if (newAnimationSpeed > 60) string = @"Infinite (no animation)";
    else string = [NSString stringWithFormat:@"%ld frame%s per second", (long)newAnimationSpeed, (newAnimationSpeed == 1. ? "" : "s")];
    [animationSpeedDescription setStringValue:string];    
}


- (NSWindow *)configureSheet {
    if (! configureSheet) {
        [NSBundle loadNibNamed:@"AngbandScreensaverConfigSheet" owner:self];
    }
    
    NSUserDefaults *defaults = [self defaults];
    
    /* Font menu */
    [fontNamePopUp setMenu:makeFontMenu()];
    NSString *fontName = [defaults objectForKey:@"FontName"];
    if (! fontName || ! [fontNamePopUp itemWithTitle:fontName]) {
        fontName = @"Monaco";
    }
    [fontNamePopUp selectItemWithTitle:fontName];
    
    /* Graphics mode */
    [graphicsPopUp selectItemWithTag:[defaults integerForKey:@"GraphicsMode"]];
    
    /* Update our slider */
    NSInteger fps = [defaults integerForKey:@"FramesPerSecond"];
    double sliderValue;
    if (fps <= 0) sliderValue = 61;
    else sliderValue = fps;
    [animationSpeedSlider setDoubleValue:sliderValue];
    
    /* Reflect the description in our text field */
    [self synchronizeAnimationSpeedDescriptionWithSlider];
    

    
    return configureSheet;
}

- (IBAction)cancelConfigure:sender {
    [NSApp endSheet:configureSheet];
}

- (IBAction)acceptConfigure:sender {
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    
    /* Font name */
    NSString *fontName = [[fontNamePopUp selectedItem] representedObject];
    if (fontName) [dictionary setObject:fontName forKey:@"FontName"];
    
    /* FPS */
    NSInteger fps;
    double sliderValue = [animationSpeedSlider doubleValue];
    if (sliderValue > 60) fps = 0;
    else fps = (NSInteger)round(sliderValue);
    [dictionary setObject:[NSNumber numberWithInteger:fps] forKey:@"FramesPerSecond"];
    
    NSMenuItem *graphicsItem = [graphicsPopUp selectedItem];
    [dictionary setObject:[NSNumber numberWithInteger:[graphicsItem tag]] forKey:@"GraphicsMode"];
        
    /* Old keys */
    [dictionary setObject:[NSNumber numberWithBool:NO] forKey:@"UseSound"];
    [dictionary setObject:[NSNumber numberWithBool:NO] forKey:@"PauseForMessages"];
    
    /* Tell Angband */
    [[AngbandConnection connection] setPreferences:dictionary];
    
    /* Done with the sheet */
    [NSApp endSheet:configureSheet];
}


- (void)dealloc {
    [configureSheet release];
    [super dealloc];
}

- (NSUserDefaults *)userDefaults {
    return [ScreenSaverDefaults defaultsForModuleWithName:[[NSBundle bundleForClass:[self class]] bundleIdentifier]];
}

- (IBAction)modifyAnimationSpeed:sender {
    [self synchronizeAnimationSpeedDescriptionWithSlider];
}

- (IBAction)deleteSaveFile:sender {
    NSInteger confirmed = NSRunAlertPanel(@"Reset Borg", @"This will move any borg save file to the trash, which will cause the borg to start a new character. Are you sure you want to do this?", @"Move Save to Trash", @"Cancel", NULL);
    if (confirmed == NSAlertDefaultReturn) {
        NSString *borgFileName = [[self userDefaults] stringForKey:@"BorgSaveFileName"];
        if (! borgFileName) borgFileName = @"Player";

        /* Big hack: hard code the path */
        NSString *saveDirectory = [@"~/Documents/Angband/save/" stringByExpandingTildeInPath];
        NSString *path = [saveDirectory stringByAppendingPathComponent:borgFileName];
        NSURL *url = [NSURL fileURLWithPath:path isDirectory:NO];
        
        [[NSWorkspace sharedWorkspace] recycleURLs:[NSArray arrayWithObject:url] completionHandler:NULL];
    }
}

@end
