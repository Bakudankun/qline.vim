vim9script


final palettes: dict<dict<dict<list<string>>>> = {}
final current_colorscheme: string = ''
final defined_highlights: list<string> = []


export def GetHighlight(mode: string,
                        tier: string,
                        nexttier: string = ''): string
  const name = GetHighlightName(mode, tier, nexttier)

  if defined_highlights->index(name) < 0
    DefineHighlight(mode, tier, nexttier)
  endif

  return '%#' .. name .. '#'
enddef


export def SetColorscheme(name: string)
  import Set from './config.vim'

  if name ==# current_colorscheme
    Set({colorscheme: name})
    return
  endif

  if !palettes->has_key(name)
    LoadPalette(name)

    if !palettes->has_key(name)
      return
    endif
  endif

  current_colorscheme = name
  ResetHighlight()
  Set({colorscheme: name})
enddef


export def ResetHighlight()
  defined_highlights = []
enddef


export def ColorExists(name: string): bool
  const palette = GetPalette()
  return !!palette && palette.normal->has_key(name) || hlexists(name)
enddef


def GetPalette(): dict<dict<list<string>>>
  import Get from '../qline/config.vim'
  if palettes->has_key(current_colorscheme)
    return palettes[current_colorscheme]
  endif

  if !current_colorscheme
    SetColorscheme(Get('colorscheme'))
  endif

  return palettes->get(current_colorscheme, {})
enddef


def GetHighlightName(mode: string,
                     tier: string,
                     nexttier: string = ''): string
  final dirs: list<any> = [mode, tier]
  if !!nexttier
    dirs->add(nexttier)
  endif

  return 'Qline_' .. dirs->join('_')
enddef


def LoadPalette(name: string)
  var palette: dict<dict<list<string>>> = {}
  try
    if name->stridx('lightline:') == 0
      palette = ConvertLightlinePalette(name[10:])
    elseif name->stridx('airline:') == 0
      palette = ConvertAirlinePalette(name[8:])
    elseif name ==# 'default'
      palette = GetOriginalPalette(name)
    endif
  catch
    # TODO: try-catch does not work for now.
  endtry
  if !palette
    echoerr 'qline.vim: ERROR: colorscheme' name 'not found.'
    return
  endif
  palettes[name] = palette
enddef


def GetOriginalPalette(name: string): dict<dict<list<string>>>
  import palette from 'qline/colorscheme/default.vim'
  # TODO: importing from dynamic path is not implemented yet.
  return palette->deepcopy()
enddef


def ConvertAirlinePalette(name: string): dict<dict<list<string>>>
  final ret: dict<dict<list<string>>> = {}
  const palette = GetAirlinePalette(name)
  if !palette
    return ret
  endif

  for category in ['normal', 'inactive', 'replace', 'commandline', 'visual', 'terminal', 'insert']
    if !palette->has_key(category)
      ret[category] = ret.normal
      continue
    endif
    ret[category] = {
      left0:  palette[category]->get('airline_a', palette.normal.airline_a)->copy(),
      left1:  palette[category]->get('airline_b', palette.normal.airline_b)->copy(),
      left2:  palette[category]->get('airline_c', palette.normal.airline_c)->copy(),
      right0: palette[category]->get('airline_z', palette.normal.airline_z)->copy(),
      right1: palette[category]->get('airline_y', palette.normal.airline_x)->copy(),
      right2: palette[category]->get('airline_x', palette.normal.airline_y)->copy(),
    }
    (ret[category])->extend({middle: [
      ret[category].left2[1],
      ret[category].left2[1],
      ret[category].left2[3],
      ret[category].left2[3],
    ]})
    if category !=# 'inactive' && !ret[category].left0->get(4)
      (ret[category].left0)->insert('bold', 4)
    endif
  endfor
  return ret
enddef


def GetAirlinePalette(name: string): dict<dict<list<string>>>
  try
    return eval('g:airline#themes#' .. name .. '#palette')->deepcopy()
      ->map({_, category -> category->map({_, section -> section->map({_, val -> '' .. val})})})
  catch
    throw 'qline.vim: ERROR: Airline palette "' .. name .. '" not found.'
  endtry
  return {}
enddef


