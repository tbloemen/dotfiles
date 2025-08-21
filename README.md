# My dotfiles

These are the dotfiles made by me.

## Installation

Make sure `git` is installed.
First, check out the dotfiles repository in your $HOME directory using git.

```bash
git clone git@github.com/tbloemen/dotfiles.git
cd dotfiles
```

Then run the install script: `sh install.sh`.
This will install the packages from pacman and the AUR as specified in the `packages` directory, and `stow` all the dotfiles into the users config.

See the [Dreams of Autonomy video](https://www.youtube.com/watch?v=y6XCebnB9gs) for more information.

## Specifications

The dunst and waybar configs are largely copied over from these [dotfiles](https://github.com/sameemul-haque/dotfiles).
