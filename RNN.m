#import <Foundation/Foundation.h>
#import <math.h> // for pow(), sqrt()

#import "GSL.h"
#import "Dynamics.h"
#import "Graph.h"
#import "pso.h"
#import "RNN.h"


#import "common.h"

#define RNN_DELTA_T 1


//***************************************************************
// static struct variable : details of rnn under training
//***************************************************************
static struct {

    id rnn; // the RNN under training
    GSLVector *vec; // vector of parameter values
    Dynamics *tdata; // the training data
    Digraph *graph; // the corresponding graph
    int target; // the current target node (for per-node training)

} t_rnn;



//***************************************************************
//          OBJECTIVE FUNCTIONS FOR PSO
//***************************************************************


// PSO objective function (for training)
// training the full weight matrix 
double global_pso_obj_fun(double *vec, size_t dim, void *params) {

    // set RNN param values from vector
    [t_rnn.rnn setFromVector:[t_rnn.vec fillFromCArray:vec
					      withSize:dim]];
    // predict training data (stored in static global variable)
    // using static global rnn
    Dynamics *pdata = [t_rnn.rnn predict:t_rnn.tdata];
    // return prediction MSE
    return [t_rnn.tdata calcMSEwith:pdata];

}


// PSO objective function (for training)
// training the weight matrix corresponding to t_rnn.graph
double global_pso_obj_fun_with_graph(double *vec, size_t dim, void *params) {

    // set RNN param values from vector
    [t_rnn.rnn setFromVector:[t_rnn.vec fillFromCArray:vec
					      withSize:dim]
		   withGraph:t_rnn.graph];
    // predict training data (stored in static global variable)
    // using static global rnn
    Dynamics *pdata = [t_rnn.rnn predict:t_rnn.tdata];
    // return prediction MSE
    return [t_rnn.tdata calcMSEwith:pdata];

}


// PSO objective function (for training)
// per-node training of RNN 
double local_pso_obj_fun(double *vec, size_t dim, void *params) {

    // set RNN param values from vector
    [t_rnn.rnn setFromVector:[GSLVector vectorFromCArray:vec
						withSize:dim]
		     forNode:t_rnn.target];
    // predict training data (stored in static global variable)
    // for current node
    // using static global rnn
    Dynamics *pdata = [t_rnn.rnn predict:t_rnn.tdata
			       forTarget:t_rnn.target];
    // return prediction MSE
    return [t_rnn.tdata calcMSEwith:pdata
			      ofVar:t_rnn.target];

}


double local_pso_obj_fun_with_graph(double *vec, size_t dim, void *params) {

    // set RNN param values from vector
    [t_rnn.rnn setFromVector:[GSLVector vectorFromCArray:vec
						withSize:dim]
		   withGraph:t_rnn.graph
		     forNode:t_rnn.target];
    // predict training data (stored in static global variable)
    // for current node
    // using static global rnn
    Dynamics *pdata = [t_rnn.rnn predict:t_rnn.tdata
			       forTarget:t_rnn.target];
    // return prediction MSE
    return [t_rnn.tdata calcMSEwith:pdata
			    ofVar:t_rnn.target];

}



//***************************************************************
//               Normal RNN (just W, B)
//***************************************************************


@implementation RNN

// create an RNN

+ (id) rnnWithNodes:(int)nodes {

    return [[[RNN alloc] initWithNodes:nodes] autorelease];

}




+ (id) rnnFromVector:(GSLVector *)vec {

    // figure out number of nodes
    int n = [RNN calcNodesForDim:[vec count]];
    // initialize RNN
    RNN *rnn = [[RNN alloc] initWithNodes:n];
    // use vec to set RNN parameter values
    [rnn setFromVector:vec];
    
    return [rnn autorelease];

}




+ (id) rnnFromVector:(GSLVector *)vec
	   withGraph:(Digraph *)graph 
{
    // figure out number of nodes
    int n = [graph countNodes];

    // initialize RNN (all w, b, t are zero)
    RNN *rnn = [[RNN alloc] initWithNodes:n];
    // use vec and graph to set RNN parameter values
    [rnn setFromVector:vec
	     withGraph:graph];

    return [rnn autorelease];

}





