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

" Compatibility Guard {{{1
" ============================================================================
" avoid line continuation issues (see ':help user_41.txt')
let s:save_cpo = &cpo
set cpo&vim
" 1}}}

" Global Plugin Options {{{1
" =============================================================================
if !exists("g:buffergator_viewport_split_policy")
    let g:buffergator_viewport_split_policy = "L"
endif
if !exists("g:buffergator_move_wrap")
    let g:buffergator_move_wrap = 1
endif
if !exists("g:buffergator_autodismiss_on_select")
    let g:buffergator_autodismiss_on_select = 1
endif
if !exists("g:buffergator_autoupdate")
    let g:buffergator_autoupdate = 0
endif
if !exists("g:buffergator_autoexpand_on_split")
    let g:buffergator_autoexpand_on_split = 1
endif
if exists("g:buffergator_split_size")
    if !exists("g:buffergator_vsplit_size")
        let g:buffergator_vsplit_size = g:buffergator_split_size
    endif
    if !exists("g:buffergator_hsplit_size")
        let g:buffergator_hsplit_size = g:buffergator_split_size
    endif
else
    if !exists("g:buffergator_vsplit_size")
        let g:buffergator_vsplit_size = 40
    endif
    if !exists("g:buffergator_hsplit_size")
        let g:buffergator_hsplit_size = 20
    endif
endif
if !exists("g:buffergator_sort_regime")
    let g:buffergator_sort_regime = "bufnum"
endif
if !exists("g:buffergator_display_regime")
    let g:buffergator_display_regime = "basename"
endif
if !exists("g:buffergator_show_full_directory_path")
    let g:buffergator_show_full_directory_path = 1
endif
if !exists("g:buffergator_remap_arrow_keys")
    let g:buffergator_remap_arrow_keys = 0
endif
if !exists("g:buffergator_mru_cycle_local_to_window")
    let g:buffergator_mru_cycle_local_to_window = 1
endif
if !exists("g:buffergator_tab_statusline")
    let g:buffergator_tab_statusline = 1
endif
if !exists("g:buffergator_window_statusline")
    let g:buffergator_window_statusline = 1
endif
" 1}}}

" Script Data and Variables {{{1
" =============================================================================

" Split Modes {{{2
" ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
" Split modes are indicated by a single letter. Upper-case letters indicate
" that the SCREEN (i.e., the entire application "window" from the operating
" system's perspective) should be split, while lower-case letters indicate
" that the VIEWPORT (i.e., the "window" in Vim's terminology, referring to the
" various subpanels or splits within Vim) should be split.
" Split policy indicators and their corresponding modes are:
"   ``/`d`/`D'  : use default splitting mode
"   `n`/`N`     : NO split, use existing window.
"   `L`         : split SCREEN vertically, with new split on the left
"   `l`         : split VIEWPORT vertically, with new split on the left
"   `R`         : split SCREEN vertically, with new split on the right
"   `r`         : split VIEWPORT vertically, with new split on the right
"   `T`         : split SCREEN horizontally, with new split on the top
"   `t`         : split VIEWPORT horizontally, with new split on the top
"   `B`         : split SCREEN horizontally, with new split on the bottom
"   `b`         : split VIEWPORT horizontally, with new split on the bottom
let s:buffergator_viewport_split_modes = {
            \ "d"   : "sp",
            \ "D"   : "sp",
            \ "N"   : "buffer",
            \ "n"   : "buffer",
            \ "L"   : "topleft vert sbuffer",
            \ "l"   : "leftabove vert sbuffer",
            \ "R"   : "botright vert sbuffer",
            \ "r"   : "rightbelow vert sbuffer",
            \ "T"   : "topleft sbuffer",
            \ "t"   : "leftabove sbuffer",
            \ "B"   : "botright sbuffer",
            \ "b"   : "rightbelow sbuffer",
            \ }
let s:buffergator_viewport_split_modes_cycle_list = ["L", "T", "R", "B"]
" 2}}}

" Buffer Status Symbols {{{3
" ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
let s:buffergator_buffer_line_symbols = {
    \ 'current'  :    ">",
    \ 'modified' :    "+",
    \ 'alternate':    "#",
    \ }

" dictionaries are not in any order, so store the order here
let s:buffergator_buffer_line_symbols_order = [
    \ 'current',
    \ 'modified',
    \ 'alternate',
    \ ]
" 3}}}

" Catalog Sort Regimes {{{2
" ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
let s:buffergator_catalog_sort_regimes = ['basename', 'filepath', 'extension', 'bufnum', 'mru']
let s:buffergator_catalog_sort_regime_desc = {
            \ 'basename' : ["basename", "by basename (followed by directory)"],
            \ 'filepath' : ["filepath", "by (full) filepath"],
            \ 'extension'  : ["ext", "by extension (followed by full filepath)"],
            \ 'bufnum'  : ["bufnum", "by buffer number"],
            \ 'mru'  : ["mru", "by most recently used"],
            \ }
let s:buffergator_default_catalog_sort_regime = "bufnum"
" 2}}}

" Catalog Display Regimes {{{2
" ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
let s:buffergator_catalog_display_regimes = ['basename', 'parentdir', 'filepath', 'bufname']
let s:buffergator_catalog_display_regime_desc = {
            \ 'basename' : ["basename", "basename (followed by directory)"],
            \ 'parentdir': ["parentdir", "basename (followed by first parent directory)"],
            \ 'filepath' : ["filepath", "full filepath"],
            \ 'bufname'  : ["bufname", "buffer name"],
            \ }
let s:buffergator_default_display_regime = "basename"
" 2}}}


" Window Open States {{{2
" ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
let s:is_buffergator_tabs_open = 0
let s:is_buffergator_buffers_open = 0
" 2}}}

" Utilities {{{1
" ==============================================================================

" Text Formatting {{{2
" ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
function! s:_format_align_left(text, width, fill_char)
    let l:fill = repeat(a:fill_char, a:width-len(a:text))
    return a:text . l:fill
endfunction

function! s:_format_align_right(text, width, fill_char)
    let l:fill = repeat(a:fill_char, a:width-len(a:text))
    return l:fill . a:text
endfunction

function! s:_format_time(secs)
    if exists("*strftime")
        return strftime("%Y-%m-%d %H:%M:%S", a:secs)
    else
        return (localtime() - a:secs) . " secs ago"
    endif
endfunction

function! s:_format_escaped_filename(file)
  if exists('*fnameescape')
    return fnameescape(a:file)
  else
    return escape(a:file," \t\n*?[{`$\\%#'\"|!<")
  endif
endfunction

" trunc: -1 = truncate left, 0 = no truncate, +1 = truncate right
function! s:_format_truncated(str, max_len, trunc)
    if len(a:str) > a:max_len
        if a:trunc > 0
            return strpart(a:str, a:max_len - 4) . " ..."
        elseif a:trunc < 0
            return '... ' . strpart(a:str, len(a:str) - a:max_len + 4)
        endif
    else
        return a:str
    endif
endfunction

" Pads/truncates text to fit a given width.
" align: -1 = align left, 0 = no align, 1 = align right
" trunc: -1 = truncate left, 0 = no truncate, +1 = truncate right
function! s:_format_filled(str, width, align, trunc)
    let l:prepped = a:str
    if a:trunc != 0
        let l:prepped = s:_format_truncated(a:str, a:width, a:trunc)
    endif
    if len(l:prepped) < a:width
        if a:align > 0
            let l:prepped = s:_format_align_right(l:prepped, a:width, " ")
        elseif a:align < 0
            let l:prepped = s:_format_align_left(l:prepped, a:width, " ")
        endif
    endif
    return l:prepped
endfunction

" 2}}}

" Messaging {{{2
" ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

function! s:NewMessenger(name)

    " allocate a new pseudo-object
    let messenger = {}
    let messenger["name"] = a:name
    if empty(a:name)
        let messenger["title"] = "buffergator"
    else
        let messenger["title"] = "buffergator (" . messenger["name"] . ")"
    endif

    function! messenger.format_message(leader, msg) dict
        return self.title . ": " . a:leader.a:msg
    endfunction

    function! messenger.format_exception( msg) dict
        return a:msg
    endfunction

    function! messenger.send_error(msg) dict
        redraw
        echohl ErrorMsg
        echomsg self.format_message("[ERROR] ", a:msg)
        echohl None
    endfunction

    function! messenger.send_warning(msg) dict
        redraw
        echohl WarningMsg
        echomsg self.format_message("[WARNING] ", a:msg)
        echohl None
    endfunction

    function! messenger.send_status(msg) dict
        redraw
        echohl None
        echomsg self.format_message("", a:msg)
    endfunction

    function! messenger.send_info(msg) dict
        redraw
        echohl None
        echo self.format_message("", a:msg)
    endfunction

    return messenger

endfunction
" 2}}}

" Catalog, Buffer, Windows, Files, etc. Management {{{2
" ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

" Searches for all buffers that have a buffer-scoped variable `varname`
" with value that matches the expression `expr`. Returns list of buffer
" numbers that meet the criterion.
function! s:_find_buffers_with_var(varname, expr)
    let l:results = []
    for l:bni in range(1, bufnr("$"))
        if !bufexists(l:bni)
            continue
        endif
        let l:bvar = getbufvar(l:bni, "")
        if empty(a:varname)
            call add(l:results, l:bni)
        elseif has_key(l:bvar, a:varname) && empty(a:expr)
            call add(l:results, l:bni)
        elseif has_key(l:bvar, a:varname) && l:bvar[a:varname] =~ a:expr
            call add(l:results, l:bni)
        endif
    endfor
    return l:results
endfunction

