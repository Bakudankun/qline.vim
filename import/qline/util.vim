vim9script


export def Component(name: string): string
  import GetComponentContent from '../qline.vim'
  return GetComponentContent(name)
enddef


# vim: et sw=2 sts=-1 cc=+1
