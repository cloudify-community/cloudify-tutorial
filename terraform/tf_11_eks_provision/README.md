## Install Cloudify manager

sudo docker run --name my_cfy_manager -d --restart unless-stopped -v /sys/fs/cgroup:/sys/fs/cgroup:ro --tmpfs /run --tmpfs /run/lock --security-opt seccomp:unconfined --cap-add SYS_ADMIN -p 80:80 -p 8000:8000 cloudifyplatform/community-cloudify-manager-aio:6.2.0


## Install and config CLI
pip install cloudify==6.1.0
cfy profiles use localhost -u admin -p admin
cfy profiles set --manager-tenant default_tenant

## Upload All Plugins
cfy plugins bundle-upload

## Create secrets
cfy secrets create aws_access_key_id --secret-string <value>
cfy secrets create aws_secret_access_key --secret-string <value>

## Run blueprint to provision eks with Terraform and Cloudify Manager
cfy apply -i inputs.yaml



