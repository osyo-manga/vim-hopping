It is under development.

# hopping.vim

## Introduction

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

![hopping](https://cloud.githubusercontent.com/assets/214488/7200019/f35e6ce2-e533-11e4-8e12-061cb0c649b3.gif)

## Usage

```vim
" Start buffer line filtering.
:HoppingStart

" Example key mapping
nmap <Space>/ <Plug>(hopping-start)

" Keymapping
let g:hopping#keymapping = {
\	"\<C-n>" : "<Over>(hopping-next)",
\	"\<C-p>" : "<Over>(hopping-prev)",
\	"\<C-u>" : "<Over>(scroll-u)",
\	"\<C-d>" : "<Over>(scroll-d)",
\}
```

## Substitute

![hopping](https://cloud.githubusercontent.com/assets/214488/8390886/0e5e85f2-1ce5-11e5-907a-b3cc274dd00d.gif)

