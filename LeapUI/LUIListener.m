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

static float prevTipPosition = 0;

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
    
    //Point and Click will be 1 finger; Pinch to zoom and Two finger scroll will be 2 fingers;
    switch ( [fingers count] ){
        case 1: {
            for(int i = 0; i < [fingers count]; i++) {
                if(((LeapFinger*)[fingers objectAtIndex:i]).tipPosition.z > 50){
                    //NSLog(@"Removing finger with distance: %f", [(LeapFinger*)[fingers objectAtIndex:i] tipPosition].z);
                    [fingers removeObjectAtIndex:i];
                    i--;
                }
            }
        }
        case 2: {
            
            /**** Two Finger Scrolling ****/
            /* Still have to: 
                1. put in checks to differentiate pinch to zoom as two finger scrolling when tipPosition < POSITION_DIFF_THRESHOLD (check x posiitons)
                2. recognize when user is not scrolling anymore (probably through some predictions like velocity * fps
                3. Map Scrolling to Trackpad Event
            */
            
            if ( [fingers count] == 2 ){
                /*NSLog(@"Y position of Finger 1: %f", [ fingers[0] tipPosition ].y );
                NSLog(@"Y position of Finger 2: %f", [ fingers[1] tipPosition ].y );
                NSLog(@"Velocity of Finger 1: %f", [ fingers[0] tipVelocity ].magnitude );
                NSLog(@"Previous Tip Position: %f", prevTipPosition );*/
                
                const int POSITION_DIFF_THRESHOLD = 8; //difference between fingers positions to recognize scroll
                const int MOVING_VELOCITY_THRESHOLD = 10;
                float tip1Position = [ fingers[0] tipPosition ].y;
                float tip2Position = [ fingers[1] tipPosition ].y;
                float tip1Velocity = [ fingers[0] tipVelocity ].magnitude;
                if ( tip1Velocity > MOVING_VELOCITY_THRESHOLD && abs(tip1Position - tip2Position) < POSITION_DIFF_THRESHOLD){
                    if ( tip1Position < prevTipPosition ){
                        NSLog(@"Scrolling Down");
                    }
                    else if ( tip1Position > prevTipPosition ){
                        NSLog(@"Scrolling Up");
                    }
                    prevTipPosition = tip1Position;
                }
            }
            /***** End Two Finger Scrolling *****/

        }
        default:{
            //NSLog(@"Nothing significant is happening");
        }
    }

}

@end
