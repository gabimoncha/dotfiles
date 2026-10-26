# Host: NAS development container

You are on `t3-dev`, a Debian 12 Docker container on a Synology NAS. The owner's
Mac is the main machine. This box is for code generation, review, and
automation.

## Limits

- Memory: 6 GiB for the whole container, shared by T3, every agent, and every
  build. CPU: 4 threads (AMD Ryzen R1600).
- Kernel 4.4 has no user namespaces, so `bwrap` and the agent sandboxes fail.
  Commands run without a sandbox, and the container is the only boundary.
- There is no systemd and no Docker. T3 runs under `~/.local/bin/t3-supervise`,
  and the tokenburnmarket daemon under `~/.local/bin/tokenburnmarket-supervise`.
- Only Linux builds run here. iOS, Xcode, simulators, Android emulators, and
  macOS apps need the Mac.

## How to work here

- Keep test runs small: run the tests for the files you changed, one process at
  a time. Ask the owner before a full build or a full test suite.
- Hand work to the Mac when it needs a simulator, a device, a GUI app, Xcode,
  Docker, or more memory. Write the exact commands the owner should run there.
- Use `bun` to run scripts. The Mac and Linux tools are in
  `~/.config/mise/config.toml`. Ask before you install a tool that is missing.
- GitHub access can be missing. Check it with `gh auth status`, and report a
  missing login to the owner.
