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

Array::at = (i) -> @[i]
Array::first = -> @at 0
Array::last = -> @[@length-1]
Array::find = (cb) -> @filter(cb)[0]
Array::select = (cb) ->
  item for item in this when cb(item) is true
Array::each = (cb) ->
  cb item for item in this

window.implement = (obj, prop) ->
  if prop instanceof Object
    obj[key] = prop[key] for key of prop
  return


window.after = (ms, cb) -> setTimeout cb, ms
window.every = (ms, cb) -> setInterval cb, ms
