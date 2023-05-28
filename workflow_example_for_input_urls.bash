#!/bin/bash

cd "$(dirname $0)"

cat "./lists/Protein-NA_dimers_from_PPI3D.txt" \
| head -3 \
| while read -r URL
do
	STRUCTNAME="$(basename ${URL} .pdb).pdb"
	
	COMPLEXFILE="./data_example_for_input_urls/complexes/${STRUCTNAME}"
	
	mkdir -p "$(dirname ${COMPLEXFILE})"
	
	curl --silent --show-error --output "$COMPLEXFILE" "$URL"
	
	./tools/extract-and-describe-receptor-protein --input-complex "$COMPLEXFILE" --chain-id "first" --output-dir './data_example_for_input_urls/receptors'
done
