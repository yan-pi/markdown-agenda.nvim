-- Markdown task agenda for Neovim, displayed with snacks.nvim's picker.
local M = {}

local files = {}

local STATUS = {
  [' '] = 'TODO',
  ['/'] = 'DOING',
  ['?'] = 'WAITING',
  ['x'] = 'DONE',
  ['X'] = 'DONE',
  ['-'] = 'CANCELLED',
}

local ACTIVE = { TODO = true, DOING = true, WAITING = true }
local ORDER = { DOING = 1, WAITING = 2, TODO = 3, DONE = 4, CANCELLED = 5 }
local CYCLE = {
  [' '] = '/',
  ['/'] = '?',
  ['?'] = 'x',
  ['x'] = ' ',
  ['X'] = ' ',
  ['-'] = ' ',
}
local STATUS_HL = {
  TODO = 'DiagnosticWarn',
  DOING = 'DiagnosticInfo',
  WAITING = 'DiagnosticHint',
  DONE = 'Comment',
  CANCELLED = 'Comment',
}

local TASK_PATTERN = '^%s*[-*]%s+%[([ /%?xX%-])%]%s+(.+)$'
local HEADING_PATTERN = '^(#+)%s+(.+)$'

---@class MarkdownAgendaOptions
---@field files? string[] Markdown files scanned by the agenda

---@param opts? MarkdownAgendaOptions
function M.setup(opts)
  opts = opts or {}
  files = vim.tbl_map(vim.fn.expand, opts.files or {})
end

local function parse_file(path)
  local items = {}
  local ok, lines = pcall(vim.fn.readfile, path)
  if not ok or not lines then
    return items
  end

  local headings = {}
  for lnum, line in ipairs(lines) do
    local hashes, title = line:match(HEADING_PATTERN)
    if hashes then
      local level = #hashes
      headings[level] = title
      for k in pairs(headings) do
        if k > level then
          headings[k] = nil
        end
      end
    else
      local marker, text = line:match(TASK_PATTERN)
      if marker then
        local section
        for level = 6, 1, -1 do
          if headings[level] then
            section = headings[level]
            break
          end
        end
        table.insert(items, {
          file = path,
          pos = { lnum, 0 },
          status = STATUS[marker],
          project = section or vim.fn.fnamemodify(path, ':t:r'),
          body = text,
        })
      end
    end
  end
  return items
end

local function collect(opts)
  opts = opts or {}
  local items = {}
  for _, path in ipairs(opts.files or files) do
    for _, item in ipairs(parse_file(path)) do
      local include
      if opts.filter then
        include = opts.filter[item.status]
      elseif opts.all then
        include = true
      else
        include = ACTIVE[item.status]
      end
      if include then
        table.insert(items, item)
      end
    end
  end
  table.sort(items, function(a, b)
    local oa, ob = ORDER[a.status] or 99, ORDER[b.status] or 99
    if oa ~= ob then
      return oa < ob
    end
    if a.project ~= b.project then
      return a.project < b.project
    end
    return a.body < b.body
  end)
  return items
end

---@class MarkdownAgendaOpenOptions
---@field all? boolean Include completed and cancelled tasks
---@field filter? table<string, boolean> Status filter
---@field files? string[] Files to scan instead of configured files
---@field title? string Picker title

---@param opts? MarkdownAgendaOpenOptions
function M.open(opts)
  opts = opts or {}
  local items = collect(opts)
  if #items == 0 then
    vim.notify('No matching tasks in agenda files', vim.log.levels.WARN)
    return
  end

  Snacks.picker.pick({
    source = 'markdown_agenda',
    title = opts.title or 'Markdown Agenda',
    items = items,
    format = function(item)
      local hl = STATUS_HL[item.status] or 'Normal'
      return {
        { string.format('%-9s', item.status), hl },
        { string.format('[%s] ', item.project), 'Comment' },
        { item.body },
      }
    end,
  })
end

---Cycle the task marker on the current line: [ ] -> [/] -> [?] -> [x] -> [ ]
function M.cycle()
  local row = vim.api.nvim_win_get_cursor(0)[1]
  local line = vim.api.nvim_get_current_line()
  local prefix, marker, rest = line:match('^(%s*[-*]%s+%[)([ /%?xX%-])(%].*)$')
  if not marker then
    vim.notify('No task marker on this line', vim.log.levels.INFO)
    return
  end
  local new = prefix .. (CYCLE[marker] or ' ') .. rest
  vim.api.nvim_buf_set_lines(0, row - 1, row, false, { new })
end

---Set an explicit task marker on the current line.
---@param target string One of " ", "/", "?", "x", "-"
function M.set(target)
  local row = vim.api.nvim_win_get_cursor(0)[1]
  local line = vim.api.nvim_get_current_line()
  local prefix, _, rest = line:match('^(%s*[-*]%s+%[)([ /%?xX%-])(%].*)$')
  if not prefix then
    vim.notify('No task marker on this line', vim.log.levels.INFO)
    return
  end
  vim.api.nvim_buf_set_lines(0, row - 1, row, false, { prefix .. target .. rest })
end

return M
