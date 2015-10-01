# Atom file-watcher Package

This package watches open files for conflicts or changes, then uses the Atom confirm feature to prompt to reload each file.

You can turn the prompts for changes on and off in the package settings.

There is also a prompt option to open the original file in a new Atom window so that you can compare your current version with the disk version.

## Installation
Either use `apm`:
```
  apm install file-watcher
```

Or find the package in the Atom registry and install.

## Settings

#### Include the Compare option

Enable this setting to add the Compare option to the Reload/Ignore prompt, which will open the file in a new editor so you can see the on-disk changes.
Enabled by default.

#### Prompt on Change

Enable this setting to also show the Reload/Ignore prompt when the file changes on disk, even if there are no unsaved changes in Atom

## License

MIT License -- Copyright (c) 2015 Laurence Blackledge