// get the dimensionality of the problem
+ (int) calcDimForNodes:(int)nodes {

    return nodes * (nodes + 1);

}



+ (int) calcDimOfSingleNodeForNodes:(int)nodes {

    return nodes + 1;

}


+ (int) calcNodesForDim:(int)dim {

    return (int) ( (sqrt(1 + 4*dim) - 1) / 2 );

}
    


+ (int) calcDimForGraph:(Digraph *) graph {

    return [graph countEdges] + [graph countNodes];

}


+ (int) calcDimForNode:(int)node
	     withGraph:(Digraph *) graph
{

    return [graph inDegreeOfNode:[NSNumber numberWithInt:node]] + 1;

}




// initializers
- (id) init {

    [self dealloc];
    @throw [NSException exceptionWithName:@"BadInitCall"
				   reason:@"Use initWith...: initializers"
				 userInfo:nil];
}



- (id) initWithNodes:(int)n {

    GSLMatrix *w = [GSLMatrix matrixWithRows:n
				  andColumns:n];
    GSLVector *b = [GSLVector vectorWithSize:n];

    self = [self initWithW:w
		      andB:b];

    if (!self) {
	[w release];
	[b release];
	return nil;
    }

    return self;
	

}


- (id) initWithW:(GSLMatrix *)w
	    andB:(GSLVector *)b
{
    self = [super init];
    if (!self)
	return nil;

    nodes = [w rows];
    W = [w retain];
    B = [b retain];

    return self;

}


- (void) reset {

    [W fillWithValue:0];
    [B fillWithValue:0];

}


- (void) resetNode:(int)n {

    [W fillRow:n 
       withValue:0];
    [B setValue:0 
	atIndex:n];

}



- (void) dealloc {

    [W release];
    [B release];
    [super dealloc];

}


- (GSLMatrix *) W {

    return W;

}


- (GSLVector *) B {

    return B;

}




- (int) nodes {
    
    return nodes;

}





// setters
- (void) setFromVector:(GSLVector *)vec {

    int i, j, vec_idx;
    // figure out number of nodes
    //int n = [RNN calcNodesForDim:[vec count]];
    // make sure this is correct
    //NSAssert(n == nodes, @"Dimensionality mismatch!!");

    // reset RNN values
    //[self reset]; --> NOT NEEDED HERE

    // initialize vec's index
    vec_idx = 0;

    // read in weight matrix
    for (i=0; i<nodes; i++)
	for (j=0; j<nodes; j++) 
	    // extract weight value and increment vec_idx
	    [W setValue:[vec valueAtIndex:vec_idx++]
		  atRow:i
	      andColumn:j];

    // read in bias vector
    for (i=0; i<nodes; i++)
	// extract bias term value and increment vec_idx
	[B setValue:[vec valueAtIndex:vec_idx++]
	    atIndex:i];

}




- (void) setFromVector:(GSLVector *)vec
	     withGraph:(Digraph *)graph
{

    int i, vec_idx;
    // figure out number of nodes
    //int n = [graph countNodes];
    // make sure this is correct
    //NSAssert(n == nodes, @"Dimensionality mismatch!!");

    // reset all parameter values
    [self reset];

    // initialize index to vec
    vec_idx = 0;

    // get graph edges
    NSArray *edges = [graph edges];
    int n_e = [edges count];
    Edge *e;

    // read in weight values (corresponding to graph edges)
    for (i=0; i<n_e; i++) {
	// get the edge
	e = [edges objectAtIndex:i];
	[W setValue:[vec valueAtIndex:vec_idx++]
	      atRow:[[e to] intValue] // rows are targets
	  andColumn:[[e from] intValue]]; // cols are regulators
    }

    // read in bias vector
    for (i=0; i<nodes; i++)
	// extract bias term value and increment vec_idx
	[B setValue:[vec valueAtIndex:vec_idx++]
	    atIndex:i];

}




- (void) setFromVector:(GSLVector *)vec
	       forNode:(int)row
{

    int i, vec_idx;

    // reset RNN values
    //[self reset]; --> NOT NEEDED HERE

    // initialize vec's index
    vec_idx = 0;

    // read in weight matrix
    for (i=0; i<nodes; i++) 
	// extract weight value and increment vec_idx
	[W setValue:[vec valueAtIndex:vec_idx++]
	      atRow:row
	  andColumn:i];

    // read in bias term value
    [B setValue:[vec valueAtIndex:vec_idx]
	atIndex:row];

}



