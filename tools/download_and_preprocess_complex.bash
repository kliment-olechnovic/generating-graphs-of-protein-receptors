#!/bin/bash

PDBID="$(echo $1 | tr '[:upper:]' '[:lower:]')"
ASSEMBLYNUM="$2"
FORCEFLAG="$3"
EXTRAARG="$4"

if [ -z "$PDBID" ] || [ -z "$ASSEMBLYNUM" ] || [ -n "$EXTRAARG" ]
then
	echo >&2 "Error: invalid arguments, need exactly two (PDBID ASSEMBLYNUM) or three (PDBID ASSEMBLYNUM force)"
	exit 1
fi

if [ -n "$FORCEFLAG" ] && [ "$FORCEFLAG" != "force" ]
then
	echo >&2 "Error: invalid flag argument, bust be either empty or 'force'"
	exit 1
fi

COMPLEX_BASENAME="${PDBID}_as_${ASSEMBLYNUM}"
COMPLEX_OUTPREFIX="./data/complexes/${COMPLEX_BASENAME}"

if [ -s "${COMPLEX_OUTPREFIX}.pdb" ] && [ "$FORCEFLAG" != "force" ]
then
	echo "Skipping: complex data already available for PDBID $PDBID assembly $ASSEMBLYNUM"
	exit 0
fi

mkdir -p "$(dirname ${COMPLEX_OUTPREFIX})"

voronota-js-pdb-utensil-download-structure --id "$PDBID" --assembly "$ASSEMBLYNUM" > "${COMPLEX_OUTPREFIX}.pdb"

if [ ! -s "${COMPLEX_OUTPREFIX}.pdb" ]
then
	echo >&2 "Error: failed to download PDBID $PDBID assembly $ASSEMBLYNUM"
	exit 1
fi

if [ ! -s "${COMPLEX_OUTPREFIX}.pdb" ]
then
	echo >&2 "Error: failed to extract sequence for PDBID $PDBID assembly $ASSEMBLYNUM"
	exit 1
fi

echo "Finished: complex data for PDBID $PDBID assembly $ASSEMBLYNUM"

