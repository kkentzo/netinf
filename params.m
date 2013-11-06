#import "params.h"
#import <getopt.h>
#import <stdio.h>
#import <sys/stat.h>

#import "Graph.h"

#import "pso.h"

#import "RNN.h"


// default settings (global variable)
params_t settings = {

    nil, // dpath
    nil, // log_path
    0, // seed
    NO, // compress
    nil, // the RNG

    nil, // tdata
    nil, // vdata
    0, // nodes
    0, // tpoints

    nil, // start
    0, // duration
    
    PHERO, // gmodel
    MODEL_DRNN, // rnn_type
    nil, // rnn_class
    NO, // decomposition

    1, // start_with
    0.1, // edsf_alpha
    0.6, // edsf_beta
    0.3, // edsf_gamma
    0.01, // edsf_delta_in
    0.05, // edsf_delta_out
    
    1, // aco_alpha
    1, // aco_beta
    50, // aco_steps
    5, // aco_ants
    10., // aco_phero_val
    0.1, // aco_rho
    0.1, // aco_lamda

    1000, // pso_steps
    NO // print_pso

};




void print_help() {

    printf("Usage: netinf [options] PATH_TO_DATASET\n");
    printf("Output : the solution graph (if log_path is not defined)\n");
    printf("Options :\n");
    printf("GENERAL PARAMETERS\n");
    printf("  --log_path DIRECTORY : where to save logs\n");
    printf("  --seed LONG : set the seed of the random number generator\n");
    printf("  -z or --compress : whether to compress the log_path directory\n");

    printf("MODEL PARAMETERS\n");
    printf("  --gmodel INT : set generative model to use in ACO (0:phero, 1:edsf)\n");
    printf("  --rnn_type INT : which type of RNN to use (0:RNN, 1:DRNN)\n");
    printf("  -d or --decompose : activate problem decomposition\n");

    printf("eDSF MODEL PARAMETERS\n");
    printf("  --edsf_start_with INT : the initial number of nodes in the DSF graph\n");
    printf("  --edsf_alpha, --edsf_beta, --edsf_gamma : the probabilities of eDSF rules\n");
    printf("  --edsf_delta_in, --edsf_delta_out : the delta parameters\n");

    printf("ACO PARAMETERS\n");
    printf("  --aco_alpha FLOAT : set the exponent of the heuristic component\n");
    printf("  --aco_beta FLOAT : set the exponent of the stigmergic component\n");
    printf("  --aco_steps INT : set the number of ACO steps\n");
    printf("  --aco_ants INT : set the number of ants in ACO\n");
    printf("  --aco_phero_val FLOAT : set the initial pheromone matrix value\n");
    printf("  --aco_rho FLOAT : set the pheromone evaporation rate\n");
    printf("  --aco_lamda FLOAT : set the lamda factor \n");

    printf("PSO PARAMETERS\n");
    printf("  --pso_steps INT : set the number of steps for PSO\n");
    printf("  -p or --print_pso : print PSO output\n");

}




void save_settings() {

    NSString *fname = [settings.log_path 
			 stringByAppendingPathComponent:SETTINGS_FNAME];
    // open file
    FILE *f = fopen([fname UTF8String], "w");
    if (!f) {
	// create log_path directory
	mkdir([settings.log_path UTF8String], 0755);
	f = fopen([fname UTF8String], "w");
    }
    // write settings
    fprintf(f, "--%s %s ", LOG_PATH, [settings.log_path UTF8String]);
    fprintf(f, "--%s %lu ", SEED, settings.seed);
    if (settings.compress)
	fprintf(f, "--%s ", COMPRESS);

    fprintf(f, "--%s %d ", GMODEL, settings.gmodel);
    fprintf(f, "--%s %d ", RNN_TYPE, settings.rnn_type);
    if (settings.decomposition)
	fprintf(f, "--%s ", DECOMPOSITION);

    fprintf(f, "--%s %d ", EDSF_START_WITH, settings.edsf_start_with);
    fprintf(f, "--%s %f ", EDSF_ALPHA, settings.edsf_alpha);
    fprintf(f, "--%s %f ", EDSF_BETA, settings.edsf_beta);
    fprintf(f, "--%s %f ", EDSF_GAMMA, settings.edsf_gamma);
    fprintf(f, "--%s %f ", EDSF_DELTA_IN, settings.edsf_delta_in);
    fprintf(f, "--%s %f ", EDSF_DELTA_OUT, settings.edsf_delta_out);

    fprintf(f, "--%s %.1f ", ACO_ALPHA, settings.aco_alpha);
    fprintf(f, "--%s %.1f ", ACO_BETA, settings.aco_beta);
    fprintf(f, "--%s %d ", ACO_STEPS, settings.aco_steps);
    fprintf(f, "--%s %d ", ACO_ANTS, settings.aco_ants);
    fprintf(f, "--%s %.1f ", ACO_PHERO_VAL, settings.aco_phero_val);
    fprintf(f, "--%s %.1f ", ACO_RHO, settings.aco_rho);
    fprintf(f, "--%s %.1f ", ACO_LAMDA, settings.aco_lamda);

    fprintf(f, "--%s %d ", PSO_STEPS, settings.pso_steps);

    fclose(f);

}
    
	



