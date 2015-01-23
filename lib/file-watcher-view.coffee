path = require 'path'
{CompositeDisposable, Emitter} = require 'atom'
{log, warn} = require './utils'

module.exports =
class FileWatcherView

  hasConflict: false
  clickEvents: []

  constructor: (@editor) ->
    @emitter = new Emitter
    @subscriptions = new CompositeDisposable
    unless @editor?
      warn "No editor instance on this editor"

    @handleEvents()
    @handleEditorEvents()
    @handleConfigChanges()

  handleEditorEvents: ->
    @subscriptions.add @editor.onDidConflict =>
      @hasConflict = true
      @showReloadPrompt if @showPrompt? && !@showActiveOnly?

    @subscriptions.add @editor.onDidSave =>
      @hasConflict = false

    @subscriptions.add @editor.onDidDestroy =>
      @destroy()

    @subscriptions.add atom.workspace.observeActivePaneItem =>
      if @editor.id is atom.workspace.getActiveTextEditor()?.id && @hasConflict
        log "File on disk has changed: " + @editor.getPath()
        @showReloadPrompt if @showPrompt?

  handleConfigChanges: ->
    @subscriptions.add atom.config.observe 'file-watcher.promptWhenFileHasChangedOnDisk',
      (promptWhenFileHasChangedOnDisk) => @showPrompt = promptWhenFileHasChangedOnDisk

    @subscriptions.add atom.config.observe 'file-watcher.promptForActiveFilesOnly',
      (promptForActiveFilesOnly) => @showActiveOnly = promptForActiveFilesOnly

  showReloadPrompt: ->
    fileName = path.basename @editor.getPath()

    @element = document.createElement('div')
    @element.classList.add('file-watcher')

    message = document.createElement('div')
    message.classList.add('message')
    message.textContent = fileName + ' has changed on disk.'

    options = document.createElement('div')
    options.classList.add('options')

    okButton = document.createElement('button')
    okButton.classList.add('ok')
    okButton.classList.add('btn')
    okButton.classList.add('btn-warning')
    okButton.textContent = 'Reload'

    cancelButton = document.createElement('button')
    cancelButton.classList.add('cancel')
    cancelButton.classList.add('btn')
    cancelButton.classList.add('btn-default')
    cancelButton.textContent = 'Ignore'

    options.appendChild(okButton)
    options.appendChild(cancelButton)

    @element.appendChild(message)
    @element.appendChild(options)

    modalOptions = {
      item: @element
      visible: true
    }
    @modal = atom.workspace.addModalPanel

  handleEvents: ->
    ok = @on 'click', '.ok', =>
      @hasConflict = false
      @editor.getBuffer.reload()
      @modal.dispose()

    cancel = @clickEvents.push @on 'click', '.cancel', =>
      @hasConflict = false
      @modal.dispose()

    @clickEvents.push ok
    @clickEvents.push cancel

  destroy: ->
    @modal?.dispose()
    @element?.remove()
    e.dispose() for e in @clickEvents
    @subscriptions.dispose()
    @emitter.emit 'did-destroy'

  onDidDestroy: (callback) ->
    @emitter.on 'did-destroy', callback
