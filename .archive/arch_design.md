# design

uv on host os
python on host os (syno)
get configtool loaded on host os
need to set up a pyproject with deps
don't need ctool-secrets?

update configtool to read database from cli command
also need to read secrets from cli command (docker exec)

systemd service that loads the config container if not running
runs configtool using docker exec to get the data
then loads all the other containers (at least portainer and terraform)
not sure how swarm handles reboots

config container that mounts secrets and configs
to update config, shut down container
clone config to backup
delete config
recreate
deploy container

open tofu container is different
how to mount tf files (git)?
terraform retrieve state, then apply on run
container runs and quits

create tf script to deploy all the swarm stacks from github
different script that fires all webhooks?

move watchtower to shepherd

update all docker overrides to env vars
create configtool db sample
include a var to enable or disable each service
