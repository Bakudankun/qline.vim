vim9script

import 'qline/config.vim'


def Mode_Content(): string
  const mode_map: dict<string> = config.Get('mode_map')
  var mode_char: string = mode(1)
  if mode_map->has_key(mode_char)
    return mode_map[mode_char]
  endif

  mode_char = mode_char[0]
  if mode_char ==# 'c'
    mode_char = getcmdtype()
  endif
  return config.Get('mode_map')->get(mode_char, '')
enddef


def SearchCount_Content(): string
  const result: dict<number> = searchcount({recompute: true})
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


const g:qline#preset#default#config: dict<any> = {
  manual: false,
  active: {
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
  inactive: {
    left: [
      ['filename'],
    ],
    right: [
      ['lineinfo'],
      ['percent'],
    ],
  },
  tabline: {
    left: [['tabs']],
    right: [['close']],
  },
  component: {
    mode: {
      content: Mode_Content,
    },
    absolutepath: {
      content: '%F',
    },
    relativepath: {
      content: '%f',
    },
    filename: {
      content: '%t',
    },
    modified: {
      content: '%M',
      visible_condition: () => &modified || !&modifiable,
    },
    keymap: {
      content: '%k',
      visible_condition: () => !!&keymap,
    },
    bufnum: {
      content: '%n',
    },
    paste: {
      content: 'PASTE',
      visible_condition: () => &paste,
      highlight: 'paste',
    },
    readonly: {
      content: '%R',
      visible_condition: () => &readonly,
    },
    charvalue: {
      content: '%b',
    },
    charvaluehex: {
      content: '%B',
    },
    fileencoding: {
      content: () => &fenc ?? &enc,
    },
    fileformat: {
      content: () => &ff,
    },
    filetype: {
      content:  () => &ft ?? "no ft",
    },
    percent: {
      content: '%3p%%',
    },
    percentwin: {
      content: '%P',
    },
    spell: {
      content: () => &spelllang,
      visible_condition: () => &spell && !!&spelllang,
    },
    lineinfo: {
      content: '%3l:%-2v',
    },
    line: {
      content: '%l',
    },
    column: {
      content: '%c',
    },
    close: {
      content: '%999X X ',
    },
    winnr: {
      content: () => winnr(),
    },
    truncation: {
      content: '%<',
      raw: true,
    },
    searchcount: {
      content: SearchCount_Content,
      visible_condition: () => v:hlsearch,
    },
  },
  colorscheme: 'default',
  separator: {
    left: '',
    right: '',
    margin: ' ',
  },
  subseparator: {
    left: ' | ',
    right: ' | ',
    margin: '',
  },
  mode_map: {
    n:          'NORMAL',
    niI:        'I-NORMAL',
    niR:        'R-NORMAL',
    niV:        'R-NORMAL',
    v:          'VISUAL',
    V:          'V-LINE',
    ["\<C-V>"]: 'V-BLOCK',
    s:          'SELECT',
    S:          'S-LINE',
    ["\<C-S>"]: 'S-BLOCK',
    i:          'INSERT',
    R:          'REPLACE',
    t:          'TERMINAL',
    [':']:      'COMMAND',
    ['>']:      'DEBUG',
    ['/']:      'SEARCH',
    ['?']:      'SEARCH',
    ['@']:      'PROMPT',
    ['-']:      'EX-INSERT',
    ['=']:      'EXPR',
  },
}


# vim: et sw=2 sts=-1 cc=+1