- (void) setFromVector:(GSLVector *)vec
	     withGraph:(Digraph *)graph
	       forNode:(int)row
{

    int vec_idx;

    // reset the node's parameter values 
    [self resetNode:row];

    // initialize index to vec
    vec_idx = 0;

    // get graph edges (array of NSNumbers)
    NSEnumerator *regs = [[graph predecessorsOfNode:[NSNumber numberWithInt:row]]
			     objectEnumerator];
    NSNumber *reg;
    while ((reg = [regs nextObject]))
	[W setValue:[vec valueAtIndex:vec_idx++]
	      atRow:row
	  andColumn:[reg intValue]];
    

    // read in bias term value
    [B setValue:[vec valueAtIndex:vec_idx]
	atIndex:row];

}





// train the RNN against TDYN (training data)
// returns the minimum achieved optimization error
- (double) trainUsingDynamics:(Dynamics *)tdyn
	      withPSOSettings:(pso_settings_t *)pso_settings
{


    // calculate dimensionality
    pso_settings->dim = [[self class] calcDimForNodes:nodes];
    // set objective function
    //pso_settings->fun = &global_pso_obj_fun;

    // set values of static t_rnn object
    t_rnn.rnn = self;
    t_rnn.vec = [[GSLVector alloc] initWithSize:pso_settings->dim];
    t_rnn.tdata = tdyn;


    // create solution
    pso_result_t solution;
    double gbest[pso_settings->dim];
    solution.gbest = gbest;

    // run PSO
    pso_solve(global_pso_obj_fun, NULL, &solution, pso_settings);

    // replace current RNN values with trained values
    [self setFromVector:[GSLVector vectorFromCArray:gbest
					   withSize:pso_settings->dim]];

    // release temporary vector
    [t_rnn.vec release];

    return solution.error;

}



// train the RNN against TDYN (training data)
//  **** problem decomposition strategy ****
// returns the minimum achieved optimization error
- (double) dtrainUsingDynamics:(Dynamics *)tdyn
	       withPSOSettings:(pso_settings_t *)pso_settings
{

    int i;
    GSLVector *errors = [GSLVector vectorWithSize:nodes];

    for (i=0; i<nodes; i++) {

	// calculate dimensionality of i^th sub-problem
	pso_settings->dim = [[self class] calcDimOfSingleNodeForNodes:nodes];
	// set objective function
	//pso_settings->fun = &local_pso_obj_fun;

	// set values of static t_rnn object
	t_rnn.rnn = self;
	t_rnn.vec = [[GSLVector alloc] initWithSize:pso_settings->dim];
	t_rnn.tdata = tdyn;
	t_rnn.target = i;

	// create solution
	pso_result_t solution;
	double gbest[pso_settings->dim];
	solution.gbest = gbest;

	// run PSO
	pso_solve(local_pso_obj_fun, NULL, &solution, pso_settings);

	// replace current RNN values with trained values
	[self setFromVector:[GSLVector vectorFromCArray:gbest
					       withSize:pso_settings->dim]
		    forNode:i];

	// release temporary vector
	[t_rnn.vec release];

	// store optimization error
	[errors setValue:solution.error 
		 atIndex:i];

    }

    // return the mean across the per-target optimization errors
    return [errors mean];

}




// train the RNN that corresponds to graph
// using TDYN (training data)
// returns the minimum achieved optimization error
- (double) trainUsingDynamics:(Dynamics *)tdyn
		    withGraph:(Digraph *)graph
	      withPSOSettings:(pso_settings_t *)pso_settings 
{

    // calculate dimensionality (from graph)
    pso_settings->dim = [[self class] calcDimForGraph:graph];
    // set objective function
    //pso_settings->fun = &global_pso_obj_fun_with_graph;

    // set values of static t_rnn object
    t_rnn.rnn = self;
    t_rnn.vec = [[GSLVector alloc] initWithSize:pso_settings->dim];
    t_rnn.tdata = tdyn;
    t_rnn.graph = graph;


    // create solution
    pso_result_t solution;
    double gbest[pso_settings->dim];
    solution.gbest = gbest;

    // run PSO
    pso_solve(global_pso_obj_fun_with_graph, NULL, &solution, pso_settings);

    // replace current RNN values with trained values
    [self setFromVector:[GSLVector vectorFromCArray:gbest
					   withSize:pso_settings->dim]
	      withGraph:graph];

    // release temporary vector
    [t_rnn.vec release];

    return solution.error;
    
}



