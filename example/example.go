package main

import (
	"fmt"
	"time"

	"github.com/nats-io/nats.go"
	slognats "github.com/samber/slog-nats"

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
