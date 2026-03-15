# treehouse

Devcontainer Features for the [human CLI](https://github.com/StephanSchmidt/human).

## Features

### `human`

Installs the `human` CLI — issue tracker interface for AI agents.

#### Usage

Add to your `devcontainer.json`:

```json
{
  "features": {
    "ghcr.io/stephanschmidt/treehouse/human:1": {}
  }
}
```

#### Options

| Option    | Type    | Default    | Description                                                                 |
|-----------|---------|------------|-----------------------------------------------------------------------------|
| `version` | string  | `"latest"` | Version of the human CLI (e.g. `"0.4.0"` or `"latest"`)                    |
| `proxy`   | boolean | `false`    | Install HTTPS proxy support (iptables + setup script). Requires NET_ADMIN.  |

#### Example with pinned version

```json
{
  "features": {
    "ghcr.io/stephanschmidt/treehouse/human:1": {
      "version": "0.4.0"
    }
  }
}
```

## Daemon mode

AI agents inside devcontainers typically use `human` in daemon mode, where credentials stay on the host. See the [human CLI docs](https://github.com/StephanSchmidt/human#devcontainer--remote-mode) for setup instructions.

## HTTPS proxy

The `human` daemon includes a transparent HTTPS proxy that filters outbound traffic from devcontainers using SNI-based domain matching — no certificates needed. This lets you control which external services an AI agent can reach.

### How it works

1. The daemon runs an HTTPS proxy on port 19287 that reads the SNI from TLS ClientHello
2. Domains are checked against an allowlist or blocklist in `.humanconfig.yaml`
3. Inside the container, iptables redirects all outbound HTTPS traffic to the proxy
4. Allowed connections are forwarded transparently; blocked connections are dropped

### Setup

**1. Configure allowed domains** in `.humanconfig.yaml` on the host:

```yaml
proxy:
  mode: allowlist    # or "blocklist"
  domains:
    - "*.github.com"
    - "api.openai.com"
    - "registry.npmjs.org"
```

- `allowlist` mode: only listed domains pass, everything else blocked
- `blocklist` mode: only listed domains blocked, everything else passes
- No `proxy:` section: block all (safe default)
- `*.example.com` matches subdomains but not `example.com` itself

**2. Start the daemon** on the host:

```bash
human daemon start
```

Copy the `HUMAN_PROXY_ADDR` from the output.

**3. Configure `devcontainer.json`:**

```json
{
  "features": {
    "ghcr.io/stephanschmidt/treehouse/human:1": {
      "proxy": true
    }
  },
  "capAdd": ["NET_ADMIN"],
  "remoteEnv": {
    "HUMAN_DAEMON_ADDR": "localhost:19285",
    "HUMAN_DAEMON_TOKEN": "<paste from 'human daemon token'>",
    "HUMAN_CHROME_ADDR": "localhost:19286",
    "HUMAN_PROXY_ADDR": "${localEnv:HUMAN_PROXY_ADDR}"
  },
  "forwardPorts": [19285, 19286],
  "postStartCommand": "sudo human-proxy-setup"
}
```

The `proxy: true` option installs `iptables` and the `human-proxy-setup` script at build time. At container start, `human-proxy-setup` reads `HUMAN_PROXY_ADDR` and sets up the iptables redirect. If `HUMAN_PROXY_ADDR` is not set, the script skips gracefully.

## Test devcontainer

The `test-devcontainer/` directory contains a ready-to-use devcontainer for testing. Build a fresh `human` binary, start the daemon, and open the devcontainer:

```bash
# Build the binary
cd /path/to/human/cli
go build -o /path/to/treehouse/test-devcontainer/human .

# Start the daemon
export HUMAN_PROXY_ADDR=$(human daemon start 2>&1 | grep HUMAN_PROXY_ADDR | awk -F= '{print $2}')

# Open the devcontainer
cd /path/to/treehouse/test-devcontainer
devcontainer up --workspace-folder .
```
