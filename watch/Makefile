SDK_HOME := $(HOME)/Library/Application\ Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.1.0-2026-03-09-6a872a80b
MC       := $(SDK_HOME)/bin/monkeyc
SIM      := $(SDK_HOME)/bin/connectiq
DO       := $(SDK_HOME)/bin/monkeydo
KEY      := $(HOME)/Library/Application\ Support/Garmin/ConnectIQ/developer_key.der
DEVICE   ?= fenix7
OUT      := bin/CricketScores.prg

.PHONY: build sim run clean

build:
	$(MC) -f monkey.jungle -d $(DEVICE) -y $(KEY) -o $(OUT)

sim:
	$(SIM) &

run: build
	$(DO) $(OUT) $(DEVICE)

clean:
	rm -rf bin/
