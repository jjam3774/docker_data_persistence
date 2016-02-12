# docker_data_persistence
A demonstration of ways that you can setup data persistence with Docker. It will also serve as a reference for people that use this repo.
A demonstration of how you can use Docker-Compose to deploy a data-persistent container along with any app that pulls that info.

**volumes**
Mount paths as volumes, optionally specifying a path on the host machine (HOST:CONTAINER), or an access mode

    HOST:CONTAINER:ro

    volumes:
     - /var/lib/mysql
     - ./cache:/tmp/cache
     - ~/configs:/etc/configs/:ro
You can mount a relative path on the host, which will expand relative to the directory of the Compose configuration file being used. Relative paths should always begin with . or ...


=======
