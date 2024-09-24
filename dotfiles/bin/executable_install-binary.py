#!/usr/bin/env python3

# /// script
# requires-python = ">=3.12"
# dependencies = [
#   "httpx",
#   "loguru",
#   "rich",
#   "semver",
#   "sh",
#   "typer",
# ]
# ///

"""Script to install or update binaries from GitHub, Deb releases, or CLI install scripts.

This script is intended to be used with Chezmoi to manage the installation of binaries
from GitHub, Deb releases, or CLI install scripts. It will check for updates to the
binary and install the update if available.
"""

import contextlib
import gzip
import platform
import re
import shutil
import tarfile
from collections.abc import Callable
from enum import Enum
from pathlib import Path
from tempfile import TemporaryDirectory
from typing import Annotated

import httpx  # pyright: ignore
import sh  # pyright: ignore
import typer  # pyright: ignore
from loguru import logger  # pyright: ignore
from rich.console import Console  # pyright: ignore
from semver import VersionInfo  # pyright: ignore

console = Console()


class Arches(str, Enum):
    """Enum to represent the architecture of the host system."""

    ARM64 = "aarch64|arm64"
    X86_64 = "amd64|x86_64"
    AARCH64 = "aarch64|arm64"  # noqa: PIE796


class LogLevel(Enum):
    """Log levels."""

    INFO = 0
    DEBUG = 1
    TRACE = 2
    WARNING = 3
    ERROR = 4


def log_formatter(record: dict) -> str:
    """Format log messages using rich for styling.

    This function takes a log record dictionary and formats the log message
    with appropriate colors and icons based on the log level. It uses the rich
    library to apply the styles and colors to the log messages. The function
    also includes additional context information such as the function name and
    line number for TRACE level logs.

    Args:
        record (dict): A dictionary containing log record information, including
                       the log level, message, function name, and line number.

    Returns:
        str: A formatted log message string with rich styling applied.
    """
    color_map = {
        "TRACE": "turquoise4",
        "DEBUG": "cyan",
        "DRYRUN": "bold blue",
        "INFO": "",
        "SUCCESS": "bold green",
        "WARNING": "bold yellow",
        "ERROR": "bold red",
        "CRITICAL": "bold white on red",
        "SECONDARY": "dim",
    }
    line_start_map = {
        "INFO": "",
        "DEBUG": "DEBUG | 🐞 ",
        "DRYRUN": "DRYRUN| 👉 ",
        "TRACE": "TRACE | 🔧 ",
        "WARNING": "⚠️ ",
        "SUCCESS": "✅ ",
        "ERROR": "❌ ",
        "CRITICAL": "💀 ",
        "EXCEPTION": "",
        "SECONDARY": "",
    }

    name = record["level"].name
    lvl_color = color_map.get(name, "bold")
    line_start = line_start_map.get(name, f"{name: <8} | ")
    if lvl_color:
        msg = f"[{lvl_color}]{line_start}{{message}}[/{lvl_color}]"
    else:
        msg = f"{line_start}{{message}}"
    func_trace = f"[#c5c5c5]({record['name']}:{record['function']}:{record['line']})[/#c5c5c5]"

    return f"{msg} {func_trace}" if name in {"TRACE"} else msg


