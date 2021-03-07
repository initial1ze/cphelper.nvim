local s = require "plenary.scandir"
local f = require "plenary.filetype"
local h = require "helpers"
local run = require "run_test"
local fw = require "plenary.window.float"

local function compile(ft)
  local exit_status = 0
  if ft == 'c' then
    exit_status = os.execute(h.vglobal_or_default("cpp_compile_command",
                                                  "gcc solution.c -o c.out"))
  elseif ft == 'cpp' then
    exit_status = os.execute(h.vglobal_or_default("c_compile_command",
                                                  "g++ solution.cpp -o cpp.out"))
  else
  end
  return exit_status
end

local function cmd(ft)
  if (ft == "python") then
    return "python solution.py"
  elseif (ft == "c") then
    return "./c.out"
  elseif (ft == "cpp") then
    return "./cpp.out"
  else
  end
end

local M = {}

function M.wrapper(...)
  local args = {...}
  local cwd = vim.fn.getcwd()
  local ft = f.detect(vim.api.nvim_buf_get_name(0))
  local results = {}
  if compile(ft) == 0 then
    if #args == 0 then
      for _, input_file in ipairs(s.scan_dir(cwd, {
        search_pattern = "input%d+",
        depth = 1
      })) do
        local result = run.run_test(string.sub(input_file, string.len(cwd) -
                                                   string.len(input_file) + 1),
                                    cmd(ft))
        vim.list_extend(results, result)
      end
    else
      for _, case in ipairs(args) do
        local result = run.run_test("input" .. case, cmd(ft))
        vim.list_extend(results, result)
      end
    end
    local win_info = fw.centered()
    local bufnr, win_id = win_info.bufnr, win_info.win_id
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, true, results)
    vim.api.nvim_buf_set_option(bufnr, 'modifiable', false)
    vim.api.nvim_buf_set_option(bufnr, 'filetype', 'Results')
  else
    vim.api.nvim_err_writeln("Compilation error")
  end
end

function M.retest_wrapper(...)
  local args = {...}
  local cwd = vim.fn.getcwd()
  local ft = f.detect(vim.api.nvim_buf_get_name(0))
  local results = {}
  if #args == 0 then
    for _, input_file in ipairs(s.scan_dir(cwd, {
      search_pattern = "input%d+",
      depth = 1
    })) do
      local result = run.run_test(string.sub(input_file, string.len(cwd) -
                                                 string.len(input_file) + 1),
                                  cmd(ft))
      vim.list_extend(results, result)
    end
  else
    for _, case in ipairs(args) do
      local result = run.run_test("input" .. case, cmd(ft))
      vim.list_extend(results, result)
    end
  end
  local win_info = fw.centered()
  local bufnr, win_id = win_info.bufnr, win_info.win_id
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, true, results)
  vim.api.nvim_buf_set_option(bufnr, 'modifiable', false)
  vim.api.nvim_buf_set_option(bufnr, 'filetype', 'Results')
end

return M