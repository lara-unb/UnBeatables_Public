FROM ubuntu:16.04

RUN groupadd -r unbeatablesgrp && useradd -r -g unbeatablesgrp unbeatables
RUN mkhomedir_helper unbeatables
RUN chown -R  unbeatables:unbeatablesgrp /home/unbeatables
RUN mkdir -p /choregraphe/
RUN chown -R  unbeatables:unbeatablesgrp /choregraphe/


COPY choregraphe-suite-2.8.6.23-linux64-setup.run ./choregraphe

RUN /choregraphe/choregraphe-suite-2.8.6.23-linux64-setup.run --mode unattended --installdir /choregraphe/
RUN rm /choregraphe/choregraphe-suite-2.8.6.23-linux64-setup.run

RUN  apt-get update \
  && apt-get install -y \
  wget \
  xz-utils \
  qt5-default \
  libavcodec-dev \
  libavformat-dev \
  libswscale-dev -y \
  libgl1-mesa-glx \
  libglib2.0-0 \
  libxaw7 \
  libxt6 \
  libxrandr2 \
  && rm -rf /var/lib/apt/lists/*

USER unbeatables
CMD /choregraphe/choregraphe