FROM mcr.microsoft.com/devcontainers/base:jammy

ARG USERNAME=vscode
USER $USERNAME

COPY kubelogin.sh /tmp/kubelogin.sh
RUN mkdir -p "$HOME/.local/bin" \
    && sudo chmod +x /tmp/kubelogin.sh \
    && /tmp/kubelogin.sh
ENV PATH="$HOME/.local/bin:${PATH}"
