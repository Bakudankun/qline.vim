vim9script

import '../../private/qline/util.vim'


var initialized: bool = false


def Init()
  if !exists('g:qline_config')
    g:qline_config = {}
  endif

  util.Extend(g:qline_config, GetPreset('default'), 'keep')
  initialized = true
enddef


export def Get(query: string, mode: string = ''): any
  if !initialized
    Init()
  endif

  const dict: string = 'g:qline_config.'
  var varname: string

  if !!mode
    varname = dict .. mode .. '.' .. query

    if exists(varname)
      return eval(varname)->deepcopy()
    endif

    if mode !=# 'inactive'
      varname = dict .. 'active.' .. query

      if exists(varname)
        return eval(varname)->deepcopy()
      endif
    endif
  endif

  varname = dict .. query

  if exists(varname)
    return eval(varname)->deepcopy()
  endif

  return v:null
enddef


export def Set(new_config: dict<any>)
  if !exists('g:qline_config')
    g:qline_config = {}
  endif

  util.Extend(g:qline_config, new_config)
enddef


def GetPreset(name: string): dict<any>
  return eval('g:qline#preset#' .. name .. '#config')
enddef


# vim: et sw=2 sts=-1 cc=+1
