//
//  FontMenu.m
//  AngbandScreenSaver
//
//  Created by Peter Ammon on 10/12/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "FontMenu.h"

static NSInteger menuItemTitleCompare(id item1, id item2, void *unused) {
    return [[item1 title] localizedCaseInsensitiveCompare:[item2 title]];
}

NSMenu *makeFontMenu(void) {
    NSSet *fontNames = [NSSet setWithArray:[[NSFontManager sharedFontManager] availableFontFamilies]];
    NSMutableArray *menuItems = [NSMutableArray array];
    for (NSString *fontName in fontNames) {
        NSMenuItem *item = [[[NSMenuItem alloc] initWithTitle:fontName action:nil keyEquivalent:@""] autorelease];
        [item setRepresentedObject:fontName];
        [menuItems addObject:item];
        
    }
    [menuItems sortUsingFunction:menuItemTitleCompare context:NULL];
    NSMenu *menu = [[[NSMenu alloc] initWithTitle:@"Font names"] autorelease];
    for (NSMenuItem *item in menuItems) {
        [menu addItem:item];
    }
    return menu;
}

