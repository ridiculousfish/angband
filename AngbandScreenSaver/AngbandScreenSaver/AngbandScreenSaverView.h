/* File: AngbandScreenSaverView.h */

/*
 * Copyright (c) 2011 Peter Ammon
 *
 * This software may be copied and distributed for educational, research,
 * and not for profit purposes provided that this copyright and statement
 * are included in all such copies.
 */

#import <ScreenSaver/ScreenSaver.h>

@class AngbandViewProxy;

@interface AngbandScreenSaverView : ScreenSaverView {
@private
    BOOL connected;
    IBOutlet NSWindow *configureSheet;
    IBOutlet NSSlider *animationSpeedSlider;
    IBOutlet NSTextField *animationSpeedDescription;
    IBOutlet NSPopUpButton *graphicsPopUp;
    IBOutlet NSPopUpButton *fontNamePopUp;
}

- (IBAction)modifyAnimationSpeed:sender;
- (IBAction)cancelConfigure:sender;
- (IBAction)acceptConfigure:sender;
- (IBAction)deleteSaveFile:sender;

@end
