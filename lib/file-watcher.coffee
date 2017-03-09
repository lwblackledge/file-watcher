fs = require 'fs'
path = require 'path'
{CompositeDisposable, Emitter} = require 'atom'
{log, warn} = require './utils'

module.exports =
class FileWatcher

  constructor: (@editor) ->
    @subscriptions = new CompositeDisposable
    @emitter = new Emitter

    unless @editor?
      warn 'No editor instance on this editor'
      return

    @hasUnderlyingFile = @editor.getBuffer()?.file?
    @currPath = @editor.getPath()
    savedByAtom = false

    @subscriptions.add atom.config.observe 'file-watcher.autoReload',
      (autoReload) => @autoReload = autoReload

    @subscriptions.add atom.config.observe 'file-watcher.promptWhenChange',
      (prompt) => @showChangePrompt = prompt

    @subscriptions.add atom.config.observe 'file-watcher.includeCompareOption',
      (compare) => @includeCompareOption = compare

    @subscriptions.add atom.config.observe 'file-watcher.useFsWatchFile',
      (useFsWatchFile) => @useFsWatchFile = useFsWatchFile

    @subscriptions.add atom.config.observe 'file-watcher.postCompareCommand',
      (command) => @postCompareCommand = command

    @subscriptions.add atom.config.observe 'file-watcher.logDebugMessages',
      (debug) => @debug = debug

    @subscribeToFileChange() if @hasUnderlyingFile

    @subscriptions.add @editor.onDidConflict =>
      @conflictInterceptor()

    @subscriptions.add @editor.onDidSave =>
      # avoid change firing when Atom saves the file
      @ignoreChange = true
      if !@hasUnderlyingFile
        @hasUnderlyingFile = true
        @subscribeToFileChange()

    @subscriptions.add @editor.onDidDestroy =>
      @destroy()

  subscribeToFileChange: ->
    @currPath = @editor.getPath()

    if @useFsWatchFile
      # try to use watchFile to handle changes on file systems that don't support inotify
      # remove existing watch first
      fs.unwatchFile @currPath
      fs.watchFile @currPath, (curr, prev) =>
        @confirmReload() if @showChangePrompt and not @ignoreChange and curr.mtime.getTime() > prev.mtime.getTime()
        @ignoreChange = false if @ignoreChange

    @subscriptions.add @editor.getBuffer()?.file.onDidChange =>
      @changeInterceptor()

    # call this to reset order of events, otherwise buffer fires first
    @editor.getBuffer()?.subscribeToFile()

  isBufferInConflict: ->
    return @editor.getBuffer()?.isInConflict()

  changeInterceptor: ->
    (log 'Change: ' + @editor.getPath()) if @debug
    @editor.getBuffer()?.conflict = true if @showChangePrompt

    # ignore if handled by the non-mounted file system
    @ignoreChange = true if @useFsWatchFile and @showChangePrompt

  conflictInterceptor: ->
    (log 'Conflict: ' + @editor.getPath()) if @debug
    @confirmReload() if @isBufferInConflict()

  forceReload: ->
    if @useFsWatchFile
      # force a re-read from the file then reload
      @editor.buffer.updateCachedDiskContents true, => @editor.getBuffer()?.reload()
    else
      @editor.getBuffer()?.reload()

  confirmReload: ->
    # if the user has selected autoReload we can just reload and exit
    if @autoReload
      @forceReload()
      return

    choice = atom.confirm
      message: 'The file "' + path.basename(@currPath) + '" has changed.'
      buttons: if @includeCompareOption then ['Reload', 'Ignore', 'Ignore All', 'Compare'] else ['Reload', 'Ignore', 'Ignore All']

    if choice is 0 # Reload
      @forceReload()
      return

    if choice is 1 #Ignore
      @editor.getBuffer()?.emitModifiedStatusChanged(true)
      return

    if choice is 2 # Ignore All
      @destroy()
      return

    # Compare
    scopePath = @editor.getPath()
    scopePostCompare = @postCompareCommand

    currEncoding = @editor.getBuffer()?.getEncoding() || 'utf8'
    currGrammar = @editor.getGrammar()
    currView = atom.views.getView(@editor)

    compPromise = atom.workspace.open null,
      split: 'right'

    compPromise.then (ed) ->
      # @currPath is lost so use path from closure
      ed.insertText fs.readFileSync(scopePath, encoding: currEncoding)
      ed.setGrammar currGrammar
      atom.commands.dispatch(currView, scopePostCompare) if scopePostCompare

  destroy: ->
    @subscriptions.dispose()
    (fs.unwatchFile @currPath) if @currPath and @hasUnderlyingFile
    @emitter.emit 'did-destroy'

  onDidDestroy: (callback) ->
    @emitter.on 'did-destroy', callback
