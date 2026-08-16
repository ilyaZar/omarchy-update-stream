# Update Channel

A compact Omarchy Quattro update widget. Left-click the bar icon to run an
update and right-click it to choose a package channel, open the corresponding
GitHub activity, refresh update availability, or adjust icon behavior.

## Requirements

- Omarchy Quattro 4.0 or newer
- the stock `omarchy` CLI and Omarchy shell

## Install

```bash
omarchy plugin add \
  https://github.com/ilyaZar/omarchy-update-channel.git --enable
```

Enabling the plugin replaces the built-in `omarchy.system-update` widget in
place. Disabling or removing it restores the built-in widget.

## Use

- Left-click the icon to run `omarchy update` in a floating terminal.
- Right-click the icon to open the update and channel panel.
- Select a channel and press **Apply** to run
  `omarchy channel set <channel>` in a floating terminal.
- Select changelog, pull requests, or issues and press **Visit** to open the
  corresponding Omarchy GitHub page.
- Press **Refresh update info** to run `omarchy update status` and synchronize
  the icon with current update availability.

The selected channel is draft state. **Apply** remains disabled whenever the
selection matches the installed channel, including after selecting another
channel and then returning to the installed one.

Channel history follows Omarchy's current channel layout:

| Channel | Changelog target                      |
|---------|---------------------------------------|
| stable  | latest GitHub release                 |
| rc      | commits on `rc`                       |
| edge    | commits on `quattro`                  |
| dev     | active checkout branch or `quattro`   |

GitHub issues are repository-wide because issues do not target a branch. Pull
requests are filtered by the branch associated with the selected channel.

## Settings

**Run without confirmation (-y)** switches left-click updates between
`omarchy update` and `omarchy update -y`.

Icon visibility has three choices:

- **Show only when updates exist** follows update availability.
- **Hide until next availability check** hides temporarily; the next manual or
  six-hour check may reveal it again.
- **Always show with Omarchy logo** keeps the widget available and replaces the
  refresh glyph with Omarchy's packaged logo.

Settings are stored on the plugin's own entry in
`~/.config/omarchy/shell.json`. Apply, refresh, and settings changes give the
bar icon a short confirmation pulse. Its color can be selected from presets or
entered as a custom `#RRGGBB` value. The default is Wispr Flow purple,
`#a77bd8`.

The existing update-icon commands remain routed through the stock IPC target:

```bash
omarchy update status
omarchy shell -q omarchy.system-update refresh
omarchy shell -q omarchy.system-update clear
```

In always-show mode, `clear` clears update availability but keeps the logo
visible, as required by that mode.

## Design reference

The visual language is inspired by the local Keyboard Layout Pulse plugin at
`../keyboard-layout-quattro-plugin`: compact controls, muted disabled text,
small toggles, panel navigation, and pulsing feedback.

This plugin does not import, symlink, share state with, or otherwise depend on
that plugin. All runtime behavior is implemented independently here.

## Test

```bash
./tests/test_contract.sh
node ./tests/test_model.mjs
omarchy plugin validate "$PWD"
```

## Architecture

- `UpdateChannel.qml` coordinates settings, actions, IPC, and child components.
- `UpdateChannelService.qml` owns polling and all `omarchy` query processes.
- `UpdateChannelButton.qml` owns bar-icon rendering and pulse feedback.
- `UpdateChannelPanel.qml` connects the main and settings pages with explicit
  action signals.
- `UpdateChannelModel.js` contains pure normalization, command, and URL helpers
  covered by the model test.

The page components own draft UI state. They request actions through signals;
they do not launch commands, write settings, or reach into the root widget.

## Remove

```bash
omarchy plugin remove io.github.ilyazar.update-channel --yes
```

## License

MIT
