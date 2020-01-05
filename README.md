# Nimspire

Save and rate your ideas with this ultra-lightweight command line tool.

### Requirements

- [Nim compiler](https://nim-lang.org/install.html)
- On MacOS you can simply run `brew install nim`

### Build

`nim c -d:release nimspire.nim`

### Usage

- Add a new idea: `./nimpsire`
- Only review: `./nimspire review`
- Only add: `./nimspire review`

I recommend adding the nimspire dir to your `PATH`,
so you can simply enter the command "nimspire".

You can find your ideas at `~/.nimspire/nimspire.db.txt`

Every line contains one idea. You can delete / reorder them manually too.

You can set up a backup folder in your `~/.nimspire/nimspire.ini`,
so you can sync your notes on multiple devices.

### Credits

Mice Pápai, 2017

> First project to try out this lovely language
> 
> Contributions are welcome
