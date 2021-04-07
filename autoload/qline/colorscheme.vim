vim9script

import {Set as SetColorscheme, ResetHighlight} from '../../import/qline/colorscheme.vim'


def qline#colorscheme#set(name: string)
  SetColorscheme(name)
enddef


def qline#colorscheme#get_list(argLead: string,
                               cmdLine: string,
                               cursorPos: number): string
  return (globpath(&runtimepath, 'import/qline/colorscheme/*.vim', 1, 1)
      ->map((_, val) => val->fnamemodify(':t:r'))
    + globpath(&runtimepath, 'autoload/lightline/colorscheme/*.vim', 1, 1)
      ->map((_, val) => 'lightline:' .. val->fnamemodify(':t:r'))
    + globpath(&runtimepath, 'autoload/airline/themes/*.vim', 1, 1)
      ->map((_, val) => 'airline:' .. val->fnamemodify(':t:r')))
    ->join("\n")
enddef


def qline#colorscheme#reset()
  ResetHighlight()
enddef


# vim: et sw=2 sts=-1 cc=+1
