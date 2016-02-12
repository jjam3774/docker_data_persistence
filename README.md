# docker_data_persistence
A demonstration of ways that you can setup data persistence with Docker. It will also serve as a reference for people that use this repo.


A demonstration of how you can use Docker-Compose to deploy a data-persistent container along with any app that pulls that info.


Steps to getting started quickly:
1. juju init 
2. juju  env local
3. juju bootstrap

To deploy:
juju deploy wordpress # or any service that want deployed

To destroy the setup:
juju destroy-environment local

To get started with GUI:
juju-quickstart -i

