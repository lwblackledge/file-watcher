{CompositeDisposable, Emitter} = require 'atom'
{log, warn} = require './utils'
FileWatcherView = require './file-watcher-view'

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

    @subscriptions.add editor.onDidSave =>
      @conflictPanel?.hide()

    @subscriptions.add editor.onDidDestroy =>
      @destroy()

    @subscriptions.add editor.onDidConflict =>
      log 'Conflict: ' + editor.getPath()
      @createView editor
      @listen()
      @conflictPanel.show() if @showPrompt && editor.getBuffer().isInConflict()

  createView: (editor) ->
    @fileWatcherView = new FileWatcherView(editor)
    @conflictPanel = atom.workspace.addModalPanel(item: @fileWatcherView, visible: false)

  listen: ->
    @fileWatcherView.onDidConfirm (editor) =>
      editor.getBuffer()?.reload()
      @conflictPanel.hide()

    @fileWatcherView.onDidCancel =>
      @conflictPanel.hide()

  destroy: ->
    @fileWatcherView?.dispose()
    @conflictPanel?.dispose()
    @subscriptions.dispose()
    @emitter.emit 'did-destroy'

  onDidDestroy: (callback) ->
    @emitter.on 'did-destroy', callback
