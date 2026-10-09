# markdown-agenda.nvim

A small Markdown task agenda for Neovim. It reads Obsidian Tasks-style checkboxes, groups tasks under their enclosing Markdown heading, and presents them in [snacks.nvim](https://github.com/folke/snacks.nvim)'s picker.

## Requirements

- Neovim
- [snacks.nvim](https://github.com/folke/snacks.nvim) with its picker enabled

## Installation with lazy.nvim

Use the local checkout while developing, or replace `dir` with this repository's Git URL once published:

```lua
{
  dir = '~/www/personal-projects/markdown-agenda.nvim',
  dependencies = { 'folke/snacks.nvim' },
  opts = {
    files = { '~/notes/Planning.md' },
  },
  keys = {
    { '<leader>za', function() require('markdown_agenda').open() end, desc = 'Markdown agenda' },
    { '<leader>zA', function() require('markdown_agenda').open { all = true } end, desc = 'Markdown agenda (all)' },
    { '<leader>zx', function() require('markdown_agenda').cycle() end, desc = 'Cycle task status' },
  },
}
```

To disable the agenda, disable or remove this lazy.nvim spec. The plugin has no built-in global keymaps; choose the mappings that suit your config.

## API

```lua
require('markdown_agenda').setup {
  files = { '~/notes/Planning.md', '~/notes/Projects.md' },
}

require('markdown_agenda').open() -- active tasks: TODO, DOING, WAITING
require('markdown_agenda').open { all = true } -- include DONE and CANCELLED
require('markdown_agenda').open { filter = { DOING = true } }
require('markdown_agenda').cycle() -- cycle marker on current line
require('markdown_agenda').set('x') -- set marker on current line
```

Recognized markers are `[ ]` TODO, `[/]` DOING, `[?]` WAITING, `[x]` DONE, and `[-]` CANCELLED.
