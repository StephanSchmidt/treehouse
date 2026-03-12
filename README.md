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

| Option    | Type   | Default    | Description                                      |
|-----------|--------|------------|--------------------------------------------------|
| `version` | string | `"latest"` | Version of the human CLI (e.g. `"0.4.0"` or `"latest"`) |

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
