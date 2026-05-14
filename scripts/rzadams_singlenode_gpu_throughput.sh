#!/bin/bash
# flux: -N 1
# flux: -g 4
# flux: -t 2h
# flux: -q pdev
# flux: --exclusive
# flux: --setattr=hugepages=512GB
# flux: --setattr=gpumode=CPX
# flux: --job-name=branson_1node_gpu_throughput
# flux: --output=branson_throughput.out
# flux: --error=branson_throughput.err

set -euo pipefail

echo "=== Allocation resources ==="
flux resource list
echo

echo "Starting Branson run on $(hostname)"
echo "Date: $(date)"

# Set environment variables
source /g/g14/jered/SID/David/branson/env.sh

# Update LD_LIBRARY_PATH to find locally built libs
export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:/g/g14/jered/SID/David/branson/install/lib:/g/g14/jered/SID/David/branson/install/lib64:

# remove all loaded modules before loaded required
module purge --force

# load all necessary modules to build dependencies
#module load PrgEnv-cray
#module load StdEnv 
module load PrgEnv-cray/${BRANSON_SETUP_CRAY_PRGENV_VERSION}
module load cce/${BRANSON_SETUP_CCE_VERSION}
module load rocm/${BRANSON_SETUP_ROCM_VERSION}
module load cray-mpich/${BRANSON_SETUP_CRAY_MPICH_VERSION}
#module load flux_wrappers/0.1

# show which modules we have loaded
module list

export RUN_NAME=branson-rzadams-throughput-05142026

function results() {
  echo "$1,$2,$(awk -F': ' '/Photons Per Second \(FOM\)/{print $2}' $3)" >> results.txt
}

function run() {
  export BRANSON_BIN=/g/g14/jered/SID/David/branson/install/bin/BRANSON
  export BRANSON_INPUT=/g/g14/jered/SID/David/branson/src/branson/inputs/3D_hohlraum_single_node.xml

  cd /p/lustre1/$USER

  mkdir -p $RUN_NAME
  cd $RUN_NAME

  cp $BRANSON_INPUT .

  echo "Ranks,Particles,FOM" >> results.txt

  for p in 100000 200000 300000 400000 500000 600000 700000 800000 900000 1000000 2000000 3000000 4000000 5000000 6600000 10000000 13300000 20000000 50000000 100000000 200000000 300000000 400000000 500000000 600000000 700000000 800000000 900000000; do 
    sed "s|<photons>.*</photons>|<photons>$p</photons>|" 3D_hohlraum_single_node.xml > 3D_hohlraum_single_node_${p}.xml; 
    flux run -N 1 -n 48 -g 0 --setopt=mpibind=verbose:1 --exclusive ${BRANSON_BIN} 3D_hohlraum_single_node_${p}.xml > ${p}.txt 2>&1;
    results 48 $p ${p}.txt
  done
}

run

