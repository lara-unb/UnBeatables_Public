FROM alvimpaulo/naoqi-python-sdk:2.8.5

USER root

RUN apt-get update && apt-get install -y build-essential
RUN apt-get update && apt-get install -y libglib2.0-dev
RUN apt-get update && apt-get install -y cmake

USER unbeatables
ENV HOME="/home/unbeatables"

RUN pip install qibuild --user
COPY ./qibuild.xml ${HOME}/.config/qi/

ENV PATH="${HOME}/.local/bin:${PATH}"

RUN mkdir -p /nao/workspace
RUN mkdir -p /nao/devtools

RUN cd /nao/ &&  qibuild init

CMD bash