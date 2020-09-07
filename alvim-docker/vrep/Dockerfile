FROM ubuntu:18.04

RUN apt-get update && apt-get upgrade -y

RUN  apt-get update \
  && apt-get install -y \
  wget \
  xz-utils \
  qt5-default \
  && rm -rf /var/lib/apt/lists/*

RUN apt-get update && apt-get install libavcodec-dev libavformat-dev libswscale-dev -y

RUN apt-get update && apt-get install -y git cmake build-essential

RUN mkdir -p /nao/vrep/

# RUN wget -c https://www.coppeliarobotics.com/files/CoppeliaSim_Edu_V4_1_0_Ubuntu18_04.tar.xz -P /nao/vrep/
COPY ./CoppeliaSim_Edu_V4_1_0_Ubuntu18_04.tar.xz /nao/vrep/
RUN tar -xJf /nao/vrep/CoppeliaSim_Edu_V4_1_0_Ubuntu18_04.tar.xz -C /nao/vrep/ && rm -R /nao/vrep/CoppeliaSim_Edu_V4_1_0_Ubuntu18_04.tar.xz

RUN git clone https://github.com/CoppeliaRobotics/videoRecorder.git
RUN cd videoRecorder/ && cmake . && make
RUN mv /videoRecorder/lib/libvvcl.so /nao/vrep/CoppeliaSim_Edu_V4_1_0_Ubuntu18_04/libvvcl.so
RUN rm -r /videoRecorder

CMD /nao/vrep/CoppeliaSim_Edu_V4_1_0_Ubuntu18_04/coppeliaSim.sh
