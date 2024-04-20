local builtin = require('telescope.builtin')


vim.keymap.set('n', '<leader>ff', builtin.find_files, {})
vim.keymap.set('n', '<leader>fg', builtin.live_grep, {})
vim.keymap.set('n', '<leader>fb', builtin.buffers, {})
vim.keymap.set('n', '<leader>fh', builtin.help_tags, {})



vim.keymap.set('v', '<leader>cch',
  function()
    local actions = require("CopilotChat.actions")
    require("CopilotChat.integrations.telescope").pick(actions.help_actions({
      selection = require("CopilotChat.select").visual
    }))
  end
  , {})

vim.keymap.set('v', '<leader>ccp',
  function()
    local actions = require("CopilotChat.actions")
    require("CopilotChat.integrations.telescope").pick(actions.prompt_actions({
      selection = require("CopilotChat.select").visual
    }))
  end
  , {})

vim.keymap.set('n', '<leader>ccp',
  function()
    local actions = require("CopilotChat.actions")
    require("CopilotChat.integrations.telescope").pick(actions.prompt_actions({
      selection = require("CopilotChat.select").buffer
    }))
  end
  , {})
