FROM alpine:3.24 AS zsh
RUN apk add --no-cache zsh
COPY ./build/.zsh_aliases ./build/.p10k.zsh /root/

FROM zsh AS builder
RUN apk add --no-cache git curl
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
# copy .zshrc after oh-my-zsh installation to avoid overwriting it
COPY ./build/.zshrc /root/
RUN TERM=xterm-256color zsh -c "source /root/.zshrc"
# zsh -c only returns the status of the last line, so check every `zinit light` plugin was cloned
RUN for p in $(sed -n 's/^[^#]*zinit light \([^ ;]*\).*/\1/p' /root/.zshrc); do \
    d="/root/.local/share/zinit/plugins/$(echo "$p" | sed 's|/|---|')"; \
    [ -n "$(ls -A "$d" 2>/dev/null)" ] || { echo "zinit plugin $p was not installed" >&2; exit 1; }; \
    done
RUN /root/.local/share/zinit/plugins/romkatv---powerlevel10k/gitstatus/install
RUN find /root/.oh-my-zsh /root/.local/share/zinit -name .git -prune -exec rm -rf {} +

FROM zsh
COPY ./build/.zshrc /root/
COPY --from=builder /root/.oh-my-zsh /root/.oh-my-zsh
COPY --from=builder /root/.local/share/zinit /root/.local/share/zinit
COPY --from=builder /root/.cache/gitstatus /root/.cache/gitstatus
CMD ["zsh"]
