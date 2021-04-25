vim9script

var initialized: bool = false


# Extend dictionaries recursively.
def Extend(base: dict<any>, merge: dict<any>, mode: string = 'force')
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


def Init()
  import default_config from 'qline/config/default.vim'

  if !exists('g:qline_config')
    g:qline_config = {}
  endif

  g:qline_config->Extend(default_config, 'keep')
  initialized = true
enddef


export def Get(query: string, mode: string = ''): any
  if !initialized
    Init()
  endif

  var varname: string

  if !!mode
    varname = 'g:qline_config.' .. mode .. '.' .. query

    if exists(varname)
      return eval(varname)
    endif

    if mode !=# 'inactive'
      varname = 'g:qline_config.active.' .. query

      if exists(varname)
        return eval(varname)
      endif
    endif
  endif

  varname = 'g:qline_config.' .. query

  if exists(varname)
    return eval(varname)
  endif

  return v:null
enddef


export def Set(new_config: dict<any>)
  if !exists('g:qline_config')
    g:qline_config = {}
  endif

  g:qline_config->Extend(new_config)
enddef


# vim: et sw=2 sts=-1 cc=+1
