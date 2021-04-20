FROM almir/webhook:2.8.0

WORKDIR /app

COPY root/app /app
COPY root/entrypoint.sh /entrypoint.sh

RUN apk add --no-cache docker-compose git jq moreutils openssh-client py3-pip && \
    apk add --no-cache -X http://dl-cdn.alpinelinux.org/alpine/edge/testing doctl && \
    pip3 install emrichen

ENTRYPOINT ["/entrypoint.sh"]
