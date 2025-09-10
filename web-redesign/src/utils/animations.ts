// Animation utilities and constants

export const animations = {
  // Fade animations
  fadeIn: 'animate-fade-in',
  fadeOut: 'animate-fade-out',
  fadeInUp: 'animate-fade-in-up',
  fadeInDown: 'animate-fade-in-down',
  fadeInLeft: 'animate-fade-in-left',
  fadeInRight: 'animate-fade-in-right',

  // Scale animations
  scaleIn: 'animate-scale-in',
  scaleOut: 'animate-scale-out',
  scaleInUp: 'animate-scale-in-up',

  // Slide animations
  slideInUp: 'animate-slide-in-up',
  slideInDown: 'animate-slide-in-down',
  slideInLeft: 'animate-slide-in-left',
  slideInRight: 'animate-slide-in-right',

  // Bounce animations
  bounce: 'animate-bounce',
  bounceIn: 'animate-bounce-in',
  bounceInUp: 'animate-bounce-in-up',

  // Pulse animations
  pulse: 'animate-pulse',
  pulseSlow: 'animate-pulse-slow',

  // Shake animations
  shake: 'animate-shake',
  shakeHorizontal: 'animate-shake-horizontal',

  // Rotate animations
  rotate: 'animate-spin',
  rotateSlow: 'animate-spin-slow',

  // Stagger animations
  stagger1: 'animate-stagger-1',
  stagger2: 'animate-stagger-2',
  stagger3: 'animate-stagger-3',
  stagger4: 'animate-stagger-4',
  stagger5: 'animate-stagger-5',
}

export const transitions = {
  // Duration
  fast: 'duration-150',
  normal: 'duration-300',
  slow: 'duration-500',
  slower: 'duration-700',

  // Easing
  easeIn: 'ease-in',
  easeOut: 'ease-out',
  easeInOut: 'ease-in-out',
  linear: 'linear',

  // Combined
  fastEaseOut: 'duration-150 ease-out',
  normalEaseInOut: 'duration-300 ease-in-out',
  slowEaseOut: 'duration-500 ease-out',
}

export const hoverEffects = {
  lift: 'hover:transform hover:-translate-y-1 hover:shadow-lg transition-all duration-200',
  scale: 'hover:transform hover:scale-105 transition-all duration-200',
  glow: 'hover:shadow-lg hover:shadow-blue-500/25 transition-all duration-200',
  slide: 'hover:transform hover:translate-x-1 transition-all duration-200',
  rotate: 'hover:transform hover:rotate-1 transition-all duration-200',
}

export const focusEffects = {
  ring: 'focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2',
  ringBlue: 'focus:outline-none focus:ring-2 focus:ring-fortaleza-blue focus:ring-offset-2',
  glow: 'focus:outline-none focus:shadow-lg focus:shadow-blue-500/25',
}

// Animation delay utilities
export const delays = {
  delay75: 'delay-75',
  delay100: 'delay-100',
  delay150: 'delay-150',
  delay200: 'delay-200',
  delay300: 'delay-300',
  delay500: 'delay-500',
  delay700: 'delay-700',
  delay1000: 'delay-1000',
}

// Stagger animation helper
export const getStaggerDelay = (index: number) => {
  const delays = ['delay-0', 'delay-75', 'delay-100', 'delay-150', 'delay-200', 'delay-300']
  return delays[Math.min(index, delays.length - 1)]
}

// Animation presets for common use cases
export const presets = {
  cardHover: `${hoverEffects.lift} ${transitions.normalEaseInOut}`,
  buttonHover: `${hoverEffects.scale} ${transitions.fastEaseOut}`,
  inputFocus: `${focusEffects.ringBlue} ${transitions.fastEaseOut}`,
  modalEnter: `${animations.fadeIn} ${animations.scaleIn} ${transitions.normalEaseInOut}`,
  modalExit: `${animations.fadeOut} ${animations.scaleOut} ${transitions.fastEaseOut}`,
  listItemEnter: `${animations.fadeInUp} ${transitions.normalEaseInOut}`,
  pageEnter: `${animations.fadeIn} ${transitions.slowEaseOut}`,
}