// train the RNN that corresponds to graph
// using TDYN (training data)
//  **** problem decomposition strategy ****
// returns the minimum achieved optimization error
- (double) dtrainUsingDynamics:(Dynamics *)tdyn
		     withGraph:(Digraph *)graph
	       withPSOSettings:(pso_settings_t *)pso_settings
{

    int i;
    GSLVector *errors = [GSLVector vectorWithSize:nodes];

    for (i=0; i<nodes; i++) {

	// calculate dimensionality of i^th sub-problem
	pso_settings->dim = [[self class] calcDimForNode:i
					       withGraph:graph];

	// set objective function
	//pso_settings->fun = &local_pso_obj_fun_with_graph;

	// set values of static t_rnn object
	t_rnn.rnn = self;
	t_rnn.vec = [[GSLVector alloc] initWithSize:pso_settings->dim];
	t_rnn.tdata = tdyn;
	t_rnn.graph = graph;
	t_rnn.target = i;

	// create solution
	pso_result_t solution;
	double gbest[pso_settings->dim];
	solution.gbest = gbest;

	// run PSO
	pso_solve(local_pso_obj_fun_with_graph, NULL, &solution, pso_settings);

	// replace current RNN values with trained values
	[self setFromVector:[GSLVector vectorFromCArray:gbest
					       withSize:pso_settings->dim]
		  withGraph:graph
		    forNode:i];

	// release temporary vector
	[t_rnn.vec release];

	// store optimization error
	[errors setValue:solution.error 
		 atIndex:i];

    }

    // return the mean across the per-target optimization errors
    return [errors mean];

}






- (Dynamics *)simulateFromState:(GSLVector *)x0
		       forSteps:(int)tpoints
{

    // initialize the predicted dynamics
    Dynamics *pdyn = [Dynamics dynamicsWithVars:nodes
				     andTPoints:tpoints];

    int reg, trg, t;
    double wsum, x;

    // copy first time point from x0
    [pdyn replaceRow:0 fromVector:x0];

    // === simulate network ===
    // for all time points
    for (t=1; t<tpoints; t++)
	// for each target
	for (trg=0; trg<nodes; trg++) {
	    // calculate the cumulative weighted effect 
	    // of all regulators
	    wsum = 0;
	    for (reg=0; reg<nodes; reg++) 
		// update weighted sum
		wsum += [W valueAtRow:trg andColumn:reg] * 
		    [pdyn valueOfVar:reg atTPoint:t-1];

	    // calculate x_i(t) of target
	    x = sigmoid0(wsum + [B valueAtIndex:trg], SIG_MU, SIG_LAMDA);
	    // add it to the predicted time series
	    [pdyn setValue:x
		     ofVar:trg
		  atTPoint:t];
	}


    return pdyn;
}



- (Dynamics *)predict:(Dynamics *)adyn {

    // get info about the actual dynamics
    int tpoints = [adyn tpoints];

    // initialize the predicted dynamics
    Dynamics *pdyn = [Dynamics dynamicsWithVars:nodes
				     andTPoints:tpoints];

    int reg, trg, t;
    double wsum, x;


    // copy first time point from adyn
    [pdyn replaceRow:0 withRow:0 fromMatrix:adyn];

    // perform one-step-ahead prediction
    // for all time points
    for (t=1; t<tpoints; t++)
	// for each target
	for (trg=0; trg<nodes; trg++) {
	    // calculate the cumulative weighted effect 
	    // of all regulators
	    wsum = 0;
	    for (reg=0; reg<nodes; reg++) 
		// update weighted sum
		wsum += [W valueAtRow:trg andColumn:reg] * 
		    [adyn valueOfVar:reg atTPoint:t-1];

	    // calculate x_i(t) of target
	    x = sigmoid0(wsum + [B valueAtIndex:trg], SIG_MU, SIG_LAMDA);
	    // add it to the predicted time series
	    [pdyn setValue:x
		     ofVar:trg
		  atTPoint:t];
	}

    return pdyn;

}



