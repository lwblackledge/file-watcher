fs = require 'fs'
path = require 'path'
FileWatcher = require '../lib/file-watcher'

describe "FileWatcher", ->
  [editor, initialFileContents] = []

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
    expect(editor.fileWatcher).toBeTruthy()
    expect(editor.fileWatcher.shouldPromptToReload()).toBeFalsy()

  it 'should prompt when there is a conflict', ->
    editor.moveToEndOfLine()
    editor.insertText('test')
    fs.appendFileSync(@testFile, 'other text')

    expect(editor.fileWatcher).toBeTruthy()
    expect(editor.fileWatcher.shouldPromptToReload()).toBeTruthy()

    fs.writeFile(@testFile, initialFileContents)

  it 'should not prompt when there is a conflict and the user has disabled prompts', ->
    
    editor.moveToEndOfLine()
    editor.insertText('test')
    fs.appendFileSync(@testFile, 'other text')

    expect(editor.fileWatcher).toBeTruthy()
    expect(editor.fileWatcher.shouldPromptToReload()).toBeTruthy()

    fs.writeFile(@testFile, initialFileContents)