" Returns split mode to use for a new Buffergator viewport.
function! s:_get_split_mode()
    if has_key(s:buffergator_viewport_split_modes, g:buffergator_viewport_split_policy)
        return s:buffergator_viewport_split_modes[g:buffergator_viewport_split_policy]
    else
        call s:_buffergator_messenger.send_error("Unrecognized split mode specified by 'g:buffergator_viewport_split_policy': " . g:buffergator_viewport_split_policy)
    endif
endfunction

" Detect filetype. From the 'taglist' plugin.
" Copyright (C) 2002-2007 Yegappan Lakshmanan
function! s:_detect_filetype(fname)
    " Ignore the filetype autocommands
    let old_eventignore = &eventignore
    set eventignore=FileType
    " Save the 'filetype', as this will be changed temporarily
    let old_filetype = &filetype
    " Run the filetypedetect group of autocommands to determine
    " the filetype
    exe 'doautocmd filetypedetect BufRead ' . a:fname
    " Save the detected filetype
    let ftype = &filetype
    " Restore the previous state
    let &filetype = old_filetype
    let &eventignore = old_eventignore
    return ftype
endfunction

function! s:_is_full_width_window(win_num)
    if winwidth(a:win_num) == &columns
        return 1
    else
        return 0
    endif
endfunction!

function! s:_is_full_height_window(win_num)
    if winheight(a:win_num) + &cmdheight + 1 == &lines
        return 1
    else
        return 0
    endif
endfunction!

function! s:_find_mru_bufnr(dir, buffergator_mru)
    let l:cur_buf_idx = index(a:buffergator_mru, bufnr("%"))
    if len(a:buffergator_mru) < 1 " maybe should be 2?
        return bufnr("%")
    endif
    if l:cur_buf_idx < 0
        let l:target_buf_idx = 0
    else
        if a:dir < 0
            let l:target_buf_idx = l:cur_buf_idx + 1 " deeper in list = older
        else
            let l:target_buf_idx = l:cur_buf_idx - 1 " up list = newer
        endif
    endif
    if l:target_buf_idx < 0
        if g:buffergator_mru_cycle_loop
            let l:target_buf_idx = len(a:buffergator_mru) - 1
        else
            call s:_buffergator_messenger.send_info("already at most recent buffer")
            return -1
        endif
    elseif l:target_buf_idx >= len(a:buffergator_mru)
        if g:buffergator_mru_cycle_loop
            let l:target_buf_idx = 0
        else
            call s:_buffergator_messenger.send_info("already at oldest buffer")
            return -1
        endif
    endif
    let l:target_bufnr = a:buffergator_mru[l:target_buf_idx]
    if !bufexists(l:target_bufnr)
                \ || !buflisted(l:target_bufnr)
                \ || getbufvar(l:target_bufnr, "&filetype") == "netrw"
        call remove(a:buffergator_mru, l:target_buf_idx)
        return s:_find_mru_bufnr(a:dir, a:buffergator_mru)
    else
        return l:target_bufnr
    endif
endfunction

" 2}}}

" Sorting {{{2
" ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

" comparison function used for sorting dictionaries by value
function! s:_compare_dicts_by_value(m1, m2, key)
    if a:m1[a:key] < a:m2[a:key]
        return -1
    elseif a:m1[a:key] > a:m2[a:key]
        return 1
    else
        return 0
    endif
endfunction

" comparison function used for sorting buffers catalog by buffer number
function! s:_compare_dicts_by_bufnum(m1, m2)
    return s:_compare_dicts_by_value(a:m1, a:m2, "bufnum")
endfunction

" comparison function used for sorting buffers catalog by buffer name
function! s:_compare_dicts_by_bufname(m1, m2)
    return s:_compare_dicts_by_value(a:m1, a:m2, "bufname")
endfunction

" comparison function used for sorting buffers catalog by (full) filepath
function! s:_compare_dicts_by_filepath(m1, m2)
    if a:m1["parentdir"] < a:m2["parentdir"]
        return -1
    elseif a:m1["parentdir"] > a:m2["parentdir"]
        return 1
    else
        if a:m1["basename"] < a:m2["basename"]
            return -1
        elseif a:m1["basename"] > a:m2["basename"]
            return 1
        else
            return 0
        endif
    endif
endfunction

" comparison function used for sorting buffers catalog by extension
function! s:_compare_dicts_by_extension(m1, m2)
    if a:m1["extension"] < a:m2["extension"]
        return -1
    elseif a:m1["extension"] > a:m2["extension"]
        return 1
    else
        return s:_compare_dicts_by_filepath(a:m1, a:m2)
    endif
endfunction

" comparison function used for sorting buffers catalog by basename
function! s:_compare_dicts_by_basename(m1, m2)
    return s:_compare_dicts_by_value(a:m1, a:m2, "basename")
endfunction

" comparison function used for sorting buffers catalog by mru
function! s:_compare_dicts_by_mru(m1, m2)
    let l:i1 = index(g:buffergator_mru, a:m1['bufnum'])
    let l:i2 = index(g:buffergator_mru, a:m2['bufnum'])
    if l:i1 < l:i2
        return -1
    elseif l:i1 > l:i2
        return 1
    else
        return 0
    endif
endfunction

" 2}}}

" 1}}}

" CatalogViewer {{{1
" ============================================================================

