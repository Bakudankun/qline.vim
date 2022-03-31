vim9script

import autoload 'qline/config.vim'
import autoload './colorscheme.vim' as color


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

  const type: string = win_getid() == str2nr(g:actual_curwin) ?
    'active' : 'inactive'
  const mode: string = type ==# 'inactive' ?
    'inactive' : mode_strings->get(mode(), 'normal')

  final statusline: dict<string> = {left: '', right: ''}
  const margin: string = config.Get('separator.margin', mode)

  for side in [left, right]
    final components: list<dict<any>> = config.Get(side, mode)
      ->mapnew((tier, list) => list->mapnew((_, name) => GetComponent(name, side .. tier)))
      ->flattennew()
      ->filter((_, val) => !!val)

    if !components
      continue
    endif

    if side ==# right
      components->reverse()
    endif

    const separator: string = config.Get('separator.' .. side, mode)
    var subseparator: string = side ==# left ? config.Get('subseparator.' .. side, mode)
                                             : config.Get('subseparator.' .. side, mode)
    const submargin: string = config.Get('subseparator.margin', mode)
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

    var sidestr = '' # string for statusline on this side
    for index in range(len(components))
      sidestr ..= components[index].content

      if index >= len(components) - 1
        break
      endif

      const current_hl = components[index].highlight
      const next_hl = components[index + 1].highlight

      if current_hl !=# next_hl
        const highlighted_separator: string = !separator ? color.GetHighlight(mode, next_hl) :
          (side ==# left ? color.GetHighlight(mode, current_hl, next_hl)
                         : color.GetHighlight(mode, next_hl, current_hl)) .. separator .. color.GetHighlight(mode, next_hl)
        if side ==# left
          if margin ==# 'INSIDE' || margin ==# 'RIGHT'
            sidestr ..= highlighted_separator .. ' '
          elseif margin ==# 'OUTSIDE' || margin ==# 'LEFT'
            sidestr ..= ' ' .. highlighted_separator
          else
            sidestr ..= margin .. highlighted_separator .. margin
          endif
        else
          if margin ==# 'OUTSIDE' || margin ==# 'RIGHT'
            sidestr ..= highlighted_separator .. ' '
          elseif margin ==# 'INSIDE' || margin ==# 'LEFT'
            sidestr ..= ' ' .. highlighted_separator
          else
            sidestr ..= margin .. highlighted_separator .. margin
          endif
        endif
      else
        sidestr ..= subseparator
      endif
    endfor

    const globmargin: string = margin =~# '\v^(INSIDE|OUTSIDE|LEFT|RIGHT)$' ? ' ' : margin
    sidestr = color.GetHighlight(mode, components[0].highlight) .. globmargin ..
                       sidestr .. globmargin

    if !!separator && components->len() > 0
      if side ==# left
        sidestr = sidestr .. color.GetHighlight(mode, components[-1].highlight, 'middle') .. separator
      else
        sidestr = color.GetHighlight(mode, components[0].highlight, 'middle') .. separator .. sidestr
      endif
    endif

    statusline[side] = sidestr
  endfor

  return statusline.left .. color.GetHighlight(mode, 'middle') .. '%=' .. statusline.right
enddef


def GetComponent(name: string, highlight: string): dict<any>
  const content: string = name->GetComponentContent()
  if !content
    return {}
  endif

  final component = config.Get('component.' .. name)
  if component->type() != v:t_dict
    return {content: content, highlight: highlight}
  endif

  component.content = content
  if !component->has_key('highlight') || !color.ColorExists(component.highlight)
    component.highlight = highlight
  endif

  return component
enddef


def GetComponentContent(name: string): string
  const components: dict<any> = config.Get('component')

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
      if config.Get('debug.show_component_error')
        visible = !!Component.visible_condition()
      else
        try
          visible = !!Component.visible_condition()
        catch
          return ''
        endtry
      endif
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
      if config.Get('debug.show_component_error')
        content = '' .. Component.content()
      else
        try
          content = '' .. Component.content()
        catch
          return ''
        endtry
      endif
    endif

    if !!Component->get('escape')
      return content->substitute('%', '%%', 'g')
    endif

    return content
  endif

  return ''
enddef


# vim: et sw=2 sts=-1 cc=+1
