# macOS dotfiles

Personal dotfiles for an Apple Silicon MacBook Pro. This branch is a clean
macOS cutover: Ubuntu, WSL, `apt`, Snap, `.deb`, AppImage, GNOME, and Linux
filesystem conventions are not supported.

The repository uses Homebrew for native packages and applications, `mise` for
language and infrastructure runtimes, and a vendored copy of Dotbot for safe,
repeatable configuration links.

## Requirements

- Apple Silicon Mac (`arm64`)
- macOS
- An administrator account for the initial Xcode Command Line Tools and
  Homebrew setup
- Internet access during the first installation

No existing Homebrew installation is required. The installer checks for the
Xcode Command Line Tools and installs Homebrew into its supported Apple Silicon
prefix, `/opt/homebrew`, before any package work begins.

## Install

Clone the repository normally; Dotbot is intentionally vendored, so there are
no submodules to initialize.

```bash
git clone YOUR_DOTFILES_REPOSITORY_URL ~/.dotfiles
cd ~/.dotfiles
./install
```

The installer is designed to be safe to run again. In order, it:

1. Confirms that the computer is an Apple Silicon Mac and checks the Xcode
   Command Line Tools.
2. Runs `scripts/macos/bootstrap-homebrew.sh`, which installs Homebrew when it
   is missing and initializes `/opt/homebrew/bin/brew` for the current run.
3. Runs `scripts/macos/brew-bundle.sh` in two explicit stages: required formulae
   first with `--no-upgrade`, then optional GUI casks. Each missing cask is
   attempted once. Unmanaged applications in `/Applications` or
   `~/Applications` are retained, and a GUI download failure does not block the
   remaining setup.
4. Runs `scripts/macos/mise-install.sh` to install the language,
   infrastructure, and npm tools declared in `config/mise/config.toml`.
5. Runs `scripts/macos/backup-conflicts.sh` immediately before linking. Existing
   non-symlink conflicts are moved, with their paths preserved, beneath
   `~/.dotfiles-backups/YYYYmmdd-HHMMSS-PID/`; symlinks are left alone.
6. Uses Dotbot to create the configuration links.
7. Runs `scripts/macos/post-install.sh` to initialize Zsh and TPM plugins, the
   bat cache, and Neovim plugins.
8. Runs `scripts/macos/verify.sh --installed` and reports any missing commands.

The installer does not copy or generate SSH private keys, log in to GitHub, or
silently change macOS preferences.

## Default software

`Brewfile` is the source of truth for native packages and applications, while
`config/mise/config.toml` is the source of truth for runtimes and
ecosystem-native tools. The default installation is grouped below so the effect
of `./install` is explicit.

### Shells, terminal, and editor

- `zsh` as the primary interactive and login-shell configuration
- Homebrew `bash` and `bash-completion@2` as the supported fallback shell
- `antidote` for declarative Zsh plugin management
- `ghostty`, `neovim`, and `tmux`
- CaskaydiaCove Nerd Font

macOS continues to provide `/bin/zsh`. Homebrew Bash is installed under
`/opt/homebrew/bin/bash`; the installer does not change the login shell to Bash.

### Git and command-line workflow

- `git`, `gh`, `git-delta`, and `lazygit`
- `bat`, `eza`, `tree`, `fd`, `fzf`, and `ripgrep`
- `tree-sitter-cli` for the `tree-sitter` parser-generator command
- `jq`, `wget`, `shellcheck`, `htop`, and `trash`
- `yazi`, `zoxide`, `ffmpeg`, `sevenzip`, `poppler`, and `imagemagick`
- `lazydocker` and `sshs`
- `stylua` for Lua formatting

### Containers and Kubernetes

- Docker Desktop, which supplies Docker Engine, the Docker CLI, and Docker
  Compose
- `kubectl`, `minikube`, and `k9s`

Docker Machine and a separately downloaded Docker Compose binary are not used.
When Docker.app already exists outside Homebrew in `/Applications` or
`~/Applications`, `brew-bundle.sh` preserves it instead of asking Homebrew to
manage it. For the standard `/Applications/Docker.app` location, the post-install
step creates missing-only links for the bundled Docker CLI and credential
helpers beneath `~/.local/bin`, plus all bundled CLI plugins—including Compose
and Buildx—beneath `~/.docker/cli-plugins`; existing destinations are never
overwritten. The same behavior applies to `~/Applications/Docker.app`.

### Window management

- AeroSpace for tiling and workspace management
- JankyBorders for focused-window borders

JankyBorders is installed from the `FelixKratz/formulae` Homebrew tap. Its
source-controlled configuration is `config/borders/bordersrc`, linked to
`~/.config/borders/bordersrc`, and AeroSpace starts it automatically at login.

### Languages and build tools

- `mise` for Node.js LTS, the latest Python, Go, Maven, Gradle, Terraform, and
  Terragrunt, plus stable Rust and Temurin Java 25 LTS
- `delve` for Go debugging
- npm developer commands used by the editor: TypeScript, ESLint, and Bash
  Language Server
- Auggie CLI and OpenAI Codex CLI, installed as npm tools through `mise`

Runtime versions live in `config/mise/config.toml`; use that file rather than a
system-wide runtime installation or a `curl | shell` version manager.

### Applications

- Ghostty
- Docker Desktop
- IntelliJ IDEA Ultimate
- Visual Studio Code
- Bruno
- Notion
- WhatsApp
- Spotify
- Maccy
- MacShot
- Raycast
- Rectangle
- AeroSpace
- Logi Options+
- Intent by Augment

