folders = $(shell ls | grep 0)
executables = $(patsubst %, %/main, $(folders))
debug_rules = $(patsubst %, debug-%, $(folders))

.PHONY: no_default $(folders) $(debug_rules)

no_default:

$(executables): %:%.ml
	@ ocamlfind ocamlc -package batteries -linkpkg $@.ml -g -o $@

$(folders): %:%/main
	@ if [ -f $@/input ]; then cat $@/input | $@/main; else $@/main; fi

$(debug_rules): debug-%:%/main
	ocamldebug -cd $(@:debug-%=%) main
