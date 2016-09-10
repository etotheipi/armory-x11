FROM ubuntu:16.04
MAINTAINER Jimmy Song <http://github.com/jimmysong>

# Install LXDE, Twisted, SWIG and Qt
RUN apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y openssh-server x11-apps lxde-core lxterminal curl gnupg g++ libcrypto++-dev swig python-dev python-twisted libqtcore4 libqt4-dev python-qt4 pyqt4-dev-tools python-psutil xdg-utils

# Download bitcoin
RUN mkdir /bitcoin
WORKDIR /bitcoin
ENV BITCOIN_VERSION 0.13.0
RUN curl -SLO "https://bitcoin.org/bin/bitcoin-core-${BITCOIN_VERSION}/bitcoin-${BITCOIN_VERSION}-x86_64-linux-gnu.tar.gz" \
 && curl -SLO "https://bitcoin.org/bin/bitcoin-core-${BITCOIN_VERSION}/SHA256SUMS.asc"

# Verify and install download
COPY laanwj-releases.asc /bitcoin
RUN gpg --import laanwj-releases.asc \
 && gpg --verify --trust-model=always SHA256SUMS.asc \
 && gpg --decrypt --output SHA256SUMS SHA256SUMS.asc \
 && grep "bitcoin-${BITCOIN_VERSION}-x86_64-linux-gnu.tar.gz" SHA256SUMS | sha256sum -c - \
 && tar -xzf "bitcoin-${BITCOIN_VERSION}-x86_64-linux-gnu.tar.gz" -C /usr --strip-components=1 \
 && rm "bitcoin-${BITCOIN_VERSION}-x86_64-linux-gnu.tar.gz" SHA256SUMS.asc SHA256SUMS

RUN ln -s /bitcoin /root/.bitcoin

# Download armory
RUN mkdir /armory
WORKDIR /armory
ENV ARMORY_VERSION 0.94.1
RUN curl -SLO "https://github.com/goatpig/BitcoinArmory/releases/download/v${ARMORY_VERSION}/armory_${ARMORY_VERSION}_amd64.deb"
RUN curl -SLO "https://github.com/goatpig/BitcoinArmory/releases/download/v${ARMORY_VERSION}/sha256sum.asc.txt"

# Verify and install download
COPY goatpig-signing-key.asc /armory
RUN gpg --import goatpig-signing-key.asc \
 && gpg --verify --trust-model=always sha256sum.asc.txt \
 && gpg --decrypt --output sha256sum.txt sha256sum.asc.txt \
 && grep "armory_${ARMORY_VERSION}_amd64.deb" sha256sum.txt | sha256sum -c - \
 && dpkg -i "armory_${ARMORY_VERSION}_amd64.deb" \
 && rm "armory_${ARMORY_VERSION}_amd64.deb" sha256sum.asc.txt sha256sum.txt

RUN ln -s /armory /root/.armory
RUN mkdir /root/.ssh \
 && chmod 700 /root/.ssh \
 && mkdir /var/run/sshd \
 && perl -p -i -e "s/\#PasswordAuthentication yes/PasswordAuthentication no/" /etc/ssh/sshd_config

# Expose SSH port for X11 forwarding
ENV DISPLAY :0
EXPOSE 22

COPY run.sh /opt
CMD ["/opt/run.sh"]
