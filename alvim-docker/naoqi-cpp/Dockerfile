FROM alvimpaulo/naoqi-qibuild:2.8.5

COPY ctc-linux64-atom-2.8.5.10.zip /nao/devtools/
RUN unzip /nao/devtools/ctc-linux64-atom-2.8.5.10.zip -d /nao/devtools/ && rm -R /nao/devtools/ctc-linux64-atom-2.8.5.10.zip

USER root
RUN chown -R unbeatables:unbeatablesgrp /home/unbeatables
USER unbeatables

RUN qitoolchain create v6-ctc /nao/devtools/ctc-linux64-atom-2.8.5.10/toolchain.xml
RUN cd /nao/ && qibuild add-config v6-ctc -t v6-ctc --default

ENTRYPOINT ["tail", "-f", "/dev/null"]