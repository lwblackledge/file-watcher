path = require 'path'
{CompositeDisposable, Emitter} = require 'atom'
{log, warn} = require './utils'

module.exports =
class FileWatcher

  hasConflict: false

  constructor: (@editor) ->
    @emitter = new Emitter
    @subscriptions = new CompositeDisposable
    unless @editor?
      warn "No editor instance on this editor"

    @fileWatcherView = new FileWatcherView(@editor, @hasConflict)

    @handleEvents()
    @handleEditorEvents()
    @handleConfigChanges()

  handleEditorEvents: ->
    @subscriptions.add @editor.onDidConflict =>
      @hasConflict = true
      @showReloadPrompt() if @showPrompt && !@showActiveOnly

    @subscriptions.add @editor.onDidSave =>
      @hasConflict = false

    @subscriptions.add @editor.onDidDestroy =>
      @destroy()

    @subscriptions.add atom.workspace.observeActivePaneItem =>
      if @editor.id is atom.workspace.getActiveTextEditor()?.id && @hasConflict
        @showReloadPrompt() if @showPrompt

  handleConfigChanges: ->
    @subscriptions.add atom.config.observe 'file-watcher.promptWhenFileHasChangedOnDisk',
      (promptWhenFileHasChangedOnDisk) => @showPrompt = promptWhenFileHasChangedOnDisk

    @subscriptions.add atom.config.observe 'file-watcher.promptForActiveFilesOnly',
      (promptForActiveFilesOnly) => @showActiveOnly = promptForActiveFilesOnly

  showReloadPrompt: ->
    @reloadPanel = atom.workspace.addModalPanel(item: @fileWatcherView, visible: true)
    @fileWatcherView.setPanel(@reloadPanel)

  handleEvents: ->
    @okButton.on 'click', '.ok', =>
      @hasConflict = false
      @editor.getBuffer.reload()
      @modal.dispose()

    @cancelButton.on 'click', '.cancel', =>
      @hasConflict = false
      @modal.dispose()

  destroy: ->
    @modal?.dispose()
    @content?.dispose()
    @subscriptions.dispose()
    @emitter.emit 'did-destroy'

  onDidDestroy: (callback) ->
    @emitter.on 'did-destroy', callback
