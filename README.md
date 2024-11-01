# YaMove

This plugin was initially created to help navigate large Yaml files, where
I could not easily keep track of the indentation of certain values, but can
help users navigate other files as well.

Additionally, you can enable smart folding, so values with greater indentation
will be folded.


##### Preview

![preview gif](https://i.imgur.com/ukyaSkl.gif)


##### SmartFolds Preview

![preview folds](https://i.imgur.com/P7kacz4.gif)

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
YaMoveIn | Move to a line with below with more indentation
YaMoveOut | Move to a line above with lesser indentation
YaMoveOutDown | Move to a line below with lesser indentation
YaMoveInUp | Move to a line above with more indentation
ToggleYaFold | Toggle the fold below the key you are on
YaToggleSmartFolds | Toggle whether smart folds are enabled

### Setting

Setting (1=enabled, 0=disabled) | Description | Default
--- | --- | ---
g:enableYaMoveSmartFolds | Enable intelligent folding to hide levels with more indentation | 0
g:enableYaMoveCloseOnMoveOut | Enable to close folds when using `YaMoveOut` or `YaMoveOutDown` | 1
g:enableYaMoveOnMultipleHits | Enable to allow escaping from lower indentations after using `YaMoveUp` or `YaMoveDown` twice, also allows moving to the next inner sections with `YaMoveIn` or `YaMoveInUp` | 1

## Usage

This is entirely up to you, but I've found that a setup like this works for me:

```
" Movement
nnoremap <C-j> :YaMoveDown<CR>
nnoremap <C-k> :YaMoveUp<CR>
nnoremap <C-h> :YaMoveOut<CR>
nnoremap <C-l> :YaMoveIn<CR>

" Less necessary movement
nnoremap <C-n> :YaMoveOutDown<CR>
nnoremap <C-p> :YaMoveInUp<CR>

" Folds
nnoremap <C-f> :ToggleYaFold<CR>


```

With this, you can hold `CTRL` and navigate using `hjkl` to quickly
navigate files based on indentation levels.
