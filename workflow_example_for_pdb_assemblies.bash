#!/bin/bash

cd "$(dirname $0)"

cat "./lists/POBSUDL_pdb_ids.txt" \
| head -3 \
| while read -r PDBID ASSEMBLYNUM CHAINID
do
	COMPLEXFILE="./data_example_for_pdb_assemblies/complexes/${PDBID}_as_${ASSEMBLYNUM}.pdb"
	
	mkdir -p "$(dirname ${COMPLEXFILE})"
	
	voronota-js-pdb-utensil-download-structure --id "$PDBID" --assembly "$ASSEMBLYNUM" > "$COMPLEXFILE"
	
	./tools/extract-and-describe-receptor-protein --input-complex "$COMPLEXFILE" --chain-id "$CHAINID" --output-dir './data_example_for_pdb_assemblies/receptors'
done
