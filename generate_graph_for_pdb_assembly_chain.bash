#!/bin/bash

PDBID="$(echo $1 | tr '[:upper:]' '[:lower:]')"
ASSEMBLYNUM="$2"
CHAINID="$3"
FORCEFLAG="$4"
EXTRAARG="$5"

if [ -z "$PDBID" ] || [ -z "$ASSEMBLYNUM" ] || [ -z "$CHAINID" ] || [ -n "$EXTRAARG" ]
then
	echo >&2 "Error: invalid arguments, need exactly three (PDBID ASSEMBLYNUM CHAINID) or four (PDBID ASSEMBLYNUM CHAINID force)"
	exit 1
fi

if [ -n "$FORCEFLAG" ] && [ "$FORCEFLAG" != "force" ]
then
	echo >&2 "Error: invalid flag argument, bust be either empty or 'force'"
	exit 1
fi

cd "$(dirname $0)"

./tools/download_and_preprocess_complex.bash "$PDBID" "$ASSEMBLYNUM" "$FORCEFLAG"

./tools/extract_and_describe_monomer.bash "./data/complexes/${PDBID}_as_${ASSEMBLYNUM}.pdb" "$CHAINID" "$FORCEFLAG"

