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
      atom.packages.activatePackage('file-watcher')

    waitsForPromise ->
      atom.workspace.open @testFile

    runs ->
      editor = atom.workspace.getActiveTextEditor()

  it 'does nothing when there is no conflict', ->
    expect(editor.fileWatcher).toBeTruthy()
    expect(editor.fileWatcher.shouldPromptToReload()).toBeFalsy()

  it 'should prompt when there is a conflict', ->
    editor.buffer.conflict = true
    expect(editor.fileWatcher).toBeTruthy()
    expect(editor.fileWatcher.shouldPromptToReload()).toBeTruthy()

  it 'should not prompt when there is a conflict and the user has disabled prompts', ->
    editor.buffer.conflict = true
    expect(editor.fileWatcher).toBeTruthy()
    expect(editor.fileWatcher.shouldPromptToReload()).toBeTruthy()

  it 'should reload if the user selects reload', ->
    spyOn(atom, 'confirm').andReturn(0)
    spyOn(editor.buffer, 'reload')

    editor.moveToEndOfLine()
    editor.insertText('test')
    fs.appendFileSync(@testFile, 'more text')

    expect(editor.fileWatcher).toBeTruthy()
    expect(editor.buffer.reload).toHaveBeenCalled()

    fs.writeFile(@testFile, initialFileContents)

  it 'should not reload if the user selects ignore', ->
    spyOn(atom, 'confirm').andReturn(1)
    spyOn(editor.buffer, 'reload')

    editor.moveToEndOfLine()
    editor.insertText('test')
    fs.appendFileSync(@testFile, 'more text')

    expect(editor.fileWatcher).toBeTruthy()
    expect(editor.buffer.reload).not.toHaveBeenCalled()

    fs.writeFile(@testFile, initialFileContents)
