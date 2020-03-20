# Docker image for ORKA-HPC
Git URL: git@i2git.cs.fau.de:orka/dockerfiles/orkadistro.git


## Minimal Requirements
- Docker v1.13.1


## Getting Started

- `./rebuild_docker.sh`
- `./run_docker.sh`
- `docker exec -it rose bash -l`

You are now logged in.


## Frequent Issues

- docker permission issues:
    - `sudo groupadd docker`
    - `sudo usermod -aG docker ${USER}`
    - `sudo service docker restart`
    - Log out and back in
