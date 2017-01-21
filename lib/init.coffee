{CompositeDisposable} = require 'atom'
{log, warn} = require './utils'
FileWatcher = require './file-watcher'

class FileWatcherInitializer

  config:
    autoReload:
      order: 1
      type: 'boolean'
      default: false
      title: 'Reload Automatically'
      description: 'Reload without a prompt. Warning: Overrides "Prompt on Change" and "Include the Compare option", and may cause a loss of work!'
    promptWhenChange:
      order: 2
      type: 'boolean'
      default: false
      title: 'Prompt on Change'
      description: 'Also prompt to reload or ignore if the file on disk changes and there are no unsaved changes in Atom'
    includeCompareOption:
      order: 3
      type: 'boolean'
      default: true
      title: 'Include the Compare option'
      description: 'Opens the file on disk as a new editor for comparisons'
    useFsWatchFile:
      order: 4
      type: 'boolean'
      default: false
      title: 'Use WatchFile -- RELOAD REQUIRED'
      description: 'This is less efficient and should only be used for mounted files systems e.g. SSHFS'
    postCompareCommand:
      order: 5
      type: 'string'
      default: ''
      title: 'Post-Compare command'
      description: 'Command to run after the compare is shown e.g. split-diff:toggle'
    logDebugMessages:
      order: 6
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
    fileWatcher?.destroy() for fileWatcher in @watchers
    @subscriptions.dispose()

module.exports = new FileWatcherInitializer()
