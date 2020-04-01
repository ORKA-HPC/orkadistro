# Docker image for ORKA-HPC
Git URL: git@i2git.cs.fau.de:orka/dockerfiles/orkadistro.git


## Minimal Requirements
- Docker v1.13.1


## Getting Started

- `./rebuild_docker.sh`
- `./run_docker.sh`. **Warning** this erases all commited data inside the running docker instance!
- `docker exec -it rose bash -l`
- `docker exec -u root -it rose bash -l`. Gives you root access right away.
  (However, the standard user is in /etc/sudoers inside the container, so
   all good :smile:)

You are now logged in.

- `./run_docker.sh --exec-shell` gets you a shell in the container.
- `./run_docker.sh --stop-and-unmount` stops and removes the running image.
  It also removes the mount directory from the overlay mount.

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
[github](https://github.com/Digilent/vivado-boards/archive/master.zip)