def instantiate_logger(
    verbosity: int, log_file: Path, log_to_file: bool
) -> None:  # pragma: no cover
    """Instantiate the Loguru logger.

    Configure the logger with the specified verbosity level, log file path,
    and whether to log to a file.

    Args:
        verbosity (int): The verbosity level of the logger. Valid values are:
            - 0: Only log messages with severity level INFO and above will be displayed.
            - 1: Only log messages with severity level DEBUG and above will be displayed.
            - 2: Only log messages with severity level TRACE and above will be displayed.
            > 2: Include debug from installed libraries
        log_file (Path): The path to the log file where the log messages will be written.
        log_to_file (bool): Whether to log the messages to the file specified by `log_file`.

    Returns:
        None
    """
    level = verbosity if verbosity < 3 else 2  # noqa: PLR2004

    logger.remove()

    with contextlib.suppress(
        TypeError
    ):  # Suppress error if DRYRUN is already defined (typically in tests)
        logger.level("DRYRUN", no=20, color="<blue>", icon="👉")
        logger.level("SECONDARY", no=20, color="<blue>", icon="👉")

    logger.add(
        console.print,
        level=LogLevel(level).name,
        colorize=True,
        format=log_formatter,
    )
    if log_to_file:
        logger.add(
            log_file,
            level=LogLevel(level).name,
            format="{time:YYYY-MM-DD HH:mm:ss} | {level: <8} | {message} ({name}:{function}:{line})",
            rotation="1 MB",
            retention=1,
            compression="zip",
        )


