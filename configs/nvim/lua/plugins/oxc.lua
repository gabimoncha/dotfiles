-- oxlint and oxfmt come from mise (configs/mise/config/config.toml), not from
-- Mason. Mason's copies are older, and oxlint finds tsrs-lint for its
-- type-aware rules only from 1.93. The language server turns on those rules
-- when the project's oxlint config sets options.typeAware. A project's own
-- node_modules/.bin/oxlint runs first.
return {
  {
    "neovim/nvim-lspconfig",
    opts = { servers = { oxlint = { mason = false } } },
  },
  {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = vim.tbl_filter(function(tool)
        return tool ~= "oxfmt" and tool ~= "oxlint"
      end, opts.ensure_installed or {})
      -- Put Mason's folder after the mise tools in PATH, so an older copy
      -- that Mason installed before this change does not hide them.
      opts.PATH = "append"
    end,
  },
}
