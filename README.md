# [L4D2] CS: GO-Style Sniper Rifle Run Speed
This is a SourceMod Plugin that lets you change the run speed of survivors when they're holding either an AWP, Hunting Rifle or Sniper Rifle similar to CS: GO. This plugin can be useful if you have the base damage of these weapons modified and want to make usage of them require more skill to avoid them being too overpowered.

**You may not want to use this plugin if you're running a listen server** (which is generally not recommended anyway). This is because the speed is only changed on the server side and the desync between server and client gets very noticeable.

# CVars
- `survivor_awp_run_speed` (set to `220.0` by default)
- `survivor_sniper_rifle_run_speed` (set to `220.0` by default)
- `survivor_hunting_rifle_run_speed` (set to `220.0` by default)

# Known Issues
- Desync between server and client as speed is changed server-side only

# Requirements
- [SourceMod 1.11+](https://www.sourcemod.net/downloads.php?branch=stable)

# Supported Platforms
- Windows
- Linux

# Supported Games
- Left 4 Dead 2