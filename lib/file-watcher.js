'use babel'
/* global atom */

import fs from 'fs'
import path from 'path'
import { CompositeDisposable, Emitter } from 'atom'
import { log, warn } from './utils'

let FileWatcher = class FileWatcher {
  constructor (editor) {
    this.editor = editor
    this.subscriptions = new CompositeDisposable()
    this.emitter = new Emitter()

    if (!this.editor) {
      warn('No editor instance on this editor')
      return
    }

    const buffer = this.editor.getBuffer()
    this.hasUnderlyingFile = (buffer && buffer.file)
    this.currPath = this.editor.getPath()
    this.isInPrompt = false

    this.subscriptions.add(atom.config.observe('file-watcher.autoReload',
      autoReload => { this.autoReload = autoReload })
    )

    this.subscriptions.add(atom.config.observe('file-watcher.promptWhenChange',
      prompt => { this.showChangePrompt = prompt })
    )

    this.subscriptions.add(atom.config.observe('file-watcher.includeCompareOption',
      compare => { this.includeCompareOption = compare })
    )

    this.subscriptions.add(atom.config.observe('file-watcher.useFsWatchFile',
      useFsWatchFile => { this.useFsWatchFile = useFsWatchFile })
    )

    this.subscriptions.add(atom.config.observe('file-watcher.postCompareCommand',
      command => { this.postCompareCommand = command })
    )

    this.subscriptions.add(atom.config.observe('file-watcher.logDebugMessages',
      debug => { this.debug = debug })
    )

    if (this.hasUnderlyingFile) { this.subscribeToFileChange() }

    this.subscriptions.add(this.editor.onDidConflict(() => {
      this.conflictInterceptor()
    }))

    this.subscriptions.add(this.editor.onDidSave(() => {
      if (!this.hasUnderlyingFile) {
        this.hasUnderlyingFile = true
        this.subscribeToFileChange()
      }
    }))

    this.subscriptions.add(this.editor.onDidDestroy(() => {
      this.destroy()
    }))
  }

  subscribeToFileChange () {
    this.currPath = this.editor.getPath()
    const buffer = this.editor.getBuffer()

    if (this.useFsWatchFile) {
      // try to use watchFile to handle changes on file systems that don't support inotify
      // remove existing watch first
      fs.unwatchFile(this.currPath)
      fs.watchFile(this.currPath, (curr, prev) => {
        if (this.showChangePrompt && !this.ignoreChange && (curr.mtime.getTime() > prev.mtime.getTime())) { this.confirmReload() }
        if (this.ignoreChange) { this.ignoreChange = false }
      })

      if (buffer) {
        this.subscriptions.add(buffer.onDidSave(() => {
          // saves will trigger watch, but ignore atom saves
          this.ignoreChange = true
        }))
      }
    }

    if (buffer) {
      this.subscriptions.add(buffer.onWillReload((event) => {
        if (this.isInReload) { return }
        this.isInReload = true

        if (this.showChangePrompt) {
          this.confirmReload()
        }
      }))

      this.subscriptions.add(buffer.onDidReload(() => {
        this.isInReload = false
        if (this.prevText) {
          buffer.setText(this.prevText)
          this.prevText = null
        }
      }))
    }
  }

  isBufferInConflict () {
    const buffer = this.editor.getBuffer()
    return buffer && buffer.isInConflict()
  }

  conflictInterceptor () {
    if (this.debug) { log(`Conflict: ${this.editor.getPath()}`) }
    if (this.isBufferInConflict()) { return this.confirmReload() }
  }

  forceReload () {
    if (this.isInReload) {
      // already reloading
      return
    }
    this.isInReload = true

    const currBuffer = this.editor.getBuffer()
    if (!currBuffer) { return }

    // atom backwards compatibility - older verison of textBuffer
    if (this.useFsWatchFile && currBuffer.updateCachedDiskContents) {
      // force a re-read from the file then reload
      return currBuffer.updateCachedDiskContents(true, () => currBuffer.reload())
    } else {
      return currBuffer.reload()
    }
  }

  confirmReload () {
    // if the user has selected autoReload we can just reload and exit
    if (this.autoReload) {
      this.forceReload()
      return
    }

    // if there is an existing prompt showing then just ignore this event and wait for user response
    if (this.isInPrompt) {
      return
    }

    this.isInPrompt = true

    const buffer = this.editor.getBuffer()

    const choice = atom.confirm({
      message: `The file "${path.basename(this.currPath)}" has changed.`,
      buttons: this.includeCompareOption ? ['Reload', 'Ignore', 'Ignore All', 'Compare'] : ['Reload', 'Ignore', 'Ignore All']
    })

    if (choice === 0) { // Reload
      this.forceReload()
      this.isInPrompt = false
      return
    }

    if (choice === 1) { // Ignore
      if (buffer) {
        this.prevText = buffer.getText()
      }
      this.isInPrompt = false
      return
    }

    if (choice === 2) { // Ignore All
      this.isInPrompt = false
      this.destroy()
      return
    }

    // Compare
    const scopePath = this.editor.getPath()
    const scopePostCompare = this.postCompareCommand

    const currEncoding = buffer ? buffer.getEncoding() : 'utf8'
    const currGrammar = this.editor.getGrammar()
    const currView = atom.views.getView(this.editor)

    const compPromise = atom.workspace.open(null, { split: 'right' })

    return compPromise.then(function (ed) {
      ed.insertText(fs.readFileSync(scopePath, { encoding: currEncoding }))
      ed.setGrammar(currGrammar)
      this.isInPrompt = false
      if (scopePostCompare) { return atom.commands.dispatch(currView, scopePostCompare) }
    })
  }

  destroy () {
    this.subscriptions.dispose()
    if (this.currPath && this.hasUnderlyingFile) { fs.unwatchFile(this.currPath) }
    return this.emitter.emit('did-destroy')
  }

  onDidDestroy (callback) {
    return this.emitter.on('did-destroy', callback)
  }
}

export default FileWatcher
