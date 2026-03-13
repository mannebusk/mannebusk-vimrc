local spinner_frames = { '⣾', '⣽', '⣻', '⢿', '⡿', '⣟', '⣯', '⣷' }

return {
  desc = 'Detect ReScript watch markers and auto-refresh quickfix',
  params = {
    auto_refresh_qf = {
      type = 'boolean',
      default = true,
      desc = 'Automatically call :RES on build finish',
    },
  },
  constructor = function(params)
    local notification = nil
    local spinner_idx = 0
    local spinning = false

    local function spin()
      if not spinning then return end
      spinner_idx = (spinner_idx % #spinner_frames) + 1
      notification = vim.notify('Compiling...', vim.log.levels.INFO, {
        title = 'ReScript',
        icon = spinner_frames[spinner_idx],
        replace = notification,
        hide_from_history = true,
      })
      vim.defer_fn(spin, 100)
    end

    return {
      on_output_lines = function(_, _, lines)
        for _, line in ipairs(lines) do
          if line:find('>>>> Start') then
            spinning = true
            spin()
          elseif line:find('>>>> Finish') then
            spinning = false
            if params.auto_refresh_qf then
              local rescript = require('rescript')
              rescript.run({ replace_notification = notification, open_qf = rescript.config.open_qf_on_watch })
            end
            notification = nil
          end
        end
      end,
    }
  end,
}
