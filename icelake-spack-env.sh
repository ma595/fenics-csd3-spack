#! /bin/bash
# ssh to icelake
ssh ma595@login-q-2.hpc.cam.ac.uk

# start from fresh shell. Do not purge environment. Here we allocate compute node:
# sintr -p icelake -N 1 --exclusive -t 1:00:0 --pty bash
srun  -p icelake -N 1 --exclusive -t 1:00:0  --pty bash

# set up environment
git clone -c feature.manyFiles=true https://github.com/spack/spack.git spack
cd spack/
source share/spack/setup-env.sh
spack env create icl-test

# Create the spack.yaml file
cat << 'EOF' > ./var/spack/environments/icl-test/spack.yaml
spack:
  modules:
    icelake-fenics-ci:
      use_view: icelake
      enable:
      - tcl
      roots:
        tcl: /rds/project/rds-5mCMIDBOkPU/ma595/fenics/spack
  specs:
  - re2c
  - py-fenics-dolfinx@main%gcc@11.3.0 ^intel-oneapi-mpi@2021.6.0%gcc@11.3.0 ^petsc@main
    +mumps
  # - fenics-performance-test@main
  view:
    icelake:
      root: /rds/project/rds-5mCMIDBOkPU/ma595/fenics/spack
      link_type: symlink
  packages:
    all:
      providers:
        mpi: [intel-oneapi-mpi]
    intel-oneapi-mpi:
      externals:
      - spec: intel-oneapi-mpi@2021.6.0%gcc
        prefix: /usr/local/software/spack/spack-rhel8-20210927/opt/spack/linux-rocky8-icelake/intel-2021.6.0/intel-oneapi-mpi-2021.6.0-guxuvcpmykplbrr2e3af2yd7njqhau5e/
      buildable: false
EOF

# activate and concretize
spack env activate icl-test
spack concretize -f
# change intel-oneapi-mpi underlying compiler to gcc (fails on mumps with intel compiler - cannot import metis.h?).
# switch to gcc as we use gcc everywhere now.
# TODO: consider adding to spack.yaml
export I_MPI_CC=gcc
export I_MPI_CXX=g++
export I_MPI_F77=gfortran
export I_MPI_F90=gfortran
export I_MPI_FC=gfortran
# this will now fail on ninja - but let it install everything
spack install
# now load re2c
spack load re2c
spack install
