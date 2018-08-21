folders = $(shell find . -name main.ml | xargs -n1 dirname | sed 's|^\./||')
executables = $(patsubst %, %/main, $(folders))
debug_rules = $(patsubst %, debug-%, $(folders))

.PHONY: no_default $(folders) $(debug_rules)
no_default:

$(folders): %:%/main
	@ if [ -f $@/input ]; then cat $@/input | OCAMLRUNPARAM=b $@/main; else $@/main; fi

$(executables): %:%.ml
	@ ocamlfind ocamlc -package batteries -linkpkg $@.ml -g -o $@

$(debug_rules): debug-%:%/main
	ocamldebug -cd $(@:debug-%=%) main
