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

Buffergator also provides a way to list tab pages and buffers associated with
windows in tab pages (the "tab page catalog", which can be invoked using the
command ":BuffergatorTabsOpen" or the provided key mapping, "<Leader>t").

By default, Buffergator provides global key maps that invoke its main
commands: "<Leader>b" to open and "<Leader>B" to close the buffer catalog, and
"<Leader>t" to open and "<Leader>T" to close the tab page catalog. If you
prefer to map other keys, or do not want any keys mapped at all, set
"g:buffergator_suppress_keymaps" to 1 in your $VIMRUNTIME.

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

