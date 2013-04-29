//
//  AppDelegate.h
//  LeapUI
//
//  Created by Siddarth Sampangi on 28/04/2013.
//  Copyright (c) 2013 Siddarth Sampangi. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "LUIListener.h"

@interface AppDelegate : NSObject <NSApplicationDelegate> {
    NSWindow *window;
    NSStatusItem *statusItem;
}

@property (assign) IBOutlet NSMenu *statusMenu;

@property (assign) IBOutlet NSWindow *window;
@property LUIListener *listener;
-(void) pressKey:(int)key down:(BOOL)pressDown;
//-(void) scrollX:(NSInteger)x scrollY:(NSInteger)y;
//- (IBAction)onQuitClick:(id)sender;
//- (IBAction)onAboutClick:(id)sender;

@end
