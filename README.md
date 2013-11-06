netinf : Gene Network Inference
====================================

This is an Objective-C re-implementation of the gene network inference
framework based on PSO (Particle Swarm Optimization) and ACO (Ant
Colony Optimization) described in the following paper:

Kentzoglanakis K. and Poole M. (2012) [A swarm intelligence framework
for reconstructing gene networks: searching for biologically plausible
architectures.](http://eprints.port.ac.uk/4889/) IEEE/ACM Transactions
on Computational Biology and Bioinformatics 9(2): 358–371.


## REQUIREMENTS

A GNUmakefile is included for compiling the code in Linux (and,
hopefully, Mac). `netinf` depends upon a few external libraries which
should be present in your system along with their respective header
(development) files. The prerequisites for compiling `netinf` are as
follows:

1. [GNUStep](http://www.gnustep.org/)

2. [GNU Scientific Library](http://www.gnu.org/software/gsl) >= 1.15


On Debian 7 (Wheezy), these requirements can be installed by running:

   `sudo apt-get install gnustep-core-devel libgsl0-dev`

Running `make` in the source directory produces an executable that is
located in `obj/netinf`


## USAGE

Use `netinf -h` for a list of options that can be specified in the
command line. In general, `netinf` takes a data file as input (check
the examples in directory `data/`) and outputs a set of file in a
directory specified using the `--log_path` switch. 

The output files include:

    * `solution.graph` : contains the directed graph that was
      discovered by ACO, as a list of nodes, a `-` separator, and a
      list of directed edges

    * `solution.errors` : contains the per-node RNN prediction errors

    * `settings` : a dump of the program's settings

