#FROM node:7-alpine
#RUN apk add -U subversion

FROM cae-artifactory.jpl.nasa.gov:16003/gov/nasa/jpl/ammos/cws:1.7
ARG JPL_GITHUB_TOKEN

USER root

#RUN yum update -y 

USER cws_user

ENV SRC_DIR=${HOME}/src
RUN mkdir -p $SRC_DIR
RUN ls -l
RUN cd $SRC_DIR &&\
    git clone https://${JPL_GITHUB_TOKEN}:x-oauth-basic@github.jpl.nasa.gov/EURC-SDS/pcs-bpmn



