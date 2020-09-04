FROM ubuntu:20.04

# Minecraft bedrock version
ARG SRV_Version=1.16.40.02

# Environment variables
ENV VERSION=$SRV_Version
ENV TZ=Asia/Tokyo
ENV DEBIAN_FRONTEND noninteractive
ENV DEBCONF_NOWARNINGS yes

# Set Timezone
RUN echo ${TZ} > /etc/timezone
RUN ln -snf /usr/share/zoneinfo/${TZ} /etc/localtime

# Install dependencies
RUN apt-get -yqq update && \
    apt-get -yqq install unzip curl libcurl4 tzdata && \
    rm -rf /var/lib/apt/lists/*

# Download and extract the bedrock server
RUN if [ "$VERSION" = "latest" ] ; then \
        LATEST_VERSION=$( \
            curl -s https://www.minecraft.net/en-us/download/server/bedrock/ 2>&1 | \
            grep -o 'https://minecraft.azureedge.net/bin-linux/[^"]*' | \
            sed 's#.*/bedrock-server-##' | sed 's/.zip//') && \
        export VERSION=$LATEST_VERSION && \
        echo "Setting VERSION to $LATEST_VERSION" ; \
    else echo "Using VERSION of $VERSION"; \
    fi && \
    curl -s https://minecraft.azureedge.net/bin-linux/bedrock-server-${VERSION}.zip --output bedrock-server.zip && \
    unzip bedrock-server.zip -d bedrock-server > /dev/null && \
    rm bedrock-server.zip

VOLUME /bedrock-server/data

# Delete default config (supplied from volume)
run rm -f /bedrock-server/server.properties /bedrock-server/permissions.json /bedrock-server/whitelist.json

# Setup symlinks from volume
RUN ln -s /bedrock-server/data/worlds             /bedrock-server/worlds            && \
    ln -s /bedrock-server/data/server.properties  /bedrock-server/server.properties && \
    ln -s /bedrock-server/data/permissions.json   /bedrock-server/permissions.json  && \
    ln -s /bedrock-server/data/whitelist.json     /bedrock-server/whitelist.json

ADD run.sh /bedrock-server/run.sh
RUN chmod +x /bedrock-server/run.sh

EXPOSE 19132/udp

WORKDIR /bedrock-server
ENV LD_LIBRARY_PATH=.
CMD ./run.sh
