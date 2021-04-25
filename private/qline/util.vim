vim9script


export def Component(name: string): string
  import GetComponentContent from './main.vim'
  return GetComponentContent(name)
enddef


var win_call_ret: any
var WinCallFunc: func
export def WinCall(winid: number, Func: func): any
  if winid == g:actual_curwin
    return Func()
  endif
  WinCallFunc = Func
  win_execute(winid, 'win_call_ret = WinCallFunc()')
  return win_call_ret
enddef


# vim: et sw=2 sts=-1 cc=+1
