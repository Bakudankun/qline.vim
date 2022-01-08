vim9script

import 'qline/config.vim'


final palettes: dict<dict<dict<list<string>>>> = {}
var current_colorscheme: string = ''
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


export def Set(name: string)
  if name ==# current_colorscheme
    config.Set({colorscheme: name})
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
  config.Set({colorscheme: name})
enddef


export def ResetHighlight()
  defined_highlights->filter((_, _) => false)
enddef


export def ColorExists(name: string): bool
  const palette = GetPalette()
  return !!palette && palette.normal->has_key(name) || hlexists(name)
enddef


def GetPalette(): dict<dict<list<string>>>
  if palettes->has_key(current_colorscheme)
    return palettes[current_colorscheme]
  endif

  if !current_colorscheme
    Set(config.Get('colorscheme'))
  endif

  return palettes->get(current_colorscheme, {})
enddef


def GetHighlightName(mode: string,
                     tier: string,
                     nexttier: string = ''): string
  final dirs: list<string> = [mode, tier]
  if !!nexttier
    dirs->add(nexttier)
  endif

  return 'Qline_' .. dirs->join('_')
enddef


def LoadPalette(name: string)
  var palette: dict<dict<list<string>>> = {}
  if name->stridx('lightline:') == 0
    palette = ConvertLightlinePalette(name[10 : ])
  elseif name->stridx('airline:') == 0
    palette = ConvertAirlinePalette(name[8 : ])
  else
    palette = GetOriginalPalette(name)
  endif
  if !palette
    return
  endif
  palettes[name] = palette
enddef


def GetOriginalPalette(name: string): dict<dict<list<string>>>
  try
    return eval('g:qline#colorscheme#' .. name .. '#palette')->deepcopy()
  catch
    throw 'qline.vim: ERROR: Palette "' .. name .. '" not found.'
  endtry
  return {}
enddef


def ConvertAirlinePalette(name: string): dict<dict<list<string>>>
  final ret: dict<dict<list<string>>> = {}
  const palette = GetAirlinePalette(name)
  if !palette
    return ret
  endif

  for modename in ['normal', 'insert', 'visual', 'replace', 'terminal', 'commandline', 'inactive']
    ret[modename] = {}
    ret[modename] = ret.normal->deepcopy()

    if !palette->has_key(modename)
      continue
    endif

    const mode = palette[modename]

    ret[modename]->extend({
        left0:  mode->get('airline_a'),
        left1:  mode->get('airline_b'),
        left2:  mode->get('airline_c'),
        right0: mode->get('airline_z'),
        right1: mode->get('airline_y'),
        right2: mode->get('airline_x'),
      }->deepcopy()->filter((_, v) => v))
    ret[modename].middle = [
      ret[modename].left2[1],
      ret[modename].left2[1],
      ret[modename].left2[3],
      ret[modename].left2[3],
    ]
    if modename !=# 'inactive' && !ret[modename].left0->get(4)
      ret[modename].left0->insert('bold', 4)
    endif
  endfor
  return ret
enddef


def GetAirlinePalette(name: string): dict<dict<list<string>>>
  try
    return eval('g:airline#themes#' .. name .. '#palette')
      ->mapnew((_, category) => category
        ->mapnew((_, section) => section
          ->mapnew((_, val) => '' .. val)))
  catch
    throw 'qline.vim: ERROR: Airline palette "' .. name .. '" not found.'
  endtry
  return {}
enddef


def ConvertLightlinePalette(name: string): dict<dict<list<string>>>
  final ret: dict<dict<list<string>>> = {}
  const palette = GetLightlinePalette(name)
  if !palette
    return ret
  endif

  for modename in ['normal', 'insert', 'visual', 'replace', 'terminal', 'commandline', 'inactive']
    ret[modename] = {}
    ret[modename] = (modename ==# 'terminal' ? ret.insert : ret.normal)->deepcopy()

    if !palette->has_key(modename)
      continue
    endif

    for [sidename, side] in palette[modename]->items()
      if sidename !=# 'left' && sidename !=# 'right'
        ret[modename][sidename] = side[0]->copy()
        continue
      endif

      for idx in range(3)
        if idx < len(side)
          ret[modename][sidename .. idx] = side[idx]->copy()
          continue
        endif
      endfor
    endfor
  endfor
  return ret
enddef


def GetLightlinePalette(name: string): dict<dict<list<list<string>>>>
  try
    return eval('g:lightline#colorscheme#' .. name .. '#palette')
      ->mapnew((_, mode) => mode
        ->mapnew((_, side) => side
          ->mapnew((_, tier) => tier
            ->mapnew((_, val) => '' .. val))))
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

  for tiername in [tier, nexttier]->filter((_, val) => !!val)
    if mode_palette->has_key(tiername)
      continue
    endif

    if tiername =~# '^\(left\|right\)\d$'
      continue
    endif

    if !palette.normal->has_key(tiername)
      if !hlexists(tiername)
        return
      endif

      palette.normal[tiername] = ConvertHighlight(tiername)
    endif

    for color in palette->values()
      if !color->has_key(tiername)
        color[tiername] = palette.normal[tiername]
      endif
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

  :execute printf('highlight %s guifg=%s guibg=%s ctermfg=%s ctermbg=%s gui=%s term=%s cterm=%s',
                  name,
                  guifg   ?? 'NONE',
                  guibg   ?? 'NONE',
                  ctermfg ?? 'NONE',
                  ctermbg ?? 'NONE',
                  attr    ?? 'NONE',
                  attr    ?? 'NONE',
                  attr    ?? 'NONE')
  defined_highlights->add(name)
enddef


def ConvertHighlight(name: string): list<string>
  const hlid = hlID(name)
  var guifg = hlid->synIDattr('fg', 'gui')
  var guibg = hlid->synIDattr('bg', 'gui')
  var ctermfg = hlid->synIDattr('fg', 'cterm')
  var ctermbg = hlid->synIDattr('bg', 'cterm')
  const attr = ['bold', 'italic', 'standout', 'underline', 'undercurl', 'strike']
    ->map((idx, val) => !hlid->synIDattr(val) ? '' : (idx == 7 ? 'strikethrough' : val))
    ->filter((_, val) => !!val)->join(',')

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
