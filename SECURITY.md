# Security

This repo must stay safe to clone onto a fresh Mac without exposing private state.

Do not commit:

- API keys, tokens, passwords, cookies, or auth headers
- Private email addresses beyond public noreply-style Git config
- Machine-local absolute paths outside this repo model
- Raycast `.rayconfig` exports or their passphrases
- Decrypted Codex state archives, raw Codex memories, or Codex memory exports
- Mackup backup contents
- App caches, histories, databases, or session state

Local-only shell state belongs under:

```text
~/.config/local/*.zsh
home/.config/local/*.zsh
```

The tracked shell config sources those files if present. Keep secrets there or in Keychain-backed tooling, not in tracked dotfiles. Repo-local examples may be tracked as `*.example`; real `*.zsh` files must stay ignored.

Before committing, run:

```bash
git diff --check
git diff --cached --check
```

Then scan any new config files for private values.
