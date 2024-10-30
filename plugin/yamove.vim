" Title:        Vim YaMove
" Description:  A plugin to aid moving between indentations. Particularly for
" Yaml files
" Last Change:  29 October 2024
" Maintainer:   cd-4 <https://github.com/cd-4>

scriptencoding utf-8

" Prevents the plugin from being loaded multiple times. If the loaded
" variable exists, do nothing more. Otherwise, assign the loaded
" variable and continue running this instance of the plugin.
if exists("g:loaded_vim_yamove")
    finish
endif
let g:loaded_vim_yamove = 1

" evacuate user setting temporarily
let s:save_cpo = &cpo
set cpo&vim

command! -nargs=0 -range YaMoveDown call yamove#YaMoveRepeat(1, 0)
command! -nargs=0 -range YaMoveUp call yamove#YaMoveRepeat(-1, 0)
command! -nargs=0 -range YaMoveIn call yamove#YaMoveRepeat(1, 1)
command! -nargs=0 -range YaMoveOut call yamove#YaMoveRepeat(-1, -1)

" restore user setting
let &cpo = s:save_cpo
unlet s:save_cpo


