.PHONY: all tmux fbterm zsh vimperator lscolor

all: install-base update-quiet

tmux:
	ln -fs tmux.conf ~/.tmux.conf

fbterm:
	ln -fs fbtermrc ~/.fbtermrc

zsh:
	ln -fs zshrc ~/.zshrc

vimperator:
	ln -fs vimperatorrc ~/.vimperatorrc
	ln -fs vimperator ~/.vimperator

lscolor:
	ln -fs lscolor256 ~/.lscolor256
