-- The mise language server checks mise config files: unknown and deprecated
-- keys, wrong value types, and unknown task names. It ignores other TOML files,
-- such as Cargo.toml. Taplo, from the LazyVim TOML extra, keeps formatting.
return {
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      opts.servers.mise = {
        mason = false,
        cmd = { "mise", "lsp" },
        filetypes = { "toml" },
        root_markers = { "mise.toml", ".mise.toml", ".git" },
        init_options = { formatting = false },
      }
    end,
  },
}
