FROM registry.fedoraproject.org/fedora:29

LABEL maintainer="Tomas Tomecek <tomas@tomecek.net>"

# curl tar gcc openssl-devel cmake make libcurl-devel zsh

# file -- required by rustup
# gcc -- linker is required to compile and link rust programs
RUN dnf install -y file gcc && \
    dnf clean all

# stable, beta, nightly, 1.15.1
# channel, channel + date, or an explicit version
ARG RUST_SPEC=stable
ARG USER_ID="1000"
ARG USER="rust"
ARG RUST_BACKTRACE="1"

ENV HOME=/home/${USER}
ENV USER=${USER}
RUN useradd -o -u ${USER_ID} -m ${USER}

# https://static.rust-lang.org/dist/2017-03-16/rust-nightly-x86_64-unknown-linux-gnu.tar.gz
RUN cd /root && curl -s -L -O https://static.rust-lang.org/rustup.sh
RUN cd /root && bash ./rustup.sh -y --default-toolchain=$RUST_SPEC --verbose

# so we can reuse layers above
ARG WITH_CLIPPY=no

USER ${USER_ID}

ENV CARGO_INSTALL_ROOT=${HOME}/.cargo
ENV PATH=${PATH}:${HOME}/.cargo/bin

RUN if [ "$WITH_CLIPPY" == "yes" ] ; then \
      cargo install clippy; \
    fi

ENV CARGO_HOME=/src/.cargo

# ENV LANG=en_US.utf8 \
#     LC_ALL=en_US.UTF-8

CMD ["/bin/bash"]

WORKDIR /src
