#!/usr/bin/env python

import qi
import argparse
import sys
import os
import threading

#logging information
#https://realpython.com/python-logging/
import logging
#change logging level accordingly
logging.basicConfig(level=logging.INFO)

# Adding competition code modules to library path
sys.path.append(os.path.join(sys.path[0], 'v6_action'))
sys.path.append(os.path.join(sys.path[0], 'v6_behavior'))
sys.path.append(os.path.join(sys.path[0], 'v6_perception'))
sys.path.append(os.path.join(sys.path[0], 'v6_communication'))

# Importing competition code modules
import action
import behavior
import perception
import communication
import testing

try:
    code_location = os.environ["NAO_CODE_LOCATION"]
except KeyError as error:
    print(error)
    raise KeyError(
        "NAO_CODE_LOCATION enviroment variable not set. Should be similar to '/home/nao/v6_competitionCode'. Please check documentation."
    )

# Establishing connection with the robot
parser = argparse.ArgumentParser()
parser.add_argument(
    "--ip",
    type=str,
    default="127.0.0.1",
    help="Robot IP address. On robot or Local Naoqi: use '127.0.0.1'.")
parser.add_argument("--port", type=int, default=9559, help="Naoqi port number")
parser.add_argument("--simulation", type=bool, default=False, help="Whether code is running is simulation or a real robot")

args = parser.parse_args()
session = qi.Session()

#parse naoqi stuff
try:
    session.connect("tcp://" + args.ip + ":" + str(args.port))
except RuntimeError:
    logging.exception(
        "Can't connect to Naoqi at ip \"" + args.ip + "\" on port " +
        str(args.port) + ".\n"
        "Please check your script arguments. Run with -h option for help.")
    sys.exit(1)

#parse simulation stuff
is_simulation = args.simulation

# Threads

action.session = session
perception.session = session
behavior.session = session

try:
    logging.info("Starting behavior thread ...")
    behavior_thread = threading.Thread(target=behavior.main, kwargs={"is_simulation":is_simulation})
    behavior_thread.start()
    logging.debug("Behavior thread started!")

    logging.info("Starting perception thread ...")
    perception_thread = threading.Thread(target=perception.main, kwargs={"is_simulation":is_simulation})
    perception_thread.start()
    logging.debug("Perception thread started!")

    # logging.info("Starting communication thread ...")
    # communication_thread = threading.Thread(target=communication.main)
    # communication_thread.start()
    # logging.debug("communication thread started!")

    behavior_thread.join()
    perception_thread.join()
    # communication_thread.join()

except:
    sys.exit(1)