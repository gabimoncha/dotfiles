-- tsrs, the Rust port of TypeScript 7, replaces the tsgo server. A project's
-- own tsrs (node_modules/.bin/tsrs in the root or a parent) runs first, so the
-- project's pinned version checks it. Other projects use the global tsrs from
-- mise through ~/.config/tsrs/tsgo.
local global_tsrs = vim.fn.expand("~/.config/tsrs/tsgo")

local function project_tsrs(root)
  for dir in vim.fs.parents(vim.fs.joinpath(root, "x")) do
    local bin = vim.fs.joinpath(dir, "node_modules", ".bin", "tsrs")
    if vim.fn.executable(bin) == 1 then
      return bin
    end
  end
end

return {
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      -- tsrs takes the settings of the LazyVim TypeScript extra. LazyVim
      -- commit c8cd5a0 renamed its server from tsgo to tsc, and it maps the
      -- tsgo extra in lazyvim.json to tsc. Before that commit, there is no tsc.
      local base = opts.servers.tsc or opts.servers.tsgo or {}
      opts.servers.tsc = { enabled = false }
      opts.servers.tsgo = { enabled = false }
      opts.servers.tsrs = vim.tbl_deep_extend("force", base, {
        enabled = true,
        mason = false,
        cmd = function(dispatchers, config)
          local root = config.root_dir or vim.fn.getcwd()
          local exe = project_tsrs(root) or global_tsrs
          return vim.lsp.rpc.start({ exe, "--lsp", "--stdio" }, dispatchers, { cwd = root })
        end,
        root_markers = { "tsconfig.json", "jsconfig.json", "package.json", ".git" },
      })
    end,
  },
}
