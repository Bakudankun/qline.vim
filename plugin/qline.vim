vim9script

if g:->get('loaded_qline')
  finish
endif

if v:version < 802
  echoerr "qline.vim requires Vim version 9.0+."
  finish
endif


import autoload 'qline.vim'
import autoload 'qline/config.vim'
import autoload '../private/qline/colorscheme.vim'
import autoload '../private/qline/showcase.vim'


command -nargs=? -complete=custom,colorscheme.GetList QlineColorscheme {
  if <q-args> == ''
    echo config.Get('colorscheme')
  else
    colorscheme.Set(<q-args>)
  endif
}
command QlineShowcase showcase.Start()


if exists('g:qline_config.manual') && g:qline_config.manual
  finish
endif


if v:vim_did_enter
  qline.Enable()
else
  augroup qline-vimenter
    autocmd!
    autocmd VimEnter * ++once qline.Enable()
  augroup END
endif


# vim: et sw=2 sts=-1 cc=+1
