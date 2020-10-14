import mapBehavior
import action

import unboard


def behaviorAction():

    action.leds.SetLeftEyeLeds(action.session, "green")
    action.leds.SetRightEyeLeds(action.session, "green")

    action.movements.StopWalk(action.session)


def behaviorTransition(behaviorName=''):
    if (behaviorName == ''):
        return mapBehavior.testBehaviour
    else:
        return mapBehavior.kicking