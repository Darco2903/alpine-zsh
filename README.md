# alpine-zsh

A tiny Alpine container with a fully set-up zsh shell, for working with Docker volumes and bind mounts.

Includes oh-my-zsh, zinit plugins and powerlevel10k, all fetched at build time, so the shell starts instantly with no downloads.

## Build

```sh
docker build -t alpine-zsh .
```

Dotfiles are taken from `build/` (`.zshrc`, `.zsh_aliases`, `.p10k.zsh`). Edit them and rebuild to customize the shell.

## Run

```sh
docker run --rm -it --hostname zsh alpine-zsh
```

| Flag             | Purpose                       |
| ---------------- | ----------------------------- |
| `--rm`           | Remove the container on exit  |
| `-it`            | Interactive terminal          |
| `--hostname zsh` | Hostname shown in the prompt  |
| `-v <src>:<dst>` | Mount a volume or host folder |
| `-w <dir>`       | Starting directory            |

### Mount a volume and a host folder

```sh
docker run --rm -it --hostname alpine-zsh \
  -v myvolume:/data \
  -v "$PWD":/host \
  -w /data \
  alpine-zsh
```

`-v` creates a named volume when the source is a name (`myvolume`), and a bind mount when it is a path (`/abs/path` or `./rel`).

### Copy between volumes

```sh
docker run --rm -it -v oldvol:/from -v newvol:/to alpine-zsh zsh
# inside the container:
cp -a /from/. /to/
```

## Shortcut

Add this to your host `~/.zshrc` to open a shell with any mix of volumes and folders mounted under `/vol`:

```sh
dsh() {
  local args=()
  local IMAGE="alpine-zsh"
  for v in "$@"; do
    if [[ $v == */* || $v == .* ]]; then
      args+=(-v "${v:A}:/vol/${v:A:t}")   # bind: absolute path, named by folder
    else
      args+=(-v "$v:/vol/$v")              # named volume
    fi
  done
  docker run --rm -it --hostname "$IMAGE" -v "$PWD":/host "${args[@]}" -w /vol "$IMAGE"
}
```

```sh
dsh myvolume ~/Downloads ./backup
# → /vol/myvolume, /vol/Downloads, /vol/backup, plus the current folder at /host
```
