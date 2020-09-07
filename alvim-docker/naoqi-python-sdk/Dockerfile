FROM python:2


RUN groupadd -r unbeatablesgrp && useradd -r -g unbeatablesgrp unbeatables
RUN mkhomedir_helper unbeatables

RUN mkdir -p /nao/devtools/
RUN chown -R  unbeatables:unbeatablesgrp /nao/
RUN chown -R  unbeatables:unbeatablesgrp /home/unbeatables

USER unbeatables

# RUN wget -c https://community-static.aldebaran.com/resources/2.8.5/pynaoqi-python2.7-2.8.5.10-linux64-20181203_200915.tar.gz
COPY --chown=unbeatables:unbeatablesgrp ./pynaoqi-python2.7-2.8.5.10-linux64-20181203_200915.tar.gz /nao/devtools/
RUN tar -xvzf /nao/devtools/pynaoqi-python2.7-2.8.5.10-linux64-20181203_200915.tar.gz -C /nao/devtools/ && rm -R /nao/devtools/pynaoqi-python2.7-2.8.5.10-linux64-20181203_200915.tar.gz

COPY requirements.txt /

RUN pip install -r /requirements.txt

ENV PYTHONPATH=${PYTHONPATH}:/nao/devtools/pynaoqi-python2.7-2.8.5.10-linux64-20181203_200915/lib/python2.7/site-packages
ENV QI_SDK_PREFIX=/nao/devtools/pynaoqi-python2.7-2.8.5.10-linux64-20181203_200915

CMD ["tail", "-f", "/dev/null"]
