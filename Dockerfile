ARG BASE_IMAGE="ubuntu"
ARG TAG="20.04"
FROM ${BASE_IMAGE}:${TAG}

ENV DEBIAN_FRONTEND="noninteractive" \
	WINEARCH="win32"

# VNC Server password
ARG PW=a

# Install prerequisites
RUN apt-get update \
    && apt-get install -yq --no-install-recommends \
        apt-transport-https \
        ca-certificates \
        cabextract \
        git \
        gosu \
        gpg-agent \
        p7zip \
        pulseaudio \
        pulseaudio-utils \
        software-properties-common \
        tzdata \
        unzip \
        wget \
        winbind \
        xvfb \
        zenity \
        sudo \
        bash-completion \
        supervisor \
        x11vnc \
        xfce4-whiskermenu-plugin thunar xfce4-panel xfce4-session xfce4-settings xfce4-terminal xfconf xfdesktop4 xfwm4 \
        ttf-dejavu adwaita-icon-theme \
        dbus-x11 \
    && x11vnc -storepasswd ${PW} /etc/vncpw \
	&& chmod 400 /etc/vncpw \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*


# Install wine and winetricks
ARG WINE_BRANCH="stable"
RUN wget -nv -O- https://dl.winehq.org/wine-builds/winehq.key | APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=1 apt-key add - \
    && apt-add-repository "deb https://dl.winehq.org/wine-builds/ubuntu/ $(grep VERSION_CODENAME= /etc/os-release | cut -d= -f2) main" \
    && dpkg --add-architecture i386 \
    && apt-get update \
    && DEBIAN_FRONTEND="noninteractive" apt-get install -y --install-recommends winehq-${WINE_BRANCH} \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/* \
    && wget -nv -O /usr/bin/winetricks https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks \
    && chmod +x /usr/bin/winetricks

# Download gecko and mono installers
COPY download_gecko_and_mono.sh /root/download_gecko_and_mono.sh
RUN chmod +x /root/download_gecko_and_mono.sh \
    && /root/download_gecko_and_mono.sh "$(dpkg -s wine-${WINE_BRANCH} | grep "^Version:\s" | awk '{print $2}' | sed -E 's/~.*$//')"

COPY pulse-client.conf /root/pulse/client.conf
COPY supervisord.conf /etc/supervisor/conf.d/

# ENTRYPOINT ["/usr/bin/entrypoint"]
CMD ["/usr/bin/supervisord","-c","/etc/supervisor/conf.d/supervisord.conf"]
