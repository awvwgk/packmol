#!/bin/bash
#
# Install Julia
if [[ $(which juliaup) ]]; then
    echo "juliaup found"
else
    curl -fsSL https://install.julialang.org | sh
fi
# Run the tests
julia runtests.jl ./input_files/water_box.inp \
                  ./input_files/ieee_signaling.inp \
                  ./input_files/mixture.inp \
                  ./input_files/spherical.inp \
                  ./input_files/bilayer.inp \
                  ./input_files/solvprotein.inp \
                  ./input_files/water_box_pbc.inp \
                  ./input_files/water_box_pbc2.inp \
                  ./input_files/water_box_pbc_negative_coordinates.inp \
                  ./input_files/water_box_pbc_slab.inp \
                  ./input_files/bilayer_pbc.inp \
                  ./input_files/solvprotein_pbc.inp \
                  ./input_files/spherical_pbc.inp \
                  ./input_files/only_one_fixed.inp

# check if output files are properly generated in a failed run
./test_failed.sh ./input_files/water_box_failed.inp packmol.log "FORCED" 
./test_failed.sh ./input_files/protein_outside_pbc_error.inp packmol.log "outside"

# Test connectivity
./test_connectivity.sh 

