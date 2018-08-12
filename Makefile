folders = $(shell ls | grep 0)
executables = $(patsubst %, %/main, $(folders))

.PHONY: no_default $(folders)

no_default:

$(executables): %: %.ml
	@ ocamlfind ocamlc -package batteries -linkpkg $@.ml -o $@

$(folders): %: %/main
	@ if [ -f $@/input ]; then cat $@/input | $@/main; else $@/main; fi
