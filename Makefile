.PHONY: all tmux fbterm zsh vimperator lscolor

all: tmux fbterm zsh vimperator lscolor256

tmux:
	ln -fs $(shell pwd)/tmux.conf ~/.tmux.conf

fbterm:
	ln -fs $(shell pwd)/fbtermrc ~/.fbtermrc

zsh:
	ln -fs $(shell pwd)/zshrc ~/.zshrc

vimperator:
	ln -fs $(shell pwd)/vimperatorrc ~/.vimperatorrc
	ln -fs $(shell pwd)/vimperator ~/.vimperator

lscolor:
	ln -fs $(shell pwd)/lscolor256 ~/.lscolor256
