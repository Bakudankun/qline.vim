vim9script

if g:->get('loaded_qline')
  finish
endif

if v:version < 802
  echoerr "qline.vim requires Vim version 9.0+."
  finish
endif


command -nargs=1 -complete=custom,qline#colorscheme#get_list
      \ QlineColorscheme qline#colorscheme#set(<q-args>)


augroup qline-dummy
  autocmd!
  autocmd User QlineUpdate :
augroup END


if exists('g:qline_config.manual') && g:qline_config.manual
  finish
endif


if v:vim_did_enter
  qline#enable()
else
  augroup qline-vimenter
    autocmd!
    autocmd VimEnter * ++once qline#enable()
  augroup END
endif


# vim: et sw=2 sts=-1 cc=+1
