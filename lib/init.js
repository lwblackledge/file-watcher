'use babel'
/* global atom */

import { CompositeDisposable } from 'atom'
import FileWatcher from './file-watcher'

class FileWatcherInitializer {
  constructor () {
    this.config = {
      autoReload: {
        order: 1,
        type: 'boolean',
        default: false,
        title: 'Reload Automatically',
        description: 'Reload without a prompt. Warning: Overrides "Prompt on Change" and "Include the Compare option", and may cause a loss of work!'
      },
      promptWhenChange: {
        order: 2,
        type: 'boolean',
        default: false,
        title: 'Prompt on Change',
        description: 'Also prompt to reload or ignore if the file on disk changes and there are no unsaved changes in Atom'
      },
      includeCompareOption: {
        order: 3,
        type: 'boolean',
        default: true,
        title: 'Include the Compare option',
        description: 'Opens the file on disk as a new editor for comparisons'
      },
      useFsWatchFile: {
        order: 4,
        type: 'boolean',
        default: false,
        title: 'Use WatchFile -- RELOAD REQUIRED',
        description: 'This is less efficient and should only be used if the standard prompts are not working e.g. perhaps you are using SSHFS'
      },
      postCompareCommand: {
        order: 5,
        type: 'string',
        default: '',
        title: 'Post-Compare command',
        description: 'Command to run after the compare is shown e.g. split-diff:toggle'
      },
      logDebugMessages: {
        order: 6,
        type: 'boolean',
        default: false,
        title: 'Log debug messages in the console'
      }
    }
  }

  activate () {
    this.subscriptions = new CompositeDisposable()

    this.watchers = []

    this.subscriptions.add(atom.workspace.observeTextEditors(editor => {
      if (editor.fileWatcher) { return }

      const fileWatcher = new FileWatcher(editor)
      editor.fileWatcher = fileWatcher
      this.watchers.push(fileWatcher)

      this.subscriptions.add(fileWatcher.onDidDestroy(() => {
        this.watchers.splice(this.watchers.indexOf(fileWatcher), 1)
      }))
    }))
  }

  deactivate () {
    for (let fileWatcher of this.watchers) {
      if (fileWatcher) {
        fileWatcher.destroy()
      }
    }
    this.subscriptions.dispose()
  }
}

export default new FileWatcherInitializer()
