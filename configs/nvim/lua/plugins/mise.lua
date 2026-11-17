-- The mise language server checks mise config files: unknown and deprecated
-- keys, wrong value types, and unknown task names. It ignores other TOML files,
-- such as Cargo.toml. Taplo, from the LazyVim TOML extra, keeps formatting.
-- The server reads config*.toml only in a folder named mise or .mise, so it
-- ignores configs/mise/config/config*.toml in a dotfiles checkout. It reads
-- them through ~/.config/mise, which links to the main checkout. In a
-- worktree, ./bin/preflight reports their unknown and deprecated keys.
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
