#ifndef __PARAMS_H__
#define __PARAMS_H__

#import <Foundation/Foundation.h>
#import "GSL.h"
#import "Dynamics.h"


// FILE NAMES
#define GRAPH_FILE @"solution.graph"
#define ERRORS_FILE @"solution.errors"


// Generative model types
#define PHERO 0
#define EDSF 1

// RNN types
#define MODEL_RNN 0
#define MODEL_DRNN 1


// FILE NAMES
#define SETTINGS_FNAME @"settings"
#define DATA_FNAME @"data"


// PROGRAM SETTINGS
#define LOG_PATH "log_path"
#define SEED "seed"
#define COMPRESS "compress"

#define GMODEL "gmodel"
#define RNN_TYPE "rnn_type"
#define DECOMPOSITION "decomposition"

#define EDSF_START_WITH "edsf_start_with"
#define EDSF_ALPHA "edsf_alpha"
#define EDSF_BETA "edsf_beta"
#define EDSF_GAMMA "edsf_gamma"
#define EDSF_DELTA_IN "edsf_delta_in"
#define EDSF_DELTA_OUT "edsf_delta_out"

#define ACO_ALPHA "aco_alpha"
#define ACO_BETA "aco_beta"
#define ACO_STEPS "aco_steps"
#define ACO_ANTS "aco_ants"
#define ACO_PHERO_VAL "aco_phero_val"
#define ACO_RHO "aco_rho"
#define ACO_LAMDA "aco_lamda"

#define PSO_STEPS "pso_steps"
#define PRINT_PSO "print_pso"



// parse settings from command line
int parse_settings(int argc, char **argv);

// save settings to log_path (saves the tasks (env) as well)
void save_settings();


// program settings
typedef struct {

    // GENERAL PARAMETERS
    NSString *dpath; // path to the data set
    NSString *log_path; // path to save logs
    unsigned long seed; // the seed of the RNG
    BOOL compress; // whether to compress log_path upon exit
    RNG *rng; // the random number generator

    // DATA
    Dynamics *tdata; // the training data
    Dynamics *vdata; // the validation data (could be nil) NOT WORKING AT THE MOMENT
    int nodes; // the number of nodes in the graph (automatically set)
    int tpoints; // the number of time points in the time series (automatically set)

    // TIMING
    NSDate *start; // starting point in time of the simulation
    unsigned long duration; // set at the end of the simulation

    // model parameters
    int gmodel; // which model to use for generating solutions
    int rnn_type; // RNN type to use
    Class rnn_class; // RNN class to use
    BOOL decomposition; // whether to activate problem decomposition

    // eDSF model parameters
    int edsf_start_with; // the initial number of nodes in the eDSF model
    double edsf_alpha;
    double edsf_beta;
    double edsf_gamma;
    double edsf_delta_in;
    double edsf_delta_out;

    // ACO parameters
    double aco_alpha; // exponent of the heuristic component
    double aco_beta; // exponent of the stigmergic component
    int aco_steps; // number of steps in ACO simulation
    int aco_ants; // number of ants
    double aco_phero_val; // initial value for the pheromome matrix
    double aco_rho; // pheromone evaporation rate
    double aco_lamda; // the lamda factor

    // PSO parameters
    int pso_steps; // the number of PSO steps
    BOOL print_pso; // whether to print output from PSO (every 100 steps)


} params_t;


// finally declare the global variable
extern params_t settings;

#endif

