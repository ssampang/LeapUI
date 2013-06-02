//
//  LUIListener.m
//  LeapUI
//
//  Created by Siddarth Sampangi on 28/04/2013.
//  Copyright (c) 2013 Siddarth Sampangi. All rights reserved.
//

#ifndef LUILISTENER

#import "LUIListener.h"
#import "LeapObjectiveC.h"
#import <Carbon/Carbon.h>
#import <Foundation/Foundation.h>
#import <CoreAudio/CoreAudio.h>

#define DEBUG 0
#define testGestures 0

#define fequal(a,b) (fabs((a) - (b)) < FLT_EPSILON)

/* Cursor movement values */
#define MIN_VIEW_THRESHOLD 70
#define MIN_FREEZE_THRESHOLD 15
#define MIN_CLICK_THRESHOLD 0
#define MAX_ZSCALE_ZOOM 2.5

/* These are values that we are simply comfortable with using.
   They do not represent the Leap's full field of view. */
#define LEAP_FIELD_OF_VIEW_WIDTH 600
#define LEAP_FIELD_OF_VIEW_HEIGHT 400

@implementation LUIListener
@synthesize window = _window;

/* GENERAL VARS */
static bool clickingFinger;

/* NAVIGATION VARS */
static BOOL clickMoving = YES;
static LeapFrame *clickPrevFrame;
static CGFloat fieldOfViewScale;
static CGFloat mainScreenWidth;
static CGFloat mainScreenHeight;
static BOOL leftClickClicked = NO;

/* STATUS ITEM VARS */
static int statusItemColor = 0; /* 1 = red; 2 = yellow; 3 = green;*/

typedef enum {
    LgreenQ = 0,
    Lgreen1 = 1,
    Lgreen2 = 2,
    Lgreen3 = 3,
    Lgreen4 = 4,
    Lgreen5 = 5,
    
    LyellowQ = 6,
    Lyellow1 = 7,
    Lyellow2 = 8,
    Lyellow3 = 9,
    Lyellow4 = 10,
    Lyellow5 = 11,
    
    LredQ = 12,
    Lred1 = 13,
    Lred2 = 14,
    Lred3 = 15,
    Lred4 = 16,
    Lred5 = 17,
    Lred0 = 18
} imageNumber;

/* Status Item constants */
static const int LbaseGreen = 0;
static const int LbaseYellow = 6;
static const int LbaseRed = 12;

static NSImage *redQ;
static NSImage *red0;
static NSImage *red1;
static NSImage *red2;
static NSImage *red3;
static NSImage *red4;
static NSImage *red5;

static NSImage *yellowQ;
static NSImage *yellow1;
static NSImage *yellow2;
static NSImage *yellow3;
static NSImage *yellow4;
static NSImage *yellow5;

static NSImage *greenQ;
static NSImage *green1;
static NSImage *green2;
static NSImage *green3;
static NSImage *green4;
static NSImage *green5;

/* DRAGGING VARS */
static BOOL leftClickDown = NO;
static BOOL dragMoving = NO;
static LeapFrame *dragPrevFrame;

/* SCROLLING VARS */
static LeapVector *scrollingVelocity;

/* PINCH AND ZOOM VARS */
static float prevTipdistance = 0;
static float startSymbol=1;

/* BRIGHTNESS CONTROL VARS */
static float prevRadius=0;
static float startSymbolR=1;
const int kMaxDisplays = 16;
const CFStringRef kDisplayBrightness = CFSTR(kIODisplayBrightnessKey);

/* VOLUME CONTROL VARS */
static float prevRotationAngle=0;
static float startSymbolV=1;

/* COMMAND+TAB VARS */
static bool cmndTabMenuIsVisible = false;
static bool userIsCmndTabbing = false;

