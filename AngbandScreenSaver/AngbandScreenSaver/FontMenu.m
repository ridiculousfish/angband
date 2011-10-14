/* File: FontMenu.m */

/*
 * Copyright (c) 2011 Peter Ammon
 *
 * This software may be copied and distributed for educational, research,
 * and not for profit purposes provided that this copyright and statement
 * are included in all such copies.
 */

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