class BinaryUpdater:
    """Class to check for updates to a binary and install the update if available."""

    def __init__(
        self,
        binary_name: str,
        repository: str,
        version_regex: str = "",
        remove_from_release: str = "",
        executable_name: str = "",
    ):
        """Initialize the BinaryUpdater class.

        Args:
            binary_name (str): Name of the binary available in the PATH
            repository (str): GitHub repository in the format 'owner/repo'
            version_regex (str): Custom regex to identify the version in the binary --version output
            remove_from_release (str): Regex used to filter out releases. Useful when more than one release is available.
            executable_name (str): Name of executable, if different from binary_name
        """
        # Initialize instance attributes
        self._release_info: dict = {}
        self._local_version = ""
        self._download_url = ""
        self._download_asset_name = ""
        self._have_checked_local_install = False  # switch when we have checked local install
        self._have_local_binary = False
        self._cmd: sh.Command = None  # Replaced by sh.Command when local binary is found

        # Set class attributes
        self.binary_name = binary_name
        self.repository = repository
        self.version_regex = version_regex
        self.remove_from_release = remove_from_release
        self.executable_name = executable_name if executable_name else binary_name

        # Get the latest release information
        self.latest_version: str = re.search(r"(\d+\.\d+\.\d+)", self.release_info["name"]).group(1)
        self.is_draft: bool = self.release_info["draft"]
        self.is_prerelease: bool = self.release_info["prerelease"]
        self.assets: list = self.release_info["assets"]

    @property
    def have_local_binary(self) -> bool:
        """Determine if the binary is installed locally.

        This method checks if the binary specified by `self.binary_name` is available
        on the local system. It caches the result to avoid redundant checks on subsequent
        calls.

        Returns:
            bool: True if the binary is installed locally, False otherwise.
        """
        if self._have_checked_local_install:
            return self._have_local_binary

        try:
            self._cmd = sh.Command(self.executable_name)
        except sh.CommandNotFound:
            self._cmd = None

        self._have_checked_local_install = True
        self._have_local_binary = bool(self._cmd)
        return self._have_local_binary

    @property
    def release_info(self) -> dict:
        """Fetch and return the latest release information for the repository.

        This method sends a GET request to the GitHub API to retrieve the latest
        release data for the specified repository. If the release information has
        already been fetched and cached, it returns the cached data.

        Returns:
            dict: A dictionary containing the latest release information.

        Raises:
            typer.Exit: If the request to the GitHub API fails.
        """
        if not self._release_info:
            url = f"https://api.github.com/repos/{self.repository}/releases/latest"
            r = httpx.get(url, follow_redirects=True)

            if r.status_code != 200:  # noqa: PLR2004
                msg = f"Failed to fetch latest release: {url}"
                logger.error(msg)
                raise typer.Exit(1)

            self._release_info = r.json()

        return self._release_info

    @property
    def local_version(self) -> str:
        """Retrieve the local version of the binary.

        Returns:
            str: The local version string of the binary. If the binary is not present locally, returns an empty string.
        """
        if not self.have_local_binary:
            return ""

        if not self._local_version:
            local_version = self._cmd("--version").strip()

            if self.version_regex:
                self._local_version = re.search(  # type: ignore [union-attr]
                    self.version_regex, local_version, re.IGNORECASE
                ).group(1)
            else:
                self._local_version = re.search(r"(\d+\.\d+\.\d+)", local_version).group(1)

        return self._local_version

    def need_install(self) -> bool:
        """Determine if the binary needs to be installed or updated.

        This method checks if the local binary is present and if its version
        is up-to-date compared to the latest available version. If the local
        binary is missing or its version is outdated, the method returns True,
        indicating that an installation or update is needed.

        Returns:
            bool: True if the binary needs to be installed or updated, False otherwise.

        Raises:
            typer.Exit: If there is an error parsing the version strings,
                indicating that the versions are not in a valid
                semantic versioning (semver) format.
        """
        if not self.have_local_binary or not self.local_version:
            return True

        try:
            return VersionInfo.parse(self.local_version) < VersionInfo.parse(self.latest_version)
        except ValueError as e:
            logger.error("Failed to parse versions. Need semver format.")
            console.print(f"{self.local_version=}")
            console.print(f"{self.latest_version=}")
            raise typer.Exit(1) from e

    def _find_deb_release(self, architecture: str, remove_from_release: str) -> list[dict]:
        """Find a .deb release for the host system based on the specified architecture.

        This method searches through the available assets to find .deb packages that match
        the given architecture. It prioritizes non-MUSL builds over MUSL builds if both are available.

        Args:
            architecture (str): The architecture of the host system (e.g., 'x86_64', 'arm64').
            remove_from_release (str): A regex pattern to filter out releases.

        Returns:
            list[dict]: A list of dictionaries representing the .deb assets that match the specified architecture.
                If both non-MUSL and MUSL builds are found, non-MUSL builds are returned first.
                If no matching assets are found, an empty list is returned.

        Raises:
            KeyError: If the specified architecture is not supported.
            typer.Exit: If an unsupported architecture is provided, the method logs an error and exits the program.
        """
        possible_assets = []
        for a in self.assets:
            if not a["name"].endswith(".deb"):
                continue

            if remove_from_release and re.search(remove_from_release, a["name"].lower()):
                continue

            try:
                if not re.search(Arches[architecture.upper()].value, a["name"].lower()):
                    continue
            except KeyError as e:
                msg = f"Unsupported architecture: {architecture}"
                logger.error(msg)
                raise typer.Exit(1) from e

            possible_assets.append(a)

        if possible_assets:
            # Prioritize non-MUSL builds over MUSL builds
            non_musl_builds = [a for a in possible_assets if "musl" not in a["name"].lower()]
            musl_builds = [a for a in possible_assets if "musl" in a["name"].lower()]

            # Return the non-MUSL builds if available, otherwise fall back to MUSL
            if non_musl_builds:
                return non_musl_builds
            if musl_builds:
                return musl_builds

        return possible_assets

    def _find_packaged_release(
        self, operating_system: str, architecture: str, remove_from_release: str
    ) -> list[dict]:
        """Find a packaged release for the host system based on the operating system and architecture.

        This method filters the available assets to find those that match the specified operating system
        and architecture. It prioritizes non-MUSL builds over MUSL builds if both are available.

        Args:
            operating_system (str): The operating system of the host (e.g., 'linux', 'windows').
            architecture (str): The architecture of the host (e.g., 'x86_64', 'arm').
            remove_from_release (str): A regex pattern to filter out releases.

        Returns:
            list[dict]: A list of dictionaries representing the possible assets that match the criteria.
                        The list is prioritized to return non-MUSL builds first if available.

        Raises:
            KeyError: If the specified architecture is not supported.
            typer.Exit: If an unsupported architecture is encountered, the program will exit with a status code of 1.
        """
        possible_assets = []
        for a in self.assets:
            if not a["name"].endswith(".tar.gz"):
                continue

            if remove_from_release and re.search(remove_from_release, a["name"].lower()):
                continue

            if not re.search(operating_system.lower(), a["name"].lower()):
                continue

            try:
                if not re.search(Arches[architecture.upper()].value, a["name"].lower()):
                    continue
            except KeyError as e:
                msg = f"Unsupported architecture: {architecture}"
                logger.error(msg)
                raise typer.Exit(1) from e

            possible_assets.append(a)

        if possible_assets:
            # Prioritize non-MUSL builds over MUSL builds
            non_musl_builds = [a for a in possible_assets if "musl" not in a["name"].lower()]
            musl_builds = [a for a in possible_assets if "musl" in a["name"].lower()]

            # Return the non-MUSL builds if available, otherwise fall back to MUSL
            if non_musl_builds:
                return non_musl_builds
            if musl_builds:
                return musl_builds

        return possible_assets

    @property
    def download_url(self) -> str:
        """Identify and return the correct asset download URL for the host system.

        This method determines the appropriate download URL for the host system by:
        1. Gathering information about the host system's platform and machine.
        2. Finding possible releases based on the host system's platform.
        3. Selecting the correct release asset if multiple are found.

        Raises:
            typer.Exit: If the host system or machine cannot be determined.
            typer.Exit: If no assets are found for the host system.
            typer.Exit: If multiple assets are found for the host system.

        Returns:
            str: The download URL of the identified asset.
        """
        if not self._download_url:
            # Get information about the host system
            host_platform = platform.uname()
            if not host_platform.system:
                logger.error("Failed to determine host system")
                raise typer.Exit(1)
            if not host_platform.machine:
                logger.error("Failed to determine host machine")
                raise typer.Exit(1)

            possible_releases = []
            if host_platform.system.lower() == "linux":
                possible_releases = self._find_deb_release(
                    host_platform.machine, self.remove_from_release
                )

            if not possible_releases:
                possible_releases = self._find_packaged_release(
                    host_platform.system, host_platform.machine, self.remove_from_release
                )

            if not possible_releases:
                msg = "No assets found for host system in release"
                logger.error(msg)
                raise typer.Exit(1)

            if len(possible_releases) > 1:
                msg = "Multiple assets found for host system"
                logger.error(msg)
                for asset in possible_releases:
                    logger.log("SECONDARY", asset["name"])
                raise typer.Exit(1)

            self._download_url = possible_releases[0]["browser_download_url"]

        return self._download_url

    @property
    def download_asset_name(self) -> str:
        """Return the name of the asset to download.

        This method extracts the asset name from the download URL. If the asset name
        has not been previously determined (i.e., `_download_asset_name` is not set),
        it will split the `download_url` by slashes and take the last segment as the
        asset name. The extracted name is then cached in `_download_asset_name` for
        future use.

        Returns:
            str: The name of the asset to be downloaded.
        """
        if not self._download_asset_name:
            self._download_asset_name = self.download_url.split("/")[-1]

        return self._download_asset_name


