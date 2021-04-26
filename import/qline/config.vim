vim9script

import Extend from '../../private/qline/util.vim'


var initialized: bool = false


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
      return eval(varname)->deepcopy()
    endif

    if mode !=# 'inactive'
      varname = 'g:qline_config.active.' .. query

      if exists(varname)
        return eval(varname)->deepcopy()
      endif
    endif
  endif

  varname = 'g:qline_config.' .. query

  if exists(varname)
    return eval(varname)->deepcopy()
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
