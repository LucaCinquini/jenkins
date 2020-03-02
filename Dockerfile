# Dockefile to create Europa Clipper CWS adaptation 
FROM cae-artifactory.jpl.nasa.gov:16003/gov/nasa/jpl/ammos/cws:1.7
ARG JPL_GITHUB_TOKEN

USER root

# update OS and install additional libraries
RUN yum update -y &&\
	yum install -y curl git wget net-tools nc &&\
	yum clean all
	
# mysql dependencies need to execute tests with mysql client
RUN yum install -y mysql-devel gcc gcc-devel python-devel &&\
    yum clean all
    
# note: download RPM and install it with YUM so to pick up dependencies too
# must be done as root
RUN cd /usr/local &&\
    wget 'https://downloads.wkhtmltopdf.org/0.12/0.12.5/wkhtmltox-0.12.5-1.centos7.i686.rpm' &&\
    yum localinstall -y wkhtmltox-0.12.5-1.centos7.i686.rpm
    
# change timezone to UTC
RUN cp /etc/localtime /root/old.timezone &&\
    rm /etc/localtime &&\
    ln -s /usr/share/zoneinfo/UTC /etc/localtime
ENV TZ=UTC
	
USER cws_user
ENV HOME=/home/cws_user

# install Python 3.X with Miniconda
ENV CONDA_HOME=${HOME}/conda
ENV PATH=${CONDA_HOME}/bin:$PATH
RUN cd && \
    wget https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda.sh && \
    bash ~/miniconda.sh -b -p ${CONDA_HOME}

# create virtual env with all PGE dependencies
RUN conda update -n base -c defaults conda &&\
    conda create -n pge_venv
RUN source activate pge_venv &&\
    pip install awscli
RUN source activate pge_venv &&\
    pip install wget
# note: must currently install an older version of OCS Python to work with the Europa Clipper OCS API
RUN source activate pge_venv &&\
    pip install m20-operational-cloud-store==6.0.1 -i https://cae-artifactory.jpl.nasa.gov/artifactory/api/pypi/pypi-release-virtual/simple

# install EuroC source code repositories (non-Python)
ENV SRC_DIR=${HOME}/src
RUN mkdir -p $SRC_DIR
RUN ls -l
RUN cd $SRC_DIR &&\
    git clone https://${JPL_GITHUB_TOKEN}:x-oauth-basic@github.jpl.nasa.gov/EURC-SDS/pcs-bpmn &&\
    git clone https://${JPL_GITHUB_TOKEN}:x-oauth-basic@github.jpl.nasa.gov/EURC-SDS/pcs-java &&\
    git clone https://${JPL_GITHUB_TOKEN}:x-oauth-basic@github.jpl.nasa.gov/EURC-SDS/pcs-cws 
    
# install python dependencies
RUN cd $SRC_DIR &&\
    git clone https://${JPL_GITHUB_TOKEN}:x-oauth-basic@github.jpl.nasa.gov/EURC-SDS/sds-core &&\
    cd sds-core &&\
    pip install --upgrade setuptools &&\
    source activate pge_venv &&\
    python setup.py install

RUN cd $SRC_DIR &&\
    git clone https://${JPL_GITHUB_TOKEN}:x-oauth-basic@github.jpl.nasa.gov/EURC-SDS/pge-python &&\
    cd pge-python &&\
    source activate pge_venv &&\
    python setup.py install
    
RUN cd $SRC_DIR &&\
    git clone https://${JPL_GITHUB_TOKEN}:x-oauth-basic@github.jpl.nasa.gov/EURC-SDS/pcs-python &&\
    cd $SRC_DIR/pcs-python && \
    source activate pge_venv &&\
    pip install -r requirements.txt
    
RUN cd $SRC_DIR &&\
    git clone https://${JPL_GITHUB_TOKEN}:x-oauth-basic@github.jpl.nasa.gov/EURC-SDS/pcs-test &&\
    cd pcs-test && \
    source activate pge_venv &&\
    pip install -r requirements.txt
    
# install elasticsearch and elasticsearch-dsl 7.X
#RUN source activate pge_venv &&\
#    pip install --upgrade elasticsearch-dsl==6.4.0

# install testing framework and dependencies
RUN cd $SRC_DIR &&\ 
    git clone https://${JPL_GITHUB_TOKEN}:x-oauth-basic@github.jpl.nasa.gov/iSDS/cws-pytest &&\
    cd cws-pytest &&\
    source activate pge_venv &&\
    pip install -r requirements.txt
ENV PYTHONPATH $SRC_DIR/cws-pytest
    
ENV CWS_INSTALL /home/cws_user/cws
ENV CATALINA_HOME ${CWS_INSTALL}/server/apache-tomcat-9.0.12

# deploy the BPMN diagrams
RUN cp $SRC_DIR/pcs-bpmn/workflows/*.bpmn ${CWS_INSTALL}/bpmn/.
    
# deploy euroc adaptation jar to webapps directories
RUN cp $SRC_DIR/pcs-cws/docker/jars/ ${CATALINA_HOME}/lib/.
RUN cp $SRC_DIR/pcs-cws/docker/jars/ ${CATALINA_HOME}/webapps/cws-ui/WEB-INF/lib/.
RUN cp $SRC_DIR/pcs-cws/docker/jars/ ${CATALINA_HOME}/webapps/cws-engine/WEB-INF/lib/.
RUN cp $SRC_DIR/pcs-cws/docker/jars/ ${CATALINA_HOME}/webapps/camunda/WEB-INF/lib/.
RUN cp $SRC_DIR/pcs-cws/docker/jars/ ${CATALINA_HOME}/webapps/engine-rest/WEB-INF/lib/.

# override startup script to automatically enable workers, initiators
COPY ./wait_for_mariadb.sh /home/cws_user/wait_for_mariadb.sh
COPY ./startup.sh /home/cws_user/startup.sh
COPY ./deploy.sh /home/cws_user/cws/deploy.sh

ENTRYPOINT [ "./wait_for_mariadb.sh" ]
