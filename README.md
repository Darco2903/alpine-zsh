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
  local IMAGE="alpine-zsh"
  local -a args
  local -A used
  local v src name n i
  for v in "$@"; do
    if [[ -e $v || $v == */* || $v == .* ]]; then
      src=${v:A} name=${v:A:t}   # bind: existing or path-like, named by folder
    else
      src=$v name=$v             # named volume
    fi
    n=$name
    for (( i = 2; ${+used[$n]}; i++ )); do n=$name-$i; done   # data, data-2, ...
    used[$n]=1
    args+=(-v "$src:/vol/$n")
  done
  docker run --rm -it --hostname "$IMAGE" -v "$PWD":/host "${args[@]}" -w /vol "$IMAGE"
}
```

```sh
dsh myvolume ~/Downloads ./backup
# → /vol/myvolume, /vol/Downloads, /vol/backup, plus the current folder at /host
```

- An argument is mounted as a folder if it exists on disk or looks like a path (contains `/` or starts with `.`), otherwise as a named volume. If a local folder and a volume share a name, the folder wins; run `dsh` from another directory to get the volume.
- Mounts with the same name get a suffix: `dsh a/data b/data` gives `/vol/data` and `/vol/data-2`.

## Notes

- The shell runs as root, so files it creates in bind mounts are owned by root on Linux hosts. Running with `--user` isn't supported, because the shell config lives in `/root`.
