FROM ubuntu:20.04

RUN echo 'APT::Install-Suggests "0";' >> /etc/apt/apt.conf.d/00-docker
RUN echo 'APT::Install-Recommends "0";' >> /etc/apt/apt.conf.d/00-docker

ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC
RUN apt-get update \
  && apt-get install -y locales \
    openssh-server \
    sudo \
    nano \
    iputils-ping \
    curl \
    wget \
    ca-certificates \
    git \
    apt-utils \
    bison \
    ccache \
    check \
    flex \
    git-lfs \
    gperf \
    lcov \
    libffi-dev \
    libncurses-dev \
    libpython2.7 \
    libusb-1.0-0-dev \
    make \
    ninja-build \
    python3 \
    python3-pip \
    unzip \
    xz-utils \
    zip \
    cmake \
    nodejs \
    npm \
    && update-ca-certificates \
  && apt-get autoremove -y \
  && rm -rf /var/lib/apt/lists/* \
  && update-alternatives --install /usr/bin/python python /usr/bin/python3 10 \
    && python -m pip install --upgrade \
      pip \
      virtualenv \
  && :


# IDF

ARG IDF_CLONE_URL=https://github.com/espressif/esp-idf.git
ARG IDF_CLONE_BRANCH_OR_TAG=release/v4.4
ARG IDF_INSTALL_TARGETS=all

ENV IDF_PATH=/opt/esp/idf
ENV IDF_TOOLS_PATH=/opt/esp

# clone esp-idf
RUN echo IDF_CHECKOUT_REF=$IDF_CHECKOUT_REF IDF_CLONE_BRANCH_OR_TAG=$IDF_CLONE_BRANCH_OR_TAG && \
    git clone --recursive \
      ${IDF_CLONE_SHALLOW:+--depth=1 --shallow-submodules} \
      ${IDF_CLONE_BRANCH_OR_TAG:+-b $IDF_CLONE_BRANCH_OR_TAG} \
      $IDF_CLONE_URL $IDF_PATH && \
    if [ -n "$IDF_CHECKOUT_REF" ]; then \
      cd $IDF_PATH && \
      if [ -n "$IDF_CLONE_SHALLOW" ]; then \
        git fetch origin --depth=1 --recurse-submodules ${IDF_CHECKOUT_REF}; \
      fi && \
      git checkout $IDF_CHECKOUT_REF && \
      git submodule update --init --recursive; \
    fi

# Install all the required tools
RUN : \
  && update-ca-certificates --fresh \
  && $IDF_PATH/tools/idf_tools.py --non-interactive install required --targets=${IDF_INSTALL_TARGETS} \
  && $IDF_PATH/tools/idf_tools.py --non-interactive install cmake \
  && $IDF_PATH/tools/idf_tools.py --non-interactive install-python-env \
  && rm -rf $IDF_TOOLS_PATH/dist \
  && :

# Ccache is installed, enable it by default
ENV IDF_CCACHE_ENABLE=1

RUN /opt/esp/idf/install.sh

# SSH
RUN locale-gen en_US.UTF-8

ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

# Create a user “sshuser” and group “sshgroup”
RUN groupadd sshgroup && useradd -ms /bin/bash -g sshgroup sshuser
# set user password
RUN echo "sshuser:devuserPass" | chpasswd
# Create sshuser directory in home
RUN mkdir -p /home/sshuser
RUN mkdir /var/run/sshd
# allow remote connect
RUN sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

# allow sshuser to do anything he wants
ADD sshuser /etc/sudoers.d

# set esp-idf patches globally
RUN echo "export IDF_PATH=/opt/esp/idf" >> /home/sshuser/.profile
RUN echo "export IDF_TOOLS_PATH=/opt/esp" >> /home/sshuser/.profile
RUN echo "source /opt/esp/idf/export.sh" >> /home/sshuser/.profile

# remove .git folder from esp-idf, it will make configuration of Clion much easier
RUN rm -rf /opt/esp/idf/.git

# set ownership for mounted folders (this may not always work)
RUN mkdir /home/sshuser/src \
    && chown sshuser:sshgroup /home/sshuser/src \
    && mkdir /home/sshuser/.ssh \
    && chown sshuser:sshgroup /home/sshuser/.ssh \
    && mkdir /home/sshuser/.cache \
    && chown sshuser:sshgroup /home/sshuser/.cache \
    && mkdir /home/sshuser/.git \
    && chown sshuser:sshgroup /home/sshuser/.git

EXPOSE 22
ENTRYPOINT ["/usr/sbin/sshd","-D"]