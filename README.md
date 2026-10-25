# alpine-zsh

A tiny Alpine container with a fully set-up zsh shell, for working with Docker volumes and bind mounts.

Includes oh-my-zsh, zinit plugins and powerlevel10k, all fetched at build time, so the shell starts instantly with no downloads.

Docker Hub: [darco2903/alpine-zsh](https://hub.docker.com/r/darco2903/alpine-zsh)

## Pull

```sh
docker pull darco2903/alpine-zsh
```

Images for `linux/amd64` and `linux/arm64` are published to Docker Hub by GitHub Actions: `latest` from `main`, and `1.2.3` / `1.2` / `1` from `v1.2.3` tags.

## Build

```sh
docker build -t darco2903/alpine-zsh .
```

Dotfiles are taken from `build/` (`.zshrc`, `.zsh_aliases`, `.p10k.zsh`). Edit them and rebuild to customize the shell; the local build replaces the pulled image under the same name.

## Run

```sh
docker run --rm -it --hostname zsh darco2903/alpine-zsh
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
  darco2903/alpine-zsh
```

`-v` creates a named volume when the source is a name (`myvolume`), and a bind mount when it is a path (`/abs/path` or `./rel`).

### Copy between volumes

```sh
docker run --rm -it -v oldvol:/from -v newvol:/to darco2903/alpine-zsh zsh
# inside the container:
cp -a /from/. /to/
```

## Shortcut

Add this to your host `~/.zshrc` to open a shell with any mix of volumes and folders mounted under `/vol`:

```sh
dsh() {
  local IMAGE="darco2903/alpine-zsh"
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
  docker run --rm -it --hostname alpine-zsh -v "$PWD":/host "${args[@]}" -w /vol "$IMAGE"
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
