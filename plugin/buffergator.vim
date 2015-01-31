""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
""  Buffergator
""
""  Vim document buffer navigation utility
""
""  Copyright 2011 Jeet Sukumaran.
""
""  This program is free software; you can redistribute it and/or modify
""  it under the terms of the GNU General Public License as published by
""  the Free Software Foundation; either version 3 of the License, or
""  (at your option) any later version.
""
""  This program is distributed in the hope that it will be useful,
""  but WITHOUT ANY WARRANTY; without even the implied warranty of
""  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
""  GNU General Public License <http://www.gnu.org/licenses/>
""  for more details.
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Reload and Compatibility Guard {{{1
" ============================================================================
" Reload protection.
if (exists('g:did_buffergator') && g:did_buffergator) || &cp || version < 700
    finish
endif
let g:did_buffergator = 1

" avoid line continuation issues (see ':help user_41.txt')
let s:save_cpo = &cpo
set cpo&vim
" 1}}}

" Global MRU Initialization {{{1
" ==============================================================================
" Moves (or adds) the given buffer number to the top of the list
if !exists("g:buffergator_mru_cycle_loop")
    let g:buffergator_mru_cycle_loop = 1
endif
let g:buffergator_track_mru = 1
let g:buffergator_mru = []
function! BuffergatorUpdateMRU(acmd_bufnr)
    if len(g:buffergator_mru) < 1 " maybe should be 2?
        if g:buffergator_mru_cycle_loop
            let g:buffergator_mru = []
            for l:bni in range(bufnr("$"), 1, -1)
                if buflisted(l:bni)
                \   && getbufvar(l:bni, "&filetype") != "netrw"
                    call add(g:buffergator_mru, l:bni)
                endif
            endfor
        endif
    endif
    if !exists("w:buffergator_mru")
        let w:buffergator_mru = g:buffergator_mru[:]
    endif
    if g:buffergator_track_mru
        let bnum = a:acmd_bufnr + 0
        " if bnum == 0 || !buflisted(bnum) || !(empty(getbufvar(bnum, "netrw_browser_active")))
        if bnum == 0 || !buflisted(bnum) || getbufvar(bnum, "&filetype") == "netrw"
            return
        endif
        call filter(g:buffergator_mru, 'v:val !=# bnum')
        call insert(g:buffergator_mru, bnum, 0)
        call filter(w:buffergator_mru, 'v:val !=# bnum')
        call insert(w:buffergator_mru, bnum, 0)
    endif
endfunction

" Autocommands that update the most recenly used buffers
augroup BuffergatorMRU
au!
autocmd BufEnter     * call BuffergatorUpdateMRU(expand('<abuf>'))
autocmd BufRead      * call BuffergatorUpdateMRU(expand('<abuf>'))
autocmd BufNewFile   * call BuffergatorUpdateMRU(expand('<abuf>'))
autocmd BufWritePost * call BuffergatorUpdateMRU(expand('<abuf>'))
augroup NONE

" 1}}}

" Public Command and Key Maps {{{1
" ==============================================================================
command! -nargs=0 BuffergatorToggle      :call buffergator#ToggleBuffergator()
command! -nargs=0 BuffergatorClose       :call buffergator#CloseBuffergator()
command! -nargs=0 BuffergatorOpen        :call buffergator#OpenBuffergator()
command! -nargs=0 BuffergatorTabsToggle  :call buffergator#ToggleBuffergatorTabs()
command! -nargs=0 BuffergatorTabsOpen    :call buffergator#OpenBuffergatorTabs()
command! -nargs=0 BuffergatorTabsClose   :call buffergator#CloseBuffergatorTabs()
command! -nargs=0 BuffergatorUpdate      :call buffergator#UpdateBuffergator('',-1)
command! -nargs=* BuffergatorMruCyclePrev :call buffergator#BuffergatorCycleMru(-1, "<args>")
command! -nargs=* BuffergatorMruCycleNext :call buffergator#BuffergatorCycleMru(1, "<args>")
command! -nargs=? -bang BuffergatorMruList     :call buffergator#BuffergatorEchoMruList('<bang>')

if !exists('g:buffergator_suppress_keymaps') || !g:buffergator_suppress_keymaps
    " nnoremap <silent> z; :BuffergatorToggle<CR>
    " nnoremap <silent> z: :BuffergatorTabsToggle<CR>
    nnoremap <silent> <Leader>b :BuffergatorOpen<CR>
    nnoremap <silent> <Leader>B :BuffergatorClose<CR>
    nnoremap <silent> <Leader>t :BuffergatorTabsOpen<CR>
    nnoremap <silent> <Leader>to :BuffergatorTabsOpen<CR>
    nnoremap <silent> <Leader>tc :BuffergatorTabsClose<CR>
    nnoremap <silent> <Leader>T :BuffergatorTabsClose<CR>
    if !exists('g:buffergator_suppress_mru_switching_keymaps') || !g:buffergator_suppress_mru_switching_keymaps
        nnoremap <silent> <M-b> :BuffergatorMruCyclePrev<CR>
        nnoremap <silent> <M-S-b> :BuffergatorMruCycleNext<CR>
        if !exists('g:buffergator_keep_old_mru_switching_keymaps') || !g:buffergator_keep_old_mru_switching_keymaps
            nnoremap <silent> gb :BuffergatorMruCyclePrev<CR>
            nnoremap <silent> gB :BuffergatorMruCycleNext<CR>
        else
            nnoremap <silent> [b :BuffergatorMruCyclePrev<CR>
            nnoremap <silent> ]b :BuffergatorMruCycleNext<CR>
        endif
    endif
    if !exists('g:buffergator_suppress_mru_switch_into_splits_keymaps') || !g:buffergator_suppress_mru_switch_into_splits_keymaps
        nnoremap <silent> <Leader><LEFT> :BuffergatorMruCyclePrev leftabove vert sbuffer<CR>
        nnoremap <silent> <Leader><UP> :BuffergatorMruCyclePrev leftabove sbuffer<CR>
        nnoremap <silent> <Leader><RIGHT> :BuffergatorMruCyclePrev rightbelow vert sbuffer<CR>
        nnoremap <silent> <Leader><DOWN> :BuffergatorMruCyclePrev rightbelow sbuffer<CR>
        nnoremap <silent> <Leader><S-LEFT> :BuffergatorMruCycleNext leftabove vert sbuffer<CR>
        nnoremap <silent> <Leader><S-UP> :BuffergatorMruCycleNext leftabove sbuffer<CR>
        nnoremap <silent> <Leader><S-RIGHT> :BuffergatorMruCycleNext rightbelow vert sbuffer<CR>
        nnoremap <silent> <Leader><S-DOWN> :BuffergatorMruCycleNext rightbelow sbuffer<CR>
    endif
endif

" 1}}}

" Restore State {{{1
" ============================================================================
" restore options
let &cpo = s:save_cpo
" 1}}}

" vim:foldlevel=4:
