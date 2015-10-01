fs = require 'fs'
path = require 'path'
{CompositeDisposable, Emitter} = require 'atom'
{log, warn} = require './utils'

module.exports =
class FileWatcher

  constructor: (@editor) ->
    @subscriptions = new CompositeDisposable
    @emitter = new Emitter

    unless @editor?
      warn 'No editor instance on this editor'
      return

    hasUnderlyingFile = @editor.getBuffer()?.file?

    @subscriptions.add atom.config.observe 'file-watcher.promptWhenChange',
      (prompt) => @showChangePrompt = prompt

    @subscriptions.add atom.config.observe 'file-watcher.includeCompareOption',
      (compare) => @includeCompareOption = compare

    @subscriptions.add atom.config.observe 'file-watcher.logDebugMessages',
      (debug) => @debug = debug

    @subscribeToFileChange() if hasUnderlyingFile

    @subscriptions.add @editor.onDidConflict =>
      @conflictInterceptor()

    @subscriptions.add @editor.onDidSave =>
      if !hasUnderlyingFile
        hasUnderlyingFile = true
        @subscribeToFileChange()

    @subscriptions.add @editor.onDidDestroy =>
      @destroy()

  subscribeToFileChange: ->
    @subscriptions.add @editor.getBuffer()?.file.onDidChange =>
      @changeInterceptor()

    # call this to reset order of events, otherwise buffer fires first
    @editor.getBuffer()?.subscribeToFile()

  isBufferInConflict: ->
    return @editor.getBuffer()?.isInConflict()

  changeInterceptor: ->
    (log 'Change: ' + @editor.getPath()) if @debug
    @editor.getBuffer()?.conflict = true if @showChangePrompt

  conflictInterceptor: ->
    (log 'Conflict: ' + @editor.getPath()) if @debug
    @confirmReload() if @isBufferInConflict()

  confirmReload: ->
    currPath = @editor.getPath()
    currEncoding = @editor.getBuffer()?.getEncoding() || 'utf8'
    currGrammar = @editor.getGrammar()

    choice = atom.confirm
      message: 'The file "' + path.basename(currPath) + '" has changed.'
      buttons: if @includeCompareOption then ['Reload', 'Ignore', 'Compare'] else ['Reload', 'Ignore']

    if choice is 1
      @editor.getBuffer()?.emitModifiedStatusChanged(true)
      return

    if choice is 0
      @editor.getBuffer()?.reload()
      return

    compPromise = atom.workspace.open null,
      split: 'right'

    compPromise.then (ed) ->
      ed.insertText fs.readFileSync(currPath, encoding: currEncoding)
      ed.setGrammar currGrammar

  destroy: ->
    @subscriptions.dispose()
    @emitter.emit 'did-destroy'

  onDidDestroy: (callback) ->
    @emitter.on 'did-destroy', callback
