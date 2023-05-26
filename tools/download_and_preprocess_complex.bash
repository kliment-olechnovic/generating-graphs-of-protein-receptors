#!/bin/bash

PDBID="$(echo $1 | tr '[:upper:]' '[:lower:]')"
ASSEMBLYNUM="$2"
EXTRAARG="$3"

if [ -z "$PDBID" ] || [ -z "$ASSEMBLYNUM" ] || [ -n "$EXTRAARG" ]
then
	echo >&2 "Error: invalid arguments, need exactly two: PDBID ASSEMBLYNUM"
	exit 1
fi

COMPLEX_BASENAME="${PDBID}_as_${ASSEMBLYNUM}"
COMPLEX_OUTPREFIX="./data/complexes/${COMPLEX_BASENAME}/${COMPLEX_BASENAME}"

if [ -s "${COMPLEX_OUTPREFIX}_structure.pdb" ] && [ -s "${COMPLEX_OUTPREFIX}_sequences.fasta" ] && [ -s "${COMPLEX_OUTPREFIX}_iface_contacts.tsv" ] && [ -s "${COMPLEX_OUTPREFIX}_bsite_areas.tsv" ]
then
	echo >&2 "Skipping: complex data already available for PDBID $PDBID assembly $ASSEMBLYNUM"
	exit 0
fi

mkdir -p "$(dirname ${COMPLEX_OUTPREFIX})"

voronota-js-pdb-utensil-download-structure --id "$PDBID" --assembly "$ASSEMBLYNUM" > "${COMPLEX_OUTPREFIX}_structure.pdb"

if [ ! -s "${COMPLEX_OUTPREFIX}_structure.pdb" ]
then
	echo >&2 "Error: failed to download PDBID $PDBID assembly $ASSEMBLYNUM"
	exit 1
fi

cat "${COMPLEX_OUTPREFIX}_structure.pdb" \
| voronota-js-pdb-utensil-print-sequence-from-structure \
> "${COMPLEX_OUTPREFIX}_sequences.fasta"

if [ ! -s "${COMPLEX_OUTPREFIX}_structure.pdb" ]
then
	echo >&2 "Error: failed to extract sequence for PDBID $PDBID assembly $ASSEMBLYNUM"
	exit 1
fi

voronota-js-fast-iface-contacts \
  --input "${COMPLEX_OUTPREFIX}_structure.pdb" \
  --as-assembly \
  --output-contacts-file "${COMPLEX_OUTPREFIX}_iface_contacts.tsv" \
  --output-bsite-file "${COMPLEX_OUTPREFIX}_bsite_areas.tsv"

if [ ! -s "${COMPLEX_OUTPREFIX}_iface_contacts.tsv" ]
then
	echo >&2 "Error: failed to compute interface contacts for PDBID $PDBID assembly $ASSEMBLYNUM"
	exit 1
fi

