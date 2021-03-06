VERSION="0.0"
GIT_COMMIT=$(shell git rev-parse --short HEAD)
GIT_BRANCH=$(shell git rev-parse --abbrev-ref HEAD)
BUILD_DATE=$(shell date '+%Y-%m-%d')
VERSION_FILE=libgadget/version.go

## This is an arbitrary comment to arbitrarily change the commit hash

GOPATH?=$(shell go env GOPATH)
GADGET_SOURCES=$(shell ls gadgetcli/*.go)
GADGETOSINIT_SOURCES=$(shell ls gadgetosinit/*.go)
LIBGADGET_SOURCES=$(shell ls libgadget/*.go)

DEPENDS=\
	golang.org/x/crypto/ssh\
	gopkg.in/yaml.v2\
	gopkg.in/satori/go.uuid.v1\
	golang.org/x/crypto/ssh\
	golang.org/x/crypto/ssh/terminal\
	gopkg.in/sirupsen/logrus.v1\
	gopkg.in/cheggaaa/pb.v1\
	github.com/tmc/scp\
	github.com/nextthingco/logrus-gadget-formatter

## Bottom two libs here^^ are essentially one-off code chunks which aren't
## likely to be updated. Neither has tags, and thus, gopkg.in links aren't
## being used.

gadget: libgadget $(GADGET_SOURCES) $(VERSION_FILE) $(LIBGADGET_SOURCES)
	@echo "Building Gadget"
	@go build -o gadget -ldflags="-s -w" -v ./gadgetcli

genversion:
	@echo "package libgadget" > $(VERSION_FILE)
	@echo "const (" >> $(VERSION_FILE)
	@echo "	Version = \"${VERSION}\"" >> $(VERSION_FILE)
	@echo "	GitCommit = \"${GIT_COMMIT}\"" >> $(VERSION_FILE)
	@echo "	GitBranch = \"${GIT_BRANCH}\"" >> $(VERSION_FILE)
	@echo "	BuildDate = \"${BUILD_DATE}\"" >> $(VERSION_FILE)
	@echo ")" >> $(VERSION_FILE)

gadget_release: libgadget $(GADGET_SOURCES) $(VERSION_FILE) $(LIBGADGET_SOURCES)
	@echo "Building Gadget Release"
	@mkdir -p build/linux
	@mkdir -p build/linux_arm
	@mkdir -p build/linux_arm64
	@mkdir -p build/windows
	@mkdir -p build/darwin
	@echo "  Linux AMD64"
	@GOOS=linux GOARCH=amd64 go build -o build/linux/gadget -ldflags="-s -w" -v ./gadgetcli
	@echo "  Linux ARM"
	@GOOS=linux GOARCH=arm go build -o build/linux_arm/gadget -ldflags="-s -w" -v ./gadgetcli
	@echo "  Linux ARM64"
	@GOOS=linux GOARCH=arm64 go build -o build/linux_arm64/gadget -ldflags="-s -w" -v ./gadgetcli
	@echo "  Windows AMD64"
	@GOOS=windows GOARCH=amd64 go build -o build/windows/gadget.exe -ldflags="-s -w" -v ./gadgetcli
	@echo "  MacOS"
	@GOOS=darwin GOARCH=amd64 go build -o build/darwin/gadget -ldflags="-s -w" -v ./gadgetcli

gadgetosinit_release: libgadget $(GADGET_SOURCES) $(VERSION_FILE) $(LIBGADGET_SOURCES)
	@echo "Building Gadget Release"
	@mkdir -p build/linux_arm
	@mkdir -p build/linux_arm64
	@GOOS=linux GOARCH=arm go build -o build/linux_arm/gadgetosinit -ldflags="-s -w" ./gadgetosinit
	@GOOS=linux GOARCH=arm64 go build -o build/linux_arm64/gadgetosinit -ldflags="-s -w" ./gadgetosinit

libgadget: genversion
	@echo "Building libgadget"
	@rm -rf ${GOPATH}/src/github.com/nextthingco/libgadget
	@cp -r libgadget ${GOPATH}/src/github.com/nextthingco/
	@go install -ldflags="-X libgadget.Version=$(VERSION) -X libgadget.GitCommit=$(GIT_COMMIT)" -v github.com/nextthingco/libgadget

tidy:
	@echo "Tidying up sources"
	@go fmt ./gadgetcli
	@go fmt ./gadgetosinit
	@go fmt ./libgadget

clean:
	@echo "Cleaning"
	@rm -rf build/ gadget gadget.yml $(VERSION_FILE)

test: $(GADGET_SOURCES) $(GADGET_SOURCES)
	@echo "Testing Gadget"
	@rm -f /tmp/gadget.yml gadgetcli/gadget.yml
	@go test -ldflags="-s -w" -v ./gadgetcli
	@go test -ldflags="-s -w" -v ./libgadget

get:
	@echo "Downloading external dependencies"
	@go get ${DEPENDS}
