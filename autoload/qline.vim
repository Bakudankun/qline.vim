vim9script

import autoload '../private/qline/statusline.vim'
import autoload '../private/qline/colorscheme.vim'


export def Enable()
  set laststatus=2
  set statusline=%{%qline#Statusline()%}

  DefineAutocmd()
enddef


export def DefineAutocmd()
  augroup qline
    autocmd!
    autocmd ColorScheme * colorscheme.ResetHighlight()
  augroup END
enddef


export def Disable()
  set statusline=
  autocmd! qline
  colorscheme.ResetHighlight()
enddef


export def Statusline(): string
  return statusline.Statusline()
enddef


# vim: et sw=2 sts=-1 cc=+1
