markdown:
	redcarpet README.md > ./docs.html

combine:
	cat ./layout.html ./docs.html > ./index.html

sass-convert:
	sass ./src/style.sass ./style.css

preview:
	open ./index.html

all: markdown combine sass-convert preview