- (Dynamics *)predict:(Dynamics *)adyn 
	    forTarget:(int)trg
{

    // get info about the actual dynamics
    int tpoints = [adyn tpoints];

    // initialize the predicted dynamics
    Dynamics *pdyn = [adyn copy];

    int reg, t;
    double wsum, x;


    // perform one-step-ahead prediction
    // for all time points
    for (t=1; t<tpoints; t++) {
	// for the specified target

	// calculate the cumulative weighted effect 
	// of all regulators
	wsum = 0;
	for (reg=0; reg<nodes; reg++) 
	    // update weighted sum
	    wsum += [W valueAtRow:trg andColumn:reg] * 
		[adyn valueOfVar:reg atTPoint:t-1];

	// calculate x_i(t) of target
	x = sigmoid0(wsum + [B valueAtIndex:trg], SIG_MU, SIG_LAMDA);
	// add it to the predicted time series
	[pdyn setValue:x
		 ofVar:trg
	      atTPoint:t];
    }


    return [pdyn autorelease];

}


- (NSString *) description {

  NSMutableString *st = [NSMutableString string];

  [st appendString:@"W=\n"];
  [st appendString:[W description]];
  [st appendString:@"\nB=\n"];
  [st appendString:[B description]];

  return st;

}


@end



//***************************************************************
//               RNN with Decay (adds T)
//***************************************************************


@implementation DRNN

+ (id) rnnWithNodes:(int)nodes {

    return [[[DRNN alloc] initWithNodes:nodes] autorelease];

}



// create an RNN
+ (id) rnnFromVector:(GSLVector *)vec {
    
    // figure out number of nodes
    int n = [DRNN calcNodesForDim:[vec count]];

    // initialize RNN 
    DRNN *rnn = [[DRNN alloc] initWithNodes:n];
    [rnn setFromVector:vec];
    return [rnn autorelease];

}




+ (id) rnnFromVector:(GSLVector *)vec
	    andGraph:(Digraph *)graph 
{

    // figure out number of nodes
    int n = [graph countNodes];
    // initialize RNN
    DRNN *rnn = [[DRNN alloc] initWithNodes:n];
    // set values
    [rnn setFromVector:vec
	     withGraph:graph];

    return [rnn autorelease];

}




// get the dimensionality of the problem
+ (int) calcDimForNodes:(int)nodes {

    return nodes * (nodes + 2);

}



+ (int) calcDimOfSingleNodeForNodes:(int)nodes {

    return nodes + 2;

}


+ (int) calcNodesForDim:(int)dim {

    return (int)sqrt(dim + 1) - 1;

}



+ (int) calcDimForGraph:(Digraph *) graph {

    return [graph countEdges] + 2 * [graph countNodes];

}


+ (int) calcDimForNode:(int)node
	     withGraph:(Digraph *) graph
{

    return [graph inDegreeOfNode:[NSNumber numberWithInt:node]] + 2;

}




// initializers
- (id) init {

    [self dealloc];
    @throw [NSException exceptionWithName:@"BadInitCall"
				   reason:@"Use initWith...: initializers"
				 userInfo:nil];
}



- (id) initWithNodes:(int)n {

    GSLMatrix *w = [GSLMatrix matrixWithRows:n
				  andColumns:n];
    GSLVector *b = [GSLVector vectorWithSize:n];
    GSLVector *t = [GSLVector vectorWithSize:n];

    self = [self initWithW:w
		      andB:b
		      andT:t];

    if (!self) {
	[w release];
	[b release];
	[t release];
	return nil;
    }

    return self;
	

}


- (id) initWithW:(GSLMatrix *)w
	    andB:(GSLVector *)b
	    andT:(GSLVector *)t 
{
    self = [super initWithW:w
		       andB:b];
    if (!self)
	return nil;

    T = [t retain];
    delta_t = RNN_DELTA_T;

    return self;

}



