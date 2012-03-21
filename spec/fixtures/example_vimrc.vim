" don't beep
set visualbell
set noerrorbells

" NORMAL MODE - make Y consistent with D and C
nmap Y y$

" VISUAL MODE - increase / decrease indentation
xmap <TAB> >gv
xmap <S-TAB> <gv

" INSERT MODE - emacs bindings
imap <C-a> <Home>
imap <C-e> <End>
imap <C-b> <Left>
imap <C-f> <Right>

" COMMAND MODE - emacs bindings
cmap <C-a> <Home>
cmap <C-e> <End>
cmap <C-b> <Left>
cmap <C-f> <Right>
