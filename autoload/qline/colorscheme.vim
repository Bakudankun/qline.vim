vim9script

import '../../private/qline/colorscheme.vim'


export def Set(name: string)
  colorscheme.Set(name)
enddef


export def GetList(argLead: string,
                   cmdLine: string,
                   cursorPos: number): string
  return (globpath(&runtimepath, 'autoload/qline/colorscheme/*.vim', 1, 1)
      ->map((_, val) => val->fnamemodify(':t:r'))
    + globpath(&runtimepath, 'autoload/lightline/colorscheme/*.vim', 1, 1)
      ->map((_, val) => 'lightline:' .. val->fnamemodify(':t:r'))
    + globpath(&runtimepath, 'autoload/airline/themes/*.vim', 1, 1)
      ->map((_, val) => 'airline:' .. val->fnamemodify(':t:r')))
    ->join("\n")
enddef


export def Reset()
  colorscheme.ResetHighlight()
enddef


# vim: et sw=2 sts=-1 cc=+1
