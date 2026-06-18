FROM ghcr.io/sagernet/sing-box:latest

# လိုအပ်သော Tools များနှင့် cloudflared ကို သွင်းခြင်း
RUN apk add --no-cache curl bash jq ca-certificates && \
    curl -L -o /usr/local/bin/cloudflared https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 && \
    chmod +x /usr/local/bin/cloudflared

# Folder တည်ဆောက်ခြင်း
RUN mkdir -p /etc/sing-box

# Config နှင့် Script ကို Copy ကူးထည့်ခြင်း
COPY config.json /etc/sing-box/config.json
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 8080

ENTRYPOINT ["/bin/bash", "/entrypoint.sh"]
