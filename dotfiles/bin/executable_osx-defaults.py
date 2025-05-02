#!/usr/bin/env -S uv run --script

"""Set MacOS Defaults."""

# /// script
# requires-python = ">=3.12"
# dependencies = [
#   "rich",
#   "sh",
# ]
# ///

import platform
import re
import shlex
import sys
from dataclasses import dataclass
from enum import Enum
from pathlib import Path

import sh  # type: ignore
from rich.console import Console  # type: ignore
from rich.text import Text  # type: ignore
from rich.theme import Theme  # type: ignore

custom_theme = Theme(
    {
        "info": "",
        "warning": "dark_orange bold",
        "error": "bold red",
        "success": "bold green",
        "debug": "cadet_blue",
        "trace": "cadet_blue",
        "secondary": "dim",
        "notice": "bold",
        "dryrun": "blue bold",
        "critical": "bold red reverse",
    }
)
console = Console(theme=custom_theme)


def run_command(  # noqa: C901
    cmd: str,
    args: list[str],
    pushd: str | Path = "",
    okay_codes: list[int] = [],
    exclude_regex: str | None = None,
    *,
    quiet: bool = False,
    sudo: bool = False,
) -> str:
    """Execute a shell command and capture its output with ANSI color support.

    Run a shell command with the specified arguments while preserving ANSI color codes and terminal formatting. Stream command output to the console in real-time unless quiet mode is enabled. Change to a different working directory before execution if pushd is specified.

    Args:
        cmd (str): The command name to execute
        args (list[str]): Command line arguments to pass to the command
        pushd (str | Path): Directory to change to before running the command. Empty string means current directory. Defaults to "".
        okay_codes (list[int]): List of exit codes that are considered successful. Defaults to [].
        exclude_regex (str | None): Regex to exclude lines from the output. Defaults to None.
        quiet (bool): Whether to suppress real-time output to console. Defaults to False.
        sudo (bool): Whether to run the command with sudo. Defaults to False.

    Returns:
        str: The complete command output as a string with ANSI color codes preserved

    Changelog:
        - v2.2.1: Initial version

    Raises:
        ShellCommandNotFoundError: When the command is not found in PATH
        ShellCommandFailedError: When the command exits with a non-zero status code
    """
    output_lines: list[str] = []

    def _process_output(line: str, exclude_regex: str | None = None) -> None:
        """Process a single line of command output.

        Collect output lines for final return value and optionally display to console. Preserve ANSI color codes and formatting when displaying output.

        Args:
            line (str): A single line of output from the command execution
            exclude_regex (str | None): Regex to exclude lines from the output. Defaults to None.
        """
        if exclude_regex and re.search(exclude_regex, line):
            return

        output_lines.append(str(line))
        if not quiet:
            console.print(Text.from_ansi(str(line)))

    def _execute_command(*, sudo: bool = False) -> str:
        """Execute the shell command and process its output.

        Create and run the shell command with the configured arguments. Handle command execution errors by raising appropriate exceptions.

        Args:
            sudo (bool): Whether to run the command with sudo. Defaults to False.

        Returns:
            str: The complete command output as a string

        Raises:
            ShellCommandNotFoundError: When the command is not found in PATH
            ShellCommandFailedError: When the command exits with a non-zero status code
        """
        try:
            command = sh.Command(cmd)
            if sudo:
                with sh.contrib.sudo(k=True, _with=True):
                    command(
                        *args,
                        _out=lambda line: _process_output(line, exclude_regex),
                        _ok_code=okay_codes or [0],
                    )
            else:
                command(
                    *args,
                    _out=lambda line: _process_output(line, exclude_regex),
                    _ok_code=okay_codes or [0],
                )
        except sh.CommandNotFound:
            console.print(f"Command not found: {cmd}", style="error")
            sys.exit(1)
        except sh.ErrorReturnCode as e:
            console.print(
                f"Above command failed with exit code {e.exit_code}",
                style="error",
            )
            console.print(f"command: '{e.full_cmd}'", style="secondary")
            if e.stdout:
                console.print(f"stdout: {e.stdout.decode()}", style="secondary")
            if e.stderr:
                console.print(f"stderr: {e.stderr.decode()}", style="secondary")

            return ""

        return "".join(output_lines)

    if pushd:
        if not isinstance(pushd, Path):
            pushd = Path(pushd)

        pushd = pushd.expanduser().absolute()

        if not pushd.exists():
            console.print(f"Directory {pushd} does not exist", style="error")
            sys.exit(1)

        with sh.pushd(pushd):
            return _execute_command(sudo=sudo)

    return _execute_command(sudo=sudo)


