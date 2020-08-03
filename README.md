# Docker image for ORKA-HPC

Git URL: git@i2git.cs.fau.de:orka/dockerfiles/orkadistro.git

## Requirements

- Docker v1.13.1
- You need to get a Research license from EDG
  1. Contact `info@edg.com`
  2. Write that you need access to the EDG C++ frontend
     sources. To make things as smooth as possible for you, 
     you can mention me, `florian.andrefranc.mayer@fau.de` and
     refer to ORKA-HPC using the ROSE toolchain.
  3. Mail the license to me.

## Getting Started

- `./setup.sh` does a clean build of the docker container.
  It also builds ROSE and orkaevolution 
  (both _inside_ the docker container).
- `./run_docker.sh -r -e -q` starts the docker container and 
  presents a shell to you running in the container. After
  you close that shell (using C-d) it suspends the container.
- `./run_docker.sh --stop-and-remove` stops and removes the
  running container. All your data in the container is
  erased that way.

## Pulling a pre-built Docker image (BETA!)

In order to prevent users from having to build this Docker image
themselves (which would be a very time consuming thing to do), we
additionally host pre-build Docker images here on i2git.

A simple
`$ docker run -it i2git.cs.fau.de:5005/orka/dockerfiles/orkadistro bash -l`
ought to be enough to pull the container, to start it, and
to launch a bash process inside it. Note that the container
**and all the changes you will have made inside it** will
be gone after the shell exits!

## Frequent Issues

- docker permission issues:
    - `sudo groupadd docker`
    - `sudo usermod -aG docker ${USER}`
    - `sudo service docker restart`
    - Log out and back in

- You need to run `run_docker.sh --stop-and-unmount` before
  you can `./rebuild.sh` the image again.

## Notes and References

The arty board description files were retrieved from
[github](https://github.com/Digilent/vivado-boards)

Currently, all users of this Distribution need a
EDG research license due to the fact that our
changes of the ROSE library are not merged into
upstream yet.