int parse_settings(int argc, char **argv) {
    
    int c;
    const char *optname;

    if (argc == 1) {
	printf("netinf : no data file specified\nRun netinf -h for usage options\n");
	return -1;
    }

    while (1) {

	int option_index = 0;
	static struct option long_options[] = {
	    {LOG_PATH, required_argument, 0, 0},
	    {SEED, required_argument, 0, 0},
	    {COMPRESS, no_argument, 0, 'z'},

	    {GMODEL, required_argument, 0, 0},
	    {RNN_TYPE, required_argument, 0, 0},
	    {DECOMPOSITION, no_argument, 0, 'd'},

	    {EDSF_START_WITH, required_argument, 0, 0},
	    {EDSF_ALPHA, required_argument, 0, 0},
	    {EDSF_BETA, required_argument, 0, 0},
	    {EDSF_GAMMA, required_argument, 0, 0},
	    {EDSF_DELTA_IN, required_argument, 0, 0},
	    {EDSF_DELTA_OUT, required_argument, 0, 0},

	    {ACO_ALPHA, required_argument, 0, 0},
	    {ACO_BETA, required_argument, 0, 0},
	    {ACO_STEPS, required_argument, 0, 0},
	    {ACO_ANTS, required_argument, 0, 0},
	    {ACO_PHERO_VAL, required_argument, 0, 0},
	    {ACO_RHO, required_argument, 0, 0},
	    {ACO_LAMDA, required_argument, 0, 0},

	    {PSO_STEPS, required_argument, 0, 0},
	    {PRINT_PSO, no_argument, 0, 'p'},

	    {"help", no_argument, 0, 'h'},
	    // {"file", 1, 0, 0},
	    {0, 0, 0, 0}
	};

	c = getopt_long(argc, argv, "zvpdh",
			long_options, &option_index);
	if (c == -1)
	    break;

	switch (c) {
	case 0:
	    if (optarg) {
		optname = long_options[option_index].name;
		if (strcmp(optname, LOG_PATH) == 0)
		    settings.log_path = [[NSString alloc] initWithCString:optarg
								 encoding:NSUTF8StringEncoding];
		else if (strcmp(optname, SEED) == 0) 
		    settings.seed = strtoul(optarg, NULL, 0);
	        else if (strcmp(optname, GMODEL) == 0)
		    settings.gmodel = atoi(optarg);
		else if (strcmp(optname, RNN_TYPE) == 0) 
		    settings.rnn_type = atoi(optarg);

		else if (strcmp(optname, EDSF_START_WITH) == 0) 
		    settings.edsf_start_with = atoi(optarg);
		else if (strcmp(optname, EDSF_ALPHA) == 0) 
		    settings.edsf_alpha = atof(optarg);
		else if (strcmp(optname, EDSF_BETA) == 0) 
		    settings.edsf_beta = atof(optarg);
		else if (strcmp(optname, EDSF_GAMMA) == 0) 
		    settings.edsf_gamma = atof(optarg);
		else if (strcmp(optname, EDSF_DELTA_IN) == 0) 
		    settings.edsf_delta_in = atof(optarg);
		else if (strcmp(optname, EDSF_DELTA_OUT) == 0) 
		    settings.edsf_delta_out = atof(optarg);

		else if (strcmp(optname, ACO_ALPHA) == 0) 
		    settings.aco_beta = atof(optarg);
		else if (strcmp(optname, ACO_BETA) == 0)
		    settings.aco_beta = atof(optarg);
		else if (strcmp(optname, ACO_STEPS) == 0)
		    settings.aco_steps = atoi(optarg);
		else if (strcmp(optname, ACO_ANTS) == 0)
		    settings.aco_ants = atoi(optarg);
		else if (strcmp(optname, ACO_PHERO_VAL) == 0)
		    settings.aco_phero_val = atof(optarg);
		else if (strcmp(optname, ACO_RHO) == 0)
		    settings.aco_rho = atof(optarg);
		else if (strcmp(optname, ACO_LAMDA) == 0)
		    settings.aco_lamda = atof(optarg);

		else if (strcmp(optname, PSO_STEPS) == 0)
		    settings.pso_steps = atoi(optarg);

		printf("Setting %s=%s\n", optname, optarg);
	    }
	    break;

	case 'h':
	    print_help();
	    return 1;

	case 'z':
	    printf("Compress the log directory\n");
	    settings.compress = YES;
	    break;

	case 'p':
	    printf("Printing PSO output\n");
	    settings.print_pso = YES;
	    break;

	case 'd':
	    printf("Activating problem decomposition\n");
	    settings.decomposition = YES;
	    break;

	case '?':
	    return -1;

	default:
	    printf("?? getopt returned character code 0%o ??\n", c);
	}
    }

    // is a log_path defined??

    // do we have 1 argument remaining??
    if (argc - optind != 1) {
	printf("netinf: please specify a data file (see netinf -h for details)\n");
	return -1;
    }

    // yes we do!
    settings.dpath = [[NSString alloc] initWithCString:argv[optind]
					      encoding:NSUTF8StringEncoding];
    printf("Using data file %s\n", [settings.dpath UTF8String]);
    // try to load training data
    settings.tdata = [[Dynamics alloc] initFromFile:settings.dpath];
    if (! settings.tdata) {
	printf("Error loading data file %s\nAborting.\n", [settings.dpath UTF8String]);
	return -1; // EXIT
    }

    // OK, set the nodes and tpoints members
    settings.nodes = [settings.tdata vars];
    settings.tpoints = [settings.tdata tpoints];

    // aaand set the RNN class to be used
    switch (settings.rnn_type) {
       case MODEL_RNN:
	   settings.rnn_class = [RNN class];
	   break;
       case MODEL_DRNN:
	   settings.rnn_class = [DRNN class];
	   break;
    }

    return 0;

}
