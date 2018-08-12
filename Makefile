folders = $(shell ls | grep 0)

.PHONY: no_default $(folders)

no_default:

$(folders): %: %/main.ml
	@ ocamlfind ocamlc -package batteries -linkpkg $@/main.ml -o $@/main
	@ cat $@/input | $@/main
