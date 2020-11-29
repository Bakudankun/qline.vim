vim9script


export const palette: dict<dict<list<string>>> = {
  normal: {
    left0:   ['#005f00', '#afdf00', '22', '148', 'bold'],
    left1:   ['#ffffff', '#585858', '231', '240'],
    left2:   ['#8a8a8a', '#303030', '245', '236'],
    middle:  ['#8a8a8a', '#303030', '245', '236'],
    right0:  ['#606060', '#d0d0d0', '241', '252'],
    right1:  ['#bcbcbc', '#585858', '250', '240'],
    right2:  ['#9e9e9e', '#303030', '247', '236'],
    error:   ['#bcbcbc', '#ff0000', '250', '196'],
    warning: ['#262626', '#b58900', '235', '136'],
    paste:   ['#ffffff', '#d75f00', '231', '166', 'bold'],
  },
  inactive: {
    left0:  ['#585858', '#262626', '240', '235'],
    left1:  ['#585858', '#121212', '240', '233'],
    left2:  ['#8a8a8a', '#303030', '245', '236'],
    middle: ['#585858', '#121212', '240', '233'],
    right0: ['#262626', '#606060', '235', '241'],
    right1: ['#585858', '#262626', '240', '235'],
    right2: ['#585858', '#121212', '240', '233'],
  },
  replace: {
    left0:  ['#ffffff', '#df0000', '231', '160', 'bold'],
    left1:  ['#ffffff', '#585858', '231', '240'],
    left2:  ['#8a8a8a', '#303030', '245', '236'],
    middle: ['#8a8a8a', '#303030', '245', '236'],
    right0: ['#606060', '#d0d0d0', '241', '252'],
    right1: ['#bcbcbc', '#585858', '250', '240'],
    right2: ['#9e9e9e', '#303030', '247', '236'],
  },
  tabline: {
    left:   ['#bcbcbc', '#585858', '250', '240'],
    middle: ['#303030', '#9e9e9e', '236', '247'],
    right:  ['#bcbcbc', '#4e4e4e', '250', '239'],
    tabsel: ['#bcbcbc', '#262626', '250', '235'],
  },
  visual: {
    left0:  ['#870000', '#ff8700', '88', '208', 'bold'],
    left1:  ['#ffffff', '#585858', '231', '240'],
    left2:  ['#8a8a8a', '#303030', '245', '236'],
    middle: ['#8a8a8a', '#303030', '245', '236'],
    right0: ['#606060', '#d0d0d0', '241', '252'],
    right1: ['#bcbcbc', '#585858', '250', '240'],
    right2: ['#9e9e9e', '#303030', '247', '236'],
  },
  insert: {
    left0:  ['#005f5f', '#ffffff', '23', '231', 'bold'],
    left1:  ['#ffffff', '#0087af', '231', '31'],
    left2:  ['#87dfff', '#005f87', '117', '24'],
    middle: ['#87dfff', '#005f87', '117', '24'],
    right0: ['#005f5f', '#87dfff', '23', '117'],
    right1: ['#87dfff', '#0087af', '117', '31'],
    right2: ['#87dfff', '#005f87', '117', '24'],
  },
  terminal: {
    left0:  ['#005f5f', '#ffffff', '23', '231', 'bold'],
    left1:  ['#ffffff', '#0087af', '231', '31'],
    left2:  ['#87dfff', '#005f87', '117', '24'],
    middle: ['#87dfff', '#005f87', '117', '24'],
    right0: ['#005f5f', '#87dfff', '23', '117'],
    right1: ['#87dfff', '#0087af', '117', '31'],
    right2: ['#87dfff', '#005f87', '117', '24'],
  },
}

# vim: et sw=2 sts=-1 cc=+1
