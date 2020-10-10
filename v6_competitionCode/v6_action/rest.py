#!/usr/bin/env python

## 	\brief This module is responsable for making the robot rest.
#	\param session Connection with the robot.


def main(session):

    motion_service = session.service("ALMotion")

    try:
        motion_service.rest()
    except:
        logging.error("Fail rest")
        exit()
