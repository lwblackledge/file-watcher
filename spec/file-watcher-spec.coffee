fs = require 'fs'
path = require 'path'
FileWatcher = require '../lib/file-watcher'

describe "FileWatcher", ->
  [editor, initialFileContents, testFile] = []

  beforeEach ->
    testFile = path.join(__dirname, 'testFile.md')
    initialFileContents = fs.readFileSync(testFile)

    waitsForPromise ->
      atom.packages.activatePackage('file-watcher')

    waitsForPromise ->
      atom.workspace.open(path.join(__dirname, 'testFile.md'))

  it 'does nothing when there is no conflict', ->
    editor = atom.workspace.getActiveTextEditor()
    expect(editor.getPath()).toContain 'testFile.md'
    expect(editor.fileWatcher).toBeTruthy()
    expect(editor.fileWatcher.isBufferInConflict()).toBeFalsy()

  it 'should prompt when there is a conflict', ->
    editor = atom.workspace.getActiveTextEditor()
    editor.buffer.conflict = true
    expect(editor.fileWatcher).toBeTruthy()
    expect(editor.fileWatcher.isBufferInConflict()).toBeTruthy()

  it 'should prompt when there is a change and the user has enabled change prompt', ->
    editor = atom.workspace.getActiveTextEditor()
    atom.config.set('file-watcher.promptWhenChange', true)

    spyOn(editor.fileWatcher, 'confirmReload')

    editor.buffer.file.emitter.emit 'did-change'

    expect(editor.fileWatcher).toBeTruthy()
    expect(editor.fileWatcher.confirmReload).toHaveBeenCalled()

  it 'should reload if the user selects reload', ->
    editor = atom.workspace.getActiveTextEditor()

    spyOn(atom, 'confirm').andReturn(0)
    spyOn(editor.buffer, 'reload')

    editor.buffer.conflict = true

    expect(editor.fileWatcher).toBeTruthy()
    expect(editor.buffer.reload).toHaveBeenCalled()

    fs.writeFile(testFile, initialFileContents)

  it 'should open a second buffer if the user selects compare', ->
    editor = atom.workspace.getActiveTextEditor()

    spyOn(atom, 'confirm').andReturn(1)
    spyOn(atom.workspace, 'open')

    editor.buffer.conflict = true

    expect(editor.fileWatcher).toBeTruthy()
    expect(atom.workspace.open).toHaveBeenCalled()

  it 'should not reload if the user selects ignore', ->
    editor = atom.workspace.getActiveTextEditor()

    spyOn(atom, 'confirm').andReturn(2)
    spyOn(editor.buffer, 'reload')

    editor.buffer.conflict = true

    expect(editor.fileWatcher).toBeTruthy()
    expect(editor.buffer.reload).not.toHaveBeenCalled()

    fs.writeFile(testFile, initialFileContents)
