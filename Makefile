
GO_BIN=go
ifeq ($(OS),Windows)
	GO_BIN=go.exe
endif

build:
	${GO_BIN} build -v ./...

test:
	$(GO_BIN) test -race -v ./...
watch-test:
	reflex -t 50ms -s -- sh -c 'gotest -race -v ./...'

bench:
	$(GO_BIN) test -benchmem -count 3 -bench ./...
watch-bench:
	reflex -t 50ms -s -- sh -c 'go test -benchmem -count 3 -bench ./...'

coverage:
	${GO_BIN} test -v -coverprofile=cover.out -covermode=atomic .
	${GO_BIN} tool cover -html=cover.out -o cover.html

tools:
	${GO_BIN} install github.com/cespare/reflex@latest
	${GO_BIN} install github.com/rakyll/gotest@latest
	${GO_BIN} install github.com/psampaz/go-mod-outdated@latest
	${GO_BIN} install github.com/jondot/goweight@latest
	${GO_BIN} install github.com/golangci/golangci-lint/cmd/golangci-lint@latest
	${GO_BIN} get -t -u golang.org/x/tools/cmd/cover
	${GO_BIN} install github.com/sonatype-nexus-community/nancy@latest
	$(GO_BIN) mod tidy

lint:
	golangci-lint run --timeout 60s --max-same-issues 50 ./...
lint-fix:
	golangci-lint run --timeout 60s --max-same-issues 50 --fix ./...

audit:
	${GO_BIN} list -json -m all | nancy sleuth

outdated:
	${GO_BIN} list -u -m -json all | go-mod-outdated -update -direct

weight:
	goweight

### nats


OS=$(shell uname -s)
#OS=Windows

NATS_SERVER_BIN_NAME=nats-server
ifeq ($(OS),Windows)
	NATS_SERVER_BIN_NAME=nats-server.exe
endif

NATS_CLI_BIN_NAME=nats
ifeq ($(OS),Windows)
	NATS_CLI_BIN_NAME=nats.exe
endif

NATS_SERVER_BIN_VERSION=v2.10.5
NATS_CLI_BIN_VERSION=v0.1.1
NATS_SURVEYOR_BIN_VERSION=v0.5.2
nats-dep:
	go install -ldflags="-X main.version=$(NATS_SERVER_BIN_VERSION)" github.com/nats-io/nats-server/v2@$(NATS_SERVER_BIN_VERSION)
	go install -ldflags="-X main.version=$(NATS_CLI_BIN_VERSION)" github.com/nats-io/natscli/nats@$(NATS_CLI_BIN_VERSION)
	go install -ldflags="-X main.version=$(NATS_SURVEYOR_BIN_VERSION)" github.com/nats-io/nats-surveyor@$(NATS_SURVEYOR_BIN_VERSION)


NATS_MAIN_CONFIG_FILE=nats-main.conf
NATS_MAIN_URL="nats://0.0.0.0:4222"
NATS_MAIN_PORT=4222

NATS_LEAF_CONFIG_FILE=nats-leaf.conf
NATS_LEAF_URL="nats://0.0.0.0:4223"
NATS_LEAF_PORT=4223

nats-print:
	nats context ls

nats-init:
	@echo ""
	@echo "Configuring NATS context ..."

	nats context save main --server "$(NATS_MAIN_URL)" 
	nats context save leaf --server "$(NATS_LEAF_URL)" 

	@echo ""
	@echo "Creating nats main conf ..."
	rm -f $(NATS_MAIN_CONFIG_FILE)
	@echo "# nats main onf" >> $(NATS_MAIN_CONFIG_FILE)
	@echo "" >> $(NATS_MAIN_CONFIG_FILE)
	@echo "port $(NATS_MAIN_PORT)" >> $(NATS_MAIN_CONFIG_FILE)
	@echo "leafnodes: { port: $(NATS_LEAF_PORT) }" >> $(NATS_MAIN_CONFIG_FILE)
	@echo ""
	@echo "Creating nats leaf conf ..."
	rm -f $(NATS_LEAF_CONFIG_FILE)
	@echo "# nats leaf conf" >> $(NATS_LEAF_CONFIG_FILE)
	@echo "" >> $(NATS_LEAF_CONFIG_FILE)
	@echo "port $(NATS_LEAF_PORT)" >> $(NATS_LEAF_CONFIG_FILE)
	@echo "leafnodes: { remotes: [ {url: "nats-leaf://0.0.0.0:7422"} ] }" >> $(NATS_LEAF_CONFIG_FILE)
	@echo ""


nats-start:
	$(NATS_SERVER_BIN_NAME) -c $(NATS_MAIN_CONFIG_FILE) 2> /dev/null & MAIN_PID=$(!)
	sleep 1
	$(NATS_SERVER_BIN_NAME) -c $(NATS_LEAF_CONFIG_FILE) 2> /dev/null & LEAF_PID=$(!)
	sleep 1
