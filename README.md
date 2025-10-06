# nix

Another nix + dotfile repository.

<!--TODO: Add picture here from assets when done-->

## Installation

1. Install Nix via [determinate
   system](https://github.com/DeterminateSystems/determinate?tab=readme-ov-file#installing-using-the-determinate-nix-installer),
   which likely is going to be using the Determinate.pkg.

2. Clone this repository:

```bash
mkdir -p ~/src/github.com/projects
nix-shell -p git --run 'git clone https://github.com/MattiasMTS/dotfiles ~/src/github.com/projects/dotfiles'
cd ~/src/github.com/projects/dotfiles
```

3. Initialize nix-darwin:

```bash
nix run nix-darwin --extra-experimental-features 'nix-command flakes' -- switch --flake .#
```