def ConvertLightlinePalette(name: string): dict<dict<list<string>>>
  final ret: dict<dict<list<string>>> = {}
  const palette: dict<dict<list<list<string>>>> = GetLightlinePalette(name)
  if !palette
    return ret
  endif
  for modename in ['normal', 'insert', 'visual', 'replace', 'terminal', 'commandline', 'inactive']
    ret[modename] = {}
    const fallback: dict<list<string>> = modename ==# 'terminal'
                                       ? ret.insert : ret.normal

    if !palette->has_key(modename)
      ret[modename] = fallback
      continue
    endif

    ret[modename] = fallback->copy()

    const mode = palette[modename]

    for sidename in mode->keys()
      const side = mode[sidename]
      if sidename !=# 'left' && sidename !=# 'right'
        (ret[modename])->extend({[sidename]: side[0]})
        continue
      endif

      for idx in range(3)
        if idx < len(side)
          (ret[modename])->extend({[sidename .. idx]: side[idx]})
          continue
        endif
      endfor
    endfor
  endfor
  return ret
enddef


def GetLightlinePalette(name: string): dict<dict<list<list<string>>>>
  try
    return eval('g:lightline#colorscheme#' .. name .. '#palette')->deepcopy()
      ->map({_, mode -> mode->map({_, side -> side->map({_, tier -> tier->map({_, val -> '' .. val})})})})
  catch
    throw 'qline.vim: ERROR: Lightline palette "' .. name .. '" not found.'
  endtry
  return {}
enddef


def DefineHighlight(mode: string,
                    tier: string,
                    nexttier: string = '')
  final palette = GetPalette()

  if !palette
    return
  endif

  const mode_palette = palette->get(mode, palette.normal)

  for color in [tier, nexttier]->filter({_, val -> !!val})
    if mode_palette->has_key(color)
      continue
    endif

    if color =~# '^\(left\|right\)\d$'
      continue
    endif

    if !palette.normal->has_key(color)
      if !hlexists(color)
        return
      endif

      (palette.normal)->extend({[color]: ConvertHighlight(color)})
    endif

    for category in palette->keys()
      palette[category]->extend({[color]: palette.normal[color]}, 'keep')
    endfor
  endfor

  var guifg = ''
  var guibg = ''
  var ctermfg = ''
  var ctermbg = ''
  var attr = ''

  if !nexttier
    const color = mode_palette->get(tier, mode_palette.middle)
    guifg = color[0]
    guibg = color[1]
    ctermfg = color[2]
    ctermbg = color[3]
    attr = color->get(4, '')
  else
    const fg = mode_palette->get(tier, mode_palette.middle)
    const bg = mode_palette->get(nexttier, mode_palette.middle)
    guifg = fg[1]
    guibg = bg[1]
    ctermfg = fg[3]
    ctermbg = bg[3]
  endif

  const name = GetHighlightName(mode, tier, nexttier)

  :execute printf('highlight %s %s %s %s %s %s',
                  name,
                  !guifg   ? '' : 'guifg=' .. guifg,
                  !guibg   ? '' : 'guibg=' .. guibg,
                  !ctermfg ? '' : 'ctermfg=' .. ctermfg,
                  !ctermbg ? '' : 'ctermbg=' .. ctermbg,
                  !attr    ? '' : 'gui=' .. attr .. ' term=' .. attr)
  defined_highlights->add(name)
enddef


def ConvertHighlight(name: string): list<string>
  const hlid = hlID(name)
  var guifg = hlid->synIDattr('fg', 'gui')
  var guibg = hlid->synIDattr('bg', 'gui')
  var ctermfg = hlid->synIDattr('fg', 'cterm')
  var ctermbg = hlid->synIDattr('bg', 'cterm')
  const attr = ['bold', 'italic', 'standout', 'underline', 'undercurl', 'strike']
    ->map({idx, val -> !hlid->synIDattr(val) ? '' : (idx == 7 ? 'strikethrough' : val)})
    ->filter({_, val -> !!val})->join(',')

  if !!hlid->synIDattr('reverse', 'gui')
    var buf = guifg
    guifg = guibg
    guibg = buf
  endif

  if !!hlid->synIDattr('reverse', 'cterm')
    var buf = ctermfg
    ctermfg = ctermbg
    ctermbg = buf
  endif

  return [guifg, guibg, ctermfg, ctermbg, attr]
enddef


# vim: et sw=2 sts=-1 cc=+1
