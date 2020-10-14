#!/usr/bin/env python


## 	\brief This module is responsable for making the robot stand.
#	\param session Connection with the robot.
def main(session, position):

    motion_service = session.service("ALMotion")
    posture_service = session.service("ALRobotPosture")

    # Wake up robot
    motion_service.wakeUp()

    try:
        # Send robot to Stand
        posture_service.goToPosture(position, 0.8)
    except:
        logging.error("Fail stand")
        exit()
