vim9script

import GetWinVar from './util.vim'

let initialized: bool = false


# Extend dictionaries recursively.
def Extend(base: dict<any>, merge: dict<any>, mode: string = 'force')
  for key in keys(merge)
    if !base->has_key(key)
      base[key] = merge[key]->deepcopy()
      continue
    endif

    if type(base[key]) == v:t_dict && type(merge[key]) == v:t_dict
      base[key]->Extend(merge[key], mode)
      continue
    endif

    if mode ==# 'force'
      base[key] = merge[key]->deepcopy()
    endif
  endfor
enddef


def Init()
  def Mode_Content(winid: number): string
    let mode_map: dict<string> = Get('mode_map')
    let mode_char: string = mode(1)
    if mode_map->has_key(mode_char)
      return mode_map[mode_char]
    endif

    mode_char = mode_char[0]
    if mode_char ==# 'c'
      mode_char = getcmdtype()
    endif
    return Get('mode_map')->get(mode_char, '')
  enddef

  def SearchCount_Content(winid: number): string
    let result: dict<number> = searchcount(#{recompute: true})
    if !result
      return ''
    endif
    if result.incomplete == 1     # timed out
      return printf('/%s [?/??]', @/)
    elseif result.total <= 0      # no match
      return ''
    elseif result.incomplete == 2 # max count exceeded
      if result.total > result.maxcount && result.current > result.maxcount
        return printf('/%s [>%d/>%d]', @/, result.maxcount, result.maxcount)
      elseif result.total > result.maxcount
        return printf('/%s [%d/>%d]', @/, result.current, result.maxcount)
      endif
    endif
    return printf('/%s [%d/%d]', @/, result.current, result.total)
  enddef

  let default_config = #{
    manual: false,
    active: #{
      left: [
        ['mode', 'paste'],
        ['filename'],
        ['readonly', 'modified'],
      ],
      right: [
        ['lineinfo'],
        ['percent'],
        ['filetype', 'fileencoding', 'fileformat'],
      ],
    },
    inactive: #{
      left: [
        ['filename'],
      ],
      right: [
        ['lineinfo'],
        ['percent'],
      ],
    },
    tabline: #{
      left: [['tabs']],
      right: [['close']],
    },
    component: #{
      mode: #{
        content: Mode_Content,
      },
      absolutepath: #{
        content: '%F',
      },
      relativepath: #{
        content: '%f',
      },
      filename: #{
        content: '%t',
      },
      modified: #{
        content: '%M',
        visible_condition: {winid -> GetWinVar('&modified') || !GetWinVar('&modifiable')},
      },
      keymap: #{
        content: '%k',
        visible_condition: {winid -> GetWinVar('&keymap')},
      },
      bufnum: #{
        content: '%n',
      },
      paste: #{
        content: 'PASTE',
        visible_condition: {winid -> &paste},
        highlight: 'paste',
      },
      readonly: #{
        content: '%R',
        visible_condition: {winid -> GetWinVar('&readonly')},
      },
      charvalue: #{
        content: '%b',
      },
      charvaluehex: #{
        content: '%B',
      },
      fileencoding: #{
        content: '%{&fenc ==# "" ? &enc : &fenc}',
      },
      fileformat: #{
        content: '%{&ff}',
      },
      filetype: #{
        content:  '%{&ft ==# "" ? "no ft" : &ft}',
      },
      percent: #{
        content: '%3p%%',
      },
      percentwin: #{
        content: '%P',
      },
      spell: #{
        content: '%{&spelllang}',
        visible_condition: {winid -> GetWinVar('&spell') && GetWinVar('&spelllang')},
      },
      lineinfo: #{
        content: '%3l:%-2v',
      },
      line: #{
        content: '%l',
      },
      column: #{
        content: '%c',
      },
      close: #{
        content: '%999X X ',
      },
      winnr: #{
        content: '%{winnr()}',
      },
      truncation: #{
        content: '%<',
        raw: true,
      },
      searchcount: #{
        content: SearchCount_Content,
        visible_condition: {winid -> v:hlsearch},
      },
    },
    colorscheme: 'default',
    separator: #{
      left: '',
      right: '',
      margin: ' ',
    },
    subseparator: #{
      left: ' | ',
      right: ' | ',
      margin: '',
    },
    mode_map: {
      'n':      'NORMAL',
      'niI':    'I-NORMAL',
      'niR':    'R-NORMAL',
      'niV':    'R-NORMAL',
      'v':      'VISUAL',
      'V':      'V-LINE',
      "\<C-V>": 'V-BLOCK',
      's':      'SELECT',
      'S':      'S-LINE',
      "\<C-S>": 'S-BLOCK',
      'i':      'INSERT',
      'R':      'REPLACE',
      't':      'TERMINAL',
      ':':      'COMMAND',
      '>':      'DEBUG',
      '/':      'SEARCH',
      '?':      'SEARCH',
      '@':      'PROMPT',
      '-':      'EX-INSERT',
      '=':      'EXPR',
    },
  }


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

  if mode
    let varname: string = 'g:qline_config.' .. mode .. '.' .. query

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

  let varname = 'g:qline_config.' .. query

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