- (void) run{
    LeapController *controller = [[LeapController alloc] init];
    [controller addListener:self];
    [controller setPolicyFlags:LEAP_POLICY_BACKGROUND_FRAMES];
    NSLog(@"Listener added");
    
    statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    [statusItem setMenu:[self statusMenu]];
    //[statusItem setTitle:@"Test"];
    NSBundle *bundle = [NSBundle mainBundle];
    
    redQ = [[NSImage alloc]initWithContentsOfFile:[bundle pathForResource:@"red?" ofType:@"jpg"] ];
    [redQ setSize:NSMakeSize(20, 20)];
    
    red0 = [[NSImage alloc]initWithContentsOfFile:[bundle pathForResource:@"red0" ofType:@"jpg"] ];
    [red0 setSize:NSMakeSize(20, 20)];
    
    red1 = [[NSImage alloc]initWithContentsOfFile:[bundle pathForResource:@"red1" ofType:@"jpg"] ];
    [red1 setSize:NSMakeSize(20, 20)];
    
    red2 = [[NSImage alloc]initWithContentsOfFile:[bundle pathForResource:@"red2" ofType:@"jpg"] ];
    [red2 setSize:NSMakeSize(20, 20)];
    
    red3 = [[NSImage alloc]initWithContentsOfFile:[bundle pathForResource:@"red3" ofType:@"jpg"] ];
    [red3 setSize:NSMakeSize(20, 20)];
    
    red4 = [[NSImage alloc]initWithContentsOfFile:[bundle pathForResource:@"red4" ofType:@"jpg"] ];
    [red4 setSize:NSMakeSize(20, 20)];
    
    red5 = [[NSImage alloc]initWithContentsOfFile:[bundle pathForResource:@"red5" ofType:@"jpg"] ];
    [red5 setSize:NSMakeSize(20, 20)];
    
    yellowQ = [[NSImage alloc]initWithContentsOfFile:[bundle pathForResource:@"yellow?" ofType:@"jpg"] ];
    [yellowQ setSize:NSMakeSize(20, 20)];
    
    yellow1 = [[NSImage alloc]initWithContentsOfFile:[bundle pathForResource:@"yellow1" ofType:@"jpg"] ];
    [yellow1 setSize:NSMakeSize(20, 20)];
    
    yellow2 = [[NSImage alloc]initWithContentsOfFile:[bundle pathForResource:@"yellow2" ofType:@"jpg"] ];
    [yellow2 setSize:NSMakeSize(20, 20)];
    
    yellow3 = [[NSImage alloc]initWithContentsOfFile:[bundle pathForResource:@"yellow3" ofType:@"jpg"] ];
    [yellow3 setSize:NSMakeSize(20, 20)];
    
    yellow4 = [[NSImage alloc]initWithContentsOfFile:[bundle pathForResource:@"yellow4" ofType:@"jpg"] ];
    [yellow4 setSize:NSMakeSize(20, 20)];
    
    yellow5 = [[NSImage alloc]initWithContentsOfFile:[bundle pathForResource:@"yellow5" ofType:@"jpg"] ];
    [yellow5 setSize:NSMakeSize(20, 20)];
    
    greenQ = [[NSImage alloc]initWithContentsOfFile:[bundle pathForResource:@"green?" ofType:@"jpg"] ];
    [greenQ setSize:NSMakeSize(20, 20)];

    green1 = [[NSImage alloc]initWithContentsOfFile:[bundle pathForResource:@"green1" ofType:@"jpg"] ];
    [green1 setSize:NSMakeSize(20, 20)];

    green2 = [[NSImage alloc]initWithContentsOfFile:[bundle pathForResource:@"green2" ofType:@"jpg"] ];
    [green2 setSize:NSMakeSize(20, 20)];

    green3 = [[NSImage alloc]initWithContentsOfFile:[bundle pathForResource:@"green3" ofType:@"jpg"] ];
    [green3 setSize:NSMakeSize(20, 20)];

    green4 = [[NSImage alloc]initWithContentsOfFile:[bundle pathForResource:@"green4" ofType:@"jpg"] ];
    [green4 setSize:NSMakeSize(20, 20)];

    green5 = [[NSImage alloc]initWithContentsOfFile:[bundle pathForResource:@"green5" ofType:@"jpg"] ];
    [green5 setSize:NSMakeSize(20, 20)];
    
    [self setStatusBarImage:red0];
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

- (void) clickAtPosition: (CGPoint) position withEvent: (CGEventType) eventType andButton: (CGMouseButton) button{
    CGEventRef click = CGEventCreateMouseEvent(
                                                       NULL, eventType,
                                                       position,
                                                       button
                                                       );
    CGEventSetType(click, eventType);
    CGEventPost(kCGHIDEventTap, click);
    CFRelease(click);
}

- (void) setStatusItemColor: (LeapFinger *) finger WithFingers: (int) numOfFingers{
    
    if(!finger){
        if(statusItemColor != Lred0){
            [self setStatusBarImage:red0];
            statusItemColor = Lred0;
        }
        return;
    }

    if(finger.tipPosition.z < MIN_CLICK_THRESHOLD) {
        if(statusItemColor != LbaseGreen + numOfFingers){
            statusItemColor = LbaseGreen + numOfFingers;
            
            switch (statusItemColor) {
                case LgreenQ:
                    [self setStatusBarImage: greenQ];
                    break;
                
                case Lgreen1:
                    [self setStatusBarImage:green1];
                    break;
                    
                case Lgreen2:
                    [self setStatusBarImage:green2];
                    break;
                    
                case Lgreen3:
                    [self setStatusBarImage:green3];
                    break;
                
                case Lgreen4:
                    [self setStatusBarImage:green4];
                    break;
                
                case Lgreen5:
                    [self setStatusBarImage:green5];
                    break;
                    
                default:
                    break;
            }
        }
    }
    else if(finger.tipPosition.z < MIN_FREEZE_THRESHOLD){
        if(statusItemColor != LbaseYellow + numOfFingers){
            statusItemColor = LbaseYellow + numOfFingers;
            
            switch (statusItemColor) {
                case LyellowQ:
                    [self setStatusBarImage: yellowQ];
                    break;
                    
                case Lyellow1:
                    [self setStatusBarImage:yellow1];
                    break;
                    
                case Lyellow2:
                    [self setStatusBarImage:yellow2];
                    break;
                    
                case Lyellow3:
                    [self setStatusBarImage:yellow3];
                    break;
                    
                case Lyellow4:
                    [self setStatusBarImage:yellow4];
                    break;
                    
                case Lyellow5:
                    [self setStatusBarImage:yellow5];
                    break;
                    
                default:
                    break;
            }
        }
    }
    else {
        if(statusItemColor != LbaseRed + numOfFingers){
            statusItemColor = LbaseRed + numOfFingers;
            
            switch (statusItemColor) {
                case LredQ:
                    [self setStatusBarImage: redQ];
                    break;
                    
                case Lred1:
                    [self setStatusBarImage:red1];
                    break;
                    
                case Lred2:
                    [self setStatusBarImage:red2];
                    break;
                    
                case Lred3:
                    [self setStatusBarImage:red3];
                    break;
                    
                case Lred4:
                    [self setStatusBarImage:red4];
                    break;
                    
                case Lred5:
                    [self setStatusBarImage:red5];
                    break;
                    
                default:
                    break;
            }
        }
    }
}

- (void) moveCursorWithFinger: (LeapFinger *) finger controller: (LeapController *) aController{
    
    //[self setStatusItemColor:finger WithFingers:1];
    /* CLICKING */
    if(finger.tipPosition.z < MIN_CLICK_THRESHOLD) {
        if(!leftClickClicked){
            leftClickClicked = YES;
            if(userIsCmndTabbing == YES) {
                userIsCmndTabbing = NO;
                cmndTabMenuIsVisible = NO;
                [self pressKey:kVK_Command down:false];
                [self pressKey:kVK_Tab down:false];
            }
        }
        return;
    }
    else if(finger.tipPosition.z < MIN_FREEZE_THRESHOLD){
        if(leftClickClicked) {
            NSPoint mouseLoc = [NSEvent mouseLocation];
            CGPoint clickPosition = CGPointMake(mouseLoc.x, mainScreenHeight - mouseLoc.y);
            [self clickAtPosition:clickPosition withEvent:kCGEventLeftMouseDown andButton:kCGMouseButtonLeft];
            [NSThread sleepForTimeInterval:0.1];
            [self clickAtPosition:clickPosition withEvent:kCGEventLeftMouseUp andButton:kCGMouseButtonLeft];
            leftClickClicked = NO;
        }
        return;
    }
    
    /* MOVEMENT */
    NSPoint mouseLoc = [NSEvent mouseLocation];
    LeapFrame *previousFrame;
    if(clickMoving) previousFrame = [aController frame:1];
    else previousFrame = clickPrevFrame;
    
    LeapFinger *prevFinger = [previousFrame finger:[finger id]];
    if(![prevFinger isValid]) return;
    
    CGFloat velocity = powf((powf(finger.tipVelocity.x,2) + powf(finger.tipVelocity.y,2)),0.5);

    CGFloat scale = velocity/100 * fieldOfViewScale;// * fabsf(finger.tipPosition.z) * MAX_ZSCALE_ZOOM/MIN_VIEW_THRESHOLD;
    
    CGFloat deltaX = (float) lroundf((finger.tipPosition.x - prevFinger.tipPosition.x) * scale);
    CGFloat deltaY = (float) lroundf((finger.tipPosition.y - prevFinger.tipPosition.y) * scale);
    
    if(deltaX == 0 && deltaY == 0) {
        clickPrevFrame = previousFrame;
        clickMoving = NO;
        return;
    }
    else clickMoving = YES;
    
    CGFloat xpos = mouseLoc.x + deltaX;
    
    if(xpos < 0) xpos = 0;
    else if(xpos > mainScreenWidth) xpos = mainScreenWidth;
    
    CGFloat ypos = mainScreenHeight - (mouseLoc.y + deltaY);
    
    if(ypos < 0) ypos = 0;
    else if(ypos > mainScreenHeight) ypos = mainScreenHeight;
    
    CGPoint fingerTip = CGPointMake(xpos,ypos);
    
    [self clickAtPosition:fingerTip withEvent:kCGEventMouseMoved andButton:kCGMouseButtonLeft];
    
    if(DEBUG) {NSLog(@"\nLeapFinger location:\t%f , %f\n\t\t\tMouseXY:\t%f , %f\n\tFinal Position: \t%f, %f\n\t\t\tDeltaXY:\t%f, %f\n\t\t\tVelocity:\t%f\n\n",
                     finger.tipPosition.x, finger.tipPosition.y,
                     mouseLoc.x, mouseLoc.y,
                     fingerTip.x, fingerTip.y,
                     deltaX, deltaY,
                     velocity);
    }
}

- (void) dragCursorWithFinger: (LeapFinger *) finger controller: (LeapController *) aController{
    //if(finger.tipPosition.z > MIN_CLICK_THRESHOLD) return;
    
    //[self setStatusItemColor:finger WithFingers:3];
    NSPoint mouseLoc = [NSEvent mouseLocation];
    CGPoint clickPosition = CGPointMake(mouseLoc.x, mainScreenHeight - mouseLoc.y);
    
    if(finger.tipPosition.z < MIN_CLICK_THRESHOLD) {
        if(!leftClickDown){
            [self clickAtPosition:clickPosition withEvent:kCGEventLeftMouseDown andButton:kCGMouseButtonLeft];
            leftClickDown = YES;
            return;
        }
    }
    else{
        if(leftClickDown) {
            [self clickAtPosition:clickPosition withEvent:kCGEventLeftMouseUp andButton:kCGMouseButtonLeft];
            leftClickDown = NO;
        }
    }
    
    LeapFrame *previousFrame;
    if(dragMoving) previousFrame = [aController frame:1];
    else previousFrame = dragPrevFrame;
    
    LeapFinger *prevFinger = [[previousFrame fingers] leftmost];
    //if(![prevFinger isValid]) return;
    
    CGFloat velocity = powf((powf(finger.tipVelocity.x,2) + powf(finger.tipVelocity.y,2)),0.5);
    
    CGFloat scale = velocity/100 * fieldOfViewScale;// * fabsf(finger.tipPosition.z) * MAX_ZSCALE_ZOOM/MIN_VIEW_THRESHOLD;
    
    CGFloat deltaX = (float) lroundf((finger.tipPosition.x - prevFinger.tipPosition.x) * scale);
    CGFloat deltaY = (float) lroundf((finger.tipPosition.y - prevFinger.tipPosition.y) * scale);
    
    if(deltaX == 0 && deltaY == 0) {
        dragPrevFrame = previousFrame;
        dragMoving = NO;
        return;
    }
    else dragMoving = YES;
    
    CGFloat xpos = mouseLoc.x + deltaX;
    
    if(xpos < 0) xpos = 0;
    else if(xpos > mainScreenWidth) xpos = mainScreenWidth;
    
    CGFloat ypos = mainScreenHeight - (mouseLoc.y + deltaY);
    
    if(ypos < 0) ypos = 0;
    else if(ypos > mainScreenHeight) ypos = mainScreenHeight;
    
    CGPoint fingerTip = CGPointMake(xpos,ypos);
    
    [self clickAtPosition:fingerTip withEvent:kCGEventLeftMouseDragged andButton:kCGMouseButtonLeft];
    
    if(DEBUG) {NSLog(@"\nLeapFinger location:\t%f , %f\n\t\t\tMouseXY:\t%f , %f\n\tFinal Position: \t%f, %f\n\t\t\tDeltaXY:\t%f, %f\n\t\t\tVelocity:\t%f\n\n",
                     finger.tipPosition.x, finger.tipPosition.y,
                     mouseLoc.x, mouseLoc.y,
                     fingerTip.x, fingerTip.y,
                     deltaX, deltaY,
                     velocity);
    }
}

- (void) cmndTabWithFinger: (LeapFinger *) finger controller: (LeapController *) aController {
    if(!cmndTabMenuIsVisible) {
        //[self setStatusItemColor:finger WithFingers:5];
        [self pressKey:kVK_Command down:false];
        [self pressKey:kVK_Tab down:false];
        
        [self pressKey:kVK_Command down:true];
        [NSThread sleepForTimeInterval: 0.1]; // 100 mS delay
        [self pressKey:kVK_Tab down:true];
        
        //[self pressKey:kVK_Command down:false];
        //[self pressKey:kVK_Tab down:false];
        
        cmndTabMenuIsVisible = true;
    }
    
    //else [self moveCursorWithFinger:finger controller:aController];
}

- (void) scrollWithFingers: (NSMutableArray *) fingers  andController:(LeapController *) aController
{
    /**** Two Finger Scrolling ****/
    /* Still have to:
     1. put in checks to differentiate pinch to zoom as two finger scrolling when tipPosition < POSITION_DIFF_THRESHOLD (check x posiitons)
     2. recognize when user is not scrolling anymore (probably through some predictions like velocity * fps
     */
    
    LeapFrame *currentFrame = [aController frame:0];
    LeapFrame *previousFrame = [aController frame:1];
    
    LeapVector *currentTipPosition = [fingers[0] tipPosition];
    LeapVector *previousTipPosition = [previousFrame finger: [ (LeapFinger *)fingers[0] id]].tipPosition;
    
    if ( previousFrame != NULL){
        //NSLog(@"Translation Probability: %f", [frame translationProbability:comparisonFrame]);
        //NSLog(@"Distance scrolled: %f: ", [frame translation:comparisonFrame].magnitude);
       
        if([currentFrame translationProbability: previousFrame] > 0.4) {
            //[self setStatusItemColor:[fingers leftmost] WithFingers:2];
            if (currentTipPosition.z < MIN_CLICK_THRESHOLD  ){
                CGEventRef scrollingY = CGEventCreateScrollWheelEvent(NULL, kCGScrollEventUnitLine, 1,
                                                                      previousTipPosition.y - currentTipPosition.y);
                CGEventRef scrollingX = CGEventCreateScrollWheelEvent(NULL, kCGScrollEventUnitLine, 2,
                                                                      previousTipPosition.x - currentTipPosition.x);
                CGEventSetType(scrollingY, kCGEventScrollWheel);
                CGEventPost(kCGHIDEventTap, scrollingY);
                CFRelease(scrollingY);
                
                CGEventSetType(scrollingX, kCGEventScrollWheel);
                CGEventPost(kCGHIDEventTap, scrollingX);
                CFRelease(scrollingX);
                
                //scrollingVelocity = [fingers[0] tipVelocity];
            }
            else {
                
                //[self inertialScrollWithVelocity: scrollingVelocity];
            }
        }
    }
    /***** End Two Finger Scrolling *****/
}

//THIS DOESNT WORK YET AT ALL. WORK IN PROGRESS
- (void) inertialScrollWithVelocity: (LeapVector *) scrollingVelocity {
    if(scrollingVelocity.x <= 0.01 && scrollingVelocity.y <= 0.01) return;
    CGEventRef scrollingY = CGEventCreateScrollWheelEvent(NULL, kCGScrollEventUnitLine, 1,
                                                          -1*scrollingVelocity.y);
    CGEventRef scrollingX = CGEventCreateScrollWheelEvent(NULL, kCGScrollEventUnitLine, 2,
                                                          -1*scrollingVelocity.x);
    CGEventSetType(scrollingY, kCGEventScrollWheel);
    CGEventPost(kCGHIDEventTap, scrollingY);
    CFRelease(scrollingY);
    
    CGEventSetType(scrollingX, kCGEventScrollWheel);
    CGEventPost(kCGHIDEventTap, scrollingX);
    CFRelease(scrollingX);
    
    
    scrollingVelocity = [[LeapVector alloc] initWithX: scrollingVelocity.x * 0.9
                                                    y: scrollingVelocity.y * 0.9
                                                    z: scrollingVelocity.z];
}

- (void) pinchAndZoom :(NSMutableArray *)fingers withController: (LeapController *) aController
{
    Boolean symbol=false;
    
    if( [[aController frame:0] scaleProbability: [aController frame:1]] < 0.4) return;
    if ( [fingers count] == 2 ){
        
        // BEGIN Two Finger Pinch&Zoom
        const float disThreshold = 2.5;
        float tip1Positionx = [ fingers[0] tipPosition ].x;
        float tip2Positionx = [ fingers[1] tipPosition ].x;
        float tip1Positiony = [ fingers[0] tipPosition ].y;
        float tip2Positiony = [ fingers[1] tipPosition ].y;
        float tip1Positionz = [ fingers[0] tipPosition ].z;
        float tip2Positionz = [ fingers[1] tipPosition ].z;
        float distance = sqrtf(powf((tip1Positionx-tip2Positionx), 2)+powf((tip1Positiony-tip2Positiony), 2)+powf((tip1Positionz-tip2Positionz), 2));
        //NSLog(@"distance = %f",distance);
        // NSLog(@"predistance = %f",prevTipdistance);
        if( distance - prevTipdistance > disThreshold&&startSymbol!=1)
        {
            NSLog(@"Zoom Gesture dectected");
            [self pressKey:kVK_Command down:true];
            [NSThread sleepForTimeInterval: 0.1]; // 100 mS delay
            [self pressKey:kVK_ANSI_Equal down:true];
            
            [self pressKey:kVK_Command down:false];
            [self pressKey:kVK_ANSI_Equal down:false];
        }
        else if ( prevTipdistance - distance > disThreshold&&startSymbol!=1){
            NSLog(@"Pinch Gesture dectected");
            [self pressKey:kVK_Command down:true];
            [NSThread sleepForTimeInterval: 0.1]; // 100 mS delay
            [self pressKey:kVK_ANSI_Minus down:true];
            
            [self pressKey:kVK_Command down:false];
            [self pressKey:kVK_ANSI_Minus down:false];
        }
        else if(startSymbol!=1)
        {
            symbol=true;
        }
        if(startSymbol==1)
            startSymbol--;
        if(symbol==true) // when you put 2 fingers in the field but do not recognize as zoom or pinch
            startSymbol=1;
        prevTipdistance = distance;
    }
}

- (float)getVolume {
	float			b_vol;
	OSStatus		err;
	AudioDeviceID		device;
	UInt32			size;
	UInt32			channels[2];
	float			volume[2];
	
	// get device
	size = sizeof device;
	err = AudioHardwareGetProperty(kAudioHardwarePropertyDefaultOutputDevice, &size, &device);
	if(err!=noErr) {
		NSLog(@"audio-volume error get device");
		return 0.0;
	}
	
	// try set master volume (channel 0)
	size = sizeof b_vol;
	err = AudioDeviceGetProperty(device, 0, 0, kAudioDevicePropertyVolumeScalar, &size, &b_vol);	//kAudioDevicePropertyVolumeScalarToDecibels
	if(noErr==err) return b_vol;
	
	// otherwise, try seperate channels
	// get channel numbers
	size = sizeof(channels);
	err = AudioDeviceGetProperty(device, 0, 0,kAudioDevicePropertyPreferredChannelsForStereo, &size,&channels);
	if(err!=noErr) NSLog(@"error getting channel-numbers");
	
	size = sizeof(float);
	err = AudioDeviceGetProperty(device, channels[0], 0, kAudioDevicePropertyVolumeScalar, &size, &volume[0]);
	if(noErr!=err) NSLog(@"error getting volume of channel %d",channels[0]);
	err = AudioDeviceGetProperty(device, channels[1], 0, kAudioDevicePropertyVolumeScalar, &size, &volume[1]);
	if(noErr!=err) NSLog(@"error getting volume of channel %d",channels[1]);
	
	b_vol = (volume[0]+volume[1])/2.00;
	
	return  b_vol;
}


// setting system volume
- (void)setVolume:(float)involume {
	OSStatus		err;
	AudioDeviceID		device;
	UInt32			size;
	Boolean			canset	= false;
	UInt32			channels[2];
	//float			volume[2];
    
	// get default device
	size = sizeof device;
	err = AudioHardwareGetProperty(kAudioHardwarePropertyDefaultOutputDevice, &size, &device);
	if(err!=noErr) {
		NSLog(@"audio-volume error get device");
		return;
	}
	
	// try set master-channel (0) volume
	size = sizeof canset;
	err = AudioDeviceGetPropertyInfo(device, 0, false, kAudioDevicePropertyVolumeScalar, &size, &canset);
	if(err==noErr && canset==true) {
		size = sizeof involume;
		err = AudioDeviceSetProperty(device, NULL, 0, false, kAudioDevicePropertyVolumeScalar, size, &involume);
		return;
	}
    
	// else, try seperate channes
	// get channels
	size = sizeof(channels);
	err = AudioDeviceGetProperty(device, 0, false, kAudioDevicePropertyPreferredChannelsForStereo, &size,&channels);
	if(err!=noErr) {
		NSLog(@"error getting channel-numbers");
		return;
	}
	
	// set volume
	size = sizeof(float);
	err = AudioDeviceSetProperty(device, 0, channels[0], false, kAudioDevicePropertyVolumeScalar, size, &involume);
	if(noErr!=err) NSLog(@"error setting volume of channel %d",channels[0]);
	err = AudioDeviceSetProperty(device, 0, channels[1], false, kAudioDevicePropertyVolumeScalar, size, &involume);
	if(noErr!=err) NSLog(@"error setting volume of channel %d",channels[1]);
}

-(void)brightnessControl:(LeapHand *)hands andFingers:(NSMutableArray *) fingers;
{
    if([fingers count]==5){
      
    float radius= [hands sphereRadius];
         // NSLog(@"current radius= %f",radius);
       // NSLog(@"prevradius = %f",prevRadius);
    const float radiusthreshold=2.2;
    if(radius - prevRadius>=radiusthreshold)
    {
        NSLog(@"Increase the Brightness");
        [self set_brightness:[self get_brightness]+0.05];
            }
    else if(prevRadius - radius>=radiusthreshold)
    {
        NSLog(@"Decrease the Brightness");
       [self set_brightness:[self get_brightness]-0.05];
    }
    prevRadius=radius;
    }
}
-(void)volumeControl:(LeapHand *)hands andController:(LeapController *) aController
{
    LeapFrame *prevFrame = [aController frame: 1];
    
    Boolean symbol=false;
    float rotationAngle=0;
    const float rotationThreshold=0.05;
    if(startSymbolV!=1){
    LeapVector *axis=[[LeapVector alloc]init];
    axis=[hands rotationAxis:prevFrame];
     rotationAngle=[hands rotationAngle:prevFrame];
        if(rotationAngle-prevRotationAngle>=rotationThreshold)
        {
            NSLog(@"Increase the Volume");
            
        }
       else if(prevRotationAngle-rotationAngle>=rotationThreshold)
       {
           NSLog(@"Decrease the Volume");
       }
        else{
    symbol=true;
        }

        }
    if(startSymbolV==1)
        startSymbolV--;
    if(symbol==true)
        startSymbolV=1;
    prevRotationAngle=rotationAngle;
    NSLog(@"rotationAngle= %f",rotationAngle);

}

- (void)onFrame:(NSNotification *)notification;
{
    LeapController *aController = (LeapController *)[notification object];
    
    // Get the most recent frame and report some basic information
    LeapFrame *frame = [aController frame:0];
     LeapHand *hand;
    if([[frame hands]count]!=0)
    {
        hand=[[frame hands] objectAtIndex:0];
    }

    //if the finger is more than MIN_VIEW_THRESHOLD millimeters away from the front of the Leap, then ignore it
    NSMutableArray *fingers = [[NSMutableArray alloc] initWithArray:[frame fingers]];
    for(int i = 0; i < [fingers count]; i++) {
        if(((LeapFinger*)[fingers objectAtIndex:i]).tipPosition.z > MIN_VIEW_THRESHOLD){
            //NSLog(@"Removing finger with distance: %f", [(LeapFinger*)[fingers objectAtIndex:i] tipPosition].z);
            [fingers removeObjectAtIndex:i];
            i--;
        }
        else if(((LeapFinger*)[fingers objectAtIndex:i]).tipPosition.z < MIN_CLICK_THRESHOLD){
            clickingFinger = true;
        }
    }
    
    //Point and Click will be 1 finger; Pinch to zoom and Two finger scroll will be 2 fingers;
    
    NSUInteger fingerCount = [fingers count];
    
    [self setStatusItemColor:[fingers leftmost] WithFingers:(int) fingerCount ];
    
    CGFloat scaleProbability = [frame scaleProbability:[aController frame:1]];
    CGFloat translationProbability = [frame translationProbability:[aController frame:1]];
    CGFloat rotationProbability = [frame rotationProbability:[aController frame:1]];
    
    if(leftClickDown) {
        [self dragCursorWithFinger: [fingers leftmost] controller:aController];
        return;
    }
    
    if(fingerCount==0)
    {
        startSymbol=1;
        startSymbolV=1;
        startSymbolR=1;
    }
    else if(fingerCount == 1) {
        if(testGestures) [self testGestureRecognition:1];
        [self moveCursorWithFinger: [fingers leftmost] controller: aController];
    }
    else if(fingerCount == 2) {
        if(scaleProbability > translationProbability) {
            if(testGestures) [self testGestureRecognition:3];
            [self pinchAndZoom:fingers withController: aController];
        }
        else {
            if(testGestures) [self testGestureRecognition:2];
            [self scrollWithFingers: fingers andController: aController];
        }
    }
    //ALERT: Why was this if( fingerCount >= 3) ??
    else if (fingerCount==3)
    {
        if(rotationProbability > translationProbability) {
            if(testGestures) [self testGestureRecognition:5];
            //[self volumeControl:hand andController:aController];
        }
        else {
            if(testGestures) [self testGestureRecognition:6];
            [self dragCursorWithFinger:[fingers leftmost] controller:aController];
        }
    }
    else if (fingerCount==4)
    {
        if(testGestures) [self testGestureRecognition:5];
        //[self volumeControl:hand andController:aController];
    }
    else if(fingerCount == 5) {
        //Sid: This can be changed later
       /* CGEventRef move = CGEventCreateMouseEvent( NULL, kCGEventMouseMoved,
                                                  CGPointMake(mainScreenWidth/2, mainScreenHeight/2),
                                                  kCGMouseButtonLeft // ignored
                                                  );
        CGEventSetType(move, kCGEventMouseMoved);
        CGEventPost(kCGHIDEventTap, move);
        CFRelease(move);*/
        
        if(userIsCmndTabbing) {
            if(testGestures) [self testGestureRecognition: 7];
            [self cmndTabWithFinger:[fingers leftmost] controller:aController];
        }
        else {
           if(scaleProbability > translationProbability ) {
                if( scaleProbability > rotationProbability) {
                    if(testGestures) [self testGestureRecognition: 4];
                    [self brightnessControl:hand andFingers:fingers];
                }
                else {
                    if(testGestures) [self testGestureRecognition:5];
                    //[self volumeControl:hand andController:aController];
                }
            }
            else {
                if( translationProbability > rotationProbability) {
                    NSArray *gestures = [frame gestures:nil];
                    LeapSwipeGesture *swipeGesture = nil;
                    for (int i = 0; i < [gestures count]; i++) {
                        if([(LeapGesture *)[gestures objectAtIndex:i] type] == LEAP_GESTURE_TYPE_SWIPE) {
                            swipeGesture = [gestures objectAtIndex:i];
                            break;
                        }
                    }
                    
                    if(swipeGesture == nil) return;
                    
                    LeapVector *swipeDirection = swipeGesture.direction;
                    if(swipeDirection.x > swipeDirection.y) return;
                    userIsCmndTabbing = true;
                    if(testGestures) [self testGestureRecognition: 7];
                    [self cmndTabWithFinger:[fingers objectAtIndex:0] controller: aController];
                    return;

                }
                else {
                    if(testGestures) [self testGestureRecognition:5];
                    //[self volumeControl:hand andController:aController];
                }
            }
            
            /*CGFloat maxProb = MAX(scaleProbability, MAX(translationProbability, rotationProbability));
             if(fequal(maxProb, scaleProbability)) {
             if(testGestures) [self testGestureRecognition: 4];
             //[self brightnessControl:hand andFingers:fingers];
            }
            else if(fequal(maxProb, translationProbability)) {
                NSArray *gestures = [frame gestures:nil];
                LeapSwipeGesture *swipeGesture = nil;
                for (int i = 0; i < [gestures count]; i++) {                
                    if([(LeapGesture *)[gestures objectAtIndex:i] type] == LEAP_GESTURE_TYPE_SWIPE) {
                        swipeGesture = [gestures objectAtIndex:i];
                        break;
                    }
                }
            
                if(swipeGesture == nil) return;
                
                LeapVector *swipeDirection = swipeGesture.direction;
                if(swipeDirection.x > swipeDirection.y) return;
                userIsCmndTabbing = true;
                if(testGestures) [self testGestureRecognition: 7];
                [self cmndTabWithFinger:[fingers objectAtIndex:0] controller: aController];
                return;
            }
            else {
                if(testGestures) [self testGestureRecognition:5];
                [self volumeControl:hand andController:aController];
            }*/

        }
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

- (void) setStatusBarImage: (NSImage *) img {
    [statusItem setImage:img];
    [statusItem setHighlightMode:YES];
}

/* This method is purely to test how well our program can recognize individual gestures */
static int currentGesture = 0;
- (void) testGestureRecognition: (int) gestureID {
    //if(gestureID != currentGesture) {
        switch (gestureID) {
            case 1:
                NSLog(@"Moving cursor");
                break;
            
            case 2:
                NSLog(@"Scrolling");
                break;
            
            case 3:
                NSLog(@"Zooming");
                break;
                
            case 4:
                NSLog(@"Brightness");
                break;
            
            case 5:
                NSLog(@"Volume Control");
                break;
                
            case 6:
                NSLog(@"Dragging");
                break;
                
            case 7:
                NSLog(@"Cmnd Tabbing");
                break;
                
            default:
                break;
        }
        currentGesture = gestureID;
    //}
}

- (float) get_brightness {
	CGDirectDisplayID display[kMaxDisplays];
	CGDisplayCount numDisplays;
	CGDisplayErr err;
	err = CGGetActiveDisplayList(kMaxDisplays, display, &numDisplays);
	
	if (err != CGDisplayNoErr)
		printf("cannot get list of displays (error %d)\n",err);
	for (CGDisplayCount i = 0; i < numDisplays; ++i) {
		
		
		CGDirectDisplayID dspy = display[i];
		CFDictionaryRef originalMode = CGDisplayCurrentMode(dspy);
		if (originalMode == NULL)
			continue;
		io_service_t service = CGDisplayIOServicePort(dspy);
		
		float brightness;
		err= IODisplayGetFloatParameter(service, kNilOptions, kDisplayBrightness,
										&brightness);
		if (err != kIOReturnSuccess) {
			fprintf(stderr,
					"failed to get brightness of display 0x%x (error %d)",
					(unsigned int)dspy, err);
			continue;
		}
		return brightness;
	}
	return -1.0;//couldn't get brightness for any display
}

- (void) set_brightness:(float) new_brightness {
	CGDirectDisplayID display[kMaxDisplays];
	CGDisplayCount numDisplays;
	CGDisplayErr err;
	err = CGGetActiveDisplayList(kMaxDisplays, display, &numDisplays);
	
	if (err != CGDisplayNoErr)
		printf("cannot get list of displays (error %d)\n",err);
	for (CGDisplayCount i = 0; i < numDisplays; ++i) {
		
		
		CGDirectDisplayID dspy = display[i];
		CFDictionaryRef originalMode = CGDisplayCurrentMode(dspy);
		if (originalMode == NULL)
			continue;
        io_service_t service = CGDisplayIOServicePort(dspy);
		/*
         float brightness;
         err= IODisplayGetFloatParameter(service, kNilOptions, kDisplayBrightness,
         &brightness);
         if (err != kIOReturnSuccess) {
         fprintf(stderr,
         "failed to get brightness of display 0x%x (error %d)",
         (unsigned int)dspy, err);
         continue;
         }
         */
		err = IODisplaySetFloatParameter(service, kNilOptions, kDisplayBrightness,
										 new_brightness);
		if (err != kIOReturnSuccess) {
			fprintf(stderr,
					"Failed to set brightness of display 0x%x (error %d)",
                    (unsigned int)dspy, err);
			continue;
		}
		
        /*	if(brightness > 0.0){
         }else{
         }*/
	}		
	
}
@end

#endif //LUILISTENER
