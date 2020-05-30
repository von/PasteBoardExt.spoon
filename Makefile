docs.json: init.lua
	hs -c "hs.doc.builder.genJSON(\"$(pwd)\")" | grep -v "^--" > $@
