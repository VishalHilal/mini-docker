FROM golang:1.21 AS build
WORKDIR /src
COPY . .
RUN CGO_ENABLED=0 go build -o /bin/dockr ./cmd/dockr

FROM alpine:3.18
COPY --from=build /bin/dockr /usr/local/bin/dockr
ENTRYPOINT ["/usr/local/bin/dockr"]
