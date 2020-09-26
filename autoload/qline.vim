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
    autocmd SafeState * OnSafeState()
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


let wascmdline: bool = false
export def OnSafeState()
  # Redraw statusline on entering commandline.
  # Using CmdlineEnter has side effect that clears command output when
  # entering command line mode in succession.
  let iscmdline: bool = mode() ==# 'c'
  if iscmdline && !wascmdline
    redrawstatus
  endif
  wascmdline = iscmdline
enddef


# vim: et sw=2 sts=-1 cc=+1
