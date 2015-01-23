{Emitter, CompositeDisposable} = require 'atom'

module.exports =
class FileWatcherModel

  @hasConflict = true

  constructor: (@editor) ->
    @emitter = new Emitter()
