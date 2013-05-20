//
//  AppDelegate.m
//  LeapUI
//
//  Created by Siddarth Sampangi on 28/04/2013.
//  Copyright (c) 2013 Siddarth Sampangi. All rights reserved.
//

#import "AppDelegate.h"

#ifndef APP_DELEGATE

@implementation AppDelegate
@synthesize listener;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    
    
    
    listener = [[LUIListener alloc]init];
    [listener run];
}

@end

#endif //APP_DELEGATE
