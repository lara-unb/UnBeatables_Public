#!/usr/bin/env python

import mapBehavior
import action
import unboard

lastBallY = 0.0

def xy_movements_clamper(number):
    """Function to clamp number between -1.0 and 1.0. Use with arguments in moveToward.

    Args:
        number (float): number to clamp

    Returns:
        float: number clamped between -1.0 and 1.0.
    """    
    return max(min(number, 1.0), -1.0)
    
## 	\brief Closed loop for walking ball when ball is seen in top camera
def behaviorAction():
    
    global lastBallY


    # State led
    action.leds.SetRightEyeLeds(action.session, "white")

    # Adjust head
    action.movements.jointName = "HeadYaw"
    action.movements.Angle = 0.0
    action.movements.MaxSpeed = 0.1
    action.movements.HeadMove(action.session)

    action.movements.jointName = "HeadPitch"
    action.movements.Angle = 10.0
    action.movements.MaxSpeed = 0.1
    action.movements.HeadMove(action.session)


    if(unboard.seeBallTop == True): 

        ballX = unboard.ballXTop
        ballY = unboard.ballYTop

        # Walk ball in closed loop. 
        # Here we set the walk parametes according with ball position return in unboard.
        if(unboard.ballXTop < 0.4 and unboard.ballXTop != -1):
            action.movements.Y = xy_movements_clamper(float(2 * (0.5 - unboard.ballXTop)))
        elif(unboard.ballXTop > 0.7 and unboard.ballXTop != -1):
            action.movements.Y = xy_movements_clamper(float(2 * (0.5 - unboard.ballXTop)))
        else:
            action.movements.Y = float(0.0)

        if(unboard.ballYTop < 0.80 and unboard.ballYTop != -1):
            action.movements.X = float(0.8)
        else:
            action.movements.X = float(0.0)
        
        action.movements.Walk(action.session)

        lastBallY = ballY

    else:
        action.movements.StopWalk(action.session)



## 	\brief  Transitions to walkBall_bot if ball is seen in bot camera.
#           Transitions to approachBall if ballY is too low on top camera.
#           Transitions to walkBall_top if ball is seen in top camera.
def behaviorTransition():   
    global lastBallY

    if(unboard.seeBallBot):
        lastBallY = 0
        return mapBehavior.walkBall_bot
    elif(lastBallY > 0.8):
        return mapBehavior.approachBall
    else:
        return mapBehavior.walkBall_top