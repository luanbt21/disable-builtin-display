[private]
default:
    @just --list

# build a release binary
build:
    swift build -c release

# build, install to $PREFIX/bin (default ~/.local/bin) and load the launch agent
install:
    ./scripts/install.sh

# re-enable the built-in display, then remove the launch agent and binary
uninstall:
    ./scripts/uninstall.sh

clean:
    swift package clean
    rm -rf .build