Homebrew detects formulae and casks it already manages, so rerunning the
installer does not intentionally reinstall them. On the Mac used for this
cutover, Docker Desktop, IntelliJ IDEA Ultimate, and Visual Studio Code already
exist and should be retained. Corporate or MDM-managed software remains outside
this repository. Casks are optional during bootstrap: each missing cask is
attempted once, and any failures are grouped into one exact
`brew install --cask ...` command for a deliberate retry.

Maccy replaces CopyQ. MacShot replaces Flameshot for screenshots, annotations,
and screen recording. Flameshot remains excluded because its Homebrew cask is
scheduled for disablement. Backdrop is also excluded in favor of the optional
wallpaper helper described below.

Intent is currently an Apple Silicon public beta distributed by Augment as a
vendor DMG rather than a Homebrew cask. Download it from
<https://www.intentapp.dev> and drag `Intent.app` into
`/Applications`; installed verification reports a warning until it is present.
The Auggie and Codex CLIs are installed automatically with the other npm tools.

Logi Options+ configures supported Logitech devices such as the MX Master 3.
Its installer requires administrator approval, and macOS must be restarted after
installation before its background components and device customizations take
effect.

## Managed configuration

Dotbot links the shell, Powerlevel10k, Git, global Git ignores, SSH, tmux,
Ghostty, Neovim, lazygit, Surfingkeys, bat, AeroSpace, JankyBorders, and wallpaper assets
into the home directory. Re-running `./install` refreshes those links after
first backing up new conflicts. AeroSpace's source-controlled configuration is
`config/aerospace/aerospace.toml`, linked to
`~/.config/aerospace/aerospace.toml`; do not also create `~/.aerospace.toml`,
because AeroSpace reports multiple configuration locations as ambiguous.

Zsh is the main experience. Bash receives its own startup configuration and
Homebrew completions so it remains usable as an alternative. Fish is not part
of this macOS setup.

During post-installation, the installer clones TPM only when it is missing,
installs the declared tmux plugins, starts one interactive Zsh to initialize the
Antidote bundle, rebuilds bat's cache, and synchronizes Neovim plugins with
Lazy. It also verifies and repairs the Markdown Preview plugin's Node.js
dependencies, including partially missing `node_modules` directories. Existing
TPM checkouts are reused; an unrelated object at the TPM path causes a clear
failure instead of being replaced.

The Git configuration keeps the repository's existing author identity, uses
the macOS Keychain as the general HTTPS credential store, and delegates
`github.com` credentials to the `gh` command without a machine-specific binary
path. SSH adds identities to the agent and stores their passphrases in the
macOS Keychain. Private keys must remain in `~/.ssh` and are never linked from
the repository.

## Optional macOS preferences

System preferences are opt-in and are never applied merely by opening a shell
or running the main installer.

```bash
./scripts/macos/apply-defaults.sh
./scripts/macos/set-wallpaper.sh [filename-or-path]
./scripts/macos/configure-aerospace.sh
```

`apply-defaults.sh` shows file extensions plus the path and status bars in
Finder, and stores screenshots as PNG files in `~/Pictures/Screenshots`.
`set-wallpaper.sh` selects a supplied image or defaults to the managed
`Cityscape_hd.jpg`. Review either script before running it; some preference
changes may require restarting the affected application.

`configure-aerospace.sh` disables macOS **Displays have separate Spaces**, as
recommended by AeroSpace for more reliable multi-monitor behavior. It does not
assign workspaces to a specific monitor, so the same configuration works when
only the built-in display is present. Log out and back in after running it;
macOS does not apply this setting until the next login.

## Verify

Run the read-only repository and script syntax checks without installing
anything:

```bash
./install --verify
```

After installation, include checks for all expected commands, `mise` runtimes,
GUI applications, Docker Compose and Buildx, and the Nerd Font with:

```bash
./scripts/macos/verify.sh --installed
```

Verification reports missing required tools as failures and missing optional
GUI applications as warnings, without changing the machine.

## Troubleshooting downloads

An HTTP 503 while downloading a cask can come from the vendor, a VPN, or a
corporate network filter. Resolve the network issue, then use the single retry
command printed in the cask summary. The installer does not retry casks
automatically. Required formulae are installed separately, so a cask download
failure cannot prevent the remaining shell, runtime, and dotfile setup from
completing.

## Post-install authentication

GitHub authentication is intentionally interactive:

```bash
gh auth login
ssh -T git@github.com
```

The Git configuration already delegates `github.com` credentials to `gh`, so
`gh auth setup-git` is unnecessary and may replace the portable helper command.

The SSH configuration expects the existing work key at `~/.ssh/git_key` and
the commercial GitHub key at `~/.ssh/git_commercial`. Add passphrases to the
Keychain without placing key material in this repository:

```bash
ssh-add --apple-use-keychain ~/.ssh/git_key
ssh-add --apple-use-keychain ~/.ssh/git_commercial
```

Internal work aliases and proxy routes remain in `config/ssh/config`; they will
only connect when the required corporate network or VPN is available.

## Updates

Install newly declared Homebrew software while retaining unmanaged apps and
avoiding automatic upgrades with:

```bash
brew update
./scripts/macos/brew-bundle.sh
```

When an upgrade of Homebrew-managed software is intentional, run
`brew upgrade` separately.

Update runtime installations after changing `config/mise/config.toml` with:

```bash
mise install
```

Pull configuration changes and safely relink them with:

```bash
cd ~/.dotfiles
git pull --ff-only
./install
```

Review the backup path printed by `./install` before removing any old files.

## License and credits

Dotbot was created by [Anish Athalye](https://github.com/anishathalye/dotbot).
See [LICENSE.md](LICENSE.md) for this repository's license.
