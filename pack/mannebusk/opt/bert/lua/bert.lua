-- bert.lua
-- Bert (Lumen surface) language support: filetype detection, tree-sitter
-- highlighting, and rebuilding the bundled grammar from the monorepo source.
--
-- The compiled parser lives in this plugin's `parser/bert.so` and the queries
-- in `queries/bert/`, so both are picked up from the runtimepath once the
-- plugin is `packadd`ed.

local M = {}

M.config = {
  -- Where the tree-sitter grammar sources live (grammar.js, src/, queries/).
  grammar_dir = '~/dev/bert/packages/tree-sitter-bert',
}

--- Root of this plugin, derived from the location of this file.
---@return string
local function plugin_root()
  local this_file = debug.getinfo(1, 'S').source:sub(2)
  -- <root>/lua/bert.lua -> <root>
  return vim.fn.fnamemodify(this_file, ':h:h')
end

local function notify(msg, level)
  vim.notify(msg, level, { title = 'Bert' })
end

--- Locate the tree-sitter CLI, preferring the grammar's own devDependency so
--- generated parsers match the version the grammar was authored against.
---@param grammar_dir string
---@return string|nil
local function tree_sitter_cli(grammar_dir)
  local local_cli = grammar_dir .. '/node_modules/.bin/tree-sitter'
  if vim.fn.executable(local_cli) == 1 then
    return local_cli
  end
  if vim.fn.executable('tree-sitter') == 1 then
    return 'tree-sitter'
  end
  return nil
end

--- Run a command, calling `on_success` with its stdout, or notifying on failure.
---@param cmd string[]
---@param cwd string
---@param step string Human-readable name of this step, used in error messages
---@param on_success fun()
local function run_step(cmd, cwd, step, on_success)
  vim.system(cmd, { cwd = cwd, text = true }, function(res)
    vim.schedule(function()
      if res.code ~= 0 then
        local detail = (res.stderr ~= '' and res.stderr or res.stdout) or ''
        notify(step .. ' failed:\n' .. vim.trim(detail), vim.log.levels.ERROR)
        return
      end
      on_success()
    end)
  end)
end

--- Regenerate, compile and install the grammar from source.
---
--- The parser is compiled to a temporary file and only moved into place once
--- `cc` succeeds, so a broken build never replaces a working parser.
function M.build_grammar()
  local grammar_dir = vim.fn.expand(M.config.grammar_dir)
  if vim.fn.isdirectory(grammar_dir) == 0 then
    notify('Grammar sources not found at ' .. grammar_dir, vim.log.levels.ERROR)
    return
  end

  local cli = tree_sitter_cli(grammar_dir)
  if not cli then
    notify('tree-sitter CLI not found (install it, or run pnpm install in the grammar package)',
      vim.log.levels.ERROR)
    return
  end

  local root = plugin_root()
  local parser_dir = root .. '/parser'
  local query_dir = root .. '/queries/bert'
  local tmp_so = vim.fn.tempname() .. '.so'

  local sources = { 'src/parser.c' }
  if vim.fn.filereadable(grammar_dir .. '/src/scanner.c') == 1 then
    table.insert(sources, 'src/scanner.c')
  end

  local compile = { 'cc', '-o', tmp_so, '-shared', '-fPIC', '-O2', '-I', 'src' }
  vim.list_extend(compile, sources)

  notify('Rebuilding grammar from ' .. grammar_dir .. '…')

  run_step({ cli, 'generate' }, grammar_dir, 'tree-sitter generate', function()
    run_step(compile, grammar_dir, 'Compiling parser', function()
      vim.fn.mkdir(parser_dir, 'p')
      vim.fn.mkdir(query_dir, 'p')

      local ok, err = pcall(function()
        assert(vim.uv.fs_rename(tmp_so, parser_dir .. '/bert.so'))
      end)
      if not ok then
        notify('Installing parser failed: ' .. tostring(err), vim.log.levels.ERROR)
        return
      end

      local copied = 0
      for _, query in ipairs(vim.fn.glob(grammar_dir .. '/queries/*.scm', false, true)) do
        local target = query_dir .. '/' .. vim.fn.fnamemodify(query, ':t')
        if vim.uv.fs_copyfile(query, target) then
          copied = copied + 1
        end
      end

      notify(('Grammar rebuilt (%d quer%s installed). Restart Neovim to load the new parser.')
        :format(copied, copied == 1 and 'y' or 'ies'))
    end)
  end)
end

function M.setup(opts)
  M.config = vim.tbl_deep_extend('force', M.config, opts or {})

  vim.filetype.add({ extension = { bert = 'bert' } })

  vim.api.nvim_create_autocmd('FileType', {
    group = vim.api.nvim_create_augroup('bert', { clear = true }),
    pattern = 'bert',
    callback = function()
      vim.treesitter.start()
    end,
  })

  vim.api.nvim_create_user_command('BertGrammarBuild', function() M.build_grammar() end, {
    desc = 'Rebuild the Bert tree-sitter grammar from source',
  })
end

return M
