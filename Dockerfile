FROM fedora:25

LABEL maintainer="Tomas Tomecek <tomas@tomecek.net>"

# RUN dnf install -y curl tar gcc openssl-devel cmake make file libcurl-devel zsh && \
#     dnf clean all

# stable, beta, nightly, 1.15.1
# channel, channel + date, or an explicit version
ARG RUST_SPEC=stable
# ARG WITH_TEST="yes"
ARG USER_ID="1000"
ARG USER="rust"
ARG RUST_BACKTRACE="1"

ENV HOME=/home/${USER}
RUN useradd -o -u ${USER_ID} -m ${USER}

# https://static.rust-lang.org/dist/2017-03-16/rust-nightly-x86_64-unknown-linux-gnu.tar.gz
RUN cd $HOME && curl -s https://static.rust-lang.org/rustup.sh | sh -s -- --spec=$RUST_SPEC --verbose --disable-sudo

USER ${USER_ID}

# RUN if [ $WITH_TEST == "yes" ] ; then \
#     cargo install clippy || : ; \
#     fi

# ENV LANG=en_US.utf8 \
#     LC_ALL=en_US.UTF-8

CMD ["/bin/bash"]

WORKDIR /src
VOLUME /src
