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

1. [GCC](http://gcc.gnu.org)

2. [GNUStep](http://www.gnustep.org/)

3. [GNU Scientific Library](http://www.gnu.org/software/gsl)


On Debian 7 (Wheezy), these requirements can be installed by running:

   `sudo apt-get install gnustep-core-devel libgsl0-dev`

Running `make` in the source directory produces an executable that is
located in `obj/netinf`


## USAGE

#### Network Inference

Use `netinf -h` for a list of options that can be specified in the
command line. In general, `netinf` takes a data file as input (check
the examples in directory `data/`) and outputs a set of file in a
directory specified using the `--log_path` switch. 

The output files include:

* `solution.graph` : contains the directed graph that was discovered
       by ACO, as a list of nodes, a `-` separator, and a list of
       directed edges

* `solution.errors` : contains the per-node RNN prediction errors

* `settings` : a dump of the program's settings

#### RNN Training and Prediction

The output files of the network inference algorithm do not include the
parameters of the trained RNN or the predicted dynamics given a
trained RNN. This can be achieved by running `netinf` on the same
`--log_path` and with the same data as in the network inference case
and switching the `--train` option on. For example:

    netinf --log_path PATH_TO_NETINF_RESULTS --train PATH_TO_NETINF_RESULTS/data

The training algorithm will read the solution graph from file
`solution.graph` in `PATH_TO_NETINF_RESULTS`, will train the
corresponding RNN and will output 2 files:

* `trained.rnn` : the parameter values of the trained RNN
* `trained.rnn.prediction` : the predicted dynamics


