import mapBehavior
import action
import time

import unboard

behaviorName = "kick"


def behaviorAction():
    # State led
    action.leds.SetRightEyeLeds(action.session, "cyan")
    action.movements.StopWalk(action.session)
    
    action.movements.Shooting(action.session)
    action.movements.StopWalk(action.session)
    action.movements.Stand(action.session)

## 	\brief Transitions to walkBall_bot after some seconds
def behaviorTransition():
    return mapBehavior.lookForBall
		
