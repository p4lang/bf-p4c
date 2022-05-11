################################################################################
# Dockerfile For VSCode
################################################################################
# This Dockerfile can be invoked in 2 ways
#
# 1. From build-image.sh which allows direct ssh into docker container (see
# details in README). This requires the SSH configuration in the Dockerfile to
# be enabled
#
# 2. Directly from Remote Containers Extension - In this case there is no need
# for a separate ssh connection or port forwarding and the plugin takes care of
# setting up the ssh and connecting to the docker container.  Specifics are in
# .devcontainer/devcontainer.json file. This requires the SSH configuration in
# the Dockerfile to be disabled
################################################################################
ARG SRC_IMG=latest
ARG DOCKER_BASE_IMAGE=amr-registry.caas.intel.com/bxd-sw/jarvis:$SRC_IMG

FROM ${DOCKER_BASE_IMAGE} as jarvis-vscode

ARG USER=user
ARG UID=1000
ARG GID=1000
# Do not set default value!
ARG KEY_DIR

ARG HTTP_PROXY=http://proxy-dmz.intel.com:911/
ARG HTTPS_PROXY=http://proxy-dmz.intel.com:912/

# Diagnostic
RUN echo USER=${USER} UID=${UID} GID=${GID} KEY_DIR=${KEY_DIR}

# default password for user
ARG PW=docker

# Package installation
# ====================
# Configure proxies
# Unsure why the HTTPS proxy has to point to the http version, but it doesnt' work otherwise
RUN echo "Acquire::http::proxy \"${HTTP_PROXY}\"; Acquire::https::proxy \"${HTTP_PROXY}\";" > /etc/apt/apt.conf.d/99HttpProxy

# Install useful packages
RUN apt-get update && apt-get install -y graphviz openssh-server sudo htop mc clang-format clang-tidy clang-format-8 clang-tidy-8 bash-completion

RUN python3 -m pip --proxy ${HTTPS_PROXY} install cpplint pylint autopep8

# Install updated version of cmake
RUN apt-get install -y apt-transport-https ca-certificates gnupg software-properties-common wget && \
    wget -O - https://apt.kitware.com/keys/kitware-archive-latest.asc 2>/dev/null | \
    gpg --dearmor - | tee /etc/apt/trusted.gpg.d/kitware.gpg >/dev/null
COPY cmake /etc/apt/preferences.d/
#RUN apt-add-repository "deb https://apt.kitware.com/ubuntu/ `lsb_release -cs` main" && \
#    apt-get update && apt-get install -y cmake cmake-curses-gui

# User creation
# =============
# Create the user using enencrypted password
RUN useradd -m ${USER} --uid=${UID} -s/bin/bash && echo "${USER}:${PW}" | chpasswd

# Configure the user to use sudo
RUN usermod -a -G sudo ${USER}
RUN echo "${USER} ALL = (root) NOPASSWD:ALL" > /etc/sudoers.d/${USER}

FROM jarvis-vscode as jarvis-vscode-ssh-tunnel
# SSH configuration
# =================
# Disabled when Dockerfile is directly invoked / KEY_DIR is not set
# only on jarvis-ssh-to-docker target

# Copy the authorized keys into container
# (Not used when home dirs mounted inside container)
ARG KEY_DIR
ARG USER
COPY ${KEY_DIR}/authorized_keys /home/${USER}/.ssh/authorized_keys
RUN chmod 700 /home/${USER}/.ssh && \
    chmod 600 /home/${USER}/.ssh/* && \
    chown -R ${USER} /home/${USER}/.ssh

# Copy SSH host keys
# (Maintains keys across image builds so that you don't have to update
# known_hosts each time you regenerate the docker image.)
COPY --chown=root:root ${KEY_DIR}/ssh_host_rsa_key /etc/ssh/
COPY --chown=root:root ${KEY_DIR}/ssh_host_rsa_key.pub /etc/ssh/
COPY --chown=root:root ${KEY_DIR}/ssh_host_dsa_key /etc/ssh/
COPY --chown=root:root ${KEY_DIR}/ssh_host_dsa_key.pub /etc/ssh/
COPY --chown=root:root ${KEY_DIR}/ssh_host_ecdsa_key /etc/ssh/
COPY --chown=root:root ${KEY_DIR}/ssh_host_ecdsa_key /etc/ssh/
COPY --chown=root:root ${KEY_DIR}/ssh_host_ed25519_key.pub /etc/ssh/
COPY --chown=root:root ${KEY_DIR}/ssh_host_ed25519_key.pub /etc/ssh/

# Start SSH server to ensure necessary directories are created
RUN service ssh start

# Configure SSH to start when launching a root shell
COPY run-ssh /sbin/
RUN chmod 755 /sbin/run-ssh
COPY root-bashrc /root/.bashrc

# Expose the port to the outside world
EXPOSE 22
