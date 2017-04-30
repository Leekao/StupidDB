fs = require 'fs'
md5 = require 'md5'
mkdirp = require 'mkdirp'

class Record
  constructor: (@id, cb) ->
    @_id = md5(@id)
    @_attributes = {}
    @_isRecord = true
    @tracking = []
    @keep_track =>
      fs.access @location()+'__name__', (e) =>
        if (e)
          return mkdirp @location(), (e) =>
            fs.writeFile @location()+'__name__', @id, =>
            cb(@) if cb
        else if cb
          @get @location(), (@_attributes) =>
            cb(@)
    return @

  keep_track: (cb) ->
    fs.readdir '/img/index/', (e, files) =>
      @tracking = files
      cb() if cb

  location: (id = @_id)->
    chars = id.split('')
    location = '/img/'
    chars.forEach (char, index) ->
      location += char
      location += '/' if index%5 is 1
    location+= '/' if location.slice(-1) isnt '/'
    return location

  remove: (key, value) ->
    if value
      console.log('deleting from object', @, key)
      newobj = []
      for k, v of @_attributes[key]
        if v isnt value
          newobj.push v
      @_attributes[key] = newobj
    else
      console.log('deleting key', @, key)
      @_attributes[key] = '__deleted__'
    @save()

  set: (key, value) ->
    if @_attributes[key]
      console.log '--->',@_attributes[key]
      if typeof(@_attributes[key]) isnt 'object' or @_attributes[key]._isRecord
        _tv = @_attributes[key]
        @_attributes[key] = [_tv]
      console.log '<---',@_attributes[key]
      @_attributes[key].push value
    else
      @_attributes[key] = value
    @save()

  report_tracked: (index) ->
    mkdirp '/img/index/'+index, (e) =>
      try
        fs.symlinkSync(@location(), '/img/index/'+index+'/'+@_id, 'dir') 

  save_object: (object, location, cb) ->
    for name, data of object
      continue if typeof(data) is 'function'
      continue if name.charAt(0) is '_'
      if @tracking.indexOf(name) > -1
        @report_tracked name, data
      if data is '__deleted__'
        if typeof(data) isnt 'object'
          fs.unlink location+name
        continue
      if typeof(data) isnt 'object'
        fs.writeFile location+name, data
        continue
      unless data._isRecord
        mkdirp location+name, (e) =>
          @save_object data, location+name+'/'
        continue
      try
        fs.symlinkSync(data.location(), location+name, 'dir') 
    
  save: (cb) ->
    @keep_track =>
      @save_object @_attributes, @location()

  vanish: ->
    location=@location()
    cb = ->
      #fs.rmdir location
    fs.readdir location, (e, files) =>
      if (e)
        return console.error(e) 
      _cb = 0
      _cbk = (e) ->
        _cb--
        cb() if _cb is 0            
      return cb(null) unless (files)
      files.forEach (file) =>
        return if file is '.' or file is '..'
        fs.lstat location+file, (e,stat) =>
          _cb++
          if @tracking.indexOf(file) > -1
            fs.unlink '/img/index/'+file+'/'+@_id
          if stat.isDirectory()
            fs.rmdir location+file, _cbk
          else
            fs.unlink location+file, _cbk

  get: (location, cb) ->
    fs.readdir location, (e, files) =>
      if (e)
        return console.error(e) 
      _cb = 0
      _data = {}
      return cb(null) unless (files)
      files.forEach (file) =>
        return if file is '.' or file is '..'
        _cb++
        fs.lstat location+file, (e,stat) =>
          if stat.isSymbolicLink()
#            console.log 'reading symlink'
            fs.readFile location+file+'/__name__', (e, data) ->
              _data[file] = new Record data
              _cb--
              cb(_data) if _cb is 0            
          if stat.isDirectory()
            @get location+file+'/', (data) ->
              _data[file] = data
              _cb--
              cb(_data) if _cb is 0            
          if stat.isFile()
            fs.readFile location+file, (e, data) =>
              _data[file] = data.toString()
              if _data[file] is 'true'
                _data[file] = true
              if _data[file] is 'false'
                _data[file] = false
              _cb--
              cb(_data) if _cb is 0            

module.exports = Record