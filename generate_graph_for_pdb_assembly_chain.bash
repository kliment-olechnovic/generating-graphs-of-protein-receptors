#!/bin/bash

PDBID="$(echo $1 | tr '[:upper:]' '[:lower:]')"
ASSEMBLYNUM="$2"
CHAINID="$3"
EXTRAARG="$4"

if [ -z "$PDBID" ] || [ -z "$ASSEMBLYNUM" ] || [ -z "$CHAINID" ]|| [ -n "$EXTRAARG" ]
then
	echo >&2 "Error: invalid arguments, need exactly three: PDBID ASSEMBLYNUM CHAINID"
	exit 1
fi

cd "$(dirname $0)"

./tools/download_and_preprocess_complex.bash "$PDBID" "$ASSEMBLYNUM"

./tools/extract_and_describe_monomer.bash "./data/complexes/${PDBID}_as_${ASSEMBLYNUM}/${PDBID}_as_${ASSEMBLYNUM}_structure.pdb" "$CHAINID"

