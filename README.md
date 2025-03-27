# nix

Another nix + dotfile repository.

<!--TODO: Add picture here from assets when done-->

## Installation

1. Install Nix:

```bash
curl -L https://nixos.org/nix/install | sh
```

2. Clone this repository:

```bash
mkdir -p ~/src/github.com/projects
nix-shell -p git --run 'git clone https://github.com/MattiasMTS/.dotfiles ~/src/github.com/projects/.dotfiles'
cd ~/src/github.com/projects/.dotfiles
```

3. Initialize nix-darwin:

```bash
nix run nix-darwin --extra-experimental-features 'nix-command flakes' -- switch --flake .#
```

4. Set up dotfile symlinks and build system:

```bash
make init     # Create symlinks for apps not managed by nix
make switch  # Build initial system configuration
```

## Daily Usage

Run `make help` to see all available commands.
