FROM ubuntu:18.04

ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8

RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
        apt-get install -y software-properties-common python-docopt sudo curl \
        python-dev git 'python.*-pip' python3-minimal 'python2.*-minimal' \
        gnupg2 python3-pip sshpass openssh-client openssh-server vim && \
        rm -rf /var/lib/apt/lists/* && \
        apt-get clean
    
RUN python3 -m pip install --upgrade pip cffi \
    pip install setuptools && \
    pip install ansible==2.10.3 ansible-base==2.10.3 && \
    pip install ansible-lint

RUN mkdir /ansible && \
    mkdir -p /etc/ansible && \
    echo 'localhost' > /etc/ansible/hosts

COPY ansible.cfg /root/.ansible.cfg

RUN mkdir /ansible/la-inventories && \
    mkdir /ansible/ala-install

WORKDIR /ansible

# https://docs.docker.com/engine/examples/running_ssh_service/
RUN mkdir /var/run/sshd
RUN echo 'root:root' | chpasswd
RUN sed -i 's/#*PermitRootLogin prohibit-password/PermitRootLogin yes/g' /etc/ssh/sshd_config

# SSH login fix. Otherwise user is kicked off after login
RUN sed -i 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' /etc/pam.d/sshd

ENV NOTVISIBLE="in users profile"
RUN echo "export VISIBLE=now" >> /etc/profile

RUN mkdir -p /root/.ssh/config.d && \
    chmod 0700 /root/.ssh

# Generate a ssh key to use internally
RUN ssh-keygen -q -t rsa -N '' -f /root/.ssh/id_rsa
RUN echo "include config.d/*" > /root/.ssh/config

# Be use 'ubuntu' user by default, let's create
RUN useradd -ms /bin/bash ubuntu
RUN adduser ubuntu sudo
# This helps ansible to run faster
RUN echo 'Defaults:ubuntu !requiretty' >> /etc/sudoers
# Configure sudo without password
RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# Authorize generated ssh key to ubuntu user
RUN mkdir -p /home/ubuntu/.ssh && \
    chmod 0700 /home/ubuntu/.ssh && \
    cp /root/.ssh/id_rsa.pub /home/ubuntu/.ssh/authorized_keys && \
    chown ubuntu:ubuntu -R /home/ubuntu/.ssh

# Not necessary right now
# EXPOSE 22

# Add extra users and dirs
RUN useradd tomcat7 && \
    useradd solr && \
    useradd image-service && \
    useradd doi-service && \
    useradd postgres

RUN mkdir -p /opt/solr/bin && \
    mkdir /usr/lib/biocache

RUN echo "2021012601 (change this date to rebuild & repeat this and the following steps)"

RUN git clone --depth 1 --branch v2.1.7 https://github.com/AtlasOfLivingAustralia/ala-install.git /ansible/ala-install

CMD ["/usr/sbin/sshd", "-D"]
