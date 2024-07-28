# Build Stage
FROM golang:latest AS easy-novnc-build
WORKDIR /src
RUN set -xe && \
    go mod init build && \
    go get github.com/geek1011/easy-novnc && \
    go build -o /bin/easy-novnc github.com/geek1011/easy-novnc

# Final Stage
FROM debian:stable-slim

ARG BUILD_DATE="2024-04-29T15:04:07Z"

ENV HOME=/data \
    PUID=1000 \
    PGID=1000 \
    HTTP_PORT=8080 \
    HTTPS_PORT=8443 \
    REVERSE_PROXY=yes \
    CRONJOBS=yes \
    VNC_EXPOSE=no \
    OPENBOX_THEME_NAME=Nightmare \
    OPENBOX_ICON_THEME_NAME=Papirus-Dark \
    OPENBOX_THEME_FONT="DejaVu Sans 9"

RUN set -xe && \
    sed -i 's/^Components: main$/& contrib non-free/' /etc/apt/sources.list.d/debian.sources && \
    apt-get update -y && \
    apt-get install -y --no-install-recommends \
    sudo openbox python3-xdg obconf tint2 feh papirus-icon-theme arc-theme \
    tigervnc-standalone-server supervisor cron python3-jinja2 python3-click \
    terminator nano wget curl ca-certificates xdg-utils htop tar fonts-dejavu \
    nginx-light gettext-base apache2-utils wine wine64 tmux && \
    mkdir -p /usr/share/desktop-directories /usr/share/man/man1 /opt/winbox && \
    wget -q -O /opt/winbox/winbox64.exe "https://mt.lv/winbox64" && \
    wget -q -O /opt/winbox/winbox-2.2.16.exe "https://github.com/bahirul/winbox/blob/main/v2.x/winbox-2.2.16.exe" && \
    chmod a+x /opt/winbox/winbox64.exe /opt/winbox/winbox-2.2.16.exe && \
    rm -rf /usr/share/themes/*/{cinnamon,gnome-shell,unity,xfwm4,plank} \
    /usr/share/icons/{Adwaita,HighContrast,Papirus,Papirus-Light,ePapirus,hicolor} \
    /etc/systemd/**/*.service \
    /usr/lib/python*/**/*.pyc \
    /etc/nginx/nginx.conf \
    /etc/xdg/autostart/* \
    /etc/xdg/openbox/* \
    /var/lib/apt/lists

COPY --from=easy-novnc-build /bin/easy-novnc /usr/local/bin/
COPY ./templates/. /

RUN set -xe && \
    chmod 0644 /etc/cron.d/*.j2 /etc/nginx/*.j2 /etc/xdg/openbox/*.j2 /etc/*.j2 && \
    chmod 0700 /etc/entrypoint.d && \
    chmod 0444 /usr/share/applications/* /etc/xdg/autostart/* && \
    chmod a+x /usr/bin/winbox64 && \
    chmod a+x /usr/bin/winbox-2.2.16 && \
    groupadd --gid ${PGID} app && \
    useradd --home-dir ${HOME} --shell /bin/bash --uid ${PUID} --gid ${PGID} app && \
    mkdir -p ${HOME}

WORKDIR ${HOME}
VOLUME ${HOME}

EXPOSE ${HTTP_PORT} ${HTTPS_PORT}
ENTRYPOINT [ "docker-entrypoint.sh" ]
CMD [ "supervisord" ]

LABEL org.opencontainers.image.title="Winbox"
LABEL org.opencontainers.image.description="Use Mikrotik's Winbox inside your browser instead of webfig!"
LABEL org.opencontainers.image.vendor="Mikrotik"
LABEL org.opencontainers.image.authors="Adam Drmota <drmotaadam@gmail.com> [Fork of t4skforce/docker-novnc]"
LABEL org.opencontainers.image.version="${VERSION}"
LABEL org.opencontainers.image.source="https://github.com/obeone/winbox-mikrotik"
