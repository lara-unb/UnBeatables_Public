FROM ubuntu:16.04

RUN apt-get update && apt-get install -y wget libglib2.0-0 libfreetype6 libsm6 libxrender1 libfontconfig1 libxext6

RUN wget --no-check-certificate 'https://docs.google.com/uc?export=download&id=1x6FP2Mn0HWhfLuGOKzUisz0jcEPR63rD' -O flasher-2.1.0.19-linux64.tar.gz

RUN tar -xvf flasher-2.1.0.19-linux64.tar.gz

RUN rm flasher-2.1.0.19-linux64.tar.gz

RUN apt update && apt install -y sudo


CMD ["bash", "/flasher-2.1.0.19-linux64/flasher"]
