#FROM node:7-alpine
#RUN apk add -U subversion

FROM cae-artifactory.jpl.nasa.gov:16003/gov/nasa/jpl/ammos/cws:1.7
ARG JPL_GITHUB_TOKEN

USER root

# update OS and install additional libraries
RUN yum update -y &&\
	yum install -y curl git wget net-tools nc &&\
	yum clean all

#RUN yum update -y 

USER cws_user
ENV HOME=/home/cws_user

RUN echo $JPL_GITHUB_TOKEN

ENV SRC_DIR=${HOME}/src
RUN mkdir -p $SRC_DIR
RUN ls -l
RUN cd $SRC_DIR &&\
    git clone https://${JPL_GITHUB_TOKEN}:x-oauth-basic@github.jpl.nasa.gov/EURC-SDS/pcs-bpmn



