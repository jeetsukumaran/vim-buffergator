Summary
=======

- Use `<Leader>b` (typically: `\b`) to open a window listing all buffers. In this
  window, you can use normal movement keys to select a buffer and then:

    - <ENTER> to edit the selected buffer in the previous window
    - <C-V> to edit the selected buffer in a new vertical split
    - <C-S> to edit the selected buffer in a new horizontal split
    - <C-T> to edit the selected buffer in a new tab page

- Use `[b` (or <M-b>) and `]b` (or <M-S-b>) to flip through the most-recently
  used buffer stack without opening the buffer listing "drawer".
- Use `<Leader><LEFT>`, `<Leader><UP>`, `<Leader><RIGHT>`, `<Leader><DOWN>` to
  split a new window left, up, right, or down, respectively, and edit the
  previous MRU buffer there.

Many other options are supported: (e.g. open in existing window/tab, or in the
same window; preview buffer without leaving buffer listing; "pin" the buffer
listing so that it is open all the time, etc. etc.)

Details
=======

Buffergator is a plugin for listing, navigating between, and selecting buffers
to edit. Upon invocation (using the command, ":BuffergatorOpen" or
"BuffergatorToggle", or the provided key mapping, "<Leader>b"), a "catalog" of
listed buffers are displayed in a separate new window split (vertical or
horizontal, based on user options; default = vertical).  From this "buffer
catalog", a buffer can be selected and opened in an existing window, a new
window split (vertical or horizontal), or a new tab page.

Selected buffers can be "previewed", i.e. opened in a window or tab page, but
with focus remaining in the buffer catalog. Even better, you can "walk" up and
down the list of buffers shown in the catalog by using <C-N> (or <SPACE>) /
<C-P> (or <C-SPACE>). These keys select the next/previous buffer in succession,
respectively, opening it for preview without leaving the buffer catalog
viewer.

The buffer opening commands follow that of NERDTree. Examples:

    - Use movement keys (h,j,k,l) to select a buffer from the list, then type
      <CR> or "o" to open it in the previous window.
    - Type "42" and <CR> or "o" to open buffer number 42 in the previous
      window.
    - You can use "go" to open the currently selected buffer in the previous
      window, but with focus remaining in the buffer catalog ("42go" will do
      the same, but will select buffer number 42).
    - You can use "s" to open the currently selected buffer in new vertical
      split. "S" will open the buffer in a new vertical split, but keep the
      focus in the buffer catalog.  ("42s" or "42S" will do the same, but will
      select buffer number 42)
    - You can use "i" to open the currently selected buffer in new horizontal
      split. "I" will open the buffer in a new vertical split, but keep the
      focus in the buffer catalog.  ("42i" or "42I" will do the same, but will
      select buffer number 42)
    - You can use "t" to open the currently selected buffer in new tab ("42t"
      will do the same, but will select buffer number 42).

To reduce strain on muscle-memory, the following Ctrl-P keymaps are also
supported:

   - <C-V> : open in new vertical split
   - <C-S> : open in new horizontal split
   - <C-T> : open in new tab

Other key maps allow you to jump to a target buffer in an open
window/split/tab page if it is already active there instead of creating a new
window. Minimal management of buffers (wiping/dropping) are also provided.

Buffergator also provides a way to list tab pages and buffers associated with
windows in tab pages (the "tab page catalog", which can be invoked using the
command ":BuffergatorTabsOpen" or the provided key mapping, "<Leader>t").

The buffer listing can be sorted alphabetically by filename, by full filepath,
by extension followed by filename, or by most-recently used (MRU).

By default, Buffergator provides global key maps that invoke its main commands:
"<Leader>b" to open and "<Leader>B" to close the buffer catalog, and
"<Leader>t" to open and "<Leader>T" to close the tab page catalog.  In
addition, in normal mode from any buffer, you can flip through the MRU
(most-recently-used) buffer list without opening the buffer catalog by using
the "[b" (or <M-b>) and "]b" (or <M-S-b>) keys.  If you prefer to map other
keys, or do not want any keys mapped at all, set
"g:buffergator_suppress_keymaps" to 1 in your $VIMRUNTIME.

[NOTE: If you have other plugins installed that have key maps that start with
"<Leader>b" (e.g., BufExplorer, which uses "<Leader>bs", "<Leader>bv", etc.),
then you may notice a slight delay or lag when typing the default "<Leader>b"
to start Buffergator. In this case, you should either use another keymap for
Buffergator or BufExplorer.]

Detailed usage description given in the help file, which can be viewed on-line
here:

    http://github.com/jeetsukumaran/vim-buffergator/blob/master/doc/buffergator.txt

Source code repository can be found here:

    http://github.com/jeetsukumaran/vim-buffergator

NOTE: There are many other plugins that provide similar functionality. This
plugin is very much in the "BufExplorer" and "SelectBuf" vein, in that it
provides a full-window buffer "view" of the buffers. I wanted a plugin that (a)
listed the loaded buffers in a (optionally-)persistant "drawer", (b) allowed me
to preview buffers without leaving the drawer, and (c) allowed me to walk up
and down the list of buffers, previewing them, but without leaving the drawer.
None of the existing plugins did this (as far as I know), and hence I rolled
out this one. The other plugins provide more functionality with respect to
other operations (e.g., buffer management), that I did not have an immediate
need for, so I did not incorporate it into this plugin.