- (void) dealloc {

    [T release];
    [super dealloc];

}



- (void) reset {

    [super reset];
    [T fillWithValue:0];

}



- (void) resetNode:(int)n {

    [super resetNode:n];
    [T setValue:0 
	atIndex:n];

}




- (GSLVector *) T {

    return T;

}



- (void) setDeltaT:(double)val {

    delta_t = val;

}



// setters
- (void) setFromVector:(GSLVector *)vec {

    int i, j, vec_idx;
    // figure out number of nodes
    //int n = [DRNN calcNodesForDim:[vec count]];
    // make sure this is correct
    //NSAssert(n == nodes, @"Dimensionality mismatch!!");

    // initialize vec's index
    vec_idx = 0;

    // read in weight matrix
    for (i=0; i<nodes; i++)
	for (j=0; j<nodes; j++) 
	    // extract weight value and increment vec_idx
	    [W setValue:[vec valueAtIndex:vec_idx++]
		  atRow:i
	      andColumn:j];

    // read in bias vector
    for (i=0; i<nodes; i++)
	// extract bias term value and increment vec_idx
	[B setValue:[vec valueAtIndex:vec_idx++]
	    atIndex:i];

    // read in time constants
    for (i=0; i<nodes; i++)
	// extract bias term value and increment vec_idx
	[T setValue:[vec valueAtIndex:vec_idx++]
	    atIndex:i];

}




- (void) setFromVector:(GSLVector *)vec
	     withGraph:(Digraph *)graph
{

    int i, vec_idx;
    // figure out number of nodes
    //int n = [graph countNodes];
    // make sure this is correct
    //NSAssert(n == nodes, @"Dimensionality mismatch!!");

    // reset all parameter values
    [self reset];

    // initialize index to vec
    vec_idx = 0;

    // get graph edges
    NSArray *edges = [graph edges];
    int n_e = [edges count];
    Edge *e;

    // read in weight values (corresponding to graph edges)
    for (i=0; i<n_e; i++) {
	// get the edge
	e = [edges objectAtIndex:i];
	[W setValue:[vec valueAtIndex:vec_idx++]
	      atRow:[[e to] intValue] // rows are targets
	  andColumn:[[e from] intValue]]; // cols are regulators
    }

    // read in bias vector
    for (i=0; i<nodes; i++)
	// extract bias term value and increment vec_idx
	[B setValue:[vec valueAtIndex:vec_idx++]
	    atIndex:i];

    // read in time constants vector
    for (i=0; i<nodes; i++)
	// extract bias term value and increment vec_idx
	[T setValue:[vec valueAtIndex:vec_idx++]
	    atIndex:i];

}





- (void) setFromVector:(GSLVector *)vec
	       forNode:(int)row
{

    int i, vec_idx;

    // reset RNN values
    //[self reset]; --> NOT NEEDED HERE

    // initialize vec's index
    vec_idx = 0;

    // read in weight matrix
    for (i=0; i<nodes; i++) 
	// extract weight value and increment vec_idx
	[W setValue:[vec valueAtIndex:vec_idx++]
	      atRow:row
	  andColumn:i];

    // read in bias term value
    [B setValue:[vec valueAtIndex:vec_idx++]
	atIndex:row];

    // read in time constant value
    [T setValue:[vec valueAtIndex:vec_idx]
	atIndex:row];

}




- (void) setFromVector:(GSLVector *)vec
	     withGraph:(Digraph *)graph
	       forNode:(int)row;
{

    int vec_idx;

    // reset the node's parameter values 
    [self resetNode:row];

    // initialize index to vec
    vec_idx = 0;

    // get graph edges (array of NSNumbers)
    NSEnumerator *regs = [[graph predecessorsOfNode:[NSNumber numberWithInt:row]]
			     objectEnumerator];
    NSNumber *reg;
    while ((reg = [regs nextObject]))
	[W setValue:[vec valueAtIndex:vec_idx++]
	      atRow:row
	  andColumn:[reg intValue]];
    

    // read in bias term value
    [B setValue:[vec valueAtIndex:vec_idx++]
	atIndex:row];

    // read in time constant value
    [T setValue:[vec valueAtIndex:vec_idx]
	atIndex:row];

}






