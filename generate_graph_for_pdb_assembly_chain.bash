#!/bin/bash

PDBID="$(echo $1 | tr '[:upper:]' '[:lower:]')"
ASSEMBLYNUM="$2"
CHAINID="$3"
EXTRAARG="$4"

if [ -z "$PDBID" ] || [ -z "$ASSEMBLYNUM" ] || [ -z "$CHAINID" ] || [ -n "$EXTRAARG" ]
then
	echo >&2 "Error: invalid arguments, need exactly three: PDBID ASSEMBLYNUM CHAINID"
	exit 1
fi

cd "$(dirname $0)"

COMPLEXFILE="./data/complexes/${PDBID}_as_${ASSEMBLYNUM}.pdb"

if [ ! -s "$COMPLEXFILE" ]
then
	mkdir -p "$(dirname ${COMPLEXFILE})"
	voronota-js-pdb-utensil-download-structure --id "$PDBID" --assembly "$ASSEMBLYNUM" > "$COMPLEXFILE"
fi

./tools/extract-and-describe-receptor-protein --input-complex "$COMPLEXFILE" --chain-id "$CHAINID" --output-dir './data/receptors'

