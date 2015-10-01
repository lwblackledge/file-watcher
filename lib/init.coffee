{CompositeDisposable} = require 'atom'
{log, warn} = require './utils'
FileWatcher = require './file-watcher'

class FileWatcherInitializer

  config:
    promptWhenChange:
      type: 'boolean'
      default: false
      title: 'Prompt on Change'
      description: 'Also prompt to reload or ignore if the file on disk changes and there are no unsaved changes in Atom'
    includeCompareOption:
      type: 'boolean'
      default: true
      title: 'Include the Compare option'
      description: 'Opens the file on disk as a new editor for comparisons'
    logDebugMessages:
      type: 'boolean'
      default: false
      title: 'Log debug messages in the console'

  activate: ->
    @subscriptions = new CompositeDisposable

    @watchers = []

    @subscriptions.add atom.workspace.observeTextEditors (editor) =>
      return if editor.fileWatcher?

      fileWatcher = new FileWatcher(editor)
      editor.fileWatcher = fileWatcher
      @watchers.push(fileWatcher)

      @subscriptions.add fileWatcher.onDidDestroy =>
        @watchers.splice(@watchers.indexOf(fileWatcher), 1)

  deactivate: ->
    fileWatcher.destroy() for fileWatcher in @watchers
    @subscriptions.dispose()

module.exports = new FileWatcherInitializer()
