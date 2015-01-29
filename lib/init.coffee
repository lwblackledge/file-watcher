{CompositeDisposable} = require 'atom'
{log, warn} = require './utils'
FileWatcher = require './file-watcher'

class FileWatcherInitializer

  config:
    promptWhenFileHasChangedOnDisk:
      type: 'boolean'
      default: true

  activate: ->
    @subscriptions = new CompositeDisposable

    @watchers = []

    @subscriptions.add atom.workspace.observeTextEditors (editor) =>
      return if editor.fileWatcher?

      fileWatcher = new FileWatcher(editor)
      @watchers.push(fileWatcher)

      @subscriptions.add fileWatcher.onDidDestroy =>
        @watchers.splice(@watchers.indexOf(fileWatcher), 1)

  deactivate: ->
    fileWatcher.destroy() for fileWatcher in @watchers
    @subscriptions.dispose()

module.exports = new FileWatcherInitializer()
