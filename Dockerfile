FROM python:3.6-slim

MAINTAINER George He <george.sre@hotmail.com>

WORKDIR /usr/src/app
COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

RUN apt-get update && apt-get install -y curl

RUN apt-get install -y ca-certificates && update-ca-certificates

ENV REQUESTS_CA_BUNDLE /etc/ssl/certs/ca-certificates.crt

COPY VERSION ./
COPY vault-agent ./

CMD [ "python", "./vault-agent" ]
