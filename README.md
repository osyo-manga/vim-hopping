# hopping.vim


## Introduction

hopping.vim is incremental buffer line filtering Vim plugin.

## Installation

[Neobundle](https://github.com/Shougo/neobundle.vim) / [Vundle](https://github.com/gmarik/Vundle.vim) / [vim-plug](https://github.com/junegunn/vim-plug)

```vim
NeoBundle 'osyo-manga/vim-hopping'
Plugin 'osyo-manga/vim-hopping'
Plug 'osyo-manga/vim-hopping'
```

[pathogen](https://github.com/tpope/vim-pathogen)

```
git clone https://github.com/osyo-manga/vim-hopping ~/.vim/bundle/vim-hopping
```

## Screencapture


## Usage

```vim
" Start buffer line filtering.
:HoppingStart

" Example key mapping
nmap <Space>/ <Plug>(hopping-start)
```


