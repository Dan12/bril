TESTS := test/base/*.bril \
	test/record/*.bril \
	test/mem/mem/*.bril \
	test/comp/*.bril \
	test/func/*.bril

.PHONY: test
test:
	python3 -m turnt $(TESTS)

.PHONY: interp
interp:
	npm run build

.PHONY: parser
parser:
	cd parser && flit install --symlink --user
