# Visual Studio Code + Jarvis Docker Image

This is a short howto which helps you to set-up the development environment
built from the official Jarvis docker image. The development is based on freely
available tools.

The current setup has been tested on:

Laptop:
* Windows 10
* MacOS 10.15 Catalina

Development VM:
* Ubuntu 18.04

**Required Tools**:

* Laptop
  * [Visual Studio Code](https://code.visualstudio.com/)
  * SSH: SSH in WSL or native SSH in Windows/MacOS
* Server
  * Docker with pulled `amr-registry.caas.intel.com/bxd-sw/jarvis:tofino` image

### Main Idea

The main idea is simple: create a docker image running an SSH server which
allows connection from Visual Studio Code via [Remote SSH
plugins](https://code.visualstudio.com/docs/remote/ssh).  To achieve this we
need to solve:

* File permissions of bind folder (repository).
* Semi-automatic building of the Docker image.
* How to start the image and export environment variables from the standard
  Jarvis image.
* Start with the zip archive downloading with Dockerfile and similar stuff.

## How to build & use the image

This process builds a Docker image that contains the necessary development
tools, the SSH server, and a script to start the SSH server within the
container.

There is also a support script which can be used for the automatic start of the
SSH server. You can also edit it to mount corresponding folders. Several
examples can be found in the `examples` subdirectory. For example, Pavel's is:

```bash
#!/usr/bin/env bash
docker run \
        --rm --user root \
        --privileged \
        -p 2222:22 \
        -v ~/reps:/mnt/reps \
        -v ~/tasks:/mnt/tasks \
        -v ~/docker/user-home/ccache:/home/$USER/.ccache \
        -v ~/docker/user-home/vscode-server:/home/$USER/.vscode-server \
        -v ~/docker/user-home/local:/home/$USER/.local \
        -it jarvis-ssh \
        /bin/bash
```

The base docker image can be obtained as described
[here](https://github.com/barefootnetworks/P4/wiki/Building-and-testing-bf-p4c-compilers-in-docker#setting-updocker-and-docker-hub)
(you need access to the group's Docker Hub).

Now, we are ready to prepare the Docker image based on the Jarvis image.  It is
also a good idea to remove the already built image if you are doing a rebuild.

Steps to build the image:

1. Pull the standard Jarvis image:

```bash
docker pull amr-registry.caas.intel.com/bxd-sw/jarvis:tofino)
```

2. Optional: Edit the Dockerfile if you wish to add additional packages to install.

3. Run the `build-image.sh` script:

```bash
./build-image.sh
```

The script builds a new image which contains tools used by Visual Studio Code
(e.g., an updated cmake), an ssh server, and your .ssh/authorized\_keys file.
The authorized\_keys file allows you to login to the container without a
password (if you are using the SSH key authentication for login to your VM :-) ).

The script also creates a set of SSH host keys which will be installed in every
image you build with this script. This eliminates the need to edit your
known\_hosts file every time you rebuild the image.

Check with the docker image command if the `jarvis-ssh` image is available. The default path for your repos is `~/reps` but you can
change the path if you need (edit the `run-jarvis-ssh` script, or see the exmaples in the `examples` directory).
The default `run-jarvis-ssh` script mounts the local `~/reps` intowill be mounted to `/mnt/reps` folder inside the docker image.
The set username is the part of the `sudo` group inside the image, default password is `docker` (if you don't change it).
The build script also takes care about the permission and proxy setup.

Start the image with the `./run-jarvis-ssh` script (or your modified version of the script). The script starts the docker image and
maps the docker image port 22 to localhost port 2222. SSH server inside the docker image is runned automatically.
Thanks to the provided from mapping localhost:22 to docker:22, ssh to docker image shoold be available now.
You can check if the SSH server runs using command (from machine where docker runs):

```bash
ssh -p 2222 localhost
```

### How to Update the Image

Update process is as similar as the build image but you need to pull the image before the call of the `build-image.sh`.

## Local Configuration

The ssh connection to docker image is working. We need to setup our local environment now.

1. Install the Visual Studio Code, start it, click on extensions and install the Remote - SSH (more details [here](https://code.visualstudio.com/docs/remote/ssh).
Restart the Visual Studio Code, press CTRL+P and select connect to the host, click on Configure SSH hosts. Configure the proxy:
`File` --> `Preferences` --> `Settings`, type `proxy` and insert the proxy settings.

2. We need to setup a port forwarding which forwards the local port 2222 to remote port 2222 where the ssh in jarvis-ssh image will be
listening. The template for your setup is following (use the real TAB key instead of the \<TAB\> ):

```
host SSHToDockerImage
<TAB>Hostname 127.0.0.1
<TAB>Port 2222
<TAB>User yourUserName
<TAB>Compression yes
<TAB>ServerAliveInterval 60
```

3. You need to have an option for login to your VM with forwarded ports, another configuration (let’s say from the WSL or your favorite SSH client):

```
host HostForRemoteVScode
<TAB>HostName yourIP
<TAB>LocalForward 2222 localhost:2222
<TAB>User yourUserName
<TAB>ServerAliveInterval 240
<TAB>Compression y
```

After adding both hosts to your local ssh config file, use the console (I am using the WSL) and login to your VM. This creates the
SSH tunnel from your local machine to the docker image. For example:

_Terminal 1:_

```bash
ssh HostForRemoteVScode
```

_Terminal 2:_

```bash
ssh SSHToDockerImage
```

4. The connection from a local machine to docker image should be working now. Back to the Visual Studio Code, press `CTRL+P`, select
`Connect to remote host` and select the host with `SSHToDockerImage`. You should be connected to SSH inside the Docker - it will take
some time until the vscode server is downloaded. The next step is to download several plugins to be able
to program in C++ & use cmake (you can also tune & share your own set of required plugins) - all plugins needs to be installed
on remote machine:

    - https://marketplace.visualstudio.com/items?itemName=ms-vscode.cpptools
    - https://marketplace.visualstudio.com/items?itemName=twxs.cmake
    - https://marketplace.visualstudio.com/items?itemName=ms-vscode.cmake-tools

5. Setup the proxy if the download is not working but this configuration should be taken from the user configuration which was done in
the previous step. Restart the vscode. Now, you have to be ready to open the folder with your repository which is mounted
in `/mnt/reps` folder. Click `File` --> `Preferences Setting`, click on `Remote`, `Extensions`, `C/C++` and make
the following configuration:

* Cpp Standard - select the language standard (mine is C++14)
* Intelli Sense Mode - select the mode (mine is gcc-x64)

6. Open the folder, and enjoy your Visual Studio Code running inside the docker image.

That’s it, no additional configuration of the build system is needed if you are fine with default options. You will also need to
reconfigure the image if you are using it for the first time (we have different paths, etc.).

We are done. Compilation, debugging and tests should be working now.
