import os
import subprocess

from configtool.errors import InvalidCommandOutputError
from configtool_client import Config
from constants import *
from tofupy.tofu import Tofu


class Stack:
    def __init__(self, name: str, path: str, base_config: Config | None = None):
        self._name = name
        self._path = path
        self._base_config = base_config
        self._stack_config = self.read_config()

    @property
    def name(self) -> str:
        return self._name

    @property
    def path(self) -> str:
        return self._path

    @property
    def env_file(self) -> str:
        return os.path.join(self._path, '.env')

    @property
    def migration_script(self) -> str:
        return os.path.join(self._path, 'migrate.sh')

    @property
    def config_file(self) -> str:
        return os.path.join(self._path, 'configtool_db.yml')

    @property
    def config_file_user(self) -> str:
        return os.path.join(self._path, 'configtool_db.user.yml')

    @property
    def tofu_path(self) -> str:
        return os.path.join(self._path, 'tofu')

    @property
    def config(self) -> Config | None:
        return self._stack_config

    @property
    def base_config(self) -> Config | None:
        return self._base_config

    def read_config(self) -> Config | None:
        if os.path.exists(self.config_file):
            stack_config = Config(
                local_file_path=os.path.join(CONFIG_PATH, 'configtool.yml'),
                local_db_path=self.config_file,
            )
            if self.base_config:
                stack_config.merge(self.base_config)

            # unlock first, so you have the secrets available, then unlock again to capture
            # user unlocks
            stack_config.deploy_env(enable_secrets=False)
            stack_config.unlock_secrets()
            stack_config.deploy_env()

            if os.path.exists(self.config_file_user):
                try:
                    stack_user_config = Config(
                        local_file_path=os.path.join(CONFIG_PATH, 'configtool.yml'),
                        local_db_path=self.config_file_user,
                    )
                    stack_config.merge(stack_user_config)

                    stack_config.deploy_env(enable_secrets=False)
                    stack_config.unlock_secrets()
                    stack_config.deploy_env()
                except InvalidCommandOutputError as exc:
                    print(
                        f"Skipping invalid user config for stack '{self.name}' at "
                        f"{self.config_file_user}: {exc}"
                    )
            else:
                print(
                    f"No user config found for stack '{self.name}' at: {self.config_file_user}"
                )
        else:
            print(
                f"No config found for stack '{self.name}' at: {self.config_file}. Returning empty config."
            )
            stack_config = None
        return stack_config

    def migrate(self):
        if os.path.exists(self.migration_script):
            try:
                result = subprocess.run(
                    ['bash', self.migration_script],
                    check=True,
                    capture_output=True,
                    text=True,
                    cwd=self._path,
                )
                if result.stdout:
                    print(result.stdout)
                if result.stderr:
                    print(result.stderr)
            except FileNotFoundError:
                print(
                    'bash was not found. Install bash or run this script in a Unix-like environment.'
                )
            except subprocess.CalledProcessError as exc:
                print(
                    f'Failed to run {self.migration_script} for stack "{self.name}". Exit code: {exc.returncode}'
                )
                if exc.stdout:
                    print(exc.stdout)
                if exc.stderr:
                    print(exc.stderr)
        else:
            print(
                f'migrate.sh for stack "{self.name}" not found at: {self.migration_script}'
            )

    def deploy_env_file(self, libraries: list[str] | None = None):
        """Deploy the .env file for this stack, merging in any secrets from the provided config."""
        config = self.config or self.base_config
        if config:
            if self.config is None and self.base_config is not None:
                print(
                    f"No stack config found for '{self.name}'. "
                    "Using base config to generate .env."
                )
            config.deploy_env_file(self.env_file, libraries=libraries)
        else:
            print(
                f"Unable to generate .env for stack '{self.name}': "
                "no config is available."
            )

    @staticmethod
    def _print_diagnostic(prefix: str, diagnostic):
        summary = getattr(diagnostic, 'summary', str(diagnostic))
        print(f"{prefix}: {summary}")

        detail = getattr(diagnostic, 'detail', None)
        if detail:
            print(f"{prefix} detail: {detail}")

    def deploy_stack(self):
        """Deploy the stack using OpenTofu."""
        print(f'Deploy target stack: "{self.name}" at {self.tofu_path}')
        # run any migrations
        self.migrate()

        # you shouldn't need to write env files for portainer stacks
        # though if you left it there, it would theoretically also deploy from the CLI, though
        # you might get into name conflicts

        # self.deploy_env_file(libraries=[self.name, 'homepi_shared'])

        # Initialize a workspace
        workspace = Tofu(cwd=self.tofu_path)
        # Initialize Terraform
        workspace.init()

        # Validate configuration
        validation = workspace.validate()
        if not validation.valid:
            print("Configuration is invalid!")
            for diagnostic in validation.diagnostics:
                self._print_diagnostic('Error', diagnostic)
            return

        # Create and review a plan
        plan_log, plan = workspace.plan()
        if plan_log.errors:
            for err in plan_log.errors:
                self._print_diagnostic('Plan error', err)
            print("Plan reported errors — skipping apply.")
            return

        if plan is None:
            print("No plan produced — skipping apply.")
            print(
                "OpenTofu did not emit a saved plan file. This can happen when planning "
                "fails before plan output is written."
            )
            return

        if plan.errored:
            print("Plan errored — skipping apply.")
            return

        print(
            f"Plan: {plan_log.added} added, "
            f"{plan_log.changed} changed, "
            f"{plan_log.removed} removed"
        )

        has_changes = any((plan_log.added, plan_log.changed, plan_log.removed))
        if not has_changes:
            print("No changes detected — stack is already up to date.")
            return

        # Some OpenTofu/plan JSON combinations omit applyability metadata.
        plan_applyable = getattr(plan, 'applyable', None)

        if plan_applyable is False:
            print(
                "Plan reports applyable=false. "
                "Skipping apply because OpenTofu marked this plan as not applyable."
            )
            return

        if plan_applyable is None:
            print(
                "Plan includes changes but does not provide applyability metadata. "
                "Proceeding with apply."
            )

        # Apply changes
        apply_log = workspace.apply()
        if apply_log.errors:
            print("Apply reported errors:")
            for err in apply_log.errors:
                self._print_diagnostic('Apply error', err)
            print(
                f"Apply summary before failure: {apply_log.added} added, "
                f"{apply_log.changed} changed, "
                f"{apply_log.removed} removed"
            )
            return

        print(
            f"Applied: {apply_log.added} added, "
            f"{apply_log.changed} changed, "
            f"{apply_log.removed} removed"
        )

        # Get outputs
        outputs = workspace.output()
        for name, output in outputs.items():
            print(f"{name}: {output.value} (type: {output.type})")
