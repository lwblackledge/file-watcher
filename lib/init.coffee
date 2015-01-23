FileWatcher = require './file-watcher'
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
    @fileWatchers = []

    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.workspace.observeTextEditors (editor) =>
      return if editor.fileWatcher?

      fileWatcher = new FileWatcher(editor)
      @fileWatchers.push fileWatcher
      @subscriptions.add fileWatcher.onDidDestroy =>
        i = @fileWatchers.indexOf fileWatcher
        if i > 0
          @fileWatchers.splice i, 1

  deactivate: ->
    @subscriptions.dispose()
    fileWatcher.destroy() for fileWatcher in @fileWatchers

module.exports = new FileWatcherInitializer()
