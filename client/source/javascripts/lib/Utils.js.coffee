String::randomId = (len = 10) ->
  strings = 'abcdefghijklmopqrstuvwxyz0123456789'
  randomStr = ''
  while len-- > -1
    index = Math.random() * strings.length
    randomStr += strings.substr index, 1
  randomStr

Array::random = ->
  index = Math.random() * (this.length - 1)
  index = Math.round index
  this[index]

Array::last = -> @[@length-1]

window.implement = (obj, prop) ->
  if prop instanceof Object
    obj[key] = prop[key] for key of prop
  return


