//
//  LUIListener.m
//  LeapUI
//
//  Created by Siddarth Sampangi on 28/04/2013.
//  Copyright (c) 2013 Siddarth Sampangi. All rights reserved.
//

#import "LUIListener.h"
#import "LeapObjectiveC.h"
#import <Carbon/Carbon.h>

#define DEBUG 0


/* Cursor movement values */
#define MIN_VIEW_THRESHOLD 100
#define MIN_FREEZE_THRESHOLD 20
#define MIN_CLICK_THRESHOLD 0
#define MAX_ZSCALE_ZOOM 2.5

/* These are values that we are simply comfortable with using.
   They do not represent the Leap's full field of view. */
#define LEAP_FIELD_OF_VIEW_WIDTH 600
#define LEAP_FIELD_OF_VIEW_HEIGHT 400

@implementation LUIListener

/* NAVIGATION VARS */
bool moving = YES;
static LeapFrame *prevFrame;
static CGFloat fieldOfViewScale;
static CGFloat mainScreenWidth;
static CGFloat mainScreenHeight;
static bool leftClickDown = NO;

/* SCROLLING VARS */
static float prevTipPosition = 0;

/* PINCH AND ZOOM VARS */
static float prevTipdistance = 0;

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

- (void)onConnect:(NSNotification *)notification
{
    NSLog(@"Connected");
    LeapController *aController = (LeapController *)[notification object];
    //    [aController enableGesture:LEAP_GESTURE_TYPE_CIRCLE enable:YES];
    //    [aController enableGesture:LEAP_GESTURE_TYPE_KEY_TAP enable:YES];
    //    [aController enableGesture:LEAP_GESTURE_TYPE_SCREEN_TAP enable:YES];
    [aController enableGesture:LEAP_GESTURE_TYPE_SWIPE enable:YES];
    
    NSRect mainScreenFrame = [[NSScreen mainScreen] frame];
    mainScreenWidth = mainScreenFrame.size.width;
    mainScreenHeight = mainScreenFrame.size.height;
    
    
    fieldOfViewScale = mainScreenWidth/LEAP_FIELD_OF_VIEW_WIDTH;
}

- (void)onDisconnect:(NSNotification *)notification
{
    NSLog(@"Disconnected");
}

- (void)onExit:(NSNotification *)notification
{
    NSLog(@"Exited");
}

- (void) click{
    
    NSPoint mouseLoc = [NSEvent mouseLocation];
    CGPoint clickPosition = CGPointMake(mouseLoc.x, mainScreenHeight - mouseLoc.y);
    
    if(!leftClickDown) {
        CGEventRef clickLeftDown = CGEventCreateMouseEvent(
                                                       NULL, kCGEventLeftMouseDown,
                                                       clickPosition,
                                                       kCGMouseButtonLeft
                                                       );
        CGEventSetType(clickLeftDown, kCGEventLeftMouseDown);
        CGEventPost(kCGHIDEventTap, clickLeftDown);
        CFRelease(clickLeftDown);
        leftClickDown = YES;
    }
    else {
        CGEventRef clickLeftUp = CGEventCreateMouseEvent(
                                                       NULL, kCGEventLeftMouseUp,
                                                       clickPosition,
                                                       kCGMouseButtonLeft
                                                       );
        CGEventSetType(clickLeftUp, kCGEventLeftMouseUp);
        CGEventPost(kCGHIDEventTap, clickLeftUp);
        CFRelease(clickLeftUp);
        leftClickDown = NO;
    }
}

