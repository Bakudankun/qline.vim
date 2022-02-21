# qline.vim

The quick, easily-customizable status line plugin written in the cutting-edge
Vim9 script.

![Demo](https://user-images.githubusercontent.com/4504807/96721994-db25e900-13e7-11eb-9628-0e774392227e.gif)


## Requirement

This plugin supports Vim version 9.0+. This means that currently no supported
Vim exists in the world. The very latest Vim might make use of this plugin, but
it must be a temporary illusion.

This plugin is under development along with Vim9 script, so anything can change.
Do not use this plugin regularly.


## Configuration

Every configurations are stored in a dictionary named `g:qline_config`. Its
format is like [lightline.vim](https://github.com/itchyny/lightline.vim) but
with some differences. On loading qline.vim, the dictionary will be "merged"
with the default configuration, so you can check `g:qline_config` to see the
current configuration at any time.

The default value is written [here](import/qline/config/default.vim). The
example configuration which is part of mine is in the following spoiler.

<details>
<summary>Example configuration</summary>

```vim
" Define highlight for Git-related components.
highlight Git guibg=#F34F29 guifg=#FFFFFF ctermbg=202 ctermfg=231

" Use :vim9cmd to use Vim9 syntax and compiled lambdas in a legacy Vim script.
vim9cmd g:qline_config = {
# Use the powerline glyphs for separators.
  separator:    {left: "\ue0b0", right: "\ue0b2", margin: ' '},
  subseparator: {left: "\ue0b1", right: "\ue0b3", margin: ' '},
# Specify components in the each sides for active/inactive windows.
# Each modes can also have specific settings.
  active: {
    left: [
      ['mode', 'paste'],
      ['gina_branch', 'gina_traffic', 'gina_status', 'filename', 'gitgutter'],
      ['bufstate']
    ],
    right: [
      ['filetype'],
      ['fileinfo'],
      ['%c%-1V', 'searchcount']
    ]
  },
  inactive: {
    left: [['filename', 'gitgutter'], ['bufstate']],
    right: [['filetype'], ['fileinfo']],
    separator: {left: '', right: '', margin: ' '},
    subseparator: {left: '|', right: '|', margin: ' '},
  },
  insert: {
    separator:    {left: "\ue0c0", right: "\ue0c2", margin: ' '},
    subseparator: {left: "\ue0c1", right: "\ue0c3", margin: ' '},
  },
  replace: {
    separator:    {left: "\ue0c0", right: "\ue0c2", margin: ' '},
    subseparator: {left: "\ue0c1", right: "\ue0c3", margin: ' '},
  },
# Define components. You can overwrite or append to the default definitions.
# If its content is a Funcref, it is evaluated before parsing the statusline.
# If visible_condition results in Falsy, or the content results in empty string,
# the component is collapsed.
# Funcrefs are evaluated in the context of the window of the drawing status line.
  component: {
    fileinfo: {
      content: () =>
        (&fenc ?? &enc) .. ' ' ..
        nerdfont#fileformat#find() ..
        (&bomb ? "\U1f4a3" : ''),
      visible_condition: () => !&buftype,
    },
    bufstate: {
      content: () =>
        (&readonly ? "\uf023" : '') ..
        (&modifiable ? '' : "\uf05e") ..
        (&modified ? "\uf040" : ''),
    },
    filetype: {
      content: () => nerdfont#find(),
    },
    gina_branch: {
      content: () => "\ue0a0" .. gina#component#repo#branch(),
      visible_condition: function('gina#component#repo#branch'),
      highlight: 'Git',
    },
    gina_traffic: {
      content: function('gina#component#traffic#preset', ['fancy']),
      highlight: 'Git',
    },
    gina_status: {
      content: function('gina#component#status#preset', ['fancy']),
      highlight: 'Git',
    },
    gitgutter: {
      content: () =>
        g:GitGutterGetHunkSummary()
          ->mapnew((idx, val) => !val ? '' : ['+', '~', '-'][idx] .. val)
          ->filter((_, val) => !!val)
          ->join(),
      visible_condition: () => g:GitGutterGetHunks(),
    },
  },
}
```

</details>

Note that some components use followings:

* [Nerd Font](https://www.nerdfonts.com/)
* [lambdalisue/nerdfont.vim](https://github.com/lambdalisue/nerdfont.vim)
* [lambdalisue/gina.vim](https://github.com/lambdalisue/gina.vim)
* [airblade/vim-gitgutter](https://github.com/airblade/vim-gitgutter)


## Colorschemes?

Currently the only default colorscheme is bundled. However, you can import
colorschemes from [vim-airline](https://github.com/vim-airline/vim-airline)
and [lightline.vim](https://github.com/itchyny/lightline.vim).
To import, you need to install those plugins **and disable** them.

```vim
Plug 'Bakudankun/qline.vim'
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'itchyny/lightline.vim'

let g:loaded_airline = 1
let g:loaded_lightline = 1
```

Then you can use their colorschemes by adding `colorscheme` item to the config:

```vim
let g:qline_config.colorscheme = 'airline:cool'
```

or use `:QlineColorscheme` to change the colorscheme.


## Troubleshooting

### qline.vim has been disabled for some reason.

When qline.vim runs into an error, qline.vim may be disabled forcibly by Vim.
`:call qline#Enable()` to re-enable.

