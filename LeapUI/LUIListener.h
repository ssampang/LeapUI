//
//  LUIListener.h
//  LeapUI
//
//  Created by Siddarth Sampangi on 28/04/2013.
//  Copyright (c) 2013 Siddarth Sampangi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LeapObjectiveC.h"

@interface LUIListener : NSObject <LeapListener>

- (void) run;

@end
