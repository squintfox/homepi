import os
import subprocess

import requests
from constants import *
from stack import Stack


def set_technitium_token_from_env() -> None:
    """
    This basically a patch for the Terraform provider which doesn't seem to work with
    username and password in v0.22.  We get a token with default user creds and set to env.
    """
    host = 'http://technitium:5380'
    # USERNAME and PASSWORD can be set via env vars for flexibility, but default to 'admin'
    # if not set
    username = os.getenv('HPI_TECHNITIUM_USERNAME', 'admin')
    password = os.getenv('HPI_TECHNITIUM_PASSWORD', 'admin')

    try:
        response = requests.get(
            f'{host}/api/user/login',
            params={'user': username, 'pass': password},
            timeout=10,
        )
        response.raise_for_status()
        payload = response.json()
    except Exception as exc:
        print(f"Unable to get Technitium token from {host}: {exc}")
        return

    if payload.get('status') != 'ok' or not payload.get('token'):
        print(
            'Technitium login did not return a token: '
            f"{payload.get('errorMessage', payload)}"
        )
        return

    token = str(payload['token'])
    os.environ['HPI_TECHNITIUM_TOKEN'] = token
    os.environ['TF_VAR_HPI_TECHNITIUM_TOKEN'] = token
    print(
        'Loaded Technitium API token into HPI_TECHNITIUM_TOKEN and TF_VAR_HPI_TECHNITIUM_TOKEN.'
    )


base_stack = Stack(name='homepi', path=CONFIG_PATH)
base_config = base_stack.config
if base_config:
    base_config.deploy_env()

    LOCAL_DATA_PATH = os.path.join('/', 'local-data')
    STACKS_PATH = os.path.join('/', 'stacks')
    # STACKS_PATH = 'C:\\git\\homepi-stacks'

    crit_stack = Stack(
        name='homepi-critical',
        path=os.path.join(CONFIG_PATH, 'homepi-critical'),
        base_config=base_config,
    )
    cmd_stack = Stack(
        name='homepi-command',
        path=os.path.join(CONFIG_PATH, 'homepi-command'),
        base_config=base_config,
    )

    # print("Current HomePi-related environment variables:")
    # for key in sorted(os.environ):
    #     if key.startswith(('HPI_', 'TF_VAR_', 'CFGT_')):
    #         print(f"{key}=***")

    print("\nDeploying critical .env file with secrets...")
    crit_stack.deploy_env_file(libraries=['homepi', 'homepi_shared'])

    # # TODO: Print contents of the .env file
    # env_file_path = crit_stack.env_file
    # try:
    #     with open(env_file_path, 'r') as env_file:
    #         print("\nContents of critical .env:")
    #         print(env_file.read())
    # except FileNotFoundError:
    #     print(f"\nCritical .env file not found at: {env_file_path}")

    print("Deploying command .env file with secrets...")
    cmd_stack.deploy_env_file(libraries=['homepi', 'homepi_shared'])
else:
    raise RuntimeError("Base config is required for setup but was not found.")


# run migrations then, run TF for Technitium initialization, which is required for
# the DNS stack
set_technitium_token_from_env()
crit_stack.deploy_stack()

stack_specs = [
    # default stacks
    ('homepage', 'homepage', base_config),
    ('code', 'code', base_config),
    ('monitor', 'monitor', base_config),
    # recommended stacks
    ('update', 'update', base_config),
    ('automate', 'automate', base_config),
    ('assets', 'assets', base_config),
    ('budget', 'budget', base_config),
    ('wealth', 'wealth', base_config),
    ('recipes', 'recipes', base_config),
    # optional stacks
    ('git', 'git', base_config),
    ('watch', 'watch', base_config),
    ('dns-tls-proxy', 'dns-tls-proxy', base_config),
    ('tools', 'tools', base_config),
    ('deploy', 'deploy', base_config),
    ('certificates', 'certificates', base_config),
    # ('file-server', 'file-server', base_config),
    ('listen', 'listen', base_config),
    ('scoreboard', 'scoreboard', base_config),
]

for stack_name, stack_path, stack_base_config in stack_specs:
    print(f"\nDeploying stack: {stack_name}")
    stack = Stack(
        name=stack_name,
        path=os.path.join(STACKS_PATH, stack_path),
        base_config=stack_base_config,
    )
    stack.deploy_stack()