def install_from_tarball(binary: BinaryUpdater, dry_run: bool) -> None:  # noqa: C901
    """Download and install a binary from a tarball.

    This function handles downloading a tarball, extracting its contents,
    and moving the binary to the appropriate directory. Supports dry-run mode.

    Args:
        binary (BinaryUpdater): Contains binary info for installation.
        dry_run (bool): If True, logs actions without performing them.

    Raises:
        typer.Exit: If any step fails.
    """

    def find_unarchived_binary(possible_dirs: list[Path], binary_name: str) -> Path | None:
        """Find the binary in one of the possible unarchived directories."""
        for directory in possible_dirs:
            if directory.exists() and directory.is_dir():
                unarchive_path = directory / binary_name
                if unarchive_path.exists() and unarchive_path.is_file():
                    return unarchive_path
        return None

    bin_dir = Path.home() / ".local" / "bin"
    bin_dir.mkdir(parents=True, exist_ok=True)

    with TemporaryDirectory() as tempdir:
        work_dir = Path(tempdir)
        download_path = work_dir / binary.download_asset_name
        possible_unarchive_dirs = [
            work_dir / binary.binary_name,
            work_dir / download_path.name,
            work_dir / download_path.stem,
            work_dir / download_path.name.replace(".tar.gz", ""),
        ]

        # Download the asset
        download_msg = f"Download: {binary.download_url}"
        if dry_run:
            logger.log("DRYRUN", download_msg)
        else:
            logger.debug(download_msg)
            with httpx.stream("GET", binary.download_url, follow_redirects=True) as r:
                r.raise_for_status()
                with download_path.open("wb") as f:
                    for chunk in r.iter_bytes():
                        f.write(chunk)

        # Unarchive the asset
        unarchive_msg = f"tar xf {download_path}"
        if dry_run:
            logger.log("DRYRUN", unarchive_msg)
        else:
            logger.debug(unarchive_msg)
            with tarfile.open(download_path, "r:gz") as tar:
                tar.extractall(path=work_dir, filter="data")

        # Move the binary to the bin directory
        unarchive_path = find_unarchived_binary(possible_unarchive_dirs, binary.binary_name)
        if not unarchive_path:
            error_msg = f"Failed to find {binary.binary_name} in archive"
            if dry_run:
                logger.log("DRYRUN", error_msg)
            else:
                logger.error(error_msg)
                raise typer.Exit(1)
        else:
            move_msg = f"mv {unarchive_path} {bin_dir / binary.binary_name}"
            if dry_run:
                logger.log("DRYRUN", move_msg)
            else:
                logger.debug(move_msg)
                shutil.move(unarchive_path, bin_dir / binary.binary_name)


