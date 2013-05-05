//
//  LUIListener.m
//  LeapUI
//
//  Created by Siddarth Sampangi on 28/04/2013.
//  Copyright (c) 2013 Siddarth Sampangi. All rights reserved.
//

#import "LUIListener.h"
#import "LeapObjectiveC.h"

@implementation LUIListener

- (void) run {
    LeapController *controller = [[LeapController alloc] init];
    [controller addListener:self];
    [controller setPolicyFlags:LEAP_POLICY_BACKGROUND_FRAMES];
    NSLog(@"Listener added");
}

- (void)onInit:(NSNotification *)notification
{
    NSLog(@"Initialized");
}

- (void)onConnect:(NSNotification *)notification;
{
    NSLog(@"Connected");
    LeapController *aController = (LeapController *)[notification object];
    //    [aController enableGesture:LEAP_GESTURE_TYPE_CIRCLE enable:YES];
    //    [aController enableGesture:LEAP_GESTURE_TYPE_KEY_TAP enable:YES];
    //    [aController enableGesture:LEAP_GESTURE_TYPE_SCREEN_TAP enable:YES];
    [aController enableGesture:LEAP_GESTURE_TYPE_SWIPE enable:YES];
}

- (void)onDisconnect:(NSNotification *)notification;
{
    NSLog(@"Disconnected");
}

- (void)onExit:(NSNotification *)notification;
{
    NSLog(@"Exited");
}

- (void)onFrame:(NSNotification *)notification;
{
    LeapController *aController = (LeapController *)[notification object];
    
    // Get the most recent frame and report some basic information
    LeapFrame *frame = [aController frame:0];
    
    //if the finger is more than 5 centimeters away from the front of the Leap, then ignore it
    NSMutableArray *fingers = [[NSMutableArray alloc] initWithArray:[frame fingers]];
    for(int i = 0; i < [fingers count]; i++) {
        if(((LeapFinger*)[fingers objectAtIndex:i]).tipPosition.z > 50){
            //NSLog(@"Removing finger with distance: %f", [(LeapFinger*)[fingers objectAtIndex:i] tipPosition].z);
            [fingers removeObjectAtIndex:i];
            i--;
        }
    }

}

@end
