#!/bin/bash

COMPLEXFILE="$1"
CHAIN="$(echo $2 | tr -d ' ')"
FORCEFLAG="$3"
EXTRAARG="$4"

if [ -z "$COMPLEXFILE" ] || [ -z "$CHAIN" ] || [ -n "$EXTRAARG" ]
then
	echo >&2 "Error: invalid arguments, need exactly two (COMPLEXFILE CHAIN) or three (COMPLEXFILE CHAIN force)"
	exit 1
fi

if [ -n "$FORCEFLAG" ] && [ "$FORCEFLAG" != "force" ]
then
	echo >&2 "Error: invalid flag argument, bust be either empty or 'force'"
	exit 1
fi

if [ ! -s "$COMPLEXFILE" ]
then
	echo >&2 "Error: complex structure file $COMPLEXFILE"
	exit 1
fi

COMPLEX_BASENAME="$(basename ${COMPLEXFILE} .pdb)"

if [ "${CHAIN}" == "first" ]
then
	CHAIN="$(cat ${COMPLEXFILE} | voronota-js-pdb-utensil-print-sequence-from-structure --selection '[-protein]' | head -1 | tr -d '>' | awk '{print $1}')"
fi

BASENAME="${COMPLEX_BASENAME}_chain_$(echo ${CHAIN} | tr ',' '-')"
OUTPREFIX="./data/receptor_graphs/${BASENAME}/${BASENAME}"

DATA_DESCRIPTION="complex '$COMPLEXFILE' chain '$CHAIN'"

if [ -s "${OUTPREFIX}_graph_nodes.csv" ] && [ -s "${OUTPREFIX}_graph_links.csv" ] && [ -s "${OUTPREFIX}_receptor.pdb" ] && [ -s "${OUTPREFIX}_iface_contacts.tsv" ] && [ -s "${OUTPREFIX}_bsite_areas.tsv" ] && [ -s "${OUTPREFIX}_sequences.fasta" ] && [ "$FORCEFLAG" != "force" ]
then
	echo "Skipping: graph data already available for $DATA_DESCRIPTION"
	exit 0
fi

mkdir -p "$(dirname ${OUTPREFIX})"

{
cat "$COMPLEXFILE" \
| voronota-js-pdb-utensil-print-sequence-from-structure --selection '[-protein]' \
| sed 's/^\(>.*\)$/\1 protein/'

cat "$COMPLEXFILE" \
| voronota-js-pdb-utensil-print-sequence-from-structure --selection '[-nucleic]' 2> /dev/null \
| sed 's/^\(>.*\)$/\1 nucleic/'
} \
> "${OUTPREFIX}_sequences.fasta"

voronota-js-fast-iface-contacts \
  --input "$COMPLEXFILE" \
  --as-assembly \
  --subselect-contacts "[-a1 [-chain ${CHAIN}] -a2! [-chain ${CHAIN}]]" \
  --output-contacts-file "${OUTPREFIX}_iface_contacts.tsv" \
  --output-bsite-file "${OUTPREFIX}_bsite_areas.tsv"

if [ ! -s "${OUTPREFIX}_iface_contacts.tsv" ]
then
	echo >&2 "Error: failed to compute interface contacts for $DATA_DESCRIPTION"
	exit 1
fi

if [ ! -s "${OUTPREFIX}_bsite_areas.tsv" ]
then
	echo >&2 "Error: failed to compute binding site areas for $DATA_DESCRIPTION"
	exit 1
fi

