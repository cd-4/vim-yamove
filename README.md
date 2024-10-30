# YaMove

This plugin was initially created to help navigate large Yaml files, where
I could not easily keep track of the indentation of certain values, but can
help users navigate other files as well.

## Installation

#### VimPlug

```
Plug 'cd-4/vim-yamove'
```

### Commands

Command | Description
--- | ---
YaMoveDown | Move to the next line with the same indentation
YaMoveUp | Move the the previous line with the same indentation
YaMoveIn | Move to a line with more indentation below the current line
YaMoveOut | Move to a line above with lesser indentation

##### Note:

The `YaMoveUp` and `YaMoveDown` functions will stop upon reaching a line with
lesser indentation.

If you would like to disable this, you can set `g:enableYaMoveMultipleHits = 1` (Default is `0`). With this set, your initial move will stop, then on a subsequent call of `YaMoveUp` or `YaMoveDown`, it will bring you to that line that blocked you.


## Usage

This is entirely up to you, but I've found that a setup like this works for me:

```
nnoremap <C-j> :YaMoveDown<CR>
nnoremap <C-k> :YaMoveUp<CR>
nnoremap <C-h> :YaMoveOut<CR>
nnoremap <C-l> :YaMoveIn<CR>
```

With this, you can hold `CTRL` and navigate using `hjkl` to quickly
navigate files based on indentation levels.
