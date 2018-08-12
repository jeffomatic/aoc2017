.PHONY: 01

01: 01/main.ml
	@ ocamlfind ocamlc -package batteries -linkpkg 01/main.ml -o 01/main
	@ cat 01/input | 01/main