class CommandType(Enum):
    """Enumeration for command types. The value is the command name.

    Attributes:
        DEFAULTS: Command is a macOS defaults command.
    """

    DEFAULTS = "defaults"
    PLISTBUDDY = "/usr/libexec/PlistBuddy"
    PMSET = "pmset"
    CHFLAGS = "chflags"


@dataclass
class Setting:
    """A class to represent a setting.

    Attributes:
        command (str): The command to run.
        description (str): A description of the setting.
    """

    command: str
    description: str
    section: str = "Other"
    type: CommandType = CommandType.DEFAULTS
    sudo: bool = False

    @property
    def args(self) -> list[str]:
        """Get the arguments for the command.

        Returns:
            list[str]: The arguments for the command.
        """
        tokens = shlex.split(self.command.strip())
        if self.sudo:
            tokens = [x for x in tokens if x.lower() != "sudo"]

        return [x for x in tokens if x.lower() != self.type.value.lower()]

    @property
    def full_description(self) -> str:
        """Get the full description of the setting.

        Returns:
            str: The full description of the setting.
        """
        return f"{self.section}: {self.description}" if self.section else self.description


commands = [
    Setting(
        command=f"chflags nohidden {Path.home()}/Library",
        description="Show ~/Library",
        type=CommandType.CHFLAGS,
    ),
    Setting(
        command="chflags nohidden /Volumes",
        description="Show /Volumes",
        type=CommandType.CHFLAGS,
        sudo=True,
    ),
    Setting(
        command="pmset -a lidwake 1",
        description="Enable lid wakeup",
        type=CommandType.PMSET,
        sudo=True,
    ),
    Setting(
        command="pmset -a autorestart 1",
        description="Restart automatically on power loss",
        type=CommandType.PMSET,
        sudo=True,
    ),
    Setting(
        command="pmset -a displaysleep 4",
        description="Sleep the display after 4 minutes",
        type=CommandType.PMSET,
        sudo=True,
    ),
    Setting(
        command="pmset -c sleep 0",
        description="Disable machine sleep while charging",
        type=CommandType.PMSET,
        sudo=True,
    ),
    Setting(
        command="pmset -b sleep 5",
        description="Set machine sleep to 5 minutes on battery",
        type=CommandType.PMSET,
        sudo=True,
    ),
    Setting(
        command='defaults write NSGlobalDomain AppleLanguages "(en-US)"',
        description="Set locale to US English",
        section="Locale",
    ),
    Setting(
        command='defaults write NSGlobalDomain AppleLocale -string "en_US@currency=USD"',
        description="Set locale to US English",
        section="Locale",
    ),
    Setting(
        command='defaults write NSGlobalDomain AppleMeasurementUnits -string "Inches"',
        description="Set measurement units to inches",
        section="Locale",
    ),
    Setting(
        command="defaults write NSGlobalDomain AppleMetricUnits -bool false",
        description="Set metric units to false",
        section="Locale",
    ),
    Setting(
        command="defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true",
        description="Expand save panel by default mode 1",
    ),
    Setting(
        command="defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true",
        description="Expand save panel by default mode 2",
    ),
    Setting(
        command="defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true",
        description="Expand print panel by default mode 1",
        section="Printing",
    ),
    Setting(
        command="defaults write NSGlobalDomain com.apple.sound.uiaudio.enabled -bool false",
        description="Disable UI sound effects",
        section="Sound",
    ),
    Setting(
        command="defaults write NSGlobalDomain PMPrintingExpandedStateForPrint2 -bool true",
        description="Expand print panel by default mode 2",
        section="Printing",
    ),
    Setting(
        command="defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false",
        description="Save new documents to disk (not iCloud) by default",
    ),
    Setting(
        command='defaults write com.apple.print.PrintingPrefs "Quit When Finished" -bool true',
        description="Quit printer app when all jobs finished",
        section="Printing",
    ),
    Setting(
        command="defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false",
        description="Disable smart quotes",
        section="Keyboard",
    ),
    Setting(
        command="defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false",
        description="Disable smart dashes",
        section="Keyboard",
    ),
    Setting(
        command="defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false",
        description="Disable smart capitalization",
        section="Keyboard",
    ),
    Setting(
        command="defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false",
        description="Disable smart period substitution",
        section="Keyboard",
    ),
    Setting(
        command="defaults write NSGlobalDomain NSWindowResizeTime .001",
        description="Get snappier save sheets",
        section="Performance",
    ),
    Setting(
        command="defaults write NSGlobalDomain AppleHighlightColor -string '0.984300 0.929400 0.450900'",
        description="Set highlight color to yellow",
        section="Display",
    ),
    Setting(
        command="defaults write NSGlobalDomain NSTableViewDefaultSizeMode -int 1",
        description="Set sidebar icon size to small",
        section="Finder",
    ),
    Setting(
        command="defaults write NSGlobalDomain AppleShowScrollBars -string 'Always'",
        description="Show scrollbars always",
        section="Display",
    ),
    Setting(
        command="defaults write com.apple.universalaccess reduceTransparency -bool true",
        description="Reduce transparency to save GPU cycles",
        section="Performance",
    ),
    Setting(
        command="defaults write NSGlobalDomain NSAutomaticWindowAnimationsEnabled -bool false",
        description="Disable window animations",
        section="Display",
    ),
    Setting(
        command="defaults write com.apple.LaunchServices LSQuarantine -bool false",
        description="Disable quarantine",
    ),
    Setting(
        command="defaults write NSGlobalDomain NSTextShowsControlCharacters -bool true",
        description="Show control characters in text views",
    ),
    Setting(
        command="defaults write NSGlobalDomain NSDisableAutomaticTermination -bool true",
        description="Disable automatic termination of inactive apps",
        section="Performance",
    ),
    Setting(
        command="defaults write -g ApplePersistence -bool no",
        description="Disable re-opening of apps after logout",
        section="Login",
    ),
    Setting(
        command="defaults write com.apple.systempreferences NSQuitAlwaysKeepsWindows -bool false",
        description="Disable 'Reopen windows when logging back in'",
        section="Login",
    ),
    Setting(
        command="defaults write com.apple.helpviewer DevMode -bool true",
        description="Enable help viewer DevMode",
    ),
    Setting(
        command="defaults write com.apple.SoftwareUpdate ScheduleFrequency -int 1",
        description="Check for software updates daily",
    ),
    Setting(
        command="defaults write com.apple.AppleMultitouchTrackpad FirstClickThreshold -int 0",
        description="light clicking",
        section="Trackpad",
    ),
    Setting(
        command="defaults write com.apple.AppleMultitouchTrackpad ActuationStrength -int 0",
        description="silent clicking",
        section="Trackpad",
    ),
    Setting(
        command="defaults write -g com.apple.trackpad.scaling 2",
        description="Set reasonable speed",
        section="Trackpad",
    ),
    Setting(
        command="defaults write com.apple.dock showLaunchpadGestureEnabled -int 0",
        description="Disable Launchpad gesture",
        section="Trackpad",
    ),
    Setting(
        command="defaults write -g com.apple.mouse.scaling 2.5",
        description="Set reasonable speed",
        section="Mouse",
    ),
    Setting(
        command="defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false",
        description="Disable press-and-hold for keys",
        section="Keyboard",
    ),
    Setting(
        command="defaults write NSGlobalDomain InitialKeyRepeat -int 12",
        description="Key repeats happen more quickly",
        section="Keyboard",
    ),
    Setting(
        command="defaults write NSGlobalDomain KeyRepeat -int 1",
        description="Blazingly fast key repeat",
        section="Keyboard",
    ),
    Setting(
        command="defaults write NSGlobalDomain AppleKeyboardUIMode -int 3",
        description="Full keyboard access",
        section="Keyboard",
    ),
    Setting(
        command="defaults write com.apple.BezelServices kDim -bool true",
        description="Illuminate built-in MacBook keyboard in low light",
        section="Keyboard",
    ),
    Setting(
        command="defaults write com.apple.BezelServices kDimTime -int 300",
        description="Turn off illumination after 5 minutes",
        section="Keyboard",
    ),
    Setting(
        command=f'defaults write com.apple.screencapture location -string "{Path.home()}/Desktop"',
        description="Save screenshots to Desktop",
        section="Screenshots",
    ),
    Setting(
        command='defaults write com.apple.screencapture type -string "png"',
        description="Set screenshot format to PNG",
        section="Screenshots",
    ),
    Setting(
        command="defaults write com.apple.screencapture disable-shadow -bool false",
        description="Enable shadow in screenshots",
        section="Screenshots",
    ),
    Setting(
        command="defaults write NSGlobalDomain AppleFontSmoothing -int 1",
        description="Font smoothing",
        section="Display",
    ),
    Setting(
        command="defaults write /Library/Preferences/com.apple.windowserver DisplayResolutionEnabled -bool true",
        description="Enable HiDPI display modes (requires restart)",
        sudo=True,
        section="Display",
    ),
    Setting(
        command="defaults write com.apple.screensaver askForPassword -int 1",
        description="Require password after sleep or screen saver",
        section="Login",
    ),
    Setting(
        command="defaults write com.apple.screensaver askForPasswordDelay -int 0",
        description="Require password immediately after sleep or screen saver begins",
        section="Login",
    ),
    Setting(
        command="defaults write com.apple.finder QuitMenuItem -bool true",
        description="Show Quit menu item (Requires restart)",
        section="Finder",
    ),
    Setting(
        command="defaults write com.apple.finder DisableAllAnimations -bool true",
        description="Disable all animations",
        section="Finder",
    ),
    Setting(
        command='defaults write com.apple.finder NewWindowTarget -string "PfHm"',
        description="Set Home folder as the default location for new Finder windows",
        section="Finder",
    ),
    Setting(
        command=f'defaults write com.apple.finder NewWindowTargetPath -string "file://{Path.home()}/"',
        description="Set Home folder as the default location for new Finder windows",
        section="Finder",
    ),
    Setting(
        command="defaults write com.apple.finder ShowExternalHardDrivesOnDesktop -bool true",
        description="Show external hard drives on desktop",
        section="Finder",
    ),
    Setting(
        command="defaults write com.apple.finder ShowHardDrivesOnDesktop -bool true",
        description="Show hard drives on desktop",
        section="Finder",
    ),
    Setting(
        command="defaults write com.apple.finder ShowMountedServersOnDesktop -bool true",
        description="Show servers on desktop",
        section="Finder",
    ),
    Setting(
        command="defaults write com.apple.finder ShowRemovableMediaOnDesktop -bool true",
        description="Show removable media on desktop",
        section="Finder",
    ),
    Setting(
        command="defaults write NSGlobalDomain AppleShowAllExtensions -bool true",
        description="Show all filename extensions",
        section="Finder",
    ),
    Setting(
        command="defaults write com.apple.finder ShowStatusBar -bool true",
        description="Show status bar",
        section="Finder",
    ),
    Setting(
        command="defaults write com.apple.finder ShowPathbar -bool true",
        description="Show path bar",
        section="Finder",
    ),
    Setting(
        command="defaults write com.apple.finder QLEnableTextSelection -bool true",
        description="Enable text selection in Quick Look",
        section="Finder",
    ),
    Setting(
        command="defaults write com.apple.finder _FXShowPosixPathInTitle -bool true",
        description="Show POSIX path in title bar",
        section="Finder",
    ),
    Setting(
        command='defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"',
        description="Search the current folder by default",
        section="Finder",
    ),
    Setting(
        command="defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false",
        description="Disable warning when changing file extension",
        section="Finder",
    ),
    Setting(
        command="defaults write NSGlobalDomain com.apple.springing.enabled -bool true",
        description="Enable spring loading for directories",
        section="Finder",
    ),
    Setting(
        command="defaults write NSGlobalDomain com.apple.springing.delay -float 0.1",
        description="Remove spring loading delay",
        section="Finder",
    ),
    Setting(
        command="defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true",
        description="Don't write .DS_Store files to network volumes",
        section="Finder",
    ),
    Setting(
        command="defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true",
        description="Don't write .DS_Store files to USB volumes",
        section="Finder",
    ),
    Setting(
        command='defaults write com.apple.finder FXPreferredViewStyle -string "clmv"',
        description="Use column view in all Finder windows",
        section="Finder",
    ),
    Setting(
        command="defaults write com.apple.finder WarnOnEmptyTrash -bool false",
        description="Disable warning when emptying trash",
        section="Finder",
    ),
    Setting(
        command="defaults write com.apple.finder FXInfoPanesExpanded -dict General -bool true MetaData -bool true OpenWith -bool true Privileges -bool true",
        description="expand file info panes",
        section="Finder",
    ),
    Setting(
        command="defaults write com.apple.dock tilesize -int 30",
        description="Set small icons",
        section="Dock",
    ),
    Setting(
        command="defaults write com.apple.dock expose-animation-duration -float 0.1",
        description="Speed up expose animations",
        section="Dock",
    ),
    Setting(
        command="defaults write com.apple.dock showhidden -bool true",
        description="Show hidden apps",
        section="Dock",
    ),
    Setting(
        command="defaults write com.apple.dock mouse-over-hilite-stack -bool true",
        description="Highlight stack on mouse over",
        section="Dock",
    ),
    Setting(
        command='defaults write com.apple.dock mineffect -string "genie"',
        description="Use 'genie' minimize effect",
        section="Dock",
    ),
    Setting(
        command="defaults write com.apple.dock static-only -bool true",
        description="Only show open applications",
        section="Dock",
    ),
    Setting(
        command="defaults write com.apple.dock minimize-to-application -bool true",
        description="Minimize to application",
        section="Dock",
    ),
    Setting(
        command="defaults write com.apple.dock persistent-apps -array",
        description="Clear persistent apps",
        section="Dock",
    ),
    Setting(
        command="defaults write com.apple.dock enable-spring-load-actions-on-all-items -bool true",
        description="Enable spring loading for all items",
        section="Dock",
    ),
    Setting(
        command="defaults write com.apple.dock show-process-indicators -bool true",
        description="Show process indicators",
        section="Dock",
    ),
    Setting(
        command="defaults write com.apple.dock launchanim -bool false",
        description="Disable launch animation",
        section="Dock",
    ),
    Setting(
        command="defaults write com.apple.dock autohide-delay -float 0",
        description="No delay when hiding",
        section="Dock",
    ),
    Setting(
        command="defaults write com.apple.dock expose-animation-duration -float 0.1",
        description="Speed up expose animations",
        section="Dock",
    ),
    Setting(
        command="defaults write com.apple.dock autohide-time-modifier -float 0",
        description="Speed up hiding/showing",
        section="Dock",
    ),
    Setting(
        command="defaults write com.apple.dock autohide -bool true",
        description="Auto-hide",
        section="Dock",
    ),
    Setting(
        command="defaults write com.apple.dashboard mcx-disabled -bool true",
        description="Disable Dashboard",
        section="Spaces",
    ),
    Setting(
        command="defaults write com.apple.dock dashboard-in-overlay -bool true",
        description="Don't show dashboard as a space",
        section="Spaces",
    ),
    Setting(
        command="defaults write com.apple.dock mru-spaces -bool false",
        description="Don't automatically rearrange spaces based on most recent use",
        section="Spaces",
    ),
    Setting(
        command="defaults write com.apple.appstore WebKitDeveloperExtras -bool true",
        description="Enable Web Inspector in App Store",
        section="App Store",
    ),
    Setting(
        command="defaults write com.apple.appstore ShowDebugMenu -bool true",
        description="Enable Debug menu in App Store",
        section="App Store",
    ),
    Setting(
        command="defaults write com.apple.TimeMachine DoNotOfferNewDisksForBackup -bool true",
        description="Don't offer new disks for backup",
        section="Time Machine",
    ),
    Setting(
        command="defaults write com.apple.TextEdit RichText -int 0",
        description="Use plain text mode for new TextEdit documents",
        section="TextEdit",
    ),
    Setting(
        command="defaults write com.apple.TextEdit PlainTextEncoding -int 4",
        description="Use UTF-8 encoding for plain text files",
        section="TextEdit",
    ),
    Setting(
        command="defaults write com.apple.TextEdit PlainTextEncodingForWrite -int 4",
        description="Use UTF-8 encoding for plain text files",
        section="TextEdit",
    ),
    Setting(
        command="defaults write com.apple.DiskUtility DUDebugMenuEnabled -bool true",
        description="Enable the debug menu in Disk Utility",
        section="Disk Utility",
    ),
    Setting(
        command="defaults write com.apple.DiskUtility advanced-image-options -bool true",
        description="Enable advanced image options in Disk Utility",
        section="Disk Utility",
    ),
    Setting(
        command="defaults -currentHost write com.apple.ImageCapture disableHotPlug -bool YES",
        description="Disable camera auto-open on connect",
        section="Image Capture",
    ),
    Setting(
        command="defaults write com.apple.Safari IncludeDevelopMenu -bool true",
        description="Enable the Develop menu in Safari",
        section="Safari",
    ),
    Setting(
        command="defaults write com.apple.Safari WebKitDeveloperExtrasEnabledPreferenceKey -bool true",
        description="Enable Web Inspector in Safari",
        section="Safari",
    ),
    Setting(
        command="defaults write com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2DeveloperExtrasEnabled -bool true",
        description="Enable Web Inspector in Safari",
        section="Safari",
    ),
    Setting(
        command="defaults write com.apple.Safari IncludeInternalDebugMenu -bool true",
        description="Enable the Debug menu in Safari",
        section="Safari",
    ),
    Setting(
        command="defaults write com.apple.Safari ShowOverlayStatusBar -bool true",
        description="Show status bar in Safari",
        section="Safari",
    ),
    Setting(
        command="defaults write NSGlobalDomain WebKitDeveloperExtras -bool true",
        description="Add a context menu item for showing the Web Inspector in web views",
        section="Safari",
    ),
    Setting(
        command="defaults write com.apple.Safari FindOnPageMatchesWordStartsOnly -bool false",
        description="Make Safari's search banners default to 'Contains' instead of 'Starts With'",
        section="Safari",
    ),
    Setting(
        command="defaults write com.apple.Safari UniversalSearchEnabled -bool false",
        description="Don't send search queries to Apple",
        section="Safari",
    ),
    Setting(
        command="defaults write com.apple.Safari SuppressSearchSuggestions -bool true",
        description="Don't send search queries to Apple",
        section="Safari",
    ),
    Setting(
        command="defaults write com.apple.Safari ShowFullURLInSmartSearchField -bool true",
        description="Show full URL in address bar",
        section="Safari",
    ),
    Setting(
        command='defaults write com.apple.Safari HomePage -string "about:blank"',
        description="Set homepage to blank",
        section="Safari",
    ),
    Setting(
        command="defaults write com.apple.Safari AutoOpenSafeDownloads -bool false",
        description="Don't open 'safe' files automatically after downloading",
        section="Safari",
    ),
    Setting(
        command='defaults write com.apple.Safari ProxiesInBookmarksBar "()"',
        description="Remove useless icons from bookmarks bar",
        section="Safari",
    ),
    Setting(
        command="defaults write com.apple.Safari ShowFavoritesBar -bool true",
        description="Show favorites bar",
        section="Safari",
    ),
    Setting(
        command="defaults write com.apple.Safari AutoFillFromAddressBook -bool false",
        description="Don't fill in address info automatically",
        section="Safari",
    ),
    Setting(
        command="defaults write com.apple.Safari AutoFillPasswords -bool false",
        description="Don't fill in password info automatically",
        section="Safari",
    ),
    Setting(
        command="defaults write com.apple.Safari AutoFillCreditCardData -bool false",
        description="Don't fill in credit card info automatically",
        section="Safari",
    ),
    Setting(
        command="defaults write com.apple.Safari AutoFillMiscellaneousForms -bool false",
        description="Don't fill in miscellaneous info automatically",
        section="Safari",
    ),
    Setting(
        command="defaults write com.apple.Safari WarnAboutFraudulentWebsites -bool true",
        description="Warn about fraudulent websites",
        section="Safari",
    ),
    Setting(
        command="defaults write com.apple.Safari SendDoNotTrackHTTPHeader -bool true",
        description="Send 'Do Not Track' HTTP header",
        section="Safari",
    ),
    Setting(
        command="defaults write com.apple.mail AddressesIncludeNameOnPasteboard -bool false",
        description="Copy email addresses as 'foo@example.com' instead of 'Foo Bar <foo@example.com>'",
        section="Mail",
    ),
    Setting(
        command="defaults write com.apple.mail DisableReplyAnimations -bool true",
        description="Disable reply animations",
        section="Mail",
    ),
    Setting(
        command="defaults write com.apple.mail DisableSendAnimations -bool true",
        description="Disable send animations",
        section="Mail",
    ),
    Setting(
        command='defaults write com.apple.mail DraftsViewerAttributes -dict-add "DisplayInThreadedMode" -string "yes"',
        description="Display emails in threaded mode",
        section="Mail",
    ),
    Setting(
        command='defaults write com.apple.mail DraftsViewerAttributes -dict-add "SortedDescending" -string "no"',
        description="Sort emails in descending order",
        section="Mail",
    ),
    Setting(
        command='defaults write com.apple.mail DraftsViewerAttributes -dict-add "SortOrder" -string "received-date"',
        description="Sort emails by received date",
        section="Mail",
    ),
    Setting(
        command="defaults write com.apple.mail-shared DisableURLLoading -bool true",
        description="Don't load external content by default",
        section="Mail",
    ),
    Setting(
        command="defaults write com.apple.mail DisableInlineAttachmentViewing -bool true",
        description="Don't show inline attachments",
        section="Mail",
    ),
    Setting(
        command="defaults write com.apple.terminal StringEncodings -array 4",
        description="Set UTF-8 as the default encoding",
        section="Terminal",
    ),
    Setting(
        command="defaults write com.apple.terminal SecureKeyboardEntry -bool true",
        description="Enable Secure Keyboard Entry",
        section="Terminal",
    ),
    Setting(
        command="defaults write com.apple.Terminal ShowLineMarks -int 0",
        description="Disable line marks",
        section="Terminal",
    ),
    Setting(
        command="defaults write com.apple.ActivityMonitor OpenMainWindow -bool true",
        description="Open Activity Monitor to main window",
        section="Activity Monitor",
    ),
    Setting(
        command="defaults write com.apple.ActivityMonitor ShowCategory -int 0",
        description="Show all processes",
        section="Activity Monitor",
    ),
    Setting(
        command="defaults write com.apple.ActivityMonitor IconType -int 5",
        description="Show CPU usage in Dock icon",
        section="Activity Monitor",
    ),
    Setting(
        command='defaults write com.apple.ActivityMonitor SortColumn -string "CPUUsage"',
        description="Sort by CPU usage",
        section="Activity Monitor",
    ),
    Setting(
        command="defaults write com.apple.ActivityMonitor SortDirection -int 0",
        description="Sort direction descending",
        section="Activity Monitor",
    ),
    Setting(
        command='defaults write com.apple.messageshelper.MessageController SOInputLineSettings -dict-add "automaticQuoteSubstitutionEnabled" -bool false',
        description="Disable smart quotes in Messages",
        section="Messages",
    ),
    Setting(
        command='defaults write com.apple.messageshelper.MessageController SOInputLineSettings -dict-add "continuousSpellCheckingEnabled" -bool false',
        description="Disable continuous spell checking in Messages",
        section="Messages",
    ),
    Setting(
        command="defaults write com.apple.universalaccess closeViewScrollWheelToggle -bool true",
        description="Enable zoom with scroll wheel",
        section="Accessibility",
    ),
    Setting(
        command="defaults write com.apple.universalaccess HIDScrollZoomModifierMask -int 262144",
        description="Enable zoom with Ctrl (^) modifier key",
        section="Accessibility",
    ),
    Setting(
        command="defaults write com.apple.universalaccess closeViewZoomFollowsFocus -bool true",
        description="Enable zoom follows focus",
        section="Accessibility",
    ),
    Setting(
        command='defaults write com.apple.BluetoothAudioAgent "Apple Bitpool Min (editable)" -int 40,',
        description="Increase sound quality for Bluetooth headphones",
        section="Bluetooth",
        type=CommandType.DEFAULTS,
        sudo=False,
    ),
    Setting(
        command=f'/usr/libexec/PlistBuddy -c "Set DesktopViewSettings:IconViewSettings:labelOnBottom false" {Path.home()}/Library/Preferences/com.apple.finder.plist',
        type=CommandType.PLISTBUDDY,
        description="Show item info to the right of the icons",
        section="Finder",
        sudo=False,
    ),
    Setting(
        command=f'/usr/libexec/PlistBuddy -c "Set :DesktopViewSettings:IconViewSettings:arrangeBy grid" {Path.home()}/Library/Preferences/com.apple.finder.plist',
        description="Arrange icons by grid 1",
        section="Finder",
        type=CommandType.PLISTBUDDY,
        sudo=False,
    ),
    Setting(
        command=f'/usr/libexec/PlistBuddy -c "Set :FK_StandardViewSettings:IconViewSettings:arrangeBy grid" {Path.home()}/Library/Preferences/com.apple.finder.plist',
        description="Arrange icons by grid 2",
        section="Finder",
        type=CommandType.PLISTBUDDY,
    ),
    Setting(
        command=f'/usr/libexec/PlistBuddy -c "Set :StandardViewSettings:IconViewSettings:arrangeBy grid" {Path.home()}/Library/Preferences/com.apple.finder.plist',
        description="Arrange icons by grid 3",
        section="Finder",
        type=CommandType.PLISTBUDDY,
    ),
    Setting(
        command=f'/usr/libexec/PlistBuddy -c "Set DesktopViewSettings:IconViewSettings:gridSpacing 100" {Path.home()}/Library/Preferences/com.apple.finder.plist',
        description="Set icon spacing to '100' 1",
        section="Finder",
        type=CommandType.PLISTBUDDY,
        sudo=False,
    ),
    Setting(
        command=f'/usr/libexec/PlistBuddy -c "Set FK_StandardViewSettings:IconViewSettings:gridSpacing 100" {Path.home()}/Library/Preferences/com.apple.finder.plist',
        description="Set icon spacing to '100' 2",
        section="Finder",
        type=CommandType.PLISTBUDDY,
        sudo=False,
    ),
    Setting(
        command=f'/usr/libexec/PlistBuddy -c "Set StandardViewSettings:IconViewSettings:gridSpacing 100" {Path.home()}/Library/Preferences/com.apple.finder.plist',
        description="Set icon spacing to '100' 3",
        section="Finder",
        type=CommandType.PLISTBUDDY,
        sudo=False,
    ),
    Setting(
        command=f'/usr/libexec/PlistBuddy -c "Set :DesktopViewSettings:IconViewSettings:iconSize 40" {Path.home()}/Library/Preferences/com.apple.finder.plist',
        description="Set icon size to '40' 1",
        section="Finder",
        type=CommandType.PLISTBUDDY,
        sudo=False,
    ),
    Setting(
        command=f'/usr/libexec/PlistBuddy -c "Set :FK_StandardViewSettings:IconViewSettings:iconSize 40" {Path.home()}/Library/Preferences/com.apple.finder.plist',
        description="Set icon size to '40' 2",
        section="Finder",
        type=CommandType.PLISTBUDDY,
        sudo=False,
    ),
    Setting(
        command=f'/usr/libexec/PlistBuddy -c "Set :StandardViewSettings:IconViewSettings:iconSize 40" {Path.home()}/Library/Preferences/com.apple.finder.plist',
        description="Set icon size to '40' 3",
        section="Finder",
        type=CommandType.PLISTBUDDY,
        sudo=False,
    ),
]


def main() -> None:
    """Set MacOS Defaults."""
    if platform.system() != "Darwin":
        console.print("This script is only for macOS")
        return

    console.rule("Setting MacOS Defaults...")
    console.print(
        "You may be asked to enter your password multiple times for commands which require sudo"
    )
    console.print("Some changes require a logout/restart to take effect")

    try:
        for cmd in sorted(commands, key=lambda x: x.section):
            console.print(f"✔ {cmd.full_description}", style="secondary")
            run_command(cmd=cmd.type.value, args=cmd.args, quiet=False, sudo=cmd.sudo)
    except KeyboardInterrupt as e:
        console.print("Exiting...")
        raise SystemExit(1) from e

    console.print(":rocket: Done setting MacOS Defaults")


if __name__ == "__main__":
    main()
