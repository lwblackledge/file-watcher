_ = require 'lodash'
FileWatcherView = require './file-watcher-view'
{CompositeDisposable} = require 'atom'

class FileWatcherInitializer

  config:
    promptWhenFileHasChangedOnDisk:
      type: 'boolean'
      default: true
    promptForActiveFilesOnly:
      type: 'boolean'
      default: false

  activate: ->
    @fileWatcherViews = []

    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.workspace.observeTextEditors (editor) =>
      return if editor.fileWatcherView?

      fileWatcherView = new FileWatcherView(editor)
      @fileWatcherViews.push fileWatcherView
      @subscriptions.add fileWatcherView.onDidDestroy =>
        i = @fileWatcherViews.indexOf fileWatcherView
        if i > 0
          @fileWatcherViews.splice i, 1

  deactivate: ->
    @subscriptions.dispose()
    fileWatcherView.destroy() for fileWatcherView in @fileWatcherViews

module.exports = new FileWatcherInitializer()
