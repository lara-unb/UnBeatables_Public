FROM alvimpaulo/naoqi-qibuild:2.8.5

USER unbeatables
COPY --chown=unbeatables:unbeatablesgrp ./naoqi-sdk-2.8.5.10-linux64.tar.gz /nao/devtools/

# RUN wget -c https://community-static.aldebaran.com/resources/2.8.5/naoqi-sdk-2.8.5.10-linux64.tar.gz -O /nao/devtools/naoqi-sdk-2.8.5.10-linux64.tar.gz
RUN tar -xvzf /nao/devtools/naoqi-sdk-2.8.5.10-linux64.tar.gz -C /nao/devtools/ && rm -R /nao/devtools/naoqi-sdk-2.8.5.10-linux64.tar.gz

USER root
RUN mkdir -p /home/unbeatables/.config/naoqi
RUN chown -R unbeatables:unbeatablesgrp /home/unbeatables/
USER unbeatables

RUN wget -c https://gist.githubusercontent.com/alvimpaulo/2995da9628e7bb17e9951315ebca40b4/raw/4ea5571d35fdbe84aa0792a556ec4fbd238630d3/ALRobotModel.xml -O /home/unbeatables/.config/naoqi/ALRobotModel.xml

RUN qitoolchain create v6-sdk /nao/devtools/naoqi-sdk-2.8.5.10-linux64/toolchain.xml
RUN cd /nao/ && qibuild add-config v6-sdk -t v6-sdk --default

CMD [ "/nao/devtools/naoqi-sdk-2.8.5.10-linux64/naoqi" ]