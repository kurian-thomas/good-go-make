# Targetting current machine
# change GOARCH GOOS env var to cross compile to different os and architecture

# Used when recipe and file / dir has the same name
.PHONY: help all test build vendor

# Change Binary name based on project
BIN=myapp
EXE_PATH="./bin/$(BIN)"
SHELL := /bin/bash # Use bash syntax

# Folder to store artifacts (keeps root clean)
TEST_ARTIFACT_DIR := test_artifacts
TEST_COVERAGE_DIR := $(TEST_ARTIFACT_DIR)/coverage
TEST_REPORTS_DIR  := $(TEST_ARTIFACT_DIR)/reports


# Optional if you need DB and migration commands
# DB_HOST=$(shell cat config/application.yml | grep -m 1 -i HOST | cut -d ":" -f2)
# DB_NAME=$(shell cat config/application.yml | grep -w -i NAME  | cut -d ":" -f2)
# DB_USER=$(shell cat config/application.yml | grep -i USERNAME | cut -d ":" -f2)

# Optional colors to beautify output
GREEN  := $(shell tput -Txterm setaf 2)
YELLOW := $(shell tput -Txterm setaf 3)
WHITE  := $(shell tput -Txterm setaf 7)
CYAN   := $(shell tput -Txterm setaf 6)
RESET  := $(shell tput -Txterm sgr0)

## Quality
### Runs code quality checks
check-quality: fmt vet lint

# Append || true below if blocking local developement
### Go linting. Update and use specific lint tool and options config from .golanci.yaml
lint:
	@golangci-lint run

### Official go static analysis tool
vet:
	@go vet ./...

### Official go file formater
fmt:
	@go fmt ./...

### Official tool to fix go.mod dependencies, missing, unused, checksums
tidy:
	@go mod tidy

## Test
### Runs local tests

# Default to all packages and all tests
P ?= ./...
R ?= .
TIMEOUT ?= 10m

### Runs local tests, eg: make test P=<module path | default all> R=<test name | default all> TIMEOUT=<time>
unit-test: tidy
	@echo '${GREEN}Running unit tests in $(P) (Test name Regex: '$(R)', Timeout: $(TIMEOUT))...${RESET}'
	@echo " "
	@go test -v $(P) -run $(R) -timeout $(TIMEOUT)

### Run Integration Tests only
test-integration:
	@echo "${GREEN}Running INTEGRATION tests in $(P) (Regex: '$(R)', Timeout: $(TIMEOUT))...${RESET}"
	@echo " "
	@go test -v --tags=integration ./test/integration/... -run $(R) -timeout $(TIMEOUT)

### Run E2E Tests only
test-e2e:
	@echo "${GREEN}Running E2E tests in $(P) (Regex: '$(R)', Timeout: $(TIMEOUT))...${RESET}"
	@echo " "
	@go test -v --tags=e2e ./test/e2e/... -run $(R) -timeout $(TIMEOUT)

## CI Pipeline
### Runs tests for ci pipelines and generates coverage report
test-for-ci: tidy vendor
	@mkdir -p $(TEST_COVERAGE_DIR)
	@mkdir -p $(TEST_REPORTS_DIR)
	@echo "🧪 Running Unit Tests..."
	-@go test -v -timeout $(TIMEOUT) ./... -coverprofile=$(TEST_COVERAGE_DIR)/coverage_unit.out \
		-json > $(TEST_REPORTS_DIR)/report_unit.json
	@echo " "
	@echo "🔌 Running Integration Tests..."
	-@go test -v --tags=integration ./test/integration/... -timeout $(TIMEOUT) -coverprofile=$(TEST_COVERAGE_DIR)/coverage_it.out \
		-json > $(TEST_REPORTS_DIR)/report_it.json
	@echo " "
	@echo "🌍 Running E2E Tests..."
	-@go test -v --tags=e2e ./test/e2e/... -timeout $(TIMEOUT) -coverprofile=$(TEST_COVERAGE_DIR)/coverage_e2e.out \
		-json > $(TEST_REPORTS_DIR)/report_e2e.json
	@echo " "

### Displays test coverage report in html mode
coverage: test-for-ci
	@echo "📊 Generating HTML reports..."
	@go tool cover -html=$(TEST_COVERAGE_DIR)/coverage_unit.out -o $(TEST_COVERAGE_DIR)/coverage_unit.html
	@go tool cover -html=$(TEST_COVERAGE_DIR)/coverage_it.out   -o $(TEST_COVERAGE_DIR)/coverage_it.html
	@go tool cover -html=$(TEST_COVERAGE_DIR)/coverage_e2e.out  -o $(TEST_COVERAGE_DIR)/coverage_e2e.html
	@echo "✅ Done! Artifacts stored in $(TEST_ARTIFACT_DIR)/"

# Helper to remove the artifacts
clean-test-artifacts:
	@rm -rf $(TEST_ARTIFACT_DIR)


## Build
### Build the go application
build:
	@mkdir -p bin/
	@go build -o $(EXE_PATH) ./cmd/hellowrld
	@echo " "
	@echo '${GREEN}Build passed${RESET}'

### Runs the go binary. use additional options if required.
run: clean build
	@chmod +x $(EXE_PATH)
	@echo ""
	@$(EXE_PATH)

### Cleans binary and other generated files
clean:
	@go clean
	@rm -rf bin/
	@rm -f coverage*.out

### Local copy of all packages required to support builds and tests in the /vendor directory, use with caution
vendor:
	@go mod vendor

### Code gen tool for wiring dependencies to services (update if using some other DI tool)
wire:
	@wire ./...

# [Optional] mock generation via go generate
# generate_mocks:
# 	go generate -x `go list ./... | grep - v wire`

# [Optional] Database commands
## Database
### Migrate database using test config
migrate: clean build
	@${EXE_PATH} migrate --config=config/application.test.yml

### Rollback database using test config
rollback: clean build
	@${EXE_PATH} migrate --config=config/application.test.yml

## Misc
### Local packages
local-packages:
	@echo $(shell go list ./... | grep -v /vendor) | tr ' ' '\n'

### External packages
external-packages:
	@go list -m -u all

## All
### Runs setup, quality checks and builds, default command if no target is specified for make
all: check-quality test build

## Help
### Show this help.
help:
	@echo ''
	@echo 'Usage:'
	@echo '  ${YELLOW}make${RESET} ${GREEN}<target>${RESET}'
	@echo ''
	@echo 'Targets:'
	@awk '/^## / {printf "  ${CYAN}%s${RESET}\n", substr($$0, 4); next} /^### / {desc = substr($$0, 5); next} /^[a-zA-Z_-]+:/ {cmd=substr($$1, 1, length($$1)-1); printf "    ${YELLOW}%-20s${GREEN}%s${RESET}\n", cmd, desc; desc = ""}' $(MAKEFILE_LIST)

# Help extracts the following from the make file
# 1 # is a comment and is ignored, 2 # is a Title, 3 # is a command description