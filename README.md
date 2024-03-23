
# slog: NATS handler

[![tag](https://img.shields.io/github/tag/samber/slog-nats.svg)](https://github.com/samber/slog-nats/releases)
![Go Version](https://img.shields.io/badge/Go-%3E%3D%201.21-%23007d9c)
[![GoDoc](https://godoc.org/github.com/samber/slog-nats?status.svg)](https://pkg.go.dev/github.com/samber/slog-nats)
![Build Status](https://github.com/samber/slog-nats/actions/workflows/test.yml/badge.svg)
[![Go report](https://goreportcard.com/badge/github.com/samber/slog-nats)](https://goreportcard.com/report/github.com/samber/slog-nats)
[![Coverage](https://img.shields.io/codecov/c/github/samber/slog-nats)](https://codecov.io/gh/samber/slog-nats)
[![Contributors](https://img.shields.io/github/contributors/samber/slog-nats)](https://github.com/samber/slog-nats/graphs/contributors)
[![License](https://img.shields.io/github/license/samber/slog-nats)](./LICENSE)

A [NATS](https://nats.io/) Handler for [slog](https://pkg.go.dev/log/slog) Go library.

**See also:**

- [slog-multi](https://github.com/samber/slog-multi): `slog.Handler` chaining, fanout, routing, failover, load balancing...
- [slog-formatter](https://github.com/samber/slog-formatter): `slog` attribute formatting
- [slog-sampling](https://github.com/samber/slog-sampling): `slog` sampling policy
- [slog-gin](https://github.com/samber/slog-gin): Gin middleware for `slog` logger
- [slog-echo](https://github.com/samber/slog-echo): Echo middleware for `slog` logger
- [slog-fiber](https://github.com/samber/slog-fiber): Fiber middleware for `slog` logger
- [slog-chi](https://github.com/samber/slog-chi): Chi middleware for `slog` logger
- [slog-http](https://github.com/samber/slog-http): `net/http` middleware for `slog` logger
- [slog-datadog](https://github.com/samber/slog-datadog): A `slog` handler for `Datadog`
- [slog-rollbar](https://github.com/samber/slog-rollbar): A `slog` handler for `Rollbar`
- [slog-sentry](https://github.com/samber/slog-sentry): A `slog` handler for `Sentry`
- [slog-syslog](https://github.com/samber/slog-syslog): A `slog` handler for `Syslog`
- [slog-logstash](https://github.com/samber/slog-logstash): A `slog` handler for `Logstash`
- [slog-fluentd](https://github.com/samber/slog-fluentd): A `slog` handler for `Fluentd`
- [slog-graylog](https://github.com/samber/slog-graylog): A `slog` handler for `Graylog`
- [slog-loki](https://github.com/samber/slog-loki): A `slog` handler for `Loki`
- [slog-slack](https://github.com/samber/slog-slack): A `slog` handler for `Slack`
- [slog-telegram](https://github.com/samber/slog-telegram): A `slog` handler for `Telegram`
- [slog-mattermost](https://github.com/samber/slog-mattermost): A `slog` handler for `Mattermost`
- [slog-microsoft-teams](https://github.com/samber/slog-microsoft-teams): A `slog` handler for `Microsoft Teams`
- [slog-webhook](https://github.com/samber/slog-webhook): A `slog` handler for `Webhook`
- [slog-kafka](https://github.com/samber/slog-kafka): A `slog` handler for `Kafka`
- [slog-nats](https://github.com/samber/slog-nats): A `slog` handler for `NATS`
- [slog-parquet](https://github.com/samber/slog-parquet): A `slog` handler for `Parquet` + `Object Storage`
- [slog-zap](https://github.com/samber/slog-zap): A `slog` handler for `Zap`
- [slog-zerolog](https://github.com/samber/slog-zerolog): A `slog` handler for `Zerolog`
- [slog-logrus](https://github.com/samber/slog-logrus): A `slog` handler for `Logrus`
- [slog-channel](https://github.com/samber/slog-channel): A `slog` handler for Go channels

## 🚀 Install

```sh
go get github.com/samber/slog-nats
```

**Compatibility**: go >= 1.21

No breaking changes will be made to exported APIs before v1.0.0.

## 💡 Usage

GoDoc: [https://pkg.go.dev/github.com/samber/slog-nats](https://pkg.go.dev/github.com/samber/slog-nats)

### Handler options

```go
type Option struct {
	// log level (default: debug)
	Level     slog.Leveler

	// NATS client
	EncodedConnection *nats.EncodedConn
	Subject           string

	// optional: customize NATS event builder
	Converter Converter

	// optional: see slog.HandlerOptions
	AddSource   bool
	ReplaceAttr func(groups []string, a slog.Attr) slog.Attr
}
```

Other global parameters:

```go
slognats.SourceKey = "source"
slognats.ContextKey = "extra"
slognats.RequestKey = "request"
slognats.ErrorKeys = []string{"error", "err"}
slognats.RequestIgnoreHeaders = false
```

### Supported attributes

The following attributes are interpreted by `slognats.DefaultConverter`:

| Atribute name    | `slog.Kind`       | Underlying type |
| ---------------- | ----------------- | --------------- |
| "user"           | group (see below) |                 |
| "error"          | any               | `error`         |
| "request"        | any               | `*http.Request` |
| other attributes | *                 |                 |

Other attributes will be injected in `extra` field.

Users must be of type `slog.Group`. Eg:

```go
slog.Group("user",
    slog.String("id", "user-123"),
    slog.String("username", "samber"),
    slog.Time("created_at", time.Now()),
)
```

### Example

```go
import (
	"context"
	"fmt"
	"time"

	slognats "github.com/samber/slog-nats"
	"github.com/nats-io/nats.go"

	"log/slog"
)

func main() {
	// docker-compose up -d
	// brew tap nats-io/nats-tools
	// brew install nats-io/nats-tools/nats
	// nats subscribe test

	uri := "nats://127.0.0.1:4222"

	nc, err := nats.Connect(uri)
	if err != nil {
		panic(err)
	}

	ec, err := nats.NewEncodedConn(nc, nats.JSON_ENCODER)
	if err != nil {
		panic(err)
	}

	defer nc.Flush()
	defer nc.Close()

	logger := slog.New(slognats.Option{Level: slog.LevelDebug, EncodedConnection: ec, Subject: "test"}.NewNATSHandler())
	logger = logger.With("release", "v1.0.0")

	logger.
		With(
			slog.Group("user",
				slog.String("id", "user-123"),
				slog.Time("created_at", time.Now()),
			),
		).
		With("error", fmt.Errorf("an error")).
		Error("a message")
}
```

NATS message:

```json
{
  	"level": "ERROR",
	"logger.name": "samber/slog-nats",
	"logger.version": "1.0.0",
	"message": "a message",
	"timestamp": "2023-04-30T01:33:21.676768Z",
	"error": {
		"error": "an error",
		"kind": "*errors.errorString",
		"stack": null
	},
	"extra": {
		"release": "v1.0.0"
	},
	"user": {
		"created_at": "2023-04-30T01:33:21.676704Z",
		"id": "user-123"
	}
}
```

## 🤝 Contributing

- Ping me on twitter [@samuelberthe](https://twitter.com/samuelberthe) (DMs, mentions, whatever :))
- Fork the [project](https://github.com/samber/slog-nats)
- Fix [open issues](https://github.com/samber/slog-nats/issues) or request new features

Don't hesitate ;)

```bash
# Install some dev dependencies
make tools

# Run tests
make test
# or
make watch-test
```

## 👤 Contributors

![Contributors](https://contrib.rocks/image?repo=samber/slog-nats)

## 💫 Show your support

Give a ⭐️ if this project helped you!

[![GitHub Sponsors](https://img.shields.io/github/sponsors/samber?style=for-the-badge)](https://github.com/sponsors/samber)

## 📝 License

Copyright © 2023 [Samuel Berthe](https://github.com/samber).

This project is [MIT](./LICENSE) licensed.
