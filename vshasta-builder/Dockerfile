# container image that will be used by jenkins to run tests/builds, etc.
FROM golang:1.12-alpine

ENV GOOGLE_APPLICATION_CREDENTIALS=/root/.config/gcloud/application_default_credentials.json

RUN apk add --no-cache bash git build-base bc curl
RUN go get golang.org/x/lint/golint
RUN go get github.com/vektra/mockery/.../
RUN mkdir -p /root/.config/gcloud && echo $'{\n\
  "client_id": "xxxxx-xxxxx.apps.googleusercontent.com",\n\
  "client_secret": "xxxxxx",\n\
  "refresh_token": "xxxxxx",\n\
  "type": "authorized_user"\n\
}' >> /root/.config/gcloud/application_default_credentials.json
