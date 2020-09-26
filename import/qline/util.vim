vim9script


export def GetWinVar(name: string, def: any = ''): any
  return g:->get('statusline_winid')->getwinvar(name, def)
enddef


export def GetBufVar(name: string, def: any = ''): any
  return g:->get('statusline_winid')->winbufnr()->getbufvar(name, def)
enddef


let win_eval_ret: any = 0
export def WinEval(expr: string): any
  let curwin = win_getid()

  if g:->get('statusline_winid', curwin) == curwin
    return eval(expr)
  endif

  win_execute(g:statusline_winid, 's:win_eval_ret = eval(' .. string(expr) .. ')')

  return win_eval_ret
enddef


export def Component(name: string): string
  import GetComponentContent from '../qline.vim'
  return GetComponentContent(name)
enddef


# vim: et sw=2 sts=-1 cc=+1
