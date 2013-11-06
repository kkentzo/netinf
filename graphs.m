#import "graphs.h"
#import "params.h"

#import "pso.h"

#import "RNN.h"
#import "Dynamics.h"
#import "common.h"




//=================================================================
//          GRAPH GENERATION FUNCTIONS
//=================================================================


// ====================================
// =========== EDSF MODEL =============
// ====================================

// returns an index from POOL array
int edsf_choose_node(GSLVector *pheros, GSLVector *degrees, double delta)
{
    int len = [pheros count];

    // calculate heuristic component
    GSLVector *probs = [GSLVector vectorWithSize:len];
    int i;
    double H, S;

    for (i=0; i<len; i++) {
	// calculate heuristic component
	if (degrees)
	    H = pow(delta + [degrees valueAtIndex:i], 
		    settings.aco_alpha);
	else
	    H = delta;

	// calculate stigmergic component
	S = pow([pheros valueAtIndex:i], settings.aco_beta);

	// update value of probs
	[probs setValue:H * S
		atIndex:i];

    }
    
    // normalize probs
    [probs divideByValue:[probs sum]];
    // run roulette and return node object
    return gsl_roulette(probs, settings.rng);
    
}



GSLVector *edsf_get_degrees(NSArray *pool, Digraph *graph, BOOL indeg) {

    int i, deg, len = [pool count];
    GSLVector *vec = [GSLVector vectorWithSize:len];
    for (i=0; i<len; i++) {
	if (indeg)
	    deg = [graph inDegreeOfNode:[NSNumber numberWithInt:i]];
	else
	    deg = [graph outDegreeOfNode:[NSNumber numberWithInt:i]];

	[vec setValue:deg
	      atIndex:i];
    }

    return vec;
}


Digraph *edsf_model(GSLMatrix *phero) {

    int i;
    int ireg, itrg; // pool indices
    NSNumber * reg, *trg; // storage of nodes

    // form pool of unconnected nodes
    NSMutableArray *pool_nc = [[NSMutableArray alloc] 
				  initWithCapacity:settings.nodes];
    // populate pool (all nodes are initially unconnected)
    for (i=0; i<settings.nodes; i++)
	[pool_nc addObject:[NSNumber numberWithInt:i]];
    
    // form pool of connected nodes (initially empty)
    NSMutableArray *pool_c = [[NSMutableArray alloc] 
				  initWithCapacity:settings.nodes];

    // initialize graph
    Digraph *graph = [Digraph digraphWithNodes:settings.nodes];

    // add a few initial edges to the graph
    for (i=0; i<settings.edsf_start_with; i++) {
	// choose a new reg node
	ireg = edsf_choose_node([[phero sumAcrossColumns] take:pool_nc],
				nil,
				1);
	reg = [pool_nc objectAtIndex:ireg];
	[pool_c addObject:[pool_nc popAtIndex:ireg]];

	// choose a new target node
	itrg = edsf_choose_node([[phero sumAcrossRows] take:pool_nc],
				nil,
				1);
	trg = [pool_nc objectAtIndex:itrg];
	[pool_c addObject:[pool_nc popAtIndex:itrg]];

	// add edge to the graph under construction
	[graph addEdgeFrom:reg
			To:trg];
    }

    // setup vector of rule probabilities
    GSLVector *rules = [[GSLVector alloc] initWithSize:3];
    [rules setValue:settings.edsf_alpha
	    atIndex:0];
    [rules setValue:settings.edsf_beta
	    atIndex:1];
    [rules setValue:settings.edsf_gamma
	    atIndex:2];

    int rule;

    // as long as there exist unconnected nodes
    while ([pool_nc count]) {

	// pick a rule to apply
	rule = gsl_roulette(rules, settings.rng);

	if (rule == 0) {
	    // choose a new reg acc to phero values of outgoing edges
	    ireg = edsf_choose_node([[phero sumAcrossColumns] take:pool_nc],
				    nil,
				    1);
	    reg = [pool_nc objectAtIndex:ireg];
	    // choose an existing trg acc to in-degrees and incoming phero
	    itrg = edsf_choose_node([[phero sumAcrossRows] take:pool_c],
				    edsf_get_degrees(pool_c, graph, YES),
				    settings.edsf_delta_in);
	    trg = [pool_c objectAtIndex:itrg];

	    // remove new reg from pool_nc and add it to pool_c
	    [pool_c addObject:[pool_nc popAtIndex:ireg]];

	} else if (rule == 1) {

	    // choose existing reg acc to out-degress and outgoing phero
	    ireg = edsf_choose_node([[phero sumAcrossColumns] take:pool_c],
				    edsf_get_degrees(pool_c, graph, NO),
				    settings.edsf_delta_out);
	    reg = [pool_c objectAtIndex:ireg];
	    // choose an existing trg acc to in-degrees and incoming phero
	    itrg = edsf_choose_node([[phero sumAcrossRows] take:pool_c],
				    edsf_get_degrees(pool_c, graph, YES),
				    settings.edsf_delta_in);
	    trg = [pool_c objectAtIndex:itrg];

	} else {

	    // choose existing reg acc to out-degress and outgoing phero
	    ireg = edsf_choose_node([[phero sumAcrossColumns] take:pool_c],
				    edsf_get_degrees(pool_c, graph, NO),
				    settings.edsf_delta_out);
	    reg = [pool_c objectAtIndex:ireg];

	    // choose new trg acc to incoming phero
	    itrg = edsf_choose_node([[phero sumAcrossRows] take:pool_nc],
				    nil,
				    1);
	    trg = [pool_nc objectAtIndex:itrg];

	    // remove new trg from pool_nc and add it to pool_c
	    [pool_c addObject:[pool_nc popAtIndex:itrg]];

	}

	// add the new edge to the graph
	[graph addEdgeFrom:reg
			To:trg];
    }

    // release arrays
    [pool_nc release];
    [pool_c release];
    [rules release];

    return graph;
}