def install_deb_package(binary: BinaryUpdater, dry_run: bool) -> None:
    """Download and install a binary from a .deb package.

    Args:
        binary (BinaryUpdater): The binary updater object containing download information.
        dry_run (bool): If True, log actions without performing them.

    Raises:
        typer.Exit: If dpkg command is not found or installation fails.
    """
    bin_dir = Path.home() / ".local" / "bin"
    bin_dir.mkdir(parents=True, exist_ok=True)
    tempdir = TemporaryDirectory(ignore_cleanup_errors=True)
    work_dir = Path(tempdir.name)
    download_path = work_dir / binary.download_asset_name

    # Download the asset
    msg = f"download {binary.download_url}"
    if dry_run:
        logger.log("DRYRUN", msg)
    else:
        logger.debug(msg)
        with httpx.stream("GET", binary.download_url, follow_redirects=True) as r:
            r.raise_for_status()
            with download_path.open("wb") as f:
                for chunk in r.iter_bytes():
                    f.write(chunk)

    # Install the .deb package
    msg = f"sudo dpkg -i {binary.binary_name}"
    if dry_run:
        logger.log("DRYRUN", msg)
    else:
        logger.debug(msg)
        try:
            dpkg = sh.Command("dpkg")
        except sh.CommandNotFound as e:
            logger.error("Failed to find dpkg")
            raise typer.Exit(1) from e

        logger.debug(f"Installing {download_path} using dpkg")
        try:
            with sh.contrib.sudo:
                dpkg("-i", download_path, _fg=True)
        except sh.ErrorReturnCode as e:
            logger.error(f"Failed to install {binary.binary_name}: {e}")
            raise typer.Exit(1) from e

    tempdir.cleanup()


def install_from_cli_script(install_script: str, dry_run: bool) -> None:
    """Execute a CLI install script to install the binary.

    This function downloads and runs a shell script to install the binary. It supports
    dry-run mode to simulate the actions without making any changes.

    Args:
        install_script (str): URL of the install script to be executed.
        dry_run (bool): If True, the function will only log the actions that would be taken
                        without actually performing them.

    Raises:
        typer.Exit: If the script execution fails, the function will log an error and exit.
    """
    msg = f"{install_script} | sh"
    if dry_run:
        logger.log("DRYRUN", msg)
    else:
        logger.debug(msg)

        curl = sh.Command("curl")
        sh_bin = sh.Command("sh")

        try:
            sh_response = sh_bin(
                _in=curl("sSfL", install_script),
            )
        except sh.ErrorReturnCode as e:
            logger.error(f"Failed to run install script: {e}")
            raise typer.Exit(1) from e

        console.print(sh_response)