function! s:NewCatalogViewer(name, title)

    " initialize
    let catalog_viewer = {}
    let catalog_viewer["bufname"] = a:name
    let catalog_viewer["title"] = a:title
    let l:buffergator_bufs = s:_find_buffers_with_var("is_buffergator_buffer", 1)
    if len(l:buffergator_bufs) > 0
        let catalog_viewer["bufnum"] = l:buffergator_bufs[0]
    endif
    let catalog_viewer["jump_map"] = {}
    let catalog_viewer["split_mode"] = s:_get_split_mode()
    let catalog_viewer["sort_regime"] = g:buffergator_sort_regime
    let catalog_viewer["display_regime"] = g:buffergator_display_regime
    let catalog_viewer["is_zoomed"] = 0
    let catalog_viewer["columns_expanded"] = 0
    let catalog_viewer["lines_expanded"] = 0
    let catalog_viewer["max_buffer_basename_len"] = 30

    " Initialize object state.
    let catalog_viewer["bufnum"] = -1

    function! catalog_viewer.line_symbols(bufinfo) dict
      let l:line_symbols = ""
      " so we can control the order they are shown in
      let l:noted_status = s:buffergator_buffer_line_symbols_order
      for l:status in l:noted_status
        if a:bufinfo['is_' . l:status]
          let l:line_symbols .= s:buffergator_buffer_line_symbols[l:status]
        else
          let l:line_symbols .= " "
        endif
      endfor
      return l:line_symbols
    endfunction

    function! catalog_viewer.list_buffers() dict
        let bcat = []
        redir => buffers_output
        execute('silent ls')
        redir END
        let self.max_buffer_basename_len = 0
        let l:buffers_output_rows = split(l:buffers_output, "\n")
        for l:buffers_output_row in l:buffers_output_rows
            let l:parts = matchlist(l:buffers_output_row, '^\s*\(\d\+\)\(.....\) "\(.*\)"')
            let l:info = {}
            let l:info["bufnum"] = l:parts[1] + 0
            if l:parts[2][0] == "u"
                let l:info["is_unlisted"] = 1
                let l:info["is_listed"] = 0
            else
                let l:info["is_unlisted"] = 0
                let l:info["is_listed"] = 1
            endif
            if l:parts[2][1] == "%"
                let l:info["is_current"] = 1
                let l:info["is_alternate"] = 0
            elseif l:parts[2][1] == "#"
                let l:info["is_current"] = 0
                let l:info["is_alternate"] = 1
            else
                let l:info["is_current"] = 0
                let l:info["is_alternate"] = 0
            endif
            if l:parts[2][2] == "a"
                let l:info["is_active"] = 1
                let l:info["is_loaded"] = 1
                let l:info["is_visible"] = 1
            elseif l:parts[2][2] == "h"
                let l:info["is_active"] = 0
                let l:info["is_loaded"] = 1
                let l:info["is_visible"] = 0
            else
                let l:info["is_active"] = 0
                let l:info["is_loaded"] = 0
                let l:info["is_visible"] = 0
            endif
            if l:parts[2][3] == "-"
                let l:info["is_modifiable"] = 0
                let l:info["is_readonly"] = 0
            elseif l:parts[2][3] == "="
                let l:info["is_modifiable"] = 1
                let l:info["is_readonly"] = 1
            else
                let l:info["is_modifiable"] = 1
                let l:info["is_readonly"] = 0
            endif
            if l:parts[2][4] == "+"
                let l:info["is_modified"] = 1
                let l:info["is_readerror"] = 0
            elseif l:parts[2][4] == "x"
                let l:info["is_modified"] = 0
                let l:info["is_readerror"] = 0
            else
                let l:info["is_modified"] = 0
                let l:info["is_readerror"] = 0
            endif
            let l:info["bufname"] = parts[3]
            let l:info["filepath"] = fnamemodify(l:info["bufname"], ":p")
            " if g:buffergator_show_full_directory_path
            "     let l:info["filepath"] = fnamemodify(l:info["bufname"], ":p")
            " else
            "     let l:info["filepath"] = fnamemodify(l:info["bufname"], ":.")
            " endif
            let l:info["basename"] = fnamemodify(l:info["bufname"], ":t")
            if len(l:info["basename"]) > self.max_buffer_basename_len
                let self.max_buffer_basename_len = len(l:info["basename"])
            endif
            let l:info["parentdir"] = fnamemodify(l:info["bufname"], ":p:h")
            if g:buffergator_show_full_directory_path
                let l:info["parentdir"] = fnamemodify(l:info["bufname"], ":p:h")
            else
                let l:info["parentdir"] = fnamemodify(l:info["bufname"], ":h")
            endif
            let l:info["extension"] = fnamemodify(l:info["bufname"], ":e")
            call add(bcat, l:info)
            " let l:buffers_info[l:info[l:key]] = l:info
        endfor
        let l:sort_func = "s:_compare_dicts_by_" . self.sort_regime
        return sort(bcat, l:sort_func)
    endfunction

    " Opens viewer if closed, closes viewer if open.
    function! catalog_viewer.toggle() dict
        " get buffer number of the catalog view buffer, creating it if neccessary
        if self.bufnum < 0 || !bufexists(self.bufnum)
            call self.open()
        else
            let l:bfwn = bufwinnr(self.bufnum)
            if l:bfwn >= 0
                call self.close(1)
            else
                call self.open()
            endif
        endif
    endfunction

    " Creates a new buffer, renders and opens it.
    function! catalog_viewer.create_buffer() dict
        " get a new buf reference
        let self.bufnum = bufnr(self.bufname, 1)
        " get a viewport onto it
        call self.activate_viewport()
        " initialize it (includes "claiming" it)
        call self.initialize_buffer()
        " render it
        call self.render_buffer()
    endfunction

    " Opens a viewport on the buffer according, creating it if neccessary
    " according to the spawn mode. Valid buffer number must already have been
    " obtained before this is called.
    function! catalog_viewer.activate_viewport() dict
        let l:bfwn = bufwinnr(self.bufnum)
        if l:bfwn == winnr()
            " viewport wth buffer already active and current
            return
        elseif l:bfwn >= 0
            " viewport with buffer exists, but not current
            execute(l:bfwn . " wincmd w")
        else
            " create viewport
            let self.split_mode = s:_get_split_mode()
            call self.expand_screen()
            execute("silent keepalt keepjumps " . self.split_mode . " " . self.bufnum)
            if g:buffergator_viewport_split_policy =~ '[RrLl]' && g:buffergator_vsplit_size
                execute("vertical resize " . g:buffergator_vsplit_size)
                setlocal winfixwidth
            elseif g:buffergator_viewport_split_policy =~ '[TtBb]' && g:buffergator_hsplit_size
                execute("resize " . g:buffergator_hsplit_size)
                setlocal winfixheight
            endif
        endif
    endfunction

    " Sets up buffer environment.
    function! catalog_viewer.initialize_buffer() dict
        call self.claim_buffer()
        call self.setup_buffer_opts()
        call self.setup_buffer_syntax()
        call self.setup_buffer_commands()
        call self.setup_buffer_keymaps()
        call self.setup_buffer_folding()
        call self.setup_buffer_statusline()
    endfunction

    " 'Claims' a buffer by setting it to point at self.
    function! catalog_viewer.claim_buffer() dict
        call setbufvar("%", "is_buffergator_buffer", 1)
        call setbufvar("%", "buffergator_catalog_viewer", self)
        call setbufvar("%", "buffergator_last_render_time", 0)
        call setbufvar("%", "buffergator_cur_line", 0)
    endfunction

    " 'Unclaims' a buffer by stripping all buffergator vars
    function! catalog_viewer.unclaim_buffer() dict
        for l:var in ["is_buffergator_buffer",
                    \ "buffergator_catalog_viewer",
                    \ "buffergator_last_render_time",
                    \ "buffergator_cur_line"
                    \ ]
            if exists("b:" . l:var)
                unlet b:{l:var}
            endif
        endfor
    endfunction

    " Sets buffer options.
    function! catalog_viewer.setup_buffer_opts() dict
        setlocal buftype=nofile
        setlocal noswapfile
        setlocal nowrap
        set bufhidden=hide
        setlocal nobuflisted
        setlocal nolist
        setlocal noinsertmode
        setlocal nonumber
        setlocal norelativenumber
        setlocal cursorline
        setlocal nospell
        setlocal matchpairs=""
        setlocal filetype=buffergator
    endfunction

    " Sets buffer commands.
    function! catalog_viewer.setup_buffer_commands() dict
        " command! -bang -nargs=* Bdfilter :call b:buffergator_catalog_viewer.set_filter('<bang>', <q-args>)
        augroup BuffergatorCatalogViewer
            au!
            autocmd BufLeave <buffer> let s:_buffergator_last_catalog_viewed = b:buffergator_catalog_viewer
        augroup END
    endfunction

    function! catalog_viewer.disable_editing_keymaps() dict
        """" Disabling of unused modification keys
        for key in [".", "p", "P", "C", "x", "X", "r", "R", "i", "I", "a", "A", "D", "S", "U"]
            try
                execute "nnoremap <buffer> " . key . " <NOP>"
            catch //
            endtry
        endfor
    endfunction

    " Sets buffer folding.
    function! catalog_viewer.setup_buffer_folding() dict
        " if has("folding")
        "     "setlocal foldcolumn=3
        "     setlocal foldmethod=syntax
        "     setlocal foldlevel=4
        "     setlocal foldenable
        "     setlocal foldtext=BuffergatorFoldText()
        "     " setlocal fillchars=fold:\ "
        "     setlocal fillchars=fold:.
        " endif
    endfunction

    " Close and quit the viewer.
    function! catalog_viewer.close(restore_prev_window) dict
        if self.bufnum < 0 || !bufexists(self.bufnum)
            return
        endif
        call self.contract_screen()
        if a:restore_prev_window
            if !self.is_usable_viewport(winnr("#")) && self.first_usable_viewport() ==# -1
            else
                try
                    if !self.is_usable_viewport(winnr("#"))
                        execute(self.first_usable_viewport() . "wincmd w")
                    else
                        execute('wincmd p')
                    endif
                catch //
                endtry
            endif
        endif
        execute("bwipe " . self.bufnum)
        let s:is_buffergator_buffers_open = 0
    endfunction

    function! catalog_viewer.expand_screen() dict
        if has("gui_running") && g:buffergator_autoexpand_on_split
            if g:buffergator_viewport_split_policy =~ '[RL]' && g:buffergator_vsplit_size
                let self.pre_expand_columns = &columns
                let &columns += g:buffergator_vsplit_size
                let self.columns_expanded = &columns - self.pre_expand_columns
            else
                let self.columns_expanded = 0
            endif
            if g:buffergator_viewport_split_policy =~ '[TB]' && g:buffergator_hsplit_size
                let self.pre_expand_lines = &lines
                let &lines += g:buffergator_hsplit_size
                let self.lines_expanded = &lines - self.pre_expand_lines
            else
                let self.lines_expanded = 0
            endif
        endif
    endfunction

    function! catalog_viewer.contract_screen() dict
        if self.columns_expanded
                    \ && &columns - self.columns_expanded > 20
            let new_size  = &columns - self.columns_expanded
            if new_size < self.pre_expand_columns
                let new_size = self.pre_expand_columns
            endif
            let &columns = new_size
        endif
        if self.lines_expanded
                    \ && &lines - self.lines_expanded > 20
            let new_size  = &lines - self.lines_expanded
            if new_size < self.pre_expand_lines
                let new_size = self.pre_expand_lines
            endif
            let &lines = new_size
        endif
    endfunction

    function! catalog_viewer.highlight_current_line()
        if self.current_buffer_index
          execute ":" . self.current_buffer_index
          if self.current_buffer_index < line('w0')
            execute "silent! normal! zt"
          elseif self.current_buffer_index > line('w$')
            execute "silent! normal! zb"
          endif
        endif
    endfunction

    " Clears the buffer contents.
    function! catalog_viewer.clear_buffer() dict
        call cursor(1, 1)
        exec 'silent! normal! "_dG'
    endfunction

    " from NERD_Tree, via VTreeExplorer: determine the number of windows open
    " to this buffer number.
    function! catalog_viewer.num_viewports_on_buffer(bnum) dict
        let cnt = 0
        let winnum = 1
        while 1
            let bufnum = winbufnr(winnum)
            if bufnum < 0
                break
            endif
            if bufnum ==# a:bnum
                let cnt = cnt + 1
            endif
            let winnum = winnum + 1
        endwhile
        return cnt
    endfunction

    " from NERD_Tree: find the window number of the first normal window
    function! catalog_viewer.first_usable_viewport() dict
        let i = 1
        while i <= winnr("$")
            let bnum = winbufnr(i)
            if bnum != -1 && getbufvar(bnum, '&buftype') ==# ''
                        \ && !getwinvar(i, '&previewwindow')
                        \ && (!getbufvar(bnum, '&modified') || &hidden)
                return i
            endif

            let i += 1
        endwhile
        return -1
    endfunction

    " from NERD_Tree: returns 0 if opening a file from the tree in the given
    " window requires it to be split, 1 otherwise
    function! catalog_viewer.is_usable_viewport(winnumber) dict
        "gotta split if theres only one window (i.e. the NERD tree)
        if winnr("$") ==# 1
            return 0
        endif
        let oldwinnr = winnr()
        execute(a:winnumber . "wincmd p")
        let specialWindow = getbufvar("%", '&buftype') != '' || getwinvar('%', '&previewwindow')
        let modified = &modified
        execute(oldwinnr . "wincmd p")
        "if its a special window e.g. quickfix or another explorer plugin then we
        "have to split
        if specialWindow
            return 0
        endif
        if &hidden
            return 1
        endif
        return !modified || self.num_viewports_on_buffer(winbufnr(a:winnumber)) >= 2
    endfunction

    " Acquires a viewport to show the source buffer. Returns the split command
    " to use when switching to the buffer.
    function! catalog_viewer.acquire_viewport(split_cmd)
        if self.split_mode == "buffer" && empty(a:split_cmd)
            " buffergator used original buffer's viewport,
            " so the the buffergator viewport is the viewport to use
            return ""
        endif
        if !self.is_usable_viewport(winnr("#")) && self.first_usable_viewport() ==# -1
            " no appropriate viewport is available: create new using default
            " split mode
            " TODO: maybe use g:buffergator_viewport_split_policy?
            if empty(a:split_cmd)
                return "sb"
            else
                return a:split_cmd
            endif
        else
            try
                if !self.is_usable_viewport(winnr("#"))
                    execute(self.first_usable_viewport() . "wincmd w")
                else
                    execute('wincmd p')
                endif
            catch /^Vim\%((\a\+)\)\=:E37/
                echo v:exception
            catch /^Vim\%((\a\+)\)\=:/
                echo v:exception
            endtry
            return a:split_cmd
        endif
    endfunction

    " Finds next occurrence of specified pattern.
    function! catalog_viewer.goto_pattern(pattern, direction) dict range
        if a:direction == "b" || a:direction == "p"
            let l:flags = "b"
            " call cursor(line(".")-1, 0)
        else
            let l:flags = ""
            " call cursor(line(".")+1, 0)
        endif
        if g:buffergator_move_wrap
            let l:flags .= "w"
        else
            let l:flags .= "W"
        endif
        let l:flags .= "e"
        let l:lnum = -1
        for i in range(v:count1)
            if search(a:pattern, l:flags) < 0
                break
            else
                let l:lnum = 1
            endif
        endfor
        if l:lnum < 0
            if l:flags[0] == "b"
                call s:_buffergator_messenger.send_info("No previous results")
            else
                call s:_buffergator_messenger.send_info("No more results")
            endif
            return 0
        else
            return 1
        endif
    endfunction

    " Cycles sort regime.
    function! catalog_viewer.cycle_sort_regime() dict
        let l:cur_regime = index(s:buffergator_catalog_sort_regimes, self.sort_regime)
        let l:cur_regime += 1
        if l:cur_regime < 0 || l:cur_regime >= len(s:buffergator_catalog_sort_regimes)
            let self.sort_regime = s:buffergator_catalog_sort_regimes[0]
        else
            let self.sort_regime = s:buffergator_catalog_sort_regimes[l:cur_regime]
        endif
        call self.open(1)
        let l:sort_desc = get(s:buffergator_catalog_sort_regime_desc, self.sort_regime, ["??", "in unspecified order"])[1]
        call s:_buffergator_messenger.send_info("sorted " . l:sort_desc)
    endfunction

    " Cycles full/relative paths
    function! catalog_viewer.cycle_directory_path_display() dict
        if self.display_regime != "basename"
            call s:_buffergator_messenger.send_info("cycling full/relative directory paths only makes sense when using the 'basename' display regime")
            return
        endif
        if g:buffergator_show_full_directory_path
            let g:buffergator_show_full_directory_path = 0
            call s:_buffergator_messenger.send_info("displaying relative directory path")
            call self.open(1)
        else
            let g:buffergator_show_full_directory_path = 1
            call s:_buffergator_messenger.send_info("displaying full directory path")
            call self.open(1)
        endif
    endfunction

    " Cycles display regime.
    function! catalog_viewer.cycle_display_regime() dict
        let l:cur_regime = index(s:buffergator_catalog_display_regimes, self.display_regime)
        let l:cur_regime += 1
        if l:cur_regime < 0 || l:cur_regime >= len(s:buffergator_catalog_display_regimes)
            let self.display_regime = s:buffergator_catalog_display_regimes[0]
        else
            let self.display_regime = s:buffergator_catalog_display_regimes[l:cur_regime]
        endif
        let b:did_syntax = 0
        call self.open(1)
        let l:display_desc = get(s:buffergator_catalog_display_regime_desc, self.display_regime, ["??", "in unspecified order"])[1]
        call s:_buffergator_messenger.send_info("displaying " . l:display_desc)
    endfunction

    " Cycles window regime.
    function! catalog_viewer.cycle_viewport_modes() dict
        let l:cur_mode = index(s:buffergator_viewport_split_modes_cycle_list, g:buffergator_viewport_split_policy)
        let l:cur_mode += 1
        if l:cur_mode < 0 || l:cur_mode >= len(s:buffergator_viewport_split_modes_cycle_list)
            let g:buffergator_viewport_split_policy = s:buffergator_viewport_split_modes_cycle_list[0]
        else
            let g:buffergator_viewport_split_policy = s:buffergator_viewport_split_modes_cycle_list[l:cur_mode]
        endif
        call buffergator#ReopenBuffergator()
    endfunction

    " Cycles autodismiss modes
    function! catalog_viewer.cycle_autodismiss_modes() dict
        if (g:buffergator_autodismiss_on_select)
            let g:buffergator_autodismiss_on_select = 0
        call s:_buffergator_messenger.send_info("will stay open on selection (autodismiss-on-select: OFF)")
        else
            let g:buffergator_autodismiss_on_select = 1
        call s:_buffergator_messenger.send_info("will close on selection (autodismiss-on-select: ON)")
        endif
    endfunction

    " Rebuilds catalog.
    function! catalog_viewer.rebuild_catalog() dict
        call self.open(1)
    endfunction

    " Zooms/unzooms window.
    function! catalog_viewer.toggle_zoom() dict
        let l:bfwn = bufwinnr(self.bufnum)
        if l:bfwn < 0
            return
        endif
        if self.is_zoomed
            " if s:_is_full_height_window(l:bfwn) && !s:_is_full_width_window(l:bfwn)
            if g:buffergator_viewport_split_policy =~ '[RrLl]'
                if !g:buffergator_vsplit_size
                    let l:new_size = &columns / 3
                else
                    let l:new_size = g:buffergator_vsplit_size
                endif
                if l:new_size > 0
                    execute("vertical resize " . string(l:new_size))
                endif
                let self.is_zoomed = 0
            " elseif s:_is_full_width_window(l:bfwn) && !s:_is_full_height_window(l:bfwn)
            elseif g:buffergator_viewport_split_policy =~ '[TtBb]'
                if !g:buffergator_hsplit_size
                    let l:new_size = &lines / 3
                else
                    let l:new_size = g:buffergator_hsplit_size
                endif
                if l:new_size > 0
                    execute("resize " . string(l:new_size))
                endif
                let self.is_zoomed = 0
            endif
        else
            " if s:_is_full_height_window(l:bfwn) && !s:_is_full_width_window(l:bfwn)
            if g:buffergator_viewport_split_policy =~ '[RrLl]'
                if &columns > 20
                    execute("vertical resize " . string(&columns-10))
                    let self.is_zoomed = 1
                endif
            " elseif s:_is_full_width_window(l:bfwn) && !s:_is_full_height_window(l:bfwn)
            elseif g:buffergator_viewport_split_policy =~ '[TtBb]'
                if &lines > 20
                    execute("resize " . string(&lines-10))
                    let self.is_zoomed = 1
                endif
            endif
        endif
    endfunction

    " functions to be implemented by derived classes
    function! catalog_viewer.update_buffers_info() dict
    endfunction

    function! catalog_viewer.open(...) dict
    endfunction

    function! catalog_viewer.setup_buffer_syntax() dict
    endfunction

    function! catalog_viewer.setup_buffer_keymaps() dict
    endfunction

    function! catalog_viewer.render_buffer() dict
    endfunction

    function! catalog_viewer.setup_buffer_statusline() dict
    endfunction

    function! catalog_viewer.append_line(text, jump_to_bufnum) dict
    endfunction

    return catalog_viewer

endfunction

" 1}}}

" BufferCatalogViewer {{{1
" ============================================================================
function! s:NewBufferCatalogViewer()

    " initialize
    let catalog_viewer = s:NewCatalogViewer("[[buffergator-buffers]]", "buffergator")
    let catalog_viewer["calling_bufnum"] = -1
    let catalog_viewer["buffers_catalog"] = {}
    let catalog_viewer["current_buffer_index"] = -1

    " Populates the buffer list
    function! catalog_viewer.update_buffers_info() dict
        let self.buffers_catalog = self.list_buffers()
        return self.buffers_catalog
    endfunction

    " Opens the buffer for viewing, creating it if needed.
    " First argument, if given, should be false if the buffers info is *not*
    " to be repopulated; defaults to 1
    " Second argument, if given, should be number of calling window.
    function! catalog_viewer.open(...) dict
        " populate data
        if (a:0 == 0 || a:1 > 0)
            call self.update_buffers_info()
        endif
        " store calling buffer
        if (a:0 >= 2 && a:2)
            let self.calling_bufnum = a:2
        else
            let self.calling_bufnum = bufnr("%")
        endif
        " get buffer number of the catalog view buffer, creating it if neccessary
        if self.bufnum < 0 || !bufexists(self.bufnum)
            " create and render a new buffer
            call self.create_buffer()
        else
            " buffer exists: activate a viewport on it according to the
            " spawning mode, re-rendering the buffer with the catalog if needed
            call self.activate_viewport()
            call self.render_buffer()
            " if (a:0 > 0 && a:1) || b:buffergator_catalog_viewer != self
            "     call self.render_buffer()
            " else
            "     " search for calling buffer number in jump map,
            "     " when found, go to that line
            " endif
        endif
    endfunction


    " Sets buffer syntax.
    function! catalog_viewer.setup_buffer_syntax() dict
        if has("syntax") && (!exists('b:did_syntax') || !b:did_syntax)
            syntax clear
            syn region BuffergatorFileLine start='^' keepend oneline end='$'
            syn match BuffergatorBufferNr '^\[.\{3\}\]' containedin=BuffergatorFileLine
            let l:line_symbols = values(s:buffergator_buffer_line_symbols)
            execute "syn match BuffergatorSymbol '[" . join(l:line_symbols,"") . "]' containedin=BuffergatorFileLine"
            for l:buffer_status_index in range(0, len(s:buffergator_buffer_line_symbols_order) - 1)
              let l:name = s:buffergator_buffer_line_symbols_order[l:buffer_status_index]
              let l:line_symbol = s:buffergator_buffer_line_symbols[l:name]
              let l:pattern = repeat('.', l:buffer_status_index)
              let l:pattern .= l:line_symbol
              let l:pattern .= repeat('.', len(s:buffergator_buffer_line_symbols_order) - (l:buffer_status_index + 1))
              let l:pattern .= '\s.\{-}/'
              let l:pattern_name = "Buffergator" . toupper(l:name[0]) . tolower(l:name[1:]) . "Entry"
              let l:element = [
                \ "syn match",
                \ l:pattern_name, "'" . l:pattern . "'me=e-1",
                \ "containedin=BuffergatorFileLine",
                \ "contains=BuffergatorSymbol"
                \ ]
              let l:syntax_cmd = join(l:element," ")
              execute l:syntax_cmd
            endfor
            highlight link BuffergatorSymbol Constant
            " highlight link BuffergatorAlternateEntry Function
            " highlight link BuffergatorModifiedEntry String
            " highlight link BuffergatorCurrentEntry Keyword
            highlight link BuffergatorBufferNr LineNr
            let b:did_syntax = 1
        endif
      endfunction

    " Sets buffer key maps.
    function! catalog_viewer.setup_buffer_keymaps() dict

        call self.disable_editing_keymaps()

        if !exists("g:buffergator_use_new_keymap") || !g:buffergator_use_new_keymap

            """" Catalog management
            noremap <buffer> <silent> cs          :call b:buffergator_catalog_viewer.cycle_sort_regime()<CR>
            noremap <buffer> <silent> cd          :call b:buffergator_catalog_viewer.cycle_display_regime()<CR>
            noremap <buffer> <silent> cp          :call b:buffergator_catalog_viewer.cycle_directory_path_display()<CR>
            noremap <buffer> <silent> cw          :call b:buffergator_catalog_viewer.cycle_viewport_modes()<CR>
            noremap <buffer> <silent> cq          :call b:buffergator_catalog_viewer.cycle_autodismiss_modes()<CR>
            noremap <buffer> <silent> cc          <NOP>
            noremap <buffer> <silent> r           :call b:buffergator_catalog_viewer.rebuild_catalog()<CR>
            noremap <buffer> <silent> q           :call b:buffergator_catalog_viewer.close(1)<CR>
            noremap <buffer> <silent> d           :<C-U>call b:buffergator_catalog_viewer.delete_target(0, 0)<CR>
            noremap <buffer> <silent> D           :<C-U>call b:buffergator_catalog_viewer.delete_target(0, 1)<CR>
            noremap <buffer> <silent> x           :<C-U>call b:buffergator_catalog_viewer.delete_target(1, 0)<CR>
            noremap <buffer> <silent> X           :<C-U>call b:buffergator_catalog_viewer.delete_target(1, 1)<CR>

            """"" Selection: show target and switch focus
            noremap <buffer> <silent> <CR>        :<C-U>call b:buffergator_catalog_viewer.visit_target(!g:buffergator_autodismiss_on_select, 0, "")<CR>
            noremap <buffer> <silent> o           :<C-U>call b:buffergator_catalog_viewer.visit_target(!g:buffergator_autodismiss_on_select, 0, "")<CR>
            noremap <buffer> <silent> <LeftMouse> :<C-U>call b:buffergator_catalog_viewer.visit_target(!g:buffergator_autodismiss_on_select, 0, "")<CR>
            noremap <buffer> <silent> s           :<C-U>call b:buffergator_catalog_viewer.visit_target(!g:buffergator_autodismiss_on_select, 0, "vert sb")<CR>
            noremap <buffer> <silent> <C-v>       :<C-U>call b:buffergator_catalog_viewer.visit_target(!g:buffergator_autodismiss_on_select, 0, "vert sb")<CR>
            noremap <buffer> <silent> i           :<C-U>call b:buffergator_catalog_viewer.visit_target(!g:buffergator_autodismiss_on_select, 0, "sb")<CR>
            noremap <buffer> <silent> <C-s>       :<C-U>call b:buffergator_catalog_viewer.visit_target(!g:buffergator_autodismiss_on_select, 0, "sb")<CR>
            noremap <buffer> <silent> t           :<C-U>call b:buffergator_catalog_viewer.visit_target(!g:buffergator_autodismiss_on_select, 0, "tab sb")<CR>
            noremap <buffer> <silent> <C-t>       :<C-U>call b:buffergator_catalog_viewer.visit_target(!g:buffergator_autodismiss_on_select, 0, "tab sb")<CR>

            """"" Selection: show target and switch focus, preserving the catalog regardless of the autodismiss setting
            noremap <buffer> <silent> po          :<C-U>call b:buffergator_catalog_viewer.visit_target(1, 0, "")<CR>
            noremap <buffer> <silent> ps          :<C-U>call b:buffergator_catalog_viewer.visit_target(1, 0, "vert sb")<CR>
            noremap <buffer> <silent> pi          :<C-U>call b:buffergator_catalog_viewer.visit_target(1, 0, "sb")<CR>
            noremap <buffer> <silent> pt          :<C-U>call b:buffergator_catalog_viewer.visit_target(1, 0, "tab sb")<CR>

            """"" Preview: show target , keeping focus on catalog
            noremap <buffer> <silent> O           :<C-U>call b:buffergator_catalog_viewer.visit_target(1, 1, "")<CR>
            noremap <buffer> <silent> go          :<C-U>call b:buffergator_catalog_viewer.visit_target(1, 1, "")<CR>
            noremap <buffer> <silent> S           :<C-U>call b:buffergator_catalog_viewer.visit_target(1, 1, "vert sb")<CR>
            noremap <buffer> <silent> gs          :<C-U>call b:buffergator_catalog_viewer.visit_target(1, 1, "vert sb")<CR>
            noremap <buffer> <silent> I           :<C-U>call b:buffergator_catalog_viewer.visit_target(1, 1, "sb")<CR>
            noremap <buffer> <silent> gi          :<C-U>call b:buffergator_catalog_viewer.visit_target(1, 1, "sb")<CR>
            noremap <buffer> <silent> T           :<C-U>call b:buffergator_catalog_viewer.visit_target(1, 1, "tab sb")<CR>
            noremap <buffer> <silent> <SPACE>     :<C-U>call b:buffergator_catalog_viewer.goto_index_entry("n", 1, 1)<CR>
            noremap <buffer> <silent> <C-SPACE>   :<C-U>call b:buffergator_catalog_viewer.goto_index_entry("p", 1, 1)<CR>
            noremap <buffer> <silent> <C-@>       :<C-U>call b:buffergator_catalog_viewer.goto_index_entry("p", 1, 1)<CR>
            noremap <buffer> <silent> <C-N>       :<C-U>call b:buffergator_catalog_viewer.goto_index_entry("n", 1, 1)<CR>
            noremap <buffer> <silent> <C-P>       :<C-U>call b:buffergator_catalog_viewer.goto_index_entry("p", 1, 1)<CR>

            """"" Preview: go to existing window showing target
            noremap <buffer> <silent> E           :<C-U>call b:buffergator_catalog_viewer.visit_open_target(1, !g:buffergator_autodismiss_on_select, "")<CR>
            noremap <buffer> <silent> eo          :<C-U>call b:buffergator_catalog_viewer.visit_open_target(0, !g:buffergator_autodismiss_on_select, "")<CR>
            noremap <buffer> <silent> es          :<C-U>call b:buffergator_catalog_viewer.visit_open_target(0, !g:buffergator_autodismiss_on_select, "vert sb")<CR>
            noremap <buffer> <silent> ei          :<C-U>call b:buffergator_catalog_viewer.visit_open_target(0, !g:buffergator_autodismiss_on_select, "sb")<CR>
            noremap <buffer> <silent> et          :<C-U>call b:buffergator_catalog_viewer.visit_open_target(0, !g:buffergator_autodismiss_on_select, "tab sb")<CR>

        else

            """" Catalog management
            noremap <buffer> <silent> s           :call b:buffergator_catalog_viewer.cycle_sort_regime()<CR>
            noremap <buffer> <silent> i           :call b:buffergator_catalog_viewer.cycle_display_regime()<CR>
            noremap <buffer> <silent> u           :call b:buffergator_catalog_viewer.rebuild_catalog()<CR>
            noremap <buffer> <silent> q           :call b:buffergator_catalog_viewer.close(1)<CR>
            noremap <buffer> <silent> d           :call b:buffergator_catalog_viewer.delete_target(0, 0)<CR>
            noremap <buffer> <silent> D           :call b:buffergator_catalog_viewer.delete_target(0, 1)<CR>
            noremap <buffer> <silent> x           :call b:buffergator_catalog_viewer.delete_target(1, 0)<CR>
            noremap <buffer> <silent> X           :call b:buffergator_catalog_viewer.delete_target(1, 1)<CR>

            " open target
            noremap <buffer> <silent> <CR>  :call b:buffergator_catalog_viewer.visit_target(!g:buffergator_autodismiss_on_select, 0, "")<CR>

            " show target line in other window, keeping catalog open and in focus
            noremap <buffer> <silent> .           :call b:buffergator_catalog_viewer.visit_target(1, 1, "")<CR>
            noremap <buffer> <silent> po          :call b:buffergator_catalog_viewer.visit_target(1, 1, "")<CR>
            noremap <buffer> <silent> ps          :call b:buffergator_catalog_viewer.visit_target(1, 1, "sb")<CR>
            noremap <buffer> <silent> pv          :call b:buffergator_catalog_viewer.visit_target(1, 1, "vert sb")<CR>
            noremap <buffer> <silent> pt          :call b:buffergator_catalog_viewer.visit_target(1, 1, "tab sb")<CR>
            noremap <buffer> <silent> <SPACE>     :<C-U>call b:buffergator_catalog_viewer.goto_index_entry("n", 1, 1)<CR>
            noremap <buffer> <silent> <C-SPACE>   :<C-U>call b:buffergator_catalog_viewer.goto_index_entry("p", 1, 1)<CR>
            noremap <buffer> <silent> <C-@>       :<C-U>call b:buffergator_catalog_viewer.goto_index_entry("p", 1, 1)<CR>
            noremap <buffer> <silent> <C-N>       :<C-U>call b:buffergator_catalog_viewer.goto_index_entry("n", 1, 1)<CR>
            noremap <buffer> <silent> <C-P>       :<C-U>call b:buffergator_catalog_viewer.goto_index_entry("p", 1, 1)<CR>

            " go to target line in other window, keeping catalog open
            noremap <buffer> <silent> o           :call b:buffergator_catalog_viewer.visit_target(1, 0, "")<CR>
            noremap <buffer> <silent> ws          :call b:buffergator_catalog_viewer.visit_target(1, 0, "sb")<CR>
            noremap <buffer> <silent> wv          :call b:buffergator_catalog_viewer.visit_target(1, 0, "vert sb")<CR>
            noremap <buffer> <silent> t           :call b:buffergator_catalog_viewer.visit_target(1, 0, "tab sb")<CR>

            " open target line in other window, closing catalog
            noremap <buffer> <silent> O           :call b:buffergator_catalog_viewer.visit_target(0, 0, "")<CR>
            noremap <buffer> <silent> wS          :call b:buffergator_catalog_viewer.visit_target(0, 0, "sb")<CR>
            noremap <buffer> <silent> wV          :call b:buffergator_catalog_viewer.visit_target(0, 0, "vert sb")<CR>
            noremap <buffer> <silent> T           :call b:buffergator_catalog_viewer.visit_target(0, 0, "tab sb")<CR>

        endif

        " other
        noremap <buffer> <silent> A           :call b:buffergator_catalog_viewer.toggle_zoom()<CR>

        if g:buffergator_remap_arrow_keys
            noremap <buffer> <UP>     <UP>
            noremap <buffer> <DOWN>   <DOWN>
        endif

    endfunction

    " Populates the buffer with the catalog index.
    function! catalog_viewer.render_buffer() dict
        setlocal modifiable
        call self.claim_buffer()
        call self.clear_buffer()
        call self.setup_buffer_syntax()
        let self.jump_map = {}
        let l:initial_line = 1
        for l:bufinfo in self.buffers_catalog
            if self.calling_bufnum == l:bufinfo.bufnum
                let l:initial_line = line("$")
            endif

            if l:bufinfo.is_current
              let self.current_buffer_index = line("$")
            endif

            let l:bufnum_str = s:_format_filled(l:bufinfo.bufnum, 3, 1, 0)
            let l:line = "[" . l:bufnum_str . "]"

            let l:line .= s:_format_filled(self.line_symbols(l:bufinfo),4,-1,0)

            if self.display_regime == "basename"
                let l:line .= s:_format_align_left(l:bufinfo.basename, self.max_buffer_basename_len, " ")
                let l:line .= "  "
                let l:line .= l:bufinfo.parentdir
            elseif self.display_regime == "parentdir"
                let l:line .= s:_format_align_left(l:bufinfo.basename, self.max_buffer_basename_len, " ")
                let l:line .= "  "
                let l:line .= fnamemodify(l:bufinfo.parentdir, ':p:h:t')
            elseif self.display_regime == "filepath"
                let l:line .= l:bufinfo.filepath
            elseif self.display_regime == "bufname"
                let l:line .= l:bufinfo.bufname
            else
                throw s:_buffergator_messenger.format_exception("Invalid display regime: '" . self.display_regime . "'")
            endif
            call self.append_line(l:line, l:bufinfo.bufnum)
        endfor
        let b:buffergator_last_render_time = localtime()
        try
            " remove extra last line
            execute('normal! GV"_X')
        catch //
        endtry
        setlocal nomodifiable
        call cursor(l:initial_line, 1)
        " call self.goto_index_entry("n", 0, 1)
    endfunction

    " Visits the specified buffer in the previous window, if it is already
    " visible there. If not, then it looks for the first window with the
    " buffer showing and visits it there. If no windows are showing the
    " buffer, ... ?
    function! catalog_viewer.visit_buffer(bufnum, split_cmd) dict
        " acquire window
        let l:split_cmd = self.acquire_viewport(a:split_cmd)
        " switch to buffer in acquired window
        let l:old_switch_buf = &switchbuf
        if empty(l:split_cmd)
            " explicit split command not given: switch to buffer in current
            " window
            let &switchbuf="useopen"
            execute("silent buffer " . a:bufnum)
        else
            " explcit split command given: split current window
            let &switchbuf="split"
            execute("silent keepalt keepjumps " . l:split_cmd . " " . a:bufnum)
        endif
        let &switchbuf=l:old_switch_buf
    endfunction

    function! catalog_viewer.get_target_bufnum(cmd_count) dict
        if a:cmd_count == 0
            let l:cur_line = line(".")
            if !has_key(l:self.jump_map, l:cur_line)
                call s:_buffergator_messenger.send_info("Not a valid navigation line")
                return -1
            endif
            let [l:jump_to_bufnum] = self.jump_map[l:cur_line].target
            return l:jump_to_bufnum
        else
            let l:jump_to_bufnum = a:cmd_count
            if bufnr(l:jump_to_bufnum) == -1
                call s:_buffergator_messenger.send_info("Not a valid buffer number: " . string(l:jump_to_bufnum) )
                return -1
            endif
            for lnum in range(1, line("$"))
                if self.jump_map[lnum].target[0] == l:jump_to_bufnum
                    call cursor(lnum, 1)
                    return l:jump_to_bufnum
                endif
            endfor
            call s:_buffergator_messenger.send_info("Not a listed buffer number: " . string(l:jump_to_bufnum) )
            return -1
        endif
    endfunction

    " Go to the selected buffer.
    function! catalog_viewer.visit_target(keep_catalog, refocus_catalog, split_cmd) dict range
        let l:jump_to_bufnum = self.get_target_bufnum(v:count)
        if l:jump_to_bufnum == -1
            return 0
        endif
        let l:cur_tab_num = tabpagenr()
        if (self.split_mode != "buffer" || !empty(a:split_cmd)) && !a:keep_catalog
            call self.close(0)
        endif
        call self.visit_buffer(l:jump_to_bufnum, a:split_cmd)
        if a:keep_catalog && a:refocus_catalog
            execute("tabnext " . l:cur_tab_num)
            execute(bufwinnr(self.bufnum) . "wincmd w")
        endif
        call s:_buffergator_messenger.send_info(expand(bufname(l:jump_to_bufnum)))
    endfunction

    " Go to the selected buffer, preferentially using a window that already is
    " showing it; if not, create a window using split_cmd
    function! catalog_viewer.visit_open_target(unconditional, keep_catalog, split_cmd) dict range
        let l:jump_to_bufnum = self.get_target_bufnum(v:count)
        if l:jump_to_bufnum == -1
            return 0
        endif
        let wnr = bufwinnr(l:jump_to_bufnum)
        if wnr != -1
            execute(wnr . "wincmd w")
            if !a:keep_catalog
                call self.close(0)
            endif
            return
        endif
        let l:cur_tab_num = tabpagenr()
        for tabnum in range(1, tabpagenr('$'))
            execute("tabnext " . tabnum)
            let wnr = bufwinnr(l:jump_to_bufnum)
            if wnr != -1
                execute(wnr . "wincmd w")
                if !a:keep_catalog
                    call self.close(0)
                endif
                return
            endif
        endfor
        execute("tabnext " . l:cur_tab_num)
        if !a:unconditional
            call self.visit_target(a:keep_catalog, 0, a:split_cmd)
        endif
    endfunction

    function! catalog_viewer.delete_target(wipe, force) dict range
        let l:bufnum_to_delete = self.get_target_bufnum(v:count)
        if l:bufnum_to_delete == -1
            return 0
        endif
        if !bufexists(l:bufnum_to_delete)
            call s:_buffergator_messenger.send_info("Not a valid or existing buffer")
            return 0
        endif
        if a:wipe && a:force
            let l:operation_desc = "unconditionally wipe"
            let l:cmd = "bw!"
        elseif a:wipe && !a:force
            let l:operation_desc = "wipe"
            let l:cmd = "bw"
        elseif !a:wipe && a:force
            let l:operation_desc = "unconditionally delete"
            let l:cmd = "bd!"
        elseif !a:wipe && !a:force
            let l:operation_desc = "delete"
            let l:cmd = "bd"
        endif

        " store current window number
        let l:cur_win_num = winnr()

        " find alternate buffer to switch to
        " let l:alternate_buffer = -1
        " for abufnum in range(l:bufnum_to_delete, 1, -1)
        "     if bufexists(abufnum) && buflisted(abufnum) && abufnum != l:bufnum_to_delete
        "         let l:alternate_buffer = abufnum
        "         break
        "     endif
        " endfor
        " if l:alternate_buffer == -1 && bufnr("$") > l:bufnum_to_delete
        "     for abufnum in range(l:bufnum_to_delete+1, bufnr("$"))
        "         if bufexists(abufnum) && buflisted(abufnum) && abufnum != l:bufnum_to_delete
        "             let l:alternate_buffer = abufnum
        "             break
        "         endif
        "     endfor
        " endif
        " if l:alternate_buffer == -1
        "     call s:_buffergator_messenger.send_warning("Cowardly refusing to delete last listed buffer")
        "     return 0
        " endif

        call self.update_buffers_info()
        if len(self.buffers_catalog) == 1
            if self.buffers_catalog[0].bufnum == l:bufnum_to_delete
                call s:_buffergator_messenger.send_warning("Cowardly refusing to delete last listed buffer")
                return 0
            else
                call s:_buffergator_messenger.send_warning("Buffer not found")
                return 0
            endif
        endif
        let l:alternate_buffer = -1
        for xbi in range(0, len(self.buffers_catalog)-1)
            let curbf = self.buffers_catalog[xbi].bufnum
            if curbf == l:bufnum_to_delete
                if xbi == len(self.buffers_catalog)-1
                    if xbi > 0
                        let l:alternate_buffer = self.buffers_catalog[xbi-1].bufnum
                    else
                        call s:_buffergator_messenger.send_warning("Cowardly refusing to delete last listed buffer")
                        return 0
                    endif
                else
                    if xbi+1 < len(self.buffers_catalog)
                        let l:alternate_buffer = self.buffers_catalog[xbi+1].bufnum
                    else
                        call s:_buffergator_messenger.send_warning("Cowardly refusing to delete last listed buffer")
                        return 0
                    endif
                endif
                break
            endif
        endfor

        let l:changed_win_bufs = []
        for winnum in range(1, winnr('$'))
            let wbufnum = winbufnr(winnum)
            if wbufnum == l:bufnum_to_delete
                call add(l:changed_win_bufs, winnum)
                execute(winnum . "wincmd w")
                execute("silent keepalt keepjumps buffer " . l:alternate_buffer)
            endif
        endfor

        let l:bufname = expand(bufname(l:bufnum_to_delete))
        try
            execute(l:cmd . string(l:bufnum_to_delete))
            call self.open(1, l:alternate_buffer)
            let l:message = l:bufname . " " . l:operation_desc . "d"
            call s:_buffergator_messenger.send_info(l:message)
        catch /E89/
            for winnum in l:changed_win_bufs
                execute(winnum . "wincmd w")
                execute("silent keepalt keepjumps buffer " . l:bufnum_to_delete)
            endfor
            execute(l:cur_win_num . "wincmd w")
            let l:message = 'Failed to ' . l:operation_desc . ' "' . l:bufname . '" because it is modified; use unconditional version of this command to force operation'
            call s:_buffergator_messenger.send_error(l:message)
        catch //
            for winnum in l:changed_win_bufs
                execute(winnum . "wincmd w")
                execute("silent keepalt keepjumps buffer " . l:bufnum_to_delete)
            endfor
            execute(l:cur_win_num . "wincmd w")
            let l:message = 'Failed to ' . l:operation_desc . ' "' . l:bufname . '"'
            call s:_buffergator_messenger.send_error(l:message)
        endtry

    endfunction

    " Finds next line with occurrence of a rendered index
    function! catalog_viewer.goto_index_entry(direction, visit_target, refocus_catalog) dict range
        if v:count > 0
            let l:target_bufnum = v:count
            if bufnr(l:target_bufnum) == -1
                call s:_buffergator_messenger.send_info("Not a valid buffer number: " . string(l:target_bufnum) )
                return -1
            endif
            let l:ok = 0
            for lnum in range(1, line("$"))
                if self.jump_map[lnum].target[0] == l:target_bufnum
                    call cursor(lnum, 1)
                    let l:ok = 1
                    break
                endif
            endfor
            if !l:ok
                call s:_buffergator_messenger.send_info("Not a listed buffer number: " . string(l:target_bufnum) )
                return -1
            endif
        else
            let l:ok = self.goto_pattern("^\[", a:direction)
            execute("normal! zz")
        endif
        if l:ok && a:visit_target
            call self.visit_target(1, a:refocus_catalog, "")
        endif
    endfunction

    " Sets buffer status line.
    function! catalog_viewer.setup_buffer_statusline() dict
        if g:buffergator_window_statusline
            setlocal statusline=%{BuffergatorBuffersStatusLine()}
        endif
    endfunction

    " Appends a line to the buffer and registers it in the line log.
    function! catalog_viewer.append_line(text, jump_to_bufnum) dict
        let l:line_map = {
                    \ "target" : [a:jump_to_bufnum],
                    \ }
        if a:0 > 0
            call extend(l:line_map, a:1)
        endif
        let self.jump_map[line("$")] = l:line_map
        call append(line("$")-1, a:text)
    endfunction

    " return object
    return catalog_viewer


endfunction
" 1}}}

" TabCatalogViewer {{{1
" ============================================================================
function! s:NewTabCatalogViewer()

    " initialize
    let catalog_viewer = s:NewCatalogViewer("[[buffergator-tabs]]", "buffergator")
    let catalog_viewer["tab_catalog"] = []

    " Opens the buffer for viewing, creating it if needed.
    " First argument, if given, should be false if the buffers info is *not*
    " to be repopulated; defaults to 1
    function! catalog_viewer.open(...) dict
        " populate data
        if (a:0 == 0 || a:1 > 0)
            call self.update_buffers_info()
        endif
        " get buffer number of the catalog view buffer, creating it if neccessary
        if self.bufnum < 0 || !bufexists(self.bufnum)
            " create and render a new buffer
            call self.create_buffer()
        else
            " buffer exists: activate a viewport on it according to the
            " spawning mode, re-rendering the buffer with the catalog if needed
            call self.activate_viewport()
            call self.render_buffer()
        endif
    endfunction

    " Populates the buffer list
    function! catalog_viewer.update_buffers_info() dict
        let self.tab_catalog = []
        for tabnum in range(1, tabpagenr('$'))
            call add(self.tab_catalog, tabpagebuflist(tabnum))
        endfor
        return self.tab_catalog
    endfunction

    " Populates the buffer with the catalog index.
    function! catalog_viewer.render_buffer() dict
        setlocal modifiable
        let l:cur_tab_num = tabpagenr()
        call self.claim_buffer()
        call self.clear_buffer()
        call self.setup_buffer_syntax()
        let self.jump_map = {}
        let l:initial_line = 1
        for l:tidx in range(len(self.tab_catalog))
            let l:tabinfo = self.tab_catalog[tidx]
            if l:cur_tab_num - 1 == l:tidx
                let l:initial_line = line("$")
            endif
            " let l:tabfield = "==== Tab Page [" . string(l:tidx+1) . "] ===="
            let l:tabfield = "TAB PAGE " . string(l:tidx+1) . ":"
            call self.append_line(l:tabfield, l:tidx+1, 1)
            for widx in range(len(l:tabinfo))
                let l:tabbufnum = l:tabinfo[widx]
                let l:tabbufname = bufname(l:tabbufnum)
                let subline = "[" . s:_format_filled(l:tabbufnum, 3, 1, 0) . "] "
                if getbufvar(l:tabbufnum, "&mod") == 1
                    let subline .= "+ "
                else
                    let subline .= "  "
                endif
                if self.display_regime == "basename"
                    let l:subline .= s:_format_align_left(fnamemodify(l:tabbufname, ":t"), 30, " ")
                    let l:subline .= fnamemodify(l:tabbufname, ":p:h")
                elseif self.display_regime == "parentdir"
                    let l:subline .= s:_format_align_left(fnamemodify(l:tabbufname, ":t"), 30, " ")
                    let l:subline .= fnamemodify(l:tabbufname, ":p:h:t")
                elseif self.display_regime == "filepath"
                    let l:subline .= fnamemodify(l:tabbufname, ":p")
                elseif self.display_regime == "bufname"
                    let l:subline .= l:tabbufname
                else
                    throw s:_buffergator_messenger.format_exception("Invalid display regime: '" . self.display_regime . "'")
                endif
                call self.append_line(l:subline, l:tidx+1, l:widx+1)
            endfor
        endfor
        let b:buffergator_last_render_time = localtime()
        try
            " remove extra last line
            execute('normal! GV"_X')
        catch //
        endtry
        setlocal nomodifiable
        call cursor(l:initial_line, 1)
        " call self.goto_index_entry("n", 0, 1)
    endfunction

    function! catalog_viewer.setup_buffer_syntax() dict
        if has("syntax") && !(exists('b:did_syntax'))
            syn match BuffergatorTabPageLine '^TAB PAGE \d\+\:$'
            " syn match BuffergatorTabPageLineStart '^==== Tab Page \[' nextgroup=BuffergatorTabPageNumber
            " syn match BuffergatorTabPageNumber '\d\+' nextgroup=BuffergatorTabPageLineEnd
            " syn match BuffergatorTabPageLineEnd '\] ====$'
            syn region BuffergatorModifiedFileLine start='^\[\s\{-}.\{-1,}\s\{-}\] + ' keepend oneline end='$'
            syn region BuffergatorUnmodifiedFileLine start='^\[\s\{-}.\{-1,}\s\{-}\]   ' keepend oneline end='$'
            syn match BuffergatorModifiedFileSyntaxKey '^\zs\[\s\{-}.\{-1,}\s\{-}\]\ze' containedin=BuffergatorModifiedFileLine nextgroup=BuffergatorModifiedFilename
            syn match BuffergatorUnmodifiedFileSyntaxKey '^\zs\[\s\{-}.\{-1,}\s\{-}\]\ze' containedin=BuffergatorUnmodifiedFileLine nextgroup=BuffergatorUnmodifiedFilename
            syn match BuffergatorModifiedFilename ' + .\+$' containedin=BuffergatorModifiedFilenameEntry
            syn match BuffergatorUnmodifiedFilename '   .\+$' containedin=BuffergatorUnmodifiedFileLine
            highlight! link BuffergatorModifiedFileSyntaxKey   LineNr
            highlight! link BuffergatorUnmodifiedFileSyntaxKey   LineNr
            highlight! link BuffergatorModifiedFileFlag   WarningMsg
            highlight! link BuffergatorModifiedFilename   WarningMsg
            highlight! link BuffergatorTabPageLine Title
            " highlight! link BufergatorModifiedFilename NonText
            " highlight! link BufergatorUnmodifiedFilename NonText
            " highlight! link BuffergatorTabPageLineStart Title
            " highlight! link BuffergatorTabPageNumber Special
            " highlight! link BuffergatorTabPageLineEnd Title
            highlight! link BuffergatorCurrentEntry CursorLine
            let b:did_syntax = 1
        endif
    endfunction

    function! catalog_viewer.setup_buffer_keymaps() dict

        call self.disable_editing_keymaps()

        noremap <buffer> <silent> cd          :call b:buffergator_catalog_viewer.cycle_display_regime()<CR>
        noremap <buffer> <silent> r           :call b:buffergator_catalog_viewer.rebuild_catalog()<CR>
        noremap <buffer> <silent> q           :call b:buffergator_catalog_viewer.close(1)<CR>

        noremap <buffer> <silent> <CR>        :call b:buffergator_catalog_viewer.visit_target()<CR>
        noremap <buffer> <silent> o           :call b:buffergator_catalog_viewer.visit_target()<CR>

        noremap <buffer> <silent> <SPACE>     :<C-U>call b:buffergator_catalog_viewer.goto_index_entry("n")<CR>
        noremap <buffer> <silent> <C-SPACE>   :<C-U>call b:buffergator_catalog_viewer.goto_index_entry("p")<CR>
        noremap <buffer> <silent> <C-@>       :<C-U>call b:buffergator_catalog_viewer.goto_index_entry("p")<CR>
        noremap <buffer> <silent> <C-N>       :<C-U>call b:buffergator_catalog_viewer.goto_win_entry("n")<CR>
        noremap <buffer> <silent> <C-P>       :<C-U>call b:buffergator_catalog_viewer.goto_win_entry("p")<CR>
        noremap <buffer> <silent> A           :call b:buffergator_catalog_viewer.toggle_zoom()<CR>

    endfunction

    " Appends a line to the buffer and registers it in the line log.
    function! catalog_viewer.append_line(text, jump_to_tabnum, jump_to_winnum) dict
        let l:line_map = {
                    \ "target" : [a:jump_to_tabnum, a:jump_to_winnum],
                    \ }
        if a:0 > 0
            call extend(l:line_map, a:1)
        endif
        let self.jump_map[line("$")] = l:line_map
        call append(line("$")-1, a:text)
    endfunction

    function! catalog_viewer.goto_index_entry(direction) dict
        let l:ok = self.goto_pattern("^T", a:direction)
        execute("normal! zz")
        " if l:ok && a:visit_target
        "     call self.visit_target(1, a:refocus_catalog, "")
        " endif
    endfunction

    function! catalog_viewer.goto_win_entry(direction) dict
        let l:ok = self.goto_pattern('^\[', a:direction)
        execute("normal! zz")
    endfunction

    " Go to the selected buffer.
    function! catalog_viewer.visit_target() dict
        let l:cur_line = line(".")
        if !has_key(l:self.jump_map, l:cur_line)
            call s:_buffergator_messenger.send_info("Not a valid navigation line")
            return 0
        endif
        let [l:jump_to_tabnum, l:jump_to_winnum] = self.jump_map[l:cur_line].target
        call self.close(0)
        execute("tabnext " . l:jump_to_tabnum)
        execute(l:jump_to_winnum . "wincmd w")
        " call s:_buffergator_messenger.send_info(expand(bufname(l:jump_to_bufnum)))
    endfunction

    function! catalog_viewer.setup_buffer_statusline() dict
        if g:buffergator_tab_statusline
            setlocal statusline=%{BuffergatorTabsStatusLine()}
        endif
    endfunction

    " return object
    return catalog_viewer

endfunction
" 1}}}

" Global Functions {{{1
" ==============================================================================
function! BuffergatorBuffersStatusLine()
    let l:line = line(".")
    let l:status_line = "[[buffergator]]"
    if has_key(b:buffergator_catalog_viewer.jump_map, l:line)
        let l:status_line .= " Buffer " . string(l:line) . " of " . string(len(b:buffergator_catalog_viewer.buffers_catalog))
    endif
    return l:status_line
endfunction
function! BuffergatorTabsStatusLine()
    let l:status_line = "[[buffergator]]"
    let l:line = line(".")
    if has_key(b:buffergator_catalog_viewer.jump_map, l:line)
        let l:status_line .= " Tab Page: " . b:buffergator_catalog_viewer.jump_map[l:line].target[0]
        let l:status_line .= ", Window: " . b:buffergator_catalog_viewer.jump_map[l:line].target[1]
    endif
    return l:status_line
endfunction
" 1}}}

" Functions Supporting User Commands {{{1
" ==============================================================================

function! buffergator#BuffergatorEchoMruList(bang)
    if !exists("w:buffergator_mru")
        let w:buffergator_mru = g:buffergator_mru[:]
    endif
    if g:buffergator_mru_cycle_local_to_window
        let l:mru_cycle_list = w:buffergator_mru
    else
        let l:mru_cycle_list = g:buffergator_mru
    endif
    if empty(a:bang)
        echo l:mru_cycle_list
    else
        for l:idx in range(len(l:mru_cycle_list))
            let l:entry = l:mru_cycle_list[l:idx]
            echo l:idx+1 . ". [" . l:entry . "] " .bufname(l:entry)
        endfor
    endif
endfunction

function! buffergator#BuffergatorCycleMru(dir, bufopencmd)
    if !exists("w:buffergator_mru")
        let w:buffergator_mru = g:buffergator_mru[:]
    endif
    if g:buffergator_mru_cycle_local_to_window
        let l:mru_cycle_list = w:buffergator_mru
    else
        let l:mru_cycle_list = g:buffergator_mru
    endif
    if len(l:mru_cycle_list) < 2
        call s:_buffergator_messenger.send_info("only one buffer available")
        return
    endif
    let l:target_buf = s:_find_mru_bufnr(a:dir, l:mru_cycle_list)
    if l:target_buf > 0
        if a:bufopencmd == ""
            let l:bufopencmd = "buffer"
        else
            let l:bufopencmd = a:bufopencmd
        endif
        let g:buffergator_track_mru = 0
        execute "silent keepalt keepjumps " . l:bufopencmd . " " . l:target_buf
        let g:buffergator_track_mru = 1
    else
        call s:_buffergator_messenger.send_info("no previous/next existing buffers available")
    endif
endfunction

function! buffergator#OpenBuffergator()
    let s:is_buffergator_buffers_open = 1
    call s:_catalog_viewer.close(0)
    call s:_catalog_viewer.open()
endfunction

function! buffergator#ReopenBuffergator()
    let s:is_buffergator_buffers_open = 1
    call s:_catalog_viewer.close(1)
    call s:_catalog_viewer.open()
endfunction

function! buffergator#UpdateBuffergator(event, affected)
    if !(g:buffergator_autoupdate)
        return
    endif
    let l:calling = bufnr("%")
    let l:self_call = 0
    let l:curr_winnr = winnr()
    let l:prev_winnr = winnr("#")
    let l:buffergators = s:_find_buffers_with_var("is_buffergator_buffer",1)
    call s:_catalog_viewer.update_buffers_info()

    " BufDelete is the last Autocommand executed, but it's done BEFORE the
    " buffer is actually deleted. - preemptively remove the buffer from
    " the list if this is a delete event
    if a:event == "delete"
        call filter(s:_catalog_viewer.buffers_catalog,'v:val["bufnum"] != ' . a:affected)
    endif

    for l:gator in l:buffergators
        if bufwinnr(l:gator) > 0
            if l:calling != l:gator
                execute bufwinnr(l:gator) . "wincmd w"
            else
                let l:self_call = 1
            endif

            " do not execute for tab view catalogs
            if has_key(b:buffergator_catalog_viewer, "tab_catalog")
                continue
            endif

            call s:_catalog_viewer.render_buffer()

            if !l:self_call
                call s:_catalog_viewer.highlight_current_line()
            endif
        endif
    endfor
    if exists("b:is_buffergator_buffer") && !l:self_call
        try
            execute l:prev_winnr . "wincmd w"
            execute l:curr_winnr . "wincmd w"
        catch //
        endtry
    elseif a:event == 'delete' && !l:self_call
        try
            execute l:prev_winnr . "wincmd w"
            execute l:curr_winnr . "wincmd w"
        catch //
        endtry
    endif
endfunction

function! buffergator#CloseBuffergator()
    "let s:is_buffergator_buffers_open = 0
    call s:_catalog_viewer.close(1)
endfunction

function! buffergator#ToggleBuffergator()
    if s:is_buffergator_buffers_open
        call buffergator#CloseBuffergator()
    else
        if s:is_buffergator_tabs_open
            call buffergator#CloseBuffergatorTabs()
        endif
        call buffergator#OpenBuffergator()
    endif
endfunction

function! buffergator#OpenBuffergatorTabs()
    let s:is_buffergator_tabs_open = 1
    call s:_tab_catalog_viewer.open()
endfunction

function! buffergator#CloseBuffergatorTabs()
    let s:is_buffergator_tabs_open = 0
    call s:_tab_catalog_viewer.close(1)
endfunction

function! buffergator#ToggleBuffergatorTabs()
    if s:is_buffergator_tabs_open
        call buffergator#CloseBuffergatorTabs()
    else
        if s:is_buffergator_buffers_open
            call buffergator#CloseBuffergator()
        endif
        call buffergator#OpenBuffergatorTabs()
    endif
endfunction

" 1}}}

" Global Initialization {{{1
" ==============================================================================
if exists("s:_buffergator_messenger")
    unlet s:_buffergator_messenger
endif
let s:_buffergator_messenger = s:NewMessenger("")
let s:_catalog_viewer = s:NewBufferCatalogViewer()
let s:_tab_catalog_viewer = s:NewTabCatalogViewer()
augroup BufferGatorAuto
au!
autocmd BufDelete * call buffergator#UpdateBuffergator('delete',expand('<abuf>'))
autocmd BufEnter * call buffergator#UpdateBuffergator('enter',expand('<abuf>'))
autocmd BufWritePost * call buffergator#UpdateBuffergator('writepost',expand('<abuf>'))
augroup NONE
" 1}}}

" Restore State {{{1
" ============================================================================
" restore options
let &cpo = s:save_cpo
" 1}}}

" vim:foldlevel=4:
