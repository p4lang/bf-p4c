# Dockerfile
ARG DOCKER_BASE_IMAGE=barefootnetworks/jarvis:tofino
FROM $DOCKER_BASE_IMAGE

ARG USER=user
ARG UID=1000
ARG GID=1000
ARG KEY_DIR

ARG HTTP_PROXY=http://proxy-mu.intel.com:911/
ARG HTTPS_PROXY=http://proxy-mu.intel.com:912/

# Diagnostic
RUN echo USER=${USER} UID=${UID} GID=${GID} KEY_DIR=${KEY_DIR}

# default password for user
ARG PW=docker

# Package installation
# ====================
# Configure proxies
RUN echo "Acquire::http::proxy \"${HTTP_PROXY}\"; Acquire::https::proxy \"${HTTPS_PROXY}\";" > /etc/apt/apt.conf.d/99HttpProxy

# Install useful packages
RUN apt-get update && apt-get install -y graphviz openssh-server sudo htop mc
RUN python3 -m pip --proxy ${HTTPS_PROXY} install cpplint pylint autopep8

# Install updated version of cmake
RUN apt-get install -y apt-transport-https ca-certificates gnupg software-properties-common wget && \
    wget -O - https://apt.kitware.com/keys/kitware-archive-latest.asc 2>/dev/null | \
    gpg --dearmor - | tee /etc/apt/trusted.gpg.d/kitware.gpg >/dev/null
COPY cmake /etc/apt/preferences.d/
RUN apt-add-repository 'deb https://apt.kitware.com/ubuntu/ xenial main' && \
    apt-get update && apt-get install -y cmake cmake-curses-gui

# User creation
# =============
# Create the user using enencrypted password
RUN useradd -m ${USER} --uid=${UID} -s/bin/bash && echo "${USER}:${PW}" | chpasswd

# Configure the user to use sudo
RUN usermod -a -G sudo ${USER}
RUN echo "${USER} ALL = (root) NOPASSWD:ALL" > /etc/sudoers.d/${USER}

# SSH configuration
# =================
# Copy the authorized keys into container
# (Not used when home dirs mounted inside container)
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