- (void) moveCursorWithFinger: (LeapFinger *) finger controller: (LeapController *) aController{
    
    if(finger.tipPosition.z < MIN_CLICK_THRESHOLD) {
        if(!leftClickDown)[self click];
        return;
    }
    else if(finger.tipPosition.z < MIN_FREEZE_THRESHOLD){
        if(leftClickDown) [self click];
        return;
    }
    
    NSPoint mouseLoc = [NSEvent mouseLocation];
    LeapFrame *previousFrame;
    if(moving) previousFrame = [aController frame:1];
    else previousFrame = prevFrame;
    
    LeapFinger *prevFinger = [previousFrame finger:[finger id]];
    if(![prevFinger isValid]) return;
    
    CGFloat velocity = powf((powf(finger.tipVelocity.x,2) + powf(finger.tipVelocity.y,2)),0.5);

    CGFloat scale = velocity/100 * fieldOfViewScale * fabsf(finger.tipPosition.z) * MAX_ZSCALE_ZOOM/MIN_VIEW_THRESHOLD;
    
    CGFloat deltaX = (float) lroundf((finger.tipPosition.x - prevFinger.tipPosition.x) * scale);
    CGFloat deltaY = (float) lroundf((finger.tipPosition.y - prevFinger.tipPosition.y) * scale);
    
    if(deltaX == 0 && deltaY == 0) {
        prevFrame = previousFrame;
        moving = NO;
        return;
    }
    else moving = YES;
    
    CGFloat xpos = mouseLoc.x + deltaX;
    
    if(xpos < 0) xpos = 0;
    else if(xpos > mainScreenWidth) xpos = mainScreenWidth;
    
    CGFloat ypos = mainScreenHeight - (mouseLoc.y + deltaY);
    
    if(ypos < 0) ypos = 0;
    else if(ypos > mainScreenHeight) ypos = mainScreenHeight;
    
    CGPoint fingerTip = CGPointMake(xpos,ypos);
    
    CGEventRef move = CGEventCreateMouseEvent( NULL, kCGEventMouseMoved,
                                               fingerTip,
                                               kCGMouseButtonLeft // ignored
                                               );
    
    if(DEBUG) {NSLog(@"\nLeapFinger location:\t%f , %f\n\t\t\tMouseXY:\t%f , %f\n\tFinal Position: \t%f, %f\n\t\t\tDeltaXY:\t%f, %f\n\t\t\tVelocity:\t%f\n\n",
                     finger.tipPosition.x, finger.tipPosition.y,
                     mouseLoc.x, mouseLoc.y,
                     fingerTip.x, fingerTip.y,
                     deltaX, deltaY,
                     velocity);
    }
    CGEventSetType(move, kCGEventMouseMoved);
    CGEventPost(kCGHIDEventTap, move);
    CFRelease(move);
}