def main(
    binary_name: Annotated[str, typer.Option(help="Name of the binary", show_default=False)],
    repository: Annotated[
        str, typer.Option(help="GitHub repository in the format 'owner/repo'", show_default=False)
    ],
    executable_name: Annotated[
        str,
        typer.Option(help="Name of executable if different from binary_name", show_default=False),
    ] = "",
    install_script: Annotated[
        str, typer.Option(help="URL for an install script to be piped to sh", show_default=False)
    ] = "",
    version_regex: Annotated[
        str,
        typer.Option(
            help="Custom regex to identify the version in the binary --version output",
            show_default=False,
        ),
    ] = "",
    remove_from_release: Annotated[
        str,
        typer.Option(
            help="Regex used to filter out releases. Useful when more than one release is available.",
            show_default=False,
        ),
    ] = "",
    log_file: Annotated[
        Path,
        typer.Option(
            help="Path to log file",
            show_default=True,
            dir_okay=False,
            file_okay=True,
            exists=False,
        ),
    ] = Path.home() / "logs" / "chezmoi_install_binaries.log",
    log_to_file: Annotated[
        bool,
        typer.Option(
            "--log-to-file",
            help="Log to file",
            show_default=True,
        ),
    ] = False,
    verbosity: Annotated[
        int,
        typer.Option(
            "-v",
            "--verbose",
            show_default=True,
            help="""Set verbosity level(0=INFO, 1=DEBUG, 2=TRACE)""",
            count=True,
        ),
    ] = 0,
    dry_run: Annotated[
        bool,
        typer.Option(
            "--dry-run",
            "-n",
            help="Report what would be done without making changes",
            show_default=True,
        ),
    ] = False,
) -> None:
    """Install or update a binary from Github.  Supports installing from tarballs, .deb packages, or CLI install scripts.  If the binary is already installed, it will be updated only if a newer version is available."""
    instantiate_logger(verbosity, log_file, log_to_file)

    console.rule(
        f"[cyan]── Install/update [bold]{binary_name}",
        align="left",
        style="bold cyan",
    )

    binary = BinaryUpdater(
        binary_name=binary_name,
        repository=repository,
        version_regex=version_regex,
        remove_from_release=remove_from_release,
        executable_name=executable_name,
    )

    logger.log("SECONDARY", f"Repository: https://github.com/{binary.repository}")
    logger.log("SECONDARY", f"Latest version: {binary.latest_version}")
    logger.log(
        "SECONDARY",
        f"Local version: {binary.local_version}"
        if binary.have_local_binary
        else f"{binary_name} not installed",
    )

    # Exit if the binary is up to date
    if not binary.need_install():
        logger.success(f"{binary.binary_name} is up to date")
        raise typer.Exit(0)

    if binary.is_draft:
        logger.warning("Latest release is a draft. Skip installation.")
        raise typer.Exit(1)

    if binary.is_prerelease:
        logger.warning("Latest release is a pre-release. Skip installation.")
        raise typer.Exit(1)

    logger.info(
        f"Update {binary.binary_name} ({binary.local_version} -> {binary.latest_version})"
        if binary.have_local_binary
        else f"Install {binary.binary_name}"
    )

    # Install the binary
    if install_script:
        install_from_cli_script(install_script, dry_run)
    elif binary.download_url.endswith(".tar.gz"):
        install_from_tarball(binary, dry_run)
    elif binary.download_url.endswith(".deb"):
        install_deb_package(binary, dry_run)

    if not dry_run:
        logger.success(
            f"Updated {binary.binary_name} to version {binary.latest_version}"
            if binary.have_local_binary
            else f"Installed {binary.binary_name} version {binary.latest_version}"
        )


if __name__ == "__main__":
    typer.run(main)
