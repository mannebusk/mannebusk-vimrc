local socket_dir = '/tmp/nvim-sockets'
vim.fn.mkdir(socket_dir, 'p')

local pid = vim.fn.getpid()
local socket_path = socket_dir .. '/nvim-' .. pid .. '.sock'
vim.fn.serverstart(socket_path)

-- Store the parent process (terminal) PID
-- Needed to later focus the terminal app when opening a link
local parent_pid_path = socket_dir .. '/nvim-' .. pid .. '.parent'
local parent_pid = vim.fn.system("ps -o ppid= -p " .. pid):gsub("%s+", "")
vim.fn.writefile({parent_pid}, parent_pid_path)

vim.api.nvim_create_autocmd('VimLeavePre', {
    callback = function()
        vim.fn.delete(socket_path)
        vim.fn.delete(parent_pid_path)
    end
})