- (Dynamics *)simulateFromState:(GSLVector *)x0
		       forSteps:(int)tpoints
{

    // initialize the predicted dynamics
    Dynamics *pdyn = [Dynamics dynamicsWithVars:nodes
				     andTPoints:tpoints];

    int reg, trg, t;
    double wsum, x;

    // copy first time point from x0
    [pdyn replaceRow:0 fromVector:x0];

    // === simulate network ===
    // for all time points
    for (t=1; t<tpoints; t++)
	// for each target
	for (trg=0; trg<nodes; trg++) {
	    // calculate the cumulative weighted effect 
	    // of all regulators
	    wsum = 0;
	    for (reg=0; reg<nodes; reg++) 
		// update weighted sum
		wsum += [W valueAtRow:trg andColumn:reg] * 
		    [pdyn valueOfVar:reg atTPoint:t-1];

	    // calculate x_i(t) of target
	    x = (delta_t / [T valueAtIndex:trg]) * sigmoid0(wsum+[B valueAtIndex:trg], SIG_MU, SIG_LAMDA) +
		(1 - (delta_t / [T valueAtIndex:trg])) * [pdyn valueOfVar:trg atTPoint:t-1];
	    // add it to the predicted time series
	    [pdyn setValue:x
		     ofVar:trg
		  atTPoint:t];
	}


    return pdyn;
}



- (Dynamics *)predict:(Dynamics *)adyn {

    // get info about the actual dynamics
    int tpoints = [adyn tpoints];

    // initialize the predicted dynamics
    Dynamics *pdyn = [Dynamics dynamicsWithVars:nodes
				     andTPoints:tpoints];

    int reg, trg, t;
    double wsum, x;


    // copy first time point from adyn
    [pdyn replaceRow:0 withRow:0 fromMatrix:adyn];

    // perform one-step-ahead prediction
    // for all time points
    for (t=1; t<tpoints; t++)
	// for each target
	for (trg=0; trg<nodes; trg++) {
	    // calculate the cumulative weighted effect 
	    // of all regulators
	    wsum = 0;
	    for (reg=0; reg<nodes; reg++) 
		// update weighted sum
		wsum += [W valueAtRow:trg andColumn:reg] * 
		    [adyn valueOfVar:reg atTPoint:t-1];

	    // calculate x_i(t) of target
	    x = (delta_t / [T valueAtIndex:trg]) * sigmoid0(wsum+[B valueAtIndex:trg], SIG_MU, SIG_LAMDA) +
		(1 - (delta_t / [T valueAtIndex:trg])) * [adyn valueOfVar:trg atTPoint:t-1];
	    // add entry to the predicted time series
	    [pdyn setValue:x
		     ofVar:trg
		  atTPoint:t];
	}

    return pdyn;

}



- (Dynamics *)predict:(Dynamics *)adyn
	    forTarget:(int)trg
{

    // get info about the actual dynamics
    int tpoints = [adyn tpoints];

    // initialize the predicted dynamics
    Dynamics *pdyn = [adyn copy];

    int reg, t;
    double wsum, x;


    // perform one-step-ahead prediction
    // for all time points
    for (t=1; t<tpoints; t++) {
	// for specified target ::
	// calculate the cumulative weighted effect 
	// of all regulators
	wsum = 0;
	for (reg=0; reg<nodes; reg++) 
	    // update weighted sum
	    wsum += [W valueAtRow:trg andColumn:reg] * 
		[adyn valueOfVar:reg atTPoint:t-1];

	// calculate x_i(t) of target
	x = (delta_t / [T valueAtIndex:trg]) * sigmoid0(wsum+[B valueAtIndex:trg], SIG_MU, SIG_LAMDA) +
	    (1 - (delta_t / [T valueAtIndex:trg])) * [adyn valueOfVar:trg atTPoint:t-1];
	// add entry to the predicted time series
	[pdyn setValue:x
		 ofVar:trg
	      atTPoint:t];
    }

    return [pdyn autorelease];

}



- (NSString *) description {

  NSMutableString *st = [super description];

  [st appendString:@"\nT=\n"];
  [st appendString:[T description]];

  return st;

}



@end
