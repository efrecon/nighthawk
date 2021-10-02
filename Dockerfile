FROM alpine

RUN apk add --no-cache curl
COPY *.sh /usr/local/bin

ENTRYPOINT [ "/usr/local/bin/nighthawk.sh" ]
CMD [ "help" ]

