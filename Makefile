NIM=nimble c

MAIN=vt_nim

SRC=src

DEBUGOUT=build
RELEASEOUT=release

FLAGS=-d:ssl --passL:-s

DEBUGOPTS=$(FLAGS) --outdir:$(DEBUGOUT) --verbose
RELEASEOPTS=$(FLAGS) --outdir:$(RELEASEOUT) -d:release --app:gui

.PHONY: run debug release clean

run:
	$(NIM) $(DEBUGOPTS) -r $(SRC)/$(MAIN)

debug:
	$(NIM) $(DEBUGOPTS) $(SRC)/$(MAIN)

release:
	$(NIM) $(RELEASEOPTS) $(SRC)/$(MAIN)

clean:
	rm ./$(DEBUGOUT)/*
	rm ./$(RELEASEOUT)/*
