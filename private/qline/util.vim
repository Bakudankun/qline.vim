vim9script


var win_call_ret: any
var WinCallFunc: func


# Call a function in the specified window.
# Returns its result.
export def WinCall(winid: number, Func: func): any
  if winid == g:actual_curwin
    return Func()
  endif
  WinCallFunc = Func
  win_execute(winid, 'win_call_ret = WinCallFunc()')
  return win_call_ret
enddef


# Extend dictionaries recursively. (in-place)
export def Extend(base: dict<any>, merge: dict<any>, mode: string = 'force')
  for [key, val] in items(merge)
    if !base->has_key(key)
      base[key] = val->deepcopy()
      continue
    endif

    if type(base[key]) == v:t_dict && type(val) == v:t_dict
      base[key]->Extend(val, mode)
      continue
    endif

    if mode ==# 'force'
      base[key] = val->deepcopy()
    endif
  endfor
enddef


# vim: et sw=2 sts=-1 cc=+1
