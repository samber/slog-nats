package slognats

import (
	"context"

	"log/slog"

	"github.com/nats-io/nats.go"
	slogcommon "github.com/samber/slog-common"
)

type Option struct {
	// log level (default: debug)
	Level slog.Leveler

	// NATS client
	EncodedConnection *nats.EncodedConn
	Subject           string

	// optional: customize NATS event builder
	Converter Converter

	// optional: see slog.HandlerOptions
	AddSource   bool
	ReplaceAttr func(groups []string, a slog.Attr) slog.Attr
}

func (o Option) NewNATSHandler() slog.Handler {
	if o.Level == nil {
		o.Level = slog.LevelDebug
	}

	if o.EncodedConnection == nil {
		panic("missing NATS connection")
	}

	if o.Subject == "" {
		panic("missing NATS subject")
	}

	if o.Converter == nil {
		o.Converter = DefaultConverter
	}

	return &NATSHandler{
		option: o,
		attrs:  []slog.Attr{},
		groups: []string{},
	}
}

var _ slog.Handler = (*NATSHandler)(nil)

type NATSHandler struct {
	option Option
	attrs  []slog.Attr
	groups []string
}

func (h *NATSHandler) Enabled(_ context.Context, level slog.Level) bool {
	return level >= h.option.Level.Level()
}

func (h *NATSHandler) Handle(ctx context.Context, record slog.Record) error {
	payload := h.option.Converter(h.option.AddSource, h.option.ReplaceAttr, h.attrs, h.groups, &record)

	return h.option.EncodedConnection.Publish(
		h.option.Subject,
		payload,
	)
}

func (h *NATSHandler) WithAttrs(attrs []slog.Attr) slog.Handler {
	return &NATSHandler{
		option: h.option,
		attrs:  slogcommon.AppendAttrsToGroup(h.groups, h.attrs, attrs...),
		groups: h.groups,
	}
}

func (h *NATSHandler) WithGroup(name string) slog.Handler {
	return &NATSHandler{
		option: h.option,
		attrs:  h.attrs,
		groups: append(h.groups, name),
	}
}
