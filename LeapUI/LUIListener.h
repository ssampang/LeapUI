//
//  LUIListener.h
//  LeapUI
//
//  Created by Siddarth Sampangi on 28/04/2013.
//  Copyright (c) 2013 Siddarth Sampangi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LeapObjectiveC.h"

@interface LUIListener : NSObject <LeapListener> {
    NSWindow *window;
    NSStatusItem *statusItem;
}

@property (assign) IBOutlet NSMenu *statusMenu;

@property (nonatomic, strong, readonly) IBOutlet NSWindow *window;

- (void) run;

@end
