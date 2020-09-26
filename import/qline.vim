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

  const type: string = g:statusline_winid == win_getid() ? 'active' : 'inactive'
  const mode: string = type ==# 'inactive' ? 'inactive'
    : mode_strings->get(mode(), 'normal')

  let statusline: dict<string> = {left: '', right: ''}
  const margin: string = Get('separator.margin', mode)

  for side in [left, right]
    let components_list: list<list<string>> = Get(side, mode)
    let components: list<dict<any>> = []
    for tier in range(len(components_list))
      for name in components_list[tier]
        components->add(GetComponent(name, side .. tier))
      endfor
    endfor

    components->filter({_, val -> val})

    # # Closure in closure does not work for now.
    # let components: list<dict<any>> = Get(side, mode)
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

      let current_hl = components[index].highlight
      let next_hl = components[index + 1].highlight

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

  let content: string = name->GetComponentContent()
  if !content
    return {}
  endif

  let component = Get('component.' .. name)
  if component->type() != v:t_dict
    return #{content: content, highlight: highlight}
  endif

  let ret = component->deepcopy()
  ret['content'] = content
  if !ret->has_key('highlight') || !ColorExists(ret.highlight)
    ret['highlight'] = highlight
  endif

  return ret
enddef


export def GetComponentContent(name: string): string
  let components: dict<any> = Get('component')

  if !components->has_key(name)
    return name =~# '^\s*%' ? name : ''
  endif

  const Component = components[name]

  if type(Component) == v:t_string
    return Component
  elseif type(Component) == v:t_func
    return '' .. Component(g:statusline_winid)
  elseif type(Component) == v:t_dict
    let visible: bool = false
    if !Component->has_key('visible_condition')
      # Assume the component is always visible if visible_condition is not set.
      visible = true
    elseif type(Component.visible_condition) == v:t_func
      try
        visible = !!Component.visible_condition(g:statusline_winid)
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
        return '' .. Component.content(g:statusline_winid)
      catch
        return '#ERROR#'
      endtry
    endif
  endif

  return ''
enddef


# vim: et sw=2 sts=-1 cc=+1
