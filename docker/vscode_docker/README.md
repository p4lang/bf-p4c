# Visual Studio Code + Jarvis Docker Image

This is a short how-to which helps you to set-up the development environment
built from the official Jarvis docker image. The development is based on freely
available tools.

The current setup has been tested on:

Laptop:
* Windows 10
* MacOS 10.15 Catalina
* MacOS Monterey

Development VM:
* Ubuntu 18.04
* Ubuntu 20.04

**Required Tools**:

* Laptop
  * [Visual Studio Code](https://code.visualstudio.com/)
  * SSH: SSH in WSL or native SSH in Windows/MacOS
* Server
  * Docker with pulled `amr-registry.caas.intel.com/bxd-sw/jarvis:latest` image

### Approaches

We outline two approaches to using Visual Studio Code (VSCode) for compiler
development within the Jarvis Docker container:

* VSCode manages its connection to the Docker container **(Recommended)**.
* VSCode connects directly to a running Docker container via an SSH tunnel.

## Prerequisites

Follow these steps on your _laptop_:

1. Install [Visual Studio Code](https://code.visualstudio.com/).

2. Start VSCode, click on extensions, and install the Remote - SSH extension (more details
   [here](https://code.visualstudio.com/docs/remote/ssh). Restart VSCode if it indicates that a
   restart is required.

3. In the Command Palette (Ctrl + Shift + P), select "Remote-SSH: Connect to Host...". From the
   drop-down menu, select "Configure SSH Hosts..." On Mac/Linux, select your ~/.ssh/config file.
   [Glen: not sure what to select on Windows.]

4. Add an entry for your dev VM if you don't already have one:

   ```
   host HostForRemoteVScode
       HostName yourHostname/yourIP
       User yourUserName
       ServerAliveInterval 240
       Compression y
       # Include the next line only you're using a direct SSH tunnel to your container (approach 2)
       LocalForward 2222 localhost:2222
   ```

5. Verify that you can connect to your VM with this newly-added host entry. From a console:

   ```bash
   ssh HostForRemoteVSCode
   ```

   Disconnect from the host.

## Approach 1: VSCode manages the connection to the Docker container

VSCode manages the connection to the Docker container using the Remote Containers extension. This
approach can use the Jarvis Docker container directly, or it can use a container derived from the
Jarvis container.

With this approach, VSCode first creates an SSH connection to your development VM and then creates a
connection to the Docker container, starting the container if it is not already running. The
approach uses the Remote SSH and the Remote Containers extensions.

### Directions

1. Decide whether you want to run everything as root or your own username within the Docker
   container. If you want to run as root then you will use the Jarvis container directly. Otherwise,
   if you want to run under your own username then you will use a container built from the Jarvis
   container.

2. In VSCode, go to Extensions and search for "Remote - Containers". Install this extension.

3. In the Command Palette (Ctrl/Command + Shift + P), click on "Remote-SSH: Connect to Host..." and
   click on "HostForRemoteVScode".

4. Click on Open Folder and open your checked out repo in the remote VM.

5. If you don't already have a `.devcontiner/devcontainer.json` file, then create this file by
   copying it from either `docker/vscode_docker/devcontainer-image.json` (running as root in
   container) or `docker/vscode_docker/devcontainer-dockerfile.json` (running as your username in
   container). You may want to customize the file after copying it.

   Sample contents for json file for root:

   ```
   {
       "name": "Jarvis",
       "image": "amr-registry.caas.intel.com/bxd-sw/jarvis:latest",
       "build": {
           "context": "..",
           "args": {
           }
       },
       "runArgs": [
           "--privileged"
       ],
       "extensions": [
           "ms-vscode.cpptools",
           "ms-vscode.cmake-tools"
       ]
   }
   ```

   Note: the `context` parameter gives the location of context folder for building the image.

   The non-root dockerfile replaces `image` with a `build` section including a `dockerfile`
   parameter:

   ```
       "build": {
           "dockerfile": "../docker/vscode_docker/Dockerfile",
           "context": "..",
           "args": {
               "USER": "${localEnv:USER}",
           },
           "target": "jarvis-vscode"
       },
   ```

   The root approach is slightly faster in the container setup phase. Customizations can be added
   via a `postCreateCommand`.

   The Devcontainer.json reference for customization can be found here:
   https://code.visualstudio.com/docs/remote/devcontainerjson-reference

6. Open the command palette (Ctrl + Shift + P) and click on "Remote-Containers: Open Folder in
   Container...". VScode searches for the `devcontainer.json` file and runs the linked Dockerfile to
   build the image. Once the image is built, a container is automatically started and a terminal
   will be available for use inside the container.

The repo folder is mapped to `/workspaces/<repo>` by default. `devcontainer.json` can be customized
based on user preferences.

Enjoy!

## Approach 2: VSCode connects to a running Docker container via an SSH tunnel
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

### How to build & use the image

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
[here](https://wiki.ith.intel.com/display/BXDCOMPILER/Docker+environment)
(you need access to the group's Docker Hub).

Now, we are ready to prepare the Docker image based on the Jarvis image.  It is
also a good idea to remove the already built image if you are doing a rebuild.

Steps to build the image on your development VM:

1. Pull the standard Jarvis image:

```bash
docker pull amr-registry.caas.intel.com/bxd-sw/jarvis)
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

Check with the docker image command if the `jarvis-ssh` image is available. The default path for
your repos is `~/reps` but you can change the path if you need (edit the `run-jarvis-ssh` script, or
see the exmaples in the `examples` directory). The default `run-jarvis-ssh` script mounts the local
`~/reps` intowill be mounted to `/mnt/reps` folder inside the docker image. The set username is the
part of the `sudo` group inside the image, default password is `docker` (if you don't change it).
The build script also takes care about the permission and proxy setup.

Start the image with the `./run-jarvis-ssh` script (or your modified version of the script). The
script starts the docker image and maps the docker image port 22 to localhost port 2222. SSH server
inside the docker image is ran automatically. Thanks to the provided from mapping localhost:22 to
docker:22, ssh to docker image should be available now. You can check if the SSH server runs using
command (from machine where docker runs):

```bash
ssh -p 2222 localhost
```

### How to Update the Image

Update process is as similar as the build image but you need to pull the image before the call of
the `build-image.sh`.

### Local Configuration

The ssh connection to docker image is working. We need to setup our local environment now.

1. Ensure you've followed the steps in the Prerequisites section.

2. In the Command Palette (Ctrl + Shift + P), select "Remote-SSH: Connect to Host...". From the
   drop-down menu, select "Configure SSH Hosts..."

3. Create a second host entry in your SSH config to connect to the Docker container:

   ```
   host SSHToDockerImage
       Hostname 127.0.0.1
       Port 2222
       User yourUserName
       Compression yes
       ServerAliveInterval 60
   ```

4. Connect to the SSH host from a console and leave the SSH session _open_:

   ```
   ssh HostForRemoteVSCode
   ```
5. The connection from a local machine to docker image should be working now. Back to the Visual
   Studio Code, open the Command Palette (Ctrl + Shift + P), select `Remote-SSH: Connect to Host...`
   and select the host with `SSHToDockerImage`. You should be connected to SSH inside the Docker -
   it will take some time as it downloads VSCode server components. The next step is to download
   several plugins to be able to program in C++ & use cmake (you can also tune & share your own set
   of required plugins) - all plugins needs to be installed on remote machine:

    - https://marketplace.visualstudio.com/items?itemName=ms-vscode.cpptools
    - https://marketplace.visualstudio.com/items?itemName=twxs.cmake
    - https://marketplace.visualstudio.com/items?itemName=ms-vscode.cmake-tools

6. Setup the proxy if the download is not working but this configuration should be taken from the
   user configuration which was done in the previous step. Restart the vscode. Now, you have to be
   ready to open the folder with your repository which is mounted in `/mnt/reps` folder. Click
   `File` --> `Preferences Setting`, click on `Remote`, `Extensions`, `C/C++` and make the following
   configuration:

   * Cpp Standard - select the language standard (mine is C++14)
   * Intelli Sense Mode - select the mode (mine is gcc-x64)

7. Open the folder, and enjoy your Visual Studio Code running inside the docker image.

That's it, no additional configuration of the build system is needed if you are fine with default
options. You will also need to reconfigure the image if you are using it for the first time (we have
different paths, etc.).

We are done. Compilation, debugging and tests should be working now.

## Building projects in VSCode

VSCode allows project building and you can even have multiple build targets for your project.

1. In your workspace (the folder in which your project resides) create `.vscode` folder and inside
   of it create `tasks.json`. Your file explorer in VSCode should now look similar to this:

   ```
   |-- Workspace
       |-- WorkspaceFolder
           |-- .vscode
           |   |-- tasks.json
           |-- bf-p4c-compilers
   ```

2. Inside the `tasks.json` file you can now put your build tasks (exact info is in the
   [documentation](https://code.visualstudio.com/docs/editor/tasks)), and it can look something like
   this:

   ```
   {
       "version": "2.0.0",
       "tasks": [
           {
               "label": "standard make -j76",
               "type": "shell",
               "command": "make -j76",
               "group": "build",
               "options": {
                   "cwd": "${fileDirname}/../bf-p4c-compilers/build"
               },
               "presentation": {
                   "reveal": "always",
                   "panel": "new"
               },
               "problemMatcher": [
                   "$gcc"
               ]
           }
       ]
   }
   ```

   This configuration file will offer you one build option called `standard make -j76` which will
   use the command `make -j76` and will execute it in the `bf-p4c-compiler/build` folder. If you'll
   be using `make -76` just make sure that you have an access to the build pool (otherwise it would
   take a lot of time).

3. To build your project with this configuration just press `ctrl + shift + b` and after short while
   a prompt should pop up containing all the builds added to the `tasks.json` file and here you can
   simply select the one you want to build with right now (build progress should show up in the
   VSCode terminal).

## Debugging in VSCode
Just as you can build projects in VSCode, you can also debug right from VSCode.

1. In your workspace (just as in case of building) create `.vscode` folder and inside of it create
   file `launch.json`. Your file explorer in VSCode should now look similar to this:

   ```
   |-- Workspace
       |-- WorkspaceFolder
           |-- .vscode
           |   |-- launch.json
           |   |-- tasks.json
           |-- bf-p4c-compilers
   ```

2. Inside the `launch.json` file you can now put your configuration (exact info is in the
   [documentation](https://code.visualstudio.com/docs/editor/debugging) and a tutorial on debugging
   in VSCode is [here](https://code.visualstudio.com/docs/cpp/introvideos-cpp)). `launch.json` can
   look something like this:

   ```
   {
       "version": "0.2.0",
       "configurations": [
           {
               "name": "(gdb) p4c-barefoot",
               "type": "cppdbg",
               "request": "launch",
               "program": "${workspaceFolder}/bf-p4c-compilers/build/p4c/extensions/bf-p4c/p4c-barefoot",

               "args": [
                   "--std=p4-16",
                   "--target=tofino",
                   "--arch=tna",
                   "/home/ubuntu/issueFolder/someP4File.p4pp"
               ],
               "stopAtEntry": false,
               "cwd": "/home/ubuntu/issueFolder/folderForOutputsOfP4CBarefoot",

               "environment": [],
               "externalConsole": false,
               "MIMode": "gdb",
               "setupCommands": [
                   {
                       "description": "Enable pretty-printing for gdb",
                       "text": "-enable-pretty-printing",
                       "ignoreFailures": true
                   }
               ]
           },
           {
               "name": "(gdb) bfas",
               "type": "cppdbg",
               "request": "launch",
               "program": "${workspaceFolder}/bf-p4c-compilers/build/bf-asm/bfas",

               "args": ["/home/ubuntu/issueFolder/someBFAFile.bfa"],
               "stopAtEntry": false,
               "cwd": "/home/ubuntu/issueFolder/folderForOutputsOfBFA",

               "environment": [],
               "externalConsole": false,
               "MIMode": "gdb",
               "setupCommands": [
                   {
                       "description": "Enable pretty-printing for gdb",
                       "text": "-enable-pretty-printing",
                       "ignoreFailures": true
                   }
               ]
           }
       ]
   }
   ```

   This configuration file sets up 2 debug options -- the first is for `p4c-barefoot` and the second
   one is for `bfas`. Path to these is specified in the `"program"` attribute and arguments with
   which it will be executed are in `"args"` attribute. So when you need to debug with different
   input arguments and files, this attribute has to be changed. Also you'll most likely want to
   change the `"cwd"` attribute to suit your setup as well.

3. Make sure you have the [C/C++
   extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode.cpptools) installed,
   otherwise install it.

4. You can now use `F5` which will run the target application or alternatively click the debug icon
   in the Activity bar (or press `ctrl+shift+d`) and in the top left of the panel next to `RUN AND
   DEBUG` select one of your debugging configurations.

5. To run this debug simply click on the green start symbol (after creating some breakpoints by
   clicking on the space next to line number or by using the `F9` shortcut) and after little while
   the debug should start and it's output will be visible in the `DEBUG CONSOLE` tab same as
   additional information. Also a small control panel with debugging control should appear.