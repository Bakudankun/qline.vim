vim9script

import Get from './qline/config.vim'

const left = 'left'
const right = 'right'

const mode_strings: dict<string> = {
  'n':      'normal',
  'v':      'visual',
  'V':      'visual',
  "\<C-V>": 'visual',
  's':      'visual',
  'S':      'visual',
  "\<C-S>": 'visual',
  'i':      'insert',
  'R':      'replace',
  't':      'terminal',
  'c':      'commandline',
}


export def Statusline(): string
  :doautocmd User QlineUpdate

  import GetHighlight from './qline/colorscheme.vim'

  g:actual_curbuf = bufnr()
  g:actual_curwin = win_getid()

  const type: string = g:statusline_winid == win_getid() ? 'active' : 'inactive'
  const mode: string = type ==# 'inactive' ? 'inactive'
    : mode_strings->get(mode(), 'normal')

  final statusline: dict<string> = {left: '', right: ''}
  const margin: string = Get('separator.margin', mode)

  for side in [left, right]
    const components_list: list<list<string>> = Get(side, mode)
    final components: list<dict<any>> = []
    for tier in range(len(components_list))
      for name in components_list[tier]
        components->add(GetComponent(name, side .. tier))
      endfor
    endfor

    components->filter({_, val -> val})

    # # Closure in closure does not work for now.
    # const components: list<dict<any>> = Get(side, mode)
    #   ->deepcopy()
    #   ->map({tier, list -> list->map({_, name -> GetComponent(name, side .. tier)})})
    #   ->flatten()
    #   ->filter({_, val -> val})

    if !components
      continue
    endif

    if side ==# right
      components->reverse()
    endif

    const separator: string = Get('separator.' .. side, mode)
    const subseparator: string = Get('subseparator.margin', mode) ..
                                 Get('subseparator.' .. side, mode) ..
                                 Get('subseparator.margin', mode)

    for index in range(len(components))
      statusline[side] = statusline[side] .. components[index].content

      if index >= len(components) - 1
        break
      endif

      const current_hl = components[index].highlight
      const next_hl = components[index + 1].highlight

      if current_hl !=# next_hl
        const actual_separator: string = separator &&
          (side ==# left ? GetHighlight(mode, current_hl, next_hl)
                         : GetHighlight(mode, next_hl, current_hl)) .. separator
        statusline[side] = statusline[side] .. margin .. actual_separator ..
                           GetHighlight(mode, next_hl) .. margin
      else
        statusline[side] = statusline[side] .. subseparator
      endif
    endfor

    statusline[side] = GetHighlight(mode, components[0].highlight) .. margin ..
                       statusline[side] .. margin

    if separator && components->len() > 0
      if side ==# left
        statusline[side] = statusline[side] .. GetHighlight(mode, components[-1].highlight, 'middle') .. separator
      else
        statusline[side] = GetHighlight(mode, components[0].highlight, 'middle') .. separator .. statusline[side]
      endif
    endif
  endfor

  return statusline.left .. GetHighlight(mode, 'middle') .. '%=' .. statusline.right
enddef


def GetComponent(name: string, highlight: string): dict<any>
  import ColorExists from './qline/colorscheme.vim'

  const content: string = name->GetComponentContent()
  if !content
    return {}
  endif

  const component = Get('component.' .. name)
  if component->type() != v:t_dict
    return #{content: content, highlight: highlight}
  endif

  final ret = component->deepcopy()
  ret['content'] = content
  if !ret->has_key('highlight') || !ColorExists(ret.highlight)
    ret['highlight'] = highlight
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
    return '' .. WinCall(Component)
  elseif type(Component) == v:t_dict
    var visible: bool = false
    if !Component->has_key('visible_condition')
      # Assume the component is always visible if visible_condition is not set.
      visible = true
    elseif type(Component.visible_condition) == v:t_func
      try
        visible = !!WinCall(Component.visible_condition)
      catch
        return '#ERROR#'
      endtry
    else
      visible = !!Component.visible_condition
    endif

    if !visible
      return ''
    endif

    if type(Component.content) == v:t_string
      return Component.content
    elseif type(Component.content) == v:t_func
      try
        return '' .. WinCall(Component.content)
      catch
        return '#ERROR#'
      endtry
    endif
  endif

  return ''
enddef


var win_call_ret: any = 0
var WinCallFunc: func
def WinCall(Func: func): any
  WinCallFunc = Func
  win_execute(g:statusline_winid, 's:win_call_ret = s:WinCallFunc()')
  return win_call_ret
enddef


# vim: et sw=2 sts=-1 cc=+1
