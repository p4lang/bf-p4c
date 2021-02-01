# Dockerfile
ARG DOCKER_BASE_IMAGE=barefootnetworks/jarvis:tofino
FROM $DOCKER_BASE_IMAGE
ARG USER=user
ARG UID=1002
ARG GID=1002
ARG HTTP_PROXY=http://proxy-mu.intel.com:911/
ARG HTTPS_PROXY=http://proxy-mu.intel.com:912/
# default password for user
ARG PW=docker
# Option1: Using unencrypted password/ specifying password
RUN useradd -m ${USER} --uid=${UID} -s/bin/bash && echo "${USER}:${PW}" | \
      chpasswd
# Copy the actual authorized keys into container
COPY ssh/authorized_keys /home/${USER}/.ssh/ 
RUN  chmod -R 700 /home/${USER}/.ssh && chown -R ${USER} /home/${USER}/.ssh

#USER ${UID}:${GID}
#WORKDIR /home/${USER}
RUN echo "Acquire::http::proxy \"${HTTP_PROXY}\"; Acquire::https::proxy \"${HTTPS_PROXY}\";" > /etc/apt/apt.conf.d/99HttpProxy
RUN apt update && apt install -y graphviz openssh-server sudo htop mc
RUN usermod -a -G sudo ${USER}
RUN service ssh start
COPY run-ssh /sbin/ 
RUN chmod 755 /sbin/run-ssh
RUN pip3 --proxy ${HTTPS_PROXY} install cpplint pylint autopep8

# Install new version of cmake
RUN sudo apt-get install -y apt-transport-https ca-certificates gnupg software-properties-common wget && wget -O - https://apt.kitware.com/keys/kitware-archive-latest.asc 2>/dev/null | \
	gpg --dearmor - | sudo tee /etc/apt/trusted.gpg.d/kitware.gpg >/dev/null
COPY cmake /etc/apt/preferences.d/
RUN sudo apt-add-repository 'deb https://apt.kitware.com/ubuntu/ xenial main' && apt update && apt install -y cmake cmake-curses-gui

# Edit the bashrc script to start SSH server automatically
RUN echo "/sbin/run-ssh" >> ~/.bashrc
EXPOSE 22
