#FROM node:7-alpine
#RUN apk add -U subversion

FROM cae-artifactory.jpl.nasa.gov:16003/gov/nasa/jpl/ammos/cws:1.7

USER root

RUN yum update -y 