{
cat << EOF
var params={}
params.complex_structure_file='$COMPLEXFILE';
params.bsite_file='${OUTPREFIX}_bsite_areas.tsv';
params.chain_id='$CHAIN';
params.output_prefix='${OUTPREFIX}';
EOF

cat << 'EOF'
voronota_auto_assert_full_success=true;

voronota_import('-file', params.complex_structure_file, '-as-assembly', '-title', 'model');

voronota_restrict_atoms("-use", "[-chain "+params.chain_id+"]");

voronota_faspr('-lib-path', './tools');

voronota_import_adjuncts_of_atoms("-file", params.bsite_file, "-no-serial");

voronota_set_adjunct_of_atoms("-use [-v! bsite_area] -name bsite_area -value 0");

voronota_construct_contacts('-probe', 0.01);

voronota_set_adjunct_of_atoms_by_expression('-expression', '_linear_combo', '-input-adjuncts', 'volume', '-parameters', [1.0, 0.0], '-output-adjunct', 'volume_vdw');

voronota_delete_adjuncts_of_atoms('-adjuncts', ['volume']);

voronota_construct_contacts('-probe', 1.4, '-adjunct-solvent-direction', '-calculate-bounding-arcs', '-force');

voronota_voromqa_global("-adj-atom-sas-potential", "voromqa_sas_potential", "-adj-contact-energy", "voromqa_energy", "-smoothing-window", 0, "-adj-atom-quality", "voromqa_score_a", "-adj-residue-quality", "voromqa_score_r");

voronota_set_adjunct_of_atoms_by_type_number("-name", "atom_type", "-typing-mode", "protein_atom");
voronota_set_adjunct_of_atoms_by_type_number("-name", "residue_type", "-typing-mode", "protein_residue");

voronota_set_adjunct_of_atoms_by_contact_areas("-use [-solvent] -name sas_area");
voronota_set_adjunct_of_atoms_by_contact_adjuncts('[-solvent]', '-source-name', 'solvdir_x', '-destination-name', 'solvdir_x', '-pooling-mode', 'min');
voronota_set_adjunct_of_atoms_by_contact_adjuncts('[-solvent]', '-source-name', 'solvdir_y', '-destination-name', 'solvdir_y', '-pooling-mode', 'min');
voronota_set_adjunct_of_atoms_by_contact_adjuncts('[-solvent]', '-source-name', 'solvdir_z', '-destination-name', 'solvdir_z', '-pooling-mode', 'min');

voronota_set_adjuncts_of_atoms_by_ufsr('[-aname CA]', '-name-prefix', 'mc_ufsr');
voronota_set_adjunct_of_atoms_by_residue_pooling('-source-name mc_ufsr_a1 -destination-name ufsr_a1 -pooling-mode max');
voronota_set_adjunct_of_atoms_by_residue_pooling('-source-name mc_ufsr_b1 -destination-name ufsr_b1 -pooling-mode max');
voronota_set_adjunct_of_atoms_by_residue_pooling('-source-name mc_ufsr_c1 -destination-name ufsr_c1 -pooling-mode max');
voronota_set_adjunct_of_atoms_by_residue_pooling('-source-name mc_ufsr_a2 -destination-name ufsr_a2 -pooling-mode max');
voronota_set_adjunct_of_atoms_by_residue_pooling('-source-name mc_ufsr_b2 -destination-name ufsr_b2 -pooling-mode max');
voronota_set_adjunct_of_atoms_by_residue_pooling('-source-name mc_ufsr_c2 -destination-name ufsr_c2 -pooling-mode max');
voronota_set_adjunct_of_atoms_by_residue_pooling('-source-name mc_ufsr_a3 -destination-name ufsr_a3 -pooling-mode max');
voronota_set_adjunct_of_atoms_by_residue_pooling('-source-name mc_ufsr_b3 -destination-name ufsr_b3 -pooling-mode max');
voronota_set_adjunct_of_atoms_by_residue_pooling('-source-name mc_ufsr_c3 -destination-name ufsr_c3 -pooling-mode max');

voronota_describe_exposure("-adj-atom-exposure-value ev14 -probe-min 1.4 -probe-max 30 -expansion 1 -smoothing-iterations 0 -smoothing-depth 0");
voronota_describe_exposure("-adj-atom-exposure-value ev28 -probe-min 2.8 -probe-max 30 -expansion 1 -smoothing-iterations 0 -smoothing-depth 0");
voronota_describe_exposure("-adj-atom-exposure-value ev56 -probe-min 5.6 -probe-max 30 -expansion 1 -smoothing-iterations 0 -smoothing-depth 0");

voronota_auto_assert_full_success=false;
voronota_set_adjunct_of_atoms("-use [-v! sas_area] -name sas_area -value 0");
voronota_set_adjunct_of_atoms("-use [-v! solvdir_x] -name solvdir_x -value 0");
voronota_set_adjunct_of_atoms("-use [-v! solvdir_y] -name solvdir_y -value 0");
voronota_set_adjunct_of_atoms("-use [-v! solvdir_z] -name solvdir_z -value 0");
voronota_set_adjunct_of_atoms("-use [-v! voromqa_sas_potential] -name voromqa_sas_potential -value 0");
voronota_set_adjunct_of_atoms("-use [-v! ev14] -name ev14 -value 2");
voronota_set_adjunct_of_atoms("-use [-v! ev28] -name ev28 -value 2");
voronota_set_adjunct_of_atoms("-use [-v! ev56] -name ev56 -value 2");
voronota_auto_assert_full_success=true;

voronota_set_adjunct_of_atoms_by_expression("-use [] -expression _multiply -input-adjuncts voromqa_sas_potential sas_area -output-adjunct voromqa_sas_energy");

voronota_set_adjunct_of_contacts("-use [] -name seq_sep_class -value 5");
voronota_set_adjunct_of_contacts("-use [] -name covalent_bond -value 0");

voronota_run_hbplus('-select-contacts', 'hbonds');
voronota_set_adjunct_of_contacts("-use [hbonds] -name hbond -value 1");

voronota_auto_assert_full_success=false;
voronota_set_adjunct_of_contacts("-use [-min-seq-sep 0 -max-seq-sep 0] -name seq_sep_class -value 0");
voronota_set_adjunct_of_contacts("-use [-min-seq-sep 1 -max-seq-sep 1] -name seq_sep_class -value 1");
voronota_set_adjunct_of_contacts("-use [-min-seq-sep 2 -max-seq-sep 2] -name seq_sep_class -value 2");
voronota_set_adjunct_of_contacts("-use [-min-seq-sep 3 -max-seq-sep 3] -name seq_sep_class -value 3");
voronota_set_adjunct_of_contacts("-use [-min-seq-sep 4 -max-seq-sep 4] -name seq_sep_class -value 4");
voronota_set_adjunct_of_contacts("-use ([-max-seq-sep 0 -max-dist 1.8] or [-min-seq-sep 1 -max-seq-sep 1 -a1 [-aname N] -a2 [-aname C] -max-dist 1.8]) -name covalent_bond -value 1");
voronota_set_adjunct_of_contacts("-use [-v! voromqa_energy] -name voromqa_energy -value 0");
voronota_set_adjunct_of_contacts("-use [-v! hbond] -name hbond -value 0");
voronota_auto_assert_full_success=true;

voronota_export_atoms('-as-pdb', '-file', params.output_prefix+'_receptor.pdb', '-pdb-b-factor', 'bsite_area');

voronota_export_adjuncts_of_atoms('-file', params.output_prefix+'_graph_nodes.csv', '-use', '[]', '-no-serial', '-adjuncts', ['atom_index', 'residue_index', 'atom_type', 'residue_type', 'center_x', 'center_y', 'center_z', 'radius', 'sas_area', 'solvdir_x', 'solvdir_y', 'solvdir_z', 'voromqa_sas_energy', 'voromqa_depth', 'voromqa_score_a', 'voromqa_score_r', 'volume', 'volume_vdw', 'ev14', 'ev28', 'ev56', 'ufsr_a1', 'ufsr_a2', 'ufsr_a3', 'ufsr_b1', 'ufsr_b2', 'ufsr_b3', 'ufsr_c1', 'ufsr_c2', 'ufsr_c3', 'bsite_area'], '-sep', ',', '-expand-ids', true);

voronota_export_adjuncts_of_contacts('-file', params.output_prefix+'_graph_links.csv', '-atoms-use', '[]', '-contacts-use', '[-no-solvent]', '-no-serial', '-adjuncts', ['atom_index1', 'atom_index2', 'area', 'boundary', 'distance', 'voromqa_energy', 'seq_sep_class', 'covalent_bond', 'hbond'], '-sep', ',', '-expand-ids', true);

EOF
} \
| voronota-js

if [ ! -s "${OUTPREFIX}_graph_nodes.csv" ] || [ ! -s "${OUTPREFIX}_graph_links.csv" ] || [ ! -s "${OUTPREFIX}_receptor.pdb" ]
then
	echo >&2 "Failed: graph data for $DATA_DESCRIPTION"
	exit 1
fi

echo "Finished: graph data for $DATA_DESCRIPTION"

