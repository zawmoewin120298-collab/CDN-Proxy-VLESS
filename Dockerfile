FROM alpine:latest

# လိုအပ်သော Packages များ သွင်းခြင်း
RUN apk add --no-cache curl bash jq ca-certificates

# ၁။ Sing-Box (Core Engine) ကို Download ဆွဲပြီး သွင်းခြင်း
RUN set -ex && \
    ARCH=$(uname -m) && \
    if [ "$ARCH" = "x86_64" ]; then BOX_ARCH="linux-amd64"; \
    elif [ "$ARCH" = "aarch64" ]; then BOX_ARCH="linux-arm64"; \
    else BOX_ARCH="linux-amd64"; fi && \
    latest_version=$(curl -s https://api.github.com/repos/SagerNet/sing-box/releases/latest | jq -r .tag_name | sed 's/v//') && \
    curl -Lo /tmp/sing-box.tar.gz "https://github.com/SagerNet/sing-box/releases/download/v${latest_version}/sing-box-${latest_version}-${BOX_ARCH}.tar.gz" && \
    tar -xzf /tmp/sing-box.tar.gz -C /tmp && \
    mv /tmp/sing-box-*/sing-box /usr/local/bin/sing-box && \
    chmod +x /usr/local/bin/sing-box && \
    rm -rf /tmp/sing-box*

# ၂။ Cloudflare Tunnel (cloudflared) ကို သွင်းခြင်း
RUN curl -L -o /usr/local/bin/cloudflared https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 && \
    chmod +x /usr/local/bin/cloudflared

# Config ဖိုင်များအတွက် Folder ဆောက်ခြင်း
RUN mkdir -p /etc/sing-box

# Config ဖိုင်နှင့် Script ကို Copy ကူးခြင်း
COPY config.yaml /etc/sing-box/config.yaml
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Port 8080 ကို လမ်းဖွင့်ပေးခြင်း
EXPOSE 8080

CMD ["/bin/bash", "/entrypoint.sh"]
