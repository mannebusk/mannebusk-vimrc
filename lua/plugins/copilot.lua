local chat = require("CopilotChat")

chat.setup {
  debug = true, -- Enable debugging

  -- Change the window layout to float and position relative to cursor to make the window look like inline chat.
  window = {
    layout = 'float',
    relative = 'cursor',
    width = 95,
    height = 0.4,
    row = 1
  },

  -- Key mappings
  mappings = {
    complete = {
      detail = 'Use /<C-n> for options.',
      insert = '<C-n>',
    },
    close = {
      normal = 'q',
      insert = '<C-c>'
    },
    reset = {
      normal = '<C-l>',
      insert = '<C-l>'
    },
    submit_prompt = {
      normal = '<CR>',
      insert = '<C-m>'
    },
    accept_diff = {
      normal = '<C-y>',
      insert = '<C-y>'
    },
    yank_diff = {
      normal = 'cgy',
    },
    show_diff = {
      normal = 'cgd'
    },
    show_system_prompt = {
      normal = 'cgp'
    },
    show_user_selection = {
      normal = 'cgs'
    },
  }
}



--
-- Quick chat with Copilot
--    - Whole buffer in normal mode
--    - Visual selection in visual mode
--
vim.keymap.set('n', '<leader>ccq', function()
  local input = vim.fn.input("Ask Copilot: ")
  if input ~= "" then
    require("CopilotChat").ask(input, { selection = require("CopilotChat.select").buffer })
  end
end)

vim.keymap.set('v', '<leader>ccq', function()
  local input = vim.fn.input("Ask Copilot: ")
  if input ~= "" then
    require("CopilotChat").ask(input, { selection = require("CopilotChat.select").visual })
  end
end)

--
-- Select help actions using telescope
--
vim.keymap.set('v', '<leader>cch',
  function()
    local actions = require("CopilotChat.actions")
    require("CopilotChat.integrations.telescope").pick(actions.help_actions({
      selection = require("CopilotChat.select").visual
    }))
  end
  , {})

--
-- Select prompt actions using telescope
--
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
