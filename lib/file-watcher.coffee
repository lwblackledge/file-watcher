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

    @subscriptions.add atom.config.observe 'file-watcher.promptWhenFileHasChangedOnDisk',
      (promptWhenFileHasChangedOnDisk) => @showPrompt = promptWhenFileHasChangedOnDisk

    @subscriptions.add @editor.onDidDestroy =>
      @destroy()

    @subscriptions.add @editor.onDidConflict =>
      log 'Conflict: ' + @editor.getPath()
      @confirmReload() if @shouldPromptToReload()

  shouldPromptToReload: ->
    return @showPrompt and @editor.getBuffer().isInConflict()

  confirmReload: ->
    currPath = @editor.getPath()
    currEncoding = @editor.getBuffer()?.encoding || 'utf8'

    choice = atom.confirm
      message: path.basename(currPath) + ' has changed on disk.'
      buttons: ['Reload', 'Compare', 'Ignore']

    return if choice is 2

    if choice is 0
      @editor.getBuffer()?.reload()
      return

    compPromise = atom.workspace.open null,
      split: 'right'

    compPromise.then (ed) ->
      ed.insertText fs.readFileSync(currPath, encoding: currEncoding)

  destroy: ->
    @subscriptions.dispose()
    @emitter.emit 'did-destroy'

  onDidDestroy: (callback) ->
    @emitter.on 'did-destroy', callback
