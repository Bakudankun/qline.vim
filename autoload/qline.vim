vim9script


def qline#enable()
  set laststatus=2
  set statusline=%!qline#statusline()

  qline#define_autocmd()
enddef


def qline#define_autocmd()
  augroup qline
    autocmd!
    autocmd ColorScheme * qline#colorscheme#reset()
  augroup END
enddef


def qline#disable()
  set statusline=
  autocmd! qline
  qline#colorscheme#reset()
enddef


def qline#statusline(): string
  import Statusline from '../import/qline.vim'
  return Statusline()
enddef


# vim: et sw=2 sts=-1 cc=+1
