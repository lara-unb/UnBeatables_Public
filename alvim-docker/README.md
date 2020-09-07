# docker-unbeatables
Repositorio com os arquivos de configuração e execução da equipe de futebol de robôs UnBeatables.

Dentro de cada pasta, existem os Dockerfile de cada build dos containers. Todos eles estão localizados em https://hub.docker.com/u/alvimpaulo

Para rodar os containers, usar `python run.py operation container_name --cmd`, onde:

`operation`: obrigatório. Por enquanto, apenas run, no futuro: exec, rm, etc.

`container_name`: obrigatório. nome do container. ex: naoqi-sdk, vrep, etc

--cmd: opicional. para quando for usar o exec.
