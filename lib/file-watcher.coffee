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
    choice = atom.confirm
      message: path.basename(@editor.getPath()) + ' has changed on disk.'
      buttons: ['Reload', 'Ignore']

    return if choice is 1

    @editor.getBuffer()?.reload()

  destroy: ->
    @subscriptions.dispose()
    @emitter.emit 'did-destroy'

  onDidDestroy: (callback) ->
    @emitter.on 'did-destroy', callback
