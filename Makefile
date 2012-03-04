markdown:
	redcarpet README.md > ./documentation/readme.html

combine:
	cat ./documentation/protocol.html ./documentation/readme.html > ./documentation/index.html

preview:
	open ./documentation/index.html

all: markdown combine preview
