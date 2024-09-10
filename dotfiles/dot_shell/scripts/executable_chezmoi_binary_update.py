#!/usr/bin/env python3

# /// script
# dependencies = [
#   "rich",
#   "httpx",
#   "sh",
#   "semver",
#   "typer",
# ]
# ///


import logging
import re
from typing import Annotated

import httpx
import sh
import typer
from rich.console import Console
from rich.logging import RichHandler
from semver import VersionInfo

c = Console()


def main(
    command: Annotated[str, typer.Option(help="Binary to check for updates")],
    github: Annotated[
        str, typer.Option(help="GitHub repository in the format 'owner/repo'")
    ],
    update_url: Annotated[
        str, typer.Option(help="Install script binary to pipe to `sh`")
    ] = None,
    log_level: Annotated[str, typer.Option(help="Log level")] = "WARNING",
):
    # Set up logging
    FORMAT = "%(message)s"
    logging.basicConfig(
        level=log_level, format=FORMAT, datefmt="[%X]", handlers=[RichHandler()]
    )
    logging.getLogger("sh").setLevel(level="WARNING")
    logging.getLogger("httpx").setLevel(level="WARNING")
    log = logging.getLogger("rich")

    c.print(f"Checking for updates to {command}")

    # Grab local version number
    try:
        cmd = sh.Command(command)
    except sh.CommandNotFound:
        log.error(f"command '{command}' not found")
        raise typer.Exit(1)

    local_version_output = cmd("--version").strip()
    local_version = re.sub(
        rf"{command} ?v?", "", local_version_output, flags=re.IGNORECASE
    )

    # Grab remote version number
    r = httpx.get(f"https://api.github.com/repos/{github}/releases/latest")

    if not r.status_code == 200:
        log.error("Failed to fetch latest release")
        raise typer.Exit(1)

    response = r.json()

    if response["draft"]:
        log.warning("Draft release")
        raise typer.Exit(1)
    elif response["prerelease"]:
        log.warning("Pre-release")
        raise typer.Exit(1)

    remote_version = response["name"].replace("v", "").strip()

    log.info(f"{local_version=}")
    log.info(f"{remote_version=}")

    # Compare versions
    if VersionInfo.parse(local_version) < VersionInfo.parse(remote_version):
        c.print(f"Update available for {command}")
        if update_url:
            c.print("Running update script")
            curl = sh.Command("curl")
            sh_bin = sh.Command("sh")
            sh_response = sh_bin(
                _in=curl("sSfL", update_url),
            )
            c.print(sh_response)
    else:
        c.print(f"No update available for {command}")


if __name__ == "__main__":
    typer.run(main)
