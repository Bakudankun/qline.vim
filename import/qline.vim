vim9script

import Get from './qline/config.vim'

const left = 'left'
const right = 'right'

const mode_strings: dict<string> = {
  n:          'normal',
  v:          'visual',
  V:          'visual',
  ["\<C-V>"]: 'visual',
  s:          'visual',
  S:          'visual',
  ["\<C-S>"]: 'visual',
  i:          'insert',
  R:          'replace',
  t:          'terminal',
  c:          'commandline',
}


export def Statusline(): string
  :doautocmd <nomodeline> User QlineUpdate

  import GetHighlight from './qline/colorscheme.vim'

  g:actual_curbuf = bufnr()
  g:actual_curwin = win_getid()

  const winid: number = g:->get('statusline_winid', g:actual_curwin)
  const type: string = winid == g:actual_curwin ? 'active' : 'inactive'
  const mode: string = type ==# 'inactive' ? 'inactive'
    : mode_strings->get(mode(), 'normal')

  final statusline: dict<string> = {left: '', right: ''}
  const margin: string = Get('separator.margin', mode)

  for side in [left, right]
    final components: list<dict<any>> = WinCall(winid, function(GetComponents, [mode, side]))

    if !components
      continue
    endif

    if side ==# right
      components->reverse()
    endif

    const separator: string = Get('separator.' .. side, mode)
    var subseparator: string = side ==# left ? Get('subseparator.' .. side, mode)
                                             : Get('subseparator.' .. side, mode)
    const submargin: string = Get('subseparator.margin', mode)
    if side ==# left
      if submargin ==# 'INSIDE' || submargin ==# 'RIGHT'
        subseparator = subseparator .. ' '
      elseif submargin ==# 'OUTSIDE' || submargin ==# 'LEFT'
        subseparator = ' ' .. subseparator
      else
        subseparator = submargin .. subseparator .. submargin
      endif
    else
      if submargin ==# 'OUTSIDE' || submargin ==# 'RIGHT'
        subseparator = subseparator .. ' '
      elseif submargin ==# 'INSIDE' || submargin ==# 'LEFT'
        subseparator = ' ' .. subseparator
      else
        subseparator = submargin .. subseparator .. submargin
      endif
    endif

    for index in range(len(components))
      statusline[side] = statusline[side] .. components[index].content

      if index >= len(components) - 1
        break
      endif

      const current_hl = components[index].highlight
      const next_hl = components[index + 1].highlight

      if current_hl !=# next_hl
        const highlighted_separator: string = !separator ? GetHighlight(mode, next_hl) :
          (side ==# left ? GetHighlight(mode, current_hl, next_hl)
                         : GetHighlight(mode, next_hl, current_hl)) .. separator .. GetHighlight(mode, next_hl)
        if side ==# left
          if margin ==# 'INSIDE' || margin ==# 'RIGHT'
            statusline[side] = statusline[side] .. highlighted_separator .. ' '
          elseif margin ==# 'OUTSIDE' || margin ==# 'LEFT'
            statusline[side] = statusline[side] .. ' ' .. highlighted_separator
          else
            statusline[side] = statusline[side] .. margin .. highlighted_separator .. margin
          endif
        else
          if margin ==# 'OUTSIDE' || margin ==# 'RIGHT'
            statusline[side] = statusline[side] .. highlighted_separator .. ' '
          elseif margin ==# 'INSIDE' || margin ==# 'LEFT'
            statusline[side] = statusline[side] .. ' ' .. highlighted_separator
          else
            statusline[side] = statusline[side] .. margin .. highlighted_separator .. margin
          endif
        endif
      else
        statusline[side] = statusline[side] .. subseparator
      endif
    endfor

    const globmargin: string = margin =~# '\v^(INSIDE|OUTSIDE|LEFT|RIGHT)$' ? ' ' : margin
    statusline[side] = GetHighlight(mode, components[0].highlight) .. globmargin ..
                       statusline[side] .. globmargin

    if !!separator && components->len() > 0
      if side ==# left
        statusline[side] = statusline[side] .. GetHighlight(mode, components[-1].highlight, 'middle') .. separator
      else
        statusline[side] = GetHighlight(mode, components[0].highlight, 'middle') .. separator .. statusline[side]
      endif
    endif
  endfor

  return statusline.left .. GetHighlight(mode, 'middle') .. '%=' .. statusline.right
enddef


def GetComponents(mode: string, side: string): list<dict<any>>
  return Get(side, mode)
    ->deepcopy()
    ->map((tier, list) => list->map((_, name) => GetComponent(name, side .. tier)))
    ->flatten()
    ->filter((_, val) => !!val)
enddef


def GetComponent(name: string, highlight: string): dict<any>
  import ColorExists from './qline/colorscheme.vim'

  const content: string = name->GetComponentContent()
  if !content
    return {}
  endif

  const component = Get('component.' .. name)
  if component->type() != v:t_dict
    return {content: content, highlight: highlight}
  endif

  final ret = component->deepcopy()
  ret.content = content
  if !ret->has_key('highlight') || !ColorExists(ret.highlight)
    ret.highlight = highlight
  endif

  return ret
enddef


export def GetComponentContent(name: string): string
  const components: dict<any> = Get('component')

  if !components->has_key(name)
    return name =~# '^\s*%' ? name : ''
  endif

  const Component = components[name]

  if type(Component) == v:t_string
    return Component
  elseif type(Component) == v:t_func
    return '' .. Component()
  elseif type(Component) == v:t_dict
    var visible: bool = false
    if !Component->has_key('visible_condition')
      # Assume the component is always visible if visible_condition is not set.
      visible = true
    elseif type(Component.visible_condition) == v:t_func
      try
        visible = !!Component.visible_condition()
      catch
        return '#ERROR#'
      endtry
    else
      visible = !!Component.visible_condition
    endif

    if !visible
      return ''
    endif

    var content: string = ''

    if type(Component.content) == v:t_string
      content = Component.content
    elseif type(Component.content) == v:t_func
      try
        content = '' .. Component.content()
      catch
        return '#ERROR#'
      endtry
    endif

    if !!Component->get('escape')
      return content->substitute('%', '%%', 'g')
    endif

    return content
  endif

  return ''
enddef


var win_call_ret: any = 0
var WinCallFunc: func
def WinCall(winid: number, Func: func): any
  if winid == g:actual_curwin
    return Func()
  endif
  WinCallFunc = Func
  win_execute(winid, 's:win_call_ret = s:WinCallFunc()')
  return win_call_ret
enddef


# vim: et sw=2 sts=-1 cc=+1
