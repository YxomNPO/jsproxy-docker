# Version 0.0.1
From ubuntu:20.04
MAINTAINER ericxin "doreanmon@yahoo.com"
RUN apt-get update && apt-get upgrade -y
RUN apt-get install curl -y
RUN apt-get install gcc -y
RUN cd /root
RUN touch powered_by_ericxin
RUN touch introduction
RUN echo 'visit IP.xip.io as your website' \
	>/root/introduction
RUN curl https://raw.githubusercontent.com/YxomNPO/jsproxy-docker/master/i.sh | bash
EXPOSE 2333
