#
# Portions of this Dockerfile based on work by Tianon Gravi (@tianon) and Jess Frazelle (@jessfraz)
#

#
# Base docker image
#
FROM ubuntu:16.04


#
# Add some common packages (see buildpack-deps:sid-curl)
#
RUN apt-get update && apt-get install -y --no-install-recommends \
		ca-certificates \
		curl \
		wget \
	&& rm -rf /var/lib/apt/lists/*

RUN set -ex; \
	if ! command -v gpg > /dev/null; then \
		apt-get update; \
		apt-get install -y --no-install-recommends \
			gnupg2 \
			dirmngr \
		; \
		rm -rf /var/lib/apt/lists/*; \
	fi

RUN apt-get update && apt-get install -y --no-install-recommends \
		bzip2 \
		unzip \
		xz-utils \
	&& rm -rf /var/lib/apt/lists/*


#
# Add Java 9
#
RUN apt-get update && \
# Here we need the "-o Dpkg" stuff because of a bug in openjdk-9-jdk for xenial (b114)
# There is a duplicate file, so we force-overwrite it
		apt-get -o Dpkg::Options::="--force-overwrite" install -y --no-install-recommends openjdk-9-jdk \
	&& rm -rf /var/lib/apt/lists/*

# Setup the JAVA_HOME

# Step 1
# add a simple script that can auto-detect the appropriate JAVA_HOME value
# based on whether the JDK or only the JRE is installed
RUN { \
		echo '#!/bin/sh'; \
		echo 'set -e'; \
		echo; \
		echo 'dirname "$(dirname "$(readlink -f "$(which javac || which java)")")"'; \
	} > /usr/local/bin/docker-java-home \
	&& chmod +x /usr/local/bin/docker-java-home

# Step 2
# do some fancy footwork to create a JAVA_HOME that's cross-architecture-safe
RUN ln -svT "/usr/lib/jvm/java-9-openjdk-$(dpkg --print-architecture)" /docker-java-home
ENV JAVA_HOME /docker-java-home


#
# Add Chrome
#
RUN curl -sS -o - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - && \
    echo "deb http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list && \
    apt-get -yqq update && \
    apt-get -yqq install google-chrome-stable && \
    rm -rf /var/lib/apt/lists/*


#
# Add Chromedriver
#
RUN CHROMEDRIVER_VERSION=`curl -sS chromedriver.storage.googleapis.com/LATEST_RELEASE` && \
    mkdir -p /opt/chromedriver-$CHROMEDRIVER_VERSION && \
    curl -sS -o /tmp/chromedriver_linux64.zip http://chromedriver.storage.googleapis.com/$CHROMEDRIVER_VERSION/chromedriver_linux64.zip && \
    unzip -qq /tmp/chromedriver_linux64.zip -d /opt/chromedriver-$CHROMEDRIVER_VERSION && \
    rm /tmp/chromedriver_linux64.zip && \
    chmod +x /opt/chromedriver-$CHROMEDRIVER_VERSION/chromedriver && \
    ln -fs /opt/chromedriver-$CHROMEDRIVER_VERSION/chromedriver /usr/local/bin/chromedriver


#
# Add Maven
#
ARG MAVEN_VERSION=3.5.2
ARG USER_HOME_DIR="/root"
ARG SHA1=190dcebb8a080f983af4420cac4f3ece7a47dd64
ARG BASE_URL=https://archive.apache.org/dist/maven/maven-3/${MAVEN_VERSION}/binaries

# Maven fails with 'Can't read cryptographic policy directory: unlimited'
# because it looks for $JAVA_HOME/conf/security/policy/unlimited but it is in
# /etc/java-9-openjdk/security/policy/unlimited
RUN ln -s /etc/java-9-openjdk /usr/lib/jvm/java-9-openjdk-$(dpkg --print-architecture)/conf

RUN mkdir -p /usr/share/maven /usr/share/maven/ref \
  && curl -fsSL -o /tmp/apache-maven.tar.gz ${BASE_URL}/apache-maven-${MAVEN_VERSION}-bin.tar.gz \
  && echo "${SHA1}  /tmp/apache-maven.tar.gz" | sha1sum -c - \
  && tar -xzf /tmp/apache-maven.tar.gz -C /usr/share/maven --strip-components=1 \
  && rm -f /tmp/apache-maven.tar.gz \
  && ln -s /usr/share/maven/bin/mvn /usr/bin/mvn

ENV MAVEN_HOME /usr/share/maven
ENV MAVEN_CONFIG "$USER_HOME_DIR/.m2"

VOLUME "$USER_HOME_DIR/.m2"


#
# Add AWS CLI
#
RUN apt-get update && apt-get install -y --no-install-recommends \
		python-setuptools \
		python-pip \
		groff-base \
	&& rm -rf /var/lib/apt/lists/*

RUN pip install awscli


#
# Set CMD to a general purpose shell for CodeBuild to do its thing
#
CMD ["bash"]