// =====================================
// =========== PHERO MODEL =============
// =====================================
Digraph *phero_model(GSLMatrix *phero) {

    // calculate phero.sum(axis=0)
    GSLVector *sumrows = [phero sumAcrossRows];
    // create graph
    Digraph *graph = [Digraph digraphWithNodes:settings.nodes];
    int reg, trg;
    double prob;
    // calculate probabilities for each 
    // pheromone matrix entry
    // and decide whether to add the edge to the graph
    for (trg=0; trg<[phero columns]; trg++)
	for (reg=0; reg<[phero rows]; reg++) {
	    prob = [phero valueAtRow:reg andColumn:trg] / [sumrows valueAtIndex:trg];
	    if ([settings.rng getUniform] < prob)
		[graph addEdgeFrom:[NSNumber numberWithInt:reg]
				To:[NSNumber numberWithInt:trg]];
	}

    return graph;
}





//=================================================================
// graph generation function 

Digraph *generate_graph(GSLMatrix *phero) {

    Digraph *g = NULL;

    switch (settings.gmodel) {
    
       case PHERO:
	   g = phero_model(phero);
	   break;
       case EDSF:
	   g = edsf_model(phero);
	   break;
    }

    return g;
}

//=================================================================
// graph evaluation function (using PSO)

GSLVector *evaluate_graph(Digraph *g) {

    // set up PSO parameters
    pso_settings_t pso_settings;

    pso_set_default_settings(&pso_settings);
    pso_settings.steps = settings.pso_steps;
    if (settings.print_pso)
	pso_settings.print_every = 100;
    else
	pso_settings.print_every = 0;
    pso_settings.rng = [settings.rng rng];
    // set obj_fun settings
    pso_settings.x_lo = -20;
    pso_settings.x_hi = 20;
    pso_settings.goal = 1e-10;


    // create RNN
    RNN *rnn = [settings.rnn_class rnnWithNodes:settings.nodes];
    double err;
    // train it
    if (settings.decomposition)
	err = [rnn dtrainUsingDynamics:settings.tdata
			     withGraph:g
		       withPSOSettings:&pso_settings];
    else
	err = [rnn trainUsingDynamics:settings.tdata
			    withGraph:g
		      withPSOSettings:&pso_settings];

    // predict data and get errors
    // Dynamics *pdata;
    // GSLVector *errors;
    // if (settings.vdata) {
    // 	// use validation data
    // 	pdata = [rnn predict:settings.vdata];
    // 	// calc MSEs per target gene
    // 	errors = [settings.vdata calcMSEVector:pdata];
    // } else {
    // 	// use training data
    // 	pdata = [rnn predict:settings.tdata];
    // 	// calc MSEs per target gene
    // 	errors = [settings.tdata calcMSEVector:pdata];
    // }

    // global error (err) is ignored; 
    // instead, return a vector of errors
    return [settings.tdata calcMSEVector:[rnn predict:settings.tdata]];
}
