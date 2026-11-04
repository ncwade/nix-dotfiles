-- Rex configuration for ncwade's Ghostty/fish setup on luna.
-- Install at ~/.config/rex/init.lua; apply with: rex config reload
-- Validate with: rex config check
-- Reference: https://www.superlogical.com/rex/docs/customize/config
-- Settings: https://www.superlogical.com/rex/docs/reference/mac-settings
--
-- Appearance and the default shell are configured in Rex Settings, not Lua.
-- Apply these once in Settings to match the existing Ghostty configuration:
--
-- Terminal > Shell > Startup command:
--   /run/current-system/sw/bin/fish --login --interactive
-- This loads the existing fish config, including Starship, direnv, mise,
-- Nix/Homebrew paths, and the 1Password SSH agent. No duplicate shell hooks
-- or environment overrides are needed here.
--
-- Themes > Import Theme:
--   ~/.config/rex/catppuccin-mocha.conf
-- Then select the imported theme under Themes > Dark Mode.
-- Interface > Appearance: Dark; Classic; Tint with theme on.
-- Terminal > Typography: 14 pt. JetBrainsMono Nerd Font is a recommended
-- choice for the prompt's symbols; Ghostty does not explicitly set a family.
-- Interface > Pane Padding: X = 16, Y = 16; use the pane background.
-- Terminal > Colors: Force theme palette for text off, preserving Starship's
-- explicit RGB colors. Use extended theme palette off (under Themes) to keep
-- the standard xterm colors 16-255; this theme defines only colors 0-15.
-- Terminal > Selection: background #353749, foreground #cdd6f4 if the theme
-- importer does not carry them across.
-- Terminal > Cursor: Force style off so fish and editors can choose a shape.
--
-- The documented Settings/Lua API has no mouse-hide-while-typing equivalent.
-- Rex manages sessions, tabs, and panes directly; no tmux runs inside it.
-- Let Rex supply TERM. Fish will select ~/.config/starship.toml because TMUX
-- is unset, retaining the normal Catppuccin Mocha prompt.
-- Terminal > Keyboard: enable Show key sequence hints for the Ctrl-S prefix.
-- Key sequences: https://www.superlogical.com/rex/docs/customize/key-sequences

-- Familiar split shortcuts, explicitly recorded here for portability.
rex.bind("cmd+d", "pane.split.right")
rex.bind("shift+cmd+d", "pane.split.down")

-- Use the same h/j/k/l directions as tmux, with Cmd-Option for Rex panes.
rex.bind("alt+cmd+h", "pane.focus.left")
rex.bind("alt+cmd+j", "pane.focus.down")
rex.bind("alt+cmd+k", "pane.focus.up")
rex.bind("alt+cmd+l", "pane.focus.right")

-- Keep Rex's other defaults, including Cmd-T for a tab and
-- Shift-Cmd-Enter to zoom/unzoom a pane.

-- Carry over the existing tmux Ctrl-S prefix to Rex itself.
-- Press Ctrl-S, release it, then the second key; Escape cancels a sequence.
rex.bind("ctrl+s>h", "pane.focus.left")
rex.bind("ctrl+s>j", "pane.focus.down")
rex.bind("ctrl+s>k", "pane.focus.up")
rex.bind("ctrl+s>l", "pane.focus.right")
rex.bind("ctrl+s>c", "client.tab.new")
rex.bind("ctrl+s>n", "client.tab.next")
rex.bind("ctrl+s>p", "client.tab.previous")
-- % and double quote on a US keyboard, matching tmux's default splits.
rex.bind("ctrl+s>shift+5", "pane.split.right")
rex.bind("ctrl+s>shift+'", "pane.split.down")
rex.bind("ctrl+s>z", "pane.zoom")
rex.bind("ctrl+s>s", "session.switch")
rex.bind("ctrl+s>r", "client.config.reload")
-- Send a literal Ctrl-S to a terminal program by pressing it twice.
rex.bind("ctrl+s>ctrl+s", "pane.send_key", { key = "ctrl+s" })
