fs = require 'fs'
path = require 'path'
FileWatcher = require '../lib/file-watcher'
FileWatcherView = require '../lib/file-watcher-view'

describe "FileWatcher", ->
  [editor, initialFileContents] = []

  isFileWatcherPanel = (panel) ->
    return panel.item instanceOf FileWatcherView

  beforeEach ->
    atom.project.setPaths __dirname
    @testFile = path.join(__dirname, 'testFile.md')
    initialFileContents = fs.readFileSync(@testFile)

    waitsForPromise ->
      atom.workspace.open 'testFile.md'

    waitsForPromise ->
      atom.packages.activatePackage('file-watcher')

    runs ->
      editor = atom.workspace.getActiveTextEditor()

  it 'does nothing when there is no conflict', ->
    for panel in atom.workspace.getModalPanels
      do (panel) ->
        expect(isFileWatcherPanel(panel)).toBe false

  it 'shows modal when there is a conflict', ->
    editor.moveToEndOfLine()
    editor.insertText('test')
    fs.appendFileSync(@testFile, 'other text')

    hasFileWatcherModal = false

    for panel in atom.workspace.getModalPanels
      do (panel) ->
        if (isFileWatcherPanel(panel))
          hasFileWatcherModal = true

    fs.writeFile(@testFile, initialFileContents)

  it 'reloads file when ok button is clicked', ->
    editor.moveToEndOfLine()
    editor.insertText('test')
    fs.appendFileSync(@testFile, 'other text')

    hasFileWatcherModal = false

    for panel in atom.workspace.getModalPanels
      do (panel) ->
        if (isFileWatcherPanel(panel))
          
          hasFileWatcherModal = true

    fs.writeFile(@testFile, initialFileContents)'
