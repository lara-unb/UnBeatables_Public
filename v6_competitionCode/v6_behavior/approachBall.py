#!/usr/bin/env python

import mapBehavior
import action
import unboard
import time


firstPass = True
t0 = 0.0
WALK_TIME = 4.0

## 	\brief Walk in open loop if ball is between top camera and bot camera
def behaviorAction():
    global firstPass
    global t0

    # State led
    if(firstPass):
        t0 = time.time()
        firstPass = False
    
    action.leds.SetRightEyeLeds(action.session, "yellow")
        
    action.movements.X = 0.6
    action.movements.Y = 0
    action.movements.Walk(action.session)

## 	\brief Transitions to walkBall_bot after 4 seconds
def behaviorTransition():
    global firstPass
    global t0

    t = time.time()

    if(t-t0 > WALK_TIME):
        firstPass = True
        return mapBehavior.walkBall_bot 
    
    return mapBehavior.approachBall

