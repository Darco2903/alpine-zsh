FROM alpine:latest AS zsh
RUN apk add --no-cache zsh
COPY ./build/.zsh_aliases ./build/.p10k.zsh /root/

FROM zsh AS builder
RUN apk add --no-cache git curl
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
# copy .zshrc after oh-my-zsh installation to avoid overwriting it
COPY ./build/.zshrc /root/
RUN TERM=xterm-256color zsh -c "source /root/.zshrc"
RUN /root/.local/share/zinit/plugins/romkatv---powerlevel10k/gitstatus/install

FROM zsh
COPY ./build/.zshrc /root/
COPY --from=builder /root/.oh-my-zsh /root/.oh-my-zsh
COPY --from=builder /root/.local/share/zinit /root/.local/share/zinit
COPY --from=builder /root/.local/share/zinit /root/.local/share/zinit
COPY --from=builder /root/.cache/gitstatus /root/.cache/gitstatus
CMD ["zsh"]
