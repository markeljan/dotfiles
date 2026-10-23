local fish_shell = vim.fn.has("win32") == 1 and "" or vim.fn.exepath("fish")

local function set_base_highlights()
  vim.api.nvim_set_hl(0, "Normal", { bg = "NONE", ctermbg = "NONE" })
  vim.api.nvim_set_hl(0, "NormalFloat", { bg = "NONE", ctermbg = "NONE" })
end

vim.opt.termguicolors = true
vim.opt.number = true
vim.opt.relativenumber = false
vim.opt.cursorline = true
vim.opt.signcolumn = "yes"
vim.opt.mouse = "a"
vim.opt.mousescroll = "ver:1,hor:3"
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.hidden = true
vim.opt.confirm = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.scrolloff = 4
vim.opt.sidescrolloff = 8
vim.opt.wrap = false
vim.opt.expandtab = true
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.softtabstop = 2
vim.opt.smartindent = true
vim.opt.updatetime = 250
vim.opt.timeoutlen = 400

if vim.fn.has("clipboard") == 1 then
  vim.opt.clipboard = "unnamedplus"
end

if fish_shell ~= "" then
  vim.opt.shell = fish_shell
  vim.opt.shellcmdflag = "-c"
  vim.opt.shellquote = ""
  vim.opt.shellxquote = ""
end

vim.cmd.colorscheme("default")
set_base_highlights()

vim.api.nvim_create_autocmd("ColorScheme", {
  pattern = "*",
  callback = set_base_highlights,
})
