path = require 'path'
{Emitter} = require 'atom'
{log, warn} = require './utils'
{$, $$, View} = require 'atom-space-pen-views'

module.exports =
class FileWatcherView extends View

  @content: ->
    @div class: 'file-watcher', =>
      @div outlet: 'fileChangedLabel', class: 'message', 'The file has changed on disk.'
      @div class: 'options', =>
        @button outlet: 'okButton', class: 'btn btn-warning icon icon-sync', 'Reload'
        @button outlet: 'cancelButton', class: 'btn btn-default icon icon-remove-close', 'Ignore'

  initialize: (@editor) ->
    @emitter = new Emitter
    fileName = path.basename @editor.getPath()
    @fileChangedLabel.text(fileName + ' has changed on disk.')
    @handleEvents()

  handleEvents: ->
    @okButton.on 'click', =>
      @emitter.emit 'did-confirm', @editor

    @cancelButton.on 'click', =>
      @emitter.emit 'did-cancel', @editor

  onDidConfirm: (callback) ->
    @emitter.on 'did-confirm', callback

  onDidCancel: (callback) ->
    @emitter.on 'did-cancel', callback

  dispose: ->
    @fileChangedLabel?.dispose()
    @okButton?.dispose()
    @cancelButton?.dispose()
    @content?.dispose()
    @emitter.dispose()
