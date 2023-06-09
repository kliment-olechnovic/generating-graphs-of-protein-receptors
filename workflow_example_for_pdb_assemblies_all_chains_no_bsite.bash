#!/bin/bash

cd "$(dirname $0)"

cat "./lists/POBSUDL_pdb_ids.txt" \
| awk '{print $1 " " $2}' \
| head -3 \
| while read -r PDBID ASSEMBLYNUM
do
	COMPLEXFILE="./data_example_for_pdb_assemblies_all_chains_no_bsite/complexes/${PDBID}_as_${ASSEMBLYNUM}.pdb"
	
	mkdir -p "$(dirname ${COMPLEXFILE})"
	
	voronota-js-pdb-utensil-download-structure --id "$PDBID" --assembly "$ASSEMBLYNUM" > "$COMPLEXFILE"
	
	./tools/extract-and-describe-receptor-protein --input-complex "$COMPLEXFILE" --all-chains-no-bsite --no-faspr --output-dir './data_example_for_pdb_assemblies_all_chains_no_bsite/receptors'
done
