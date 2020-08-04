NIM=nimble c

MAIN=vt_nim

SRC=src

DEBUGOUT=build
RELEASEOUT=release

FLAGS=-d:ssl

DEBUGOPTS=$(FLAGS) --outdir:$(DEBUGOUT)
RELEASEOPTS=$(FLAGS) --outdir:$(RELEASEOUT) -d:release

run:
	$(NIM) $(DEBUGOPTS) -r $(SRC)/$(MAIN)

debug:
	$(NIM) $(DEBUGOPTS) $(SRC)/$(MAIN)

release:
	$(NIM) $(RELEASEOPTS) $(SRC)/$(MAIN)

clean:
	rm ./$(DEBUGOUT)/*
	rm ./$(RELEASEOUT)/*
