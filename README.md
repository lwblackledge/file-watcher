# Atom file-watcher Package

This package watches open files for conflicts or changes, then uses the Atom confirm feature to prompt to reload each file.

You can turn the prompts for changes on and off in the package settings.

There is also a prompt option to open the original file in a new Atom window so that you can compare your current version with the disk version.

If you are looking at a file that has frequent changes you can also choose to 'Ignore All' changes, which will stop any future alerts until you reload the entire Atom window.

## Installation
Either use `apm`:
```
  apm install file-watcher
```

Or find the package in the Atom registry and install.

## Settings

#### AutoReload

Reload without a prompt. Warning: Overrides "Prompt on Change" and "Include the Compare option", and may cause a loss of work!

#### Include the Compare option

Enable this setting to add the Compare option to the Reload/Ignore prompt, which will open the file in a new editor so you can see the on-disk changes.
Enabled by default.

#### Prompt on Change

Enable this setting to also show the Reload/Ignore prompt when the file changes on disk, even if there are no unsaved changes in Atom.

#### Post-Compare Command

Define an Atom command to run after the compare is shown e.g. split-diff:toggle

#### Use WatchFile

Some file systems like SSHFS or FTP don't support `inotify` and Atom cannot tell when they change. This option adds polling and should only be enabled if you are using a file system like SSHFS or FTP. There may be a slight delay as it polls every 5 seconds, and some reloads can be delayed due to network latency.

## License

MIT License -- Copyright (c) 2015-2018 Laurence Blackledge
