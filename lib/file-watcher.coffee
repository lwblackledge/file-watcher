{CompositeDisposable} = require 'atom'
{log, warn} = require './utils'
FileWatcherView = require './file-watcher-view'

class FileWatcher

  config:
    promptWhenFileHasChangedOnDisk:
      type: 'boolean'
      default: true

  activate: ->
    @subscriptions = new CompositeDisposable

    @subscriptions.add atom.config.observe 'file-watcher.promptWhenFileHasChangedOnDisk',
      (promptWhenFileHasChangedOnDisk) => @showPrompt = promptWhenFileHasChangedOnDisk

    @subscriptions.add atom.workspace.observeTextEditors (editor) =>
      editor.onDidConflict =>
        log 'Conflict: ' + editor.getPath()
        @createView editor
        @listen()
        @conflictPanel.show() if @showPrompt && editor.getBuffer().isInConflict()

      editor.onDidSave =>
        @conflictPanel?.hide()

  createView: (editor) ->
    @fileWatcherView = new FileWatcherView(editor)
    @conflictPanel = atom.workspace.addModalPanel(item: @fileWatcherView, visible: false)

  listen: ->
    @fileWatcherView.onDidConfirm (editor) =>
      editor.getBuffer()?.reload()
      @conflictPanel.hide()

    @fileWatcherView.onDidCancel =>
      @conflictPanel.hide()

  deactivate: ->
    @fileWatcherView?.dispose()
    @conflictPanel?.dispose()
    @subscriptions.dispose()

module.exports = new FileWatcher()
