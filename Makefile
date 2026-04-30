.PHONY: build release run app clean help

help:
	@echo "Targets:"
	@echo "  make build    — debug build (.build/debug/Sharpie)"
	@echo "  make release  — release build (.build/release/Sharpie)"
	@echo "  make run      — swift run (foreground, ⌃C to quit)"
	@echo "  make app      — assemble Sharpie.app at build/Sharpie.app"
	@echo "  make clean    — remove .build and build/"

build:
	swift build

release:
	swift build -c release

run:
	swift run

app:
	./scripts/build-app.sh

clean:
	rm -rf .build build
