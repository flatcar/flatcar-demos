FROM alpine AS builder

RUN apk add git go
RUN git clone https://github.com/MartinHeinz/aranet4-exporter-go.git
RUN cd aranet4-exporter-go \
    && go build

# We want a minimal shell env in the container for
#  flexible / variable command line expansion.
FROM alpine
COPY --from=builder /aranet4-exporter-go/aranet4-exporter /
