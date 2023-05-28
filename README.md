# Annotating binding sites of proteins

## Idea

This repository provides and showcases tools to automatically annotate binding sites in protein structures and describe annotated structures as graphs.

## Requitements 

Main requrements is [Voronota-JS](https://kliment-olechnovic.github.io/voronota/expansion_js/index.html) from the latest [Voronota package](https://github.com/kliment-olechnovic/voronota/releases/).

For detecting hydrogen bonds, HBPLUS is required.

## Core script

The core script used in the provided example workflows is "extract-and-describe-receptor-protein" from the "tools" directory.
Its interface is described below:

    'extract-and-describe-receptor-protein' extracts and describes one or more protein chains from a protein complex.
    
    Options:
        --input-complex           string  *  path to full protein complex file in PDB format
        --chain-id                string     chain ID (or comma-separated IDs), default is 'first' to take the first protein chain
        --output-dir              string  *  output directory path
        --output-naming           string     output files naming mode, default is 'BASENAME/name', other possibilities are 'BASENAME_name' and 'BASENAME/BASENAME_name'
        --no-faspr                           flag to not rebuild side-chains with FASPR
        --help | -h                          flag to display help message and exit
        
    Standard output:
        Information messages in stdout, error messages in stderr
        
    Examples:
        extract-and-describe-receptor-protein --input-complex "./2zsk.pdb"
        
        extract-and-describe-receptor-protein --input-complex "./2zsk.pdb" --chain-id "A"
        
        extract-and-describe-receptor-protein --input-complex "./3bep.pdb" --chain-id "A,B" --output-dir "./output" --output-naming "BASENAME/BASENAME_name"
        

## Workflow example scripts

The workflow example scripts are examples of getting input oligomeric structures, extracting protein receptor chain structures, and describing the extracted receptor structures as graphs.

### Downloading and analyzing PDB assemblies

"workflow_example_for_pdb_assemblies.bash" downloads and analyzes PDB assemblies:

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

### Downloading and analyzing structures from PPI3D

"workflow_example_for_input_urls.bash" downloads and analyzes structures from PPI3D

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

## Generated graph data

In a generated graph, nodes are atoms and atom-atom contacts are links.
Contacts were derived from the Voronoi tessellation of atomic balls.
Various features (mostly tessellation-derived) were assigned to nodes and links.

A generated graph is described in two files:

* `"graph_nodes.csv"` - graph nodes table file, one row per node
* `"graph_links.csv"` - graph links table file, one row per link

Other generated files are not needed for the graph description, but provide additional information:

* `"iface_contacts.tsv"` - table of inter-chain atom-atom contacts
* `"bsite_areas.tsv"` - table of per-atom binding site areas
* `"receptor.pdb"` - graph source structure PDB file with binding site areas written as b-factors
* `"sequences.fasta"` - sequences and chain names of the input complex

### Data format of the graph nodes file

Example (first 10 lines) from the file `"data_example_for_pdb_assemblies/receptors/12AS_as_1_chain_A/graph_nodes.csv"`:

    ID_chainID,ID_resSeq,ID_iCode,ID_serial,ID_altLoc,ID_resName,ID_name,atom_index,residue_index,atom_type,residue_type,center_x,center_y,center_z,radius,sas_area,solvdir_x,solvdir_y,solvdir_z,voromqa_sas_energy,voromqa_depth,voromqa_score_a,voromqa_score_r,volume,volume_vdw,ev14,ev28,ev56,ufsr_a1,ufsr_a2,ufsr_a3,ufsr_b1,ufsr_b2,ufsr_b3,ufsr_c1,ufsr_c2,ufsr_c3,bsite_area
    A,4,.,.,.,ALA,N,0,0,3,0,11.751,37.846,29.016,1.7,41.4766,-0.863194,-0.504809,0.00804754,62.2166,1,0.0354562,0.0180571,58.1273,15.1948,0.0592625,0.0587856,0.0577525,34.0362,142.282,-695.661,30.7108,139.133,-120.039,34.0362,142.282,-695.661,0
    A,4,.,.,.,ALA,CA,1,0,1,0,12.501,39.048,28.539,1.9,16.0071,-0.723214,0.378031,-0.577975,12.2818,1,0.0201598,0.0180571,31.4288,13.2112,0.059126,0.0588335,0.0586043,34.0362,142.282,-695.661,30.7108,139.133,-120.039,34.0362,142.282,-695.661,0
    A,4,.,.,.,ALA,C,2,0,0,0,13.74,38.628,27.754,1.75,2.84327,-0.49904,-0.427352,-0.753876,5.61198,1,0.012912,0.0180571,13.6506,8.74604,0.468728,0.43478,0.434589,34.0362,142.282,-695.661,30.7108,139.133,-120.039,34.0362,142.282,-695.661,0
    A,4,.,.,.,ALA,O,3,0,4,0,14.207,37.495,27.89,1.49,0.420279,-0.674764,-0.487097,-0.554464,0.212241,1,0.019627,0.0180571,14.2814,9.11478,0.786379,0.725897,2,34.0362,142.282,-695.661,30.7108,139.133,-120.039,34.0362,142.282,-695.661,0
    A,4,.,.,.,ALA,CB,4,0,2,0,12.894,39.938,29.72,1.92,48.633,-0.352764,0.742267,0.569735,3.48716,1,0.0021303,0.0180571,79.9541,23.4409,0.044606,0.0445338,0.0444399,34.0362,142.282,-695.661,30.7108,139.133,-120.039,34.0362,142.282,-695.661,0
    A,5,.,.,.,TYR,N,5,1,150,18,14.235,39.531,26.906,1.7,11.047,-0.697925,0.335794,-0.632569,21.6876,1,0.00180551,0.0133319,24.8739,10.0261,0.0750426,0.0741913,0.0740735,32.3373,132.08,-612.203,30.7108,139.133,-120.039,34.0362,142.282,-695.661,0
    A,5,.,.,.,TYR,CA,6,1,144,18,15.552,39.41,26.282,1.9,2.04646,-0.580731,-0.132339,-0.803267,3.13821,1,0.00505478,0.0133319,21.8251,13.0046,0.467696,0.444068,0.451287,32.3373,132.08,-612.203,30.7108,139.133,-120.039,34.0362,142.282,-695.661,0
    A,5,.,.,.,TYR,C,7,1,143,18,16.616,38.913,27.263,1.75,0,0,0,0,0,2,0.0209671,0.0133319,9.14366,8.51446,2,2,2,32.3373,132.08,-612.203,30.7108,139.133,-120.039,34.0362,142.282,-695.661,0
    A,5,.,.,.,TYR,O,8,1,151,18,17.187,37.844,27.068,1.49,0,0,0,0,0,2,0.0179517,0.0133319,11.7691,8.78583,2,2,2,32.3373,132.08,-612.203,30.7108,139.133,-120.039,34.0362,142.282,-695.661,0

Description of the graph nodes table columns:

* __ID_chainID__ - chain name in PDB file, given just for reference
* __ID_resSeq__ - residue number in PDB file, given just for reference
* __ID_iCode__ - insertion code in PDB file, usually null and written as '.', given just for reference
* __ID_altLoc__ - atom alternate location indicator in PDB file, usually null and written as '.', given just for reference
* __ID_serial__ - atom serial number in PDB file, usually null and written as '.', given just for reference
* __ID_resName__ - residue name
* __ID_name__ - atom name
* __atom_index__ - atom index (starting from 0), used to describe atom-atom links in the corresponding links.csv file
* __residue_index__ - residue index (starting from 0), to be used for pooling (from atom-level to residue-level)
* __atom_type__ - atom type encoded as a number from 0 to 159
* __residue_type__ - amino acid residue type encoded as a number from 0 to 19
* __center_x__, __center_y__, __center_z__ - atom center coordinates, to be either ignored or used with special care ensuring rotational and translational invariance
* __radius__ - atom van der Waals radius
* __sas_area__ - solvent-accessible surface area: larger area means that the atom is less buried and more exposed
* __solvdir_x__, __solvdir_y__, __solvdir_z__ - mean solvent-accessible surface direction vector, to be either ignored or used with special care ensuring rotational and translational invariance
* __voromqa_sas_energy__ - observed atom-solvent VoroMQA energy value
* __voromqa_depth__ - atom topological distance from the surface, starts with 1 for surface atoms
* __voromqa_score_a__ - atom-level VoroMQA score
* __voromqa_score_r__ - residue-level VoroMQA score, same for all the  atoms in the same residue
* __volume__ - volume of the Voronoi cell of an atom constrained inside the solvent-accessible surface
* __volume_vdw__ - volume of the Voronoi cell of an atom constrained inside the van der Waals surface
* __ev14__, __ev28__, __ev56__ - geometric buriedness values for different minimum probing radii (1.4, 2.8, 5.6), range from 0 (most exposed) to 1 (most buried), value of 2 is assigned to all atoms not accessible by external probes
* __ufsr_a1__, __ufsr_a2__, ... , __ufsr_c2__, __ufsr_c3__ - geometric descriptors calculated using the Ultra-fast Shape Recognition algorithm adapted for polymers
* __bsite_area__ - sum of all inbter-chain contact area involving the node atom

### Data format of the graph links file

Example (first 10 lines) from the file `"data_example_for_pdb_assemblies/receptors/12AS_as_1_chain_A/graph_links.csv"`:

    ID1_chainID,ID1_resSeq,ID1_iCode,ID1_serial,ID1_altLoc,ID1_resName,ID1_name,ID2_chainID,ID2_resSeq,ID2_iCode,ID2_serial,ID2_altLoc,ID2_resName,ID2_name,atom_index1,atom_index2,area,boundary,distance,voromqa_energy,seq_sep_class,covalent_bond,hbond
    A,4,.,.,.,ALA,N,A,4,.,.,.,ALA,CA,0,1,15.1469,6.01209,1.49494,0,0,1,0
    A,4,.,.,.,ALA,N,A,4,.,.,.,ALA,C,0,2,1.35326,0.948384,2.48199,0,0,0,0
    A,4,.,.,.,ALA,N,A,4,.,.,.,ALA,O,0,3,5.13359,1.74202,2.72452,0,0,0,0
    A,4,.,.,.,ALA,N,A,4,.,.,.,ALA,CB,0,4,7.11129,4.21153,2.48566,0,0,0,0
    A,4,.,.,.,ALA,N,A,7,.,.,.,ALA,CB,0,29,10.2298,5.98794,3.83588,1.87473,3,0,0
    A,4,.,.,.,ALA,N,A,8,.,.,.,LYS,N,0,30,0.0397181,0.283811,4.87566,0.0686924,4,0,0
    A,4,.,.,.,ALA,N,A,8,.,.,.,LYS,CB,0,34,0.0266537,0.819239,5.5762,0.0332625,4,0,0
    A,4,.,.,.,ALA,CA,A,4,.,.,.,ALA,C,1,2,9.3871,1.66547,1.5257,0,0,1,0
    A,4,.,.,.,ALA,CA,A,4,.,.,.,ALA,O,1,3,0.280716,0,2.39655,0,0,0,0

Description of the graph links table columns:

* __ID1_chainID__, __ID1_resSeq__, __ID1_iCode__, __ID1_serial__, __ID1_altLoc__, __ID1_resName__, __ID1_name__ -  general info about the first atom participating in the link, see descriptions of ID columns of the nodes table
* __ID2_chainID__, __ID2_resSeq__, __ID2_iCode__, __ID2_serial__, __ID2_altLoc__, __ID2_resName__, __ID2_name__ -  general info about the second atom participating in the link, see descriptions of ID columns of the nodes table
* __atom_index1__ - node index of the first atom participating in the link
* __atom_index2__ - node index of the second atom participating in the link
* __area__ - tessellation-derived contact area
* __boundary__ - length of the contact-solvent boundary, 0 if contact is not adjacent to the solvent-accessible surface
* __distance__ - distance between two atoms
* __voromqa_energy__ - contact VoroMQA-energy value
* __seq_sep_class__ - residue sequence separation class, ranging from 0 (sequence separation = 0) to 5 (sequence separation >= 5)
* __covalent_bond__ - covalent bond indicator (0 or 1)
* __hbond__ - hydrogen bond indicator (0 or 1)

## Important notes

### About graph connectivity

The links in the links.csv file are to be viewed as non-directional.
For processing with a GNN, it is usually necessary to define bidirectional connections and self-connections:

* if there is (i -> j) link, there should also be (j -> i) link with the same features
* there should be (i -> i) link with apppropriate features for every node i

### About atom-to-residue pooling

An atom-level graph can be coarse-grained - converted into a residue-level graph.
A residue-level graph is much smaller, therefore much faster to train GNNs with.
The area, volume, and energy features can be simply summed when going to the residue level.

### About using the data in PyTorch Geometric

I made a separate [repository](https://github.com/kliment-olechnovic/gnn-custom-dataset-example)
that is intended purely to demonstrate how to make a graph dataset for PyTorch Geometric from graph nodes (vertices) and links (edges) stored in CSV files.

