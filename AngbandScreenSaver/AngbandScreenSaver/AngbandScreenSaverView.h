//
//  AngbandScreenSaverView.h
//  AngbandScreenSaver
//
//  Created by Peter Ammon on 10/7/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

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

@end
