FROM debian:jessie
MAINTAINER Chris Robertson <dev@tsuirobertson.org>

ENV DEBIAN_FRONTEND="noninteractive" HOME="/root" LC_ALL="C.UTF-8" LANG="en_US.UTF-8" LANGUAGE="en_US.UTF-8"

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      cron duplicity && \
    rm -rf /var/lib/apt/lists/*

RUN mkdir -p /data

ADD run.sh /
RUN chmod a+x /run.sh

ENTRYPOINT ["/run.sh"]
CMD ["start"]