- (void) scrollWithFingers: (NSMutableArray *) fingers
{
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
- (void) PinchandZoom :(NSMutableArray *)fingers;
{
    if ( [fingers count] == 2 ){
        
        // BEGIN Two Finger Pinch&Zoom
        const float disThreshold = 1.24;
        float tip1Positionx = [ fingers[0] tipPosition ].x;
        float tip2Positionx = [ fingers[1] tipPosition ].x;
        float tip1Positiony = [ fingers[0] tipPosition ].y;
        float tip2Positiony = [ fingers[1] tipPosition ].y;
        float tip1Positionz = [ fingers[0] tipPosition ].z;
        float tip2Positionz = [ fingers[1] tipPosition ].z;
        float distance = sqrtf(powf((tip1Positionx-tip2Positionx), 2)+powf((tip1Positiony-tip2Positiony), 2)+powf((tip1Positionz-tip2Positionz), 2));
        //NSLog(@"distance = %f",distance);
        // NSLog(@"predistance = %f",prevTipdistance);
        if( distance - prevTipdistance > disThreshold)
        {
            NSLog(@"Zoom Gesture dectected");
            [self pressKey:kVK_Command down:true];
            [NSThread sleepForTimeInterval: 0.1]; // 100 mS delay
            [self pressKey:kVK_ANSI_Equal down:true];
            
            [NSThread sleepForTimeInterval: 0.1];
            
            [self pressKey:kVK_Command down:true];
            [NSThread sleepForTimeInterval: 0.1];
            [self pressKey:kVK_ANSI_Equal down:true];
            
        }
        else if ( prevTipdistance - distance > disThreshold){
            NSLog(@"Pinch Gesture dectected");
            [self pressKey:kVK_Command down:true];
            [NSThread sleepForTimeInterval: 0.1]; // 100 mS delay
            [self pressKey:kVK_ANSI_Minus down:true];
            
            [NSThread sleepForTimeInterval: 0.1];
            
            [self pressKey:kVK_Command down:true];
            [NSThread sleepForTimeInterval: 0.1];
            [self pressKey:kVK_ANSI_Minus down:true];
        }
        prevTipdistance = distance;
    }
}
- (void)onFrame:(NSNotification *)notification;
{
    LeapController *aController = (LeapController *)[notification object];
    
    // Get the most recent frame and report some basic information
    LeapFrame *frame = [aController frame:0];
    
    //if the finger is more than MIN_VIEW_THRESHOLD millimeters away from the front of the Leap, then ignore it
    NSMutableArray *fingers = [[NSMutableArray alloc] initWithArray:[frame fingers]];
    for(int i = 0; i < [fingers count]; i++) {
        if(((LeapFinger*)[fingers objectAtIndex:i]).tipPosition.z > MIN_VIEW_THRESHOLD){
            //NSLog(@"Removing finger with distance: %f", [(LeapFinger*)[fingers objectAtIndex:i] tipPosition].z);
            [fingers removeObjectAtIndex:i];
            i--;
        }
    }
    
    //Point and Click will be 1 finger; Pinch to zoom and Two finger scroll will be 2 fingers;
    
    /*NOTE: for some reason the switch statement didn't work. When I added "case 5", it would always default
            to that even when I was only showing 1 finger. I replaced it with an if-statement and it worked
            so I just left that there. I will remove the switch statement entirely in a few days if you guys
            can't figure out a solution either.*/
    
    /*NSLog(@"FINGERS: %ld", (unsigned long)fingers.count);
    switch ( (unsigned long)[fingers count] ){
        case 1: {
            [self moveCursorWithFinger: [fingers objectAtIndex:0] controller: aController];
        }
        case 2: {
            [self scrollWithFingers:fingers];
        }
        case 5: {
         //Sid: This can be changed later 
            CGEventRef move = CGEventCreateMouseEvent( NULL, kCGEventMouseMoved,
                                                      CGPointMake(mainScreenWidth/2, mainScreenHeight/2),
                                                      kCGMouseButtonLeft // ignored
                                                      );
            CGEventSetType(move, kCGEventMouseMoved);
            CGEventPost(kCGHIDEventTap, move);
            CFRelease(move);
        }
        default:{
            //NSLog(@"Nothing significant is happening");
        }
    }*/
    
    NSUInteger fingerCount = [fingers count];
    if(fingerCount == 1) {
        [self moveCursorWithFinger: [fingers objectAtIndex:0] controller: aController];
    }
    else if(fingerCount == 2) {
        [self scrollWithFingers:fingers];
         [self PinchandZoom:fingers];
    }
    else if(fingerCount == 5) {
        //Sid: This can be changed later
        CGEventRef move = CGEventCreateMouseEvent( NULL, kCGEventMouseMoved,
                                                  CGPointMake(mainScreenWidth/2, mainScreenHeight/2),
                                                  kCGMouseButtonLeft // ignored
                                                  );
        CGEventSetType(move, kCGEventMouseMoved);
        CGEventPost(kCGHIDEventTap, move);
        CFRelease(move);
    }
    else {
        //NSLog(@"Nothing significant is happening");
    }

}
-(void) pressKey:(int)key down:(BOOL)pressDown{
    CGEventRef downEvent = CGEventCreateKeyboardEvent(NULL, key, pressDown);
    
    CGEventPost(kCGHIDEventTap, downEvent);
    
    CFRelease(downEvent);
}
@end
