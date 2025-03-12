vim9script

import autoload 'qline/config.vim'


final palettes: dict<dict<dict<dict<any>>>> = {}
var current_colorscheme: string = ''
var defined_highlights: list<string> = []


export def GetHighlight(mode: string,
                        tier: string,
                        nexttier: string = ''): string
  const name = GetHighlightName(mode, tier, nexttier)

  if defined_highlights->index(name) < 0
    DefineHighlight(mode, tier, nexttier)
  endif

  return $'%#{name}#'
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
  defined_highlights = []
enddef


export def ColorExists(name: string): bool
  const palette = GetPalette()
  return !!palette && palette.normal->has_key(name) || hlexists(name)
enddef


export def GetList(argLead: string,
                   cmdLine: string,
                   cursorPos: number): string
  return (globpath(&runtimepath, 'autoload/qline/colorscheme/*.vim', 1, 1)
      ->map((_, val) => val->fnamemodify(':t:r'))
    + globpath(&runtimepath, 'autoload/lightline/colorscheme/*.vim', 1, 1)
      ->map((_, val) => 'lightline:' .. val->fnamemodify(':t:r'))
    + globpath(&runtimepath, 'autoload/airline/themes/*.vim', 1, 1)
      ->map((_, val) => 'airline:' .. val->fnamemodify(':t:r')))
    ->join("\n")
enddef


def GetPalette(): dict<dict<dict<any>>>
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
  var palette: dict<dict<dict<any>>>
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


def GetOriginalPalette(name: string): dict<dict<dict<any>>>
  try
    return eval($'g:qline#colorscheme#{name}#palette')->deepcopy()
  catch
    throw $'qline.vim: ERROR: Palette "{name}" not found.'
  endtry
  return {}
enddef


def ConvertAirlinePalette(name: string): dict<dict<dict<any>>>
  final ret: dict<dict<dict<any>>> = {}
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
      }->deepcopy()->filter((_, v) => !!v)->map((_, v) => {
        final color: dict<any> = {guifg: v[0], guibg: v[1], ctermfg: v[2], ctermbg: v[3]}
        if len(v) > 4
          color.term  = v[4]->split(',')->reduce((acc, val) => acc->extend({[val]: true}), {})
          color.cterm = color.term
          color.gui   = color.term
        endif
        return color
      }))
    ret[modename].middle = {
      guifg:   ret[modename].left2.guibg,
      guibg:   ret[modename].left2.guibg,
      ctermfg: ret[modename].left2.ctermbg,
      ctermbg: ret[modename].left2.ctermbg,
    }
    if modename !=# 'inactive' && !ret[modename].left0->has_key('term')
      ret[modename].left0.term  = {bold: true}
      ret[modename].left0.cterm = {bold: true}
      ret[modename].left0.gui   = {bold: true}
    endif
  endfor
  return ret
enddef


def GetAirlinePalette(name: string): dict<dict<list<string>>>
  try
    return eval($'g:airline#themes#{name}#palette')
      ->mapnew((_, category) => category
        ->mapnew((_, section) => section
          ->mapnew((_, val) => $'{val}')))
  catch
    throw $'qline.vim: ERROR: Airline palette "{name}" not found.'
  endtry
  return {}
enddef


def ConvertLightlinePalette(name: string): dict<dict<dict<any>>>
  final ret: dict<dict<dict<any>>> = {}
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
        const color: list<string> = side[0]
        ret[modename][sidename] = {guifg: color[0], guibg: color[1], ctermfg: color[2], ctermbg: color[3]}
        final item = ret[modename][sidename]
        if len(color) > 4
          item.term = color[4]->split(',')->reduce((acc, val) => acc->extend({[val]: true}), {})
          item.cterm = item.term->copy()
          item.gui = item.term->copy()
        endif
        continue
      endif

      for idx in range(min([3, len(side)]))
        const color: list<string> = side[idx]
        ret[modename][sidename .. idx] = {guifg: color[0], guibg: color[1], ctermfg: color[2], ctermbg: color[3]}
        final item = ret[modename][sidename .. idx]
        if len(color) > 4
          item.term = color[4]->split(',')->reduce((acc, val) => acc->extend({[val]: true}), {})
          item.cterm = item.term->copy()
          item.gui = item.term->copy()
        endif
      endfor
    endfor
  endfor
  return ret
enddef


def GetLightlinePalette(name: string): dict<dict<list<list<string>>>>
  try
    return eval($'g:lightline#colorscheme#{name}#palette')
      ->mapnew((_, mode) => mode
        ->mapnew((_, side) => side
          ->mapnew((_, tier) => tier
            ->mapnew((_, val) => $'{val}'))))
  catch
    throw $'qline.vim: ERROR: Lightline palette "{name}" not found.'
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

  final hl: dict<any> = {}

  if !nexttier
    hl->extend(mode_palette->get(tier, mode_palette.middle)->deepcopy())
  else
    const fg = mode_palette->get(tier, mode_palette.middle)
    const bg = mode_palette->get(nexttier, mode_palette.middle)
    hl.guifg = fg.guibg
    hl.guibg = bg.guibg
    hl.ctermfg = fg.ctermbg
    hl.ctermbg = bg.ctermbg
  endif

  hl.name = GetHighlightName(mode, tier, nexttier)

  hlset([hl])

  defined_highlights->add(hl.name)
enddef


def ConvertHighlight(name: string): dict<any>
  final hl = hlget(name, true)[0]

  if hl->get('gui', {})->get('reverse', false)
    [hl.guifg, hl.guibg] = [hl.guibg, hl.guifg]
    hl.gui.reverse = false
  endif

  if hl->get('cterm', {})->get('reverse', false)
    [hl.ctermfg, hl.ctermbg] = [hl.ctermbg, hl.ctermfg]
    hl.cterm.reverse = false
  endif

  return hl
enddef


# vim: et sw=2 sts=-1 cc=+1
