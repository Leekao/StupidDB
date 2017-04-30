fs = require 'fs'
md5 = require 'md5'
mkdirp = require 'mkdirp'
Record = require './record'
stdin = process.openStdin()
tty = require('tty')
#console.log(tty)
#tty.setRawMode(true)

gather_by = (record, key, cb, depth = 6) ->
  new Record record, (_record) ->
    if _record._attributes[key]
      value = _record._attributes[key]
      setImmediate ->
        cb(value)
      if value._isRecord and depth > 0
        setImmediate ->
          gather_by value, key, cb, depth-1
        
setImmediate ->
  gather_by 'Erez', 'friend', (value) ->
    console.log value.id.toString()
          

define_new_record = (record_name, cb) ->
  return new Record record_name, (record) ->
    cb(Object.keys(record._attributes).length is 0)

describe = (record_name) ->
  return new Record record_name, (record) ->
    console.log record_name
    for key, value of record._attributes
      if value is true
        return console.log('has',key)
      if value is false
        return console.log('does not have',key)
      unless key is '__name__'
        console.log(key,'is',value)

new_input = (record_name, attrib, value, cb) ->
  return new Record record_name, (record) ->
    if typeof(value) is 'object'
      value = value.map (v) ->
        if /^[A-Z]/.test(v)
          return new Record v
        return v
      record.set(attrib, value)
      record.save()
      return cb(null)
    if /^[A-Z]/.test(value)
      new Record value, (_value) ->
        record.set(attrib, _value)
        record.save()
        if Object.keys(_value._attributes).length > 0
          cb(_value._attributes)
        else
          cb(null)
    else
      if parseInt(value).toString() is value
        value = parseInt(value)
        record.set(attrib, value)
        record.save()

process.stdin.resume()
wtf = ->
  console.log """
    "This is [record]" - Creates a new record
    "[record] has (a|an) [attribute], [value] and [value]..." - Set attributes and relations
    "[record] has (number) [attribute], [value] and [value]... - Set array of values
    "track [index]" - Add new index
    "report [index]" - Lists index
    "describe [record]" - displays shallow record
    "forget [record]" - removes all attributes and relations from object
  """

fs.readdir '/img/index/', (e, files) =>
  console.log """

---------------------------------------------------------
    Welcome to StupidDB, the dumbest DB created.
    "wtf" displays the help, it is not very helpful.
---------------------------------------------------------

  """
  console.log 'tracking', files

process.stdin.on 'data', (chunk) ->
  chunk = chunk.toString()
  if chunk.indexOf('wtf') is 0
    return wtf()
  if chunk.indexOf('This is') is 0
    record_name = chunk.slice(8).trim()
    return define_new_record record_name, (isNew) ->
      unless isNew
        process.stdout.write 'I already know '+chunk.slice(8)+'\n\r'
      else
        process.stdout.write 'now I know ' + chunk.slice(8)+'\n\r'

  if chunk.indexOf('track') is 0
    parts = chunk.split(' ').map (e) -> e.trim()
    console.log 'tracking',parts[1]
    location = '/img/index/'+parts[1]+'/'
    return mkdirp location, (e) ->
      console.error(e) if e

  if chunk.indexOf('report') is 0
    parts = chunk.split(' ').map (e) -> e.trim()
    location = '/img/index/'+parts[1]+'/'
    console.log 'reporting '+parts[1]
    _data = {}
    return fs.readdir location, (e, files) =>
      files.map (file) ->
        fs.readFile location+file+'/__name__', (e, data) ->
          console.log '-=->',data.toString()

  if chunk.indexOf('describe') is 0
    parts = chunk.split(/\s/)
    return describe parts[1]

  if chunk.indexOf('forget') is 0
    return new Record chunk.substring(7).trim(), (record) ->
      record.vanish (done) ->
        process.stdout.write 'who is '+chunk.slice(7).trim()+'?'+'\n\r'

  if chunk.indexOf('delete') is 0
    parts = chunk.split(' ').map (e) -> e.trim()
    if parts.length > 4
      record = parts[5]
      key = parts[3]
      value = parts[1]
    else
      record = parts[3]
      key = parts[1]
      value = null
    console.log record, key, value, record is 'Erez'
    return new Record record, (_record) ->
      _record.remove key, value

  if /^[A-Z]/.test(chunk.slice(0,1))
    from = chunk.substring 0, chunk.indexOf(' ')
  
  if /has\s([0-9])/.test(chunk)
    quantity = /has\s([0-9])/.exec(chunk)[1]
    parts = chunk.split(/[0-9]/)
    _parts = parts[1].split(',').map (e) -> e.trim()
    attrib = _parts[0]
    value = _parts[1].split('and').map (e) -> e.trim()
    process.stdout.write 'I see.\n\r'
    return new_input from, attrib, value, (new_record) ->
      console.log('hmmmm')
      
  if chunk.indexOf('has a') > -1
    parts = chunk.split(' has a ').map (e) -> e.trim()
    if parts.length is 1
      parts = chunk.split(' has an ').map (e) -> e.trim()
    parts = parts[1].split(',').map (e) -> e.trim()
    if parts.length > 1
      attrib = parts[0]
      value = parts[1]
    else
      attrib = parts[0]
      value = true
    process.stdout.write 'I see.\n\r'
    new_input from, attrib, value, (new_record) ->
      if new_record
        process.stdout.write 'I already know '+value+'\n\r'
        console.log(new_record)
      else
        console.log 'now I know', value

  else
    console.log 'ok, '+chunk.trim()