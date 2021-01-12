import os
import argparse
import subprocess
import logging

parser = argparse.ArgumentParser()
parser.add_argument("operation")
parser.add_argument("container_name")
parser.add_argument("--num", type=int, default=1, help="Number of robots to be used when lauching naoqi-sdk")
parser.add_argument("--cmd")
parser.add_argument("--cmd-arg")
args = parser.parse_args()

if os.name == "nt":
    #windows
    cmd_prefix = ""
else:
    cmd_prefix = "sudo"

try:
    nao_folder_location = os.environ["NAO_FOLDER_LOCATION"]
    if ("workspace" not in os.listdir(nao_folder_location)):
        raise RuntimeError(
            "workspace not found in nao folder. Did you configure it correctly?"
        )
except KeyError:
    logging.error(
        " NAO_FOLDER_LOCATION not found, please set it to something like /home/paulo/nao. Using $HOME/nao."
    )
    nao_folder_location = os.environ["HOME"] + "/nao"

if os.name != "nt":
    #linux
    if (args.operation == "rm-all"):
        subprocess.call(
            "{} docker container list -a | awk  '{print $1}' | xargs -I \{\} {} docker container rm {}"
            .format(cmd_prefix, cmd_prefix))

# docker run a container
if (args.operation == "run"):
    if (args.container_name == "vrep"):
        subprocess.call(
            '{} docker run --rm -d --net=host --env="DISPLAY" --volume="$HOME/.Xauthority:/root/.Xauthority:rw" -v "{}/workspace/:/nao/workspace/" --name vrep  alvimpaulo/vrep:4.1'
            .format(cmd_prefix, nao_folder_location),
            shell=True)
    elif (args.container_name == "naoqi-sdk"):
        for idx in range(args.num):
            cmd_return = subprocess.Popen([
                cmd_prefix, "docker", "run", "-d", "--net=host", "-e",
                "NAO_CODE_LOCATION=\"/nao/workspace/UnBeatables/v6_competitionCode/\"",
                "-v",
                "{}/workspace/:/nao/workspace/".format(nao_folder_location),
                "-v", "/dev/:/dev/", "--name", "naoqi-sdk-{}".format(idx),
                "alvimpaulo/naoqi-sdk:2.8.5",
                "/nao/devtools/naoqi-sdk-2.8.5.10-linux64/naoqi", "-v",
                "--disable-life", "-p", str(9600 + idx)
            ]).wait()
            if(cmd_return == 125):
                cmd_return = subprocess.Popen([
                cmd_prefix, "docker", "start", "naoqi-sdk-{}".format(idx)]).wait()
            elif(cmd_return != 0):
                print("Erro no docker, id = {}".format(cmd_return))

    elif (args.container_name == "choregraph"):
        subprocess.call(
            '{} docker run --rm -d --net=host --env="DISPLAY" --volume="$HOME/.Xauthority:/root/.Xauthority:rw" --name choregraph alvimpaulo/choregraph:2.8.6'
            .format(cmd_prefix),
            shell=True)
    elif (args.container_name == "naoqi-python-sdk"):
        subprocess.call(
            '{} docker run --rm -e NAO_CODE_LOCATION="/nao/workspace/UnBeatables/v6_competitionCode/" -d -v "{}/workspace/:/nao/workspace/"  -v /dev/:/dev/ --name naoqi-python-sdk alvimpaulo/naoqi-python-sdk:2.8.5'
            .format(cmd_prefix, nao_folder_location),
            shell=True)
    elif (args.container_name == "choregraphe"):
        subprocess.call(
            '{} docker run --rm --env="DISPLAY" --net=host --volume="$HOME/.Xauthority:/root/.Xauthority:rw" -v "{}/workspace/:/nao/workspace/" --name choregraphe  alvimpaulo/choregraphe:2.8.6'
            .format(cmd_prefix, nao_folder_location),
            shell=True)

    else:
        subprocess.call(
            '{} docker run --rm -d -v "{}/workspace/:/nao/workspace/" --name {} alvimpaulo/{}:2.8.5'
            .format(cmd_prefix, nao_folder_location, args.container_name,
                    args.container_name),
            shell=True)

# exec some program into container
if (args.operation == "exec"):
    subprocess.call("{} docker exec {} {} {}".format(cmd_prefix,
                                                     args.container_name,
                                                     args.cmd, args.cmd_arg),
                    shell=True)

# run bash into named container
if (args.operation == "ssh"):
    subprocess.call("{} docker exec -it {} bash".format(
        cmd_prefix, args.container_name),
                    shell=True)

# TODO: passar pro robo vitual
# TODO: passar pro robo real

# TODO: rodar no robo virtual
# TODO: rodar no robo real

# TODO: rodar um arquivo de python
# TODO: rodar o competition code

# TODO: remover containers parados
# TODO: parar os containers
# TODO: start container
