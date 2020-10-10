#!/usr/bin/env python

import mapBehavior
import action
import unboard
import time

t0 = 0.0
TURN_TIME = 18.0
firstPass = True


## 	\brief Closed loop for walking ball when ball is seen in bot camera
def behaviorAction():


    global firstPass
    global t0

    # State led
    if(firstPass):
        t0 = time.time()
        firstPass = False

    # State led
    action.leds.SetRightEyeLeds(action.session, "magenta")

    # Adjust head
    action.movements.jointName = "HeadYaw"
    action.movements.Angle = 0.0
    action.movements.MaxSpeed = 0.1
    action.movements.HeadMove(action.session)

    action.movements.jointName = "HeadPitch"
    action.movements.Angle = 29.0
    action.movements.MaxSpeed = 0.1
    action.movements.HeadMove(action.session)

    if(unboard.ballSide == "Left"):
        sign = 1
    else:
        sign = -1


    action.movements.X = 0.0
    action.movements.Y = 0.0
    action.movements.Theta = sign*0.5
    action.movements.Walk(action.session)

    print("Look", action.movements.X, action.movements.Y, unboard.ballSide)



    
def behaviorTransition():
    global firstPasss
    global t0

    t = time.time()

    if(unboard.seeBallBot):
        firstPass = True
        action.movements.Theta = 0.0
        return mapBehavior.walkBall_bot
    elif(unboard.seeBallTop):
        firstPass = True
        action.movements.Theta = 0.0
        return mapBehavior.walkBall_top
    if(t-t0 > TURN_TIME):
        firstPass = True
        print("Sair lookForBall")
    

    return mapBehavior.lookForBall