#ifndef __RNN_H__
#define __RNN_H__


/*
The weight matrix contains entries of the form W[i,j]
where i : targets (rows)
and j : regulators (columns)

so w[i,j] indicates how target node i is regulated by regulator node j

 */




//***************************************************************
//               Normal RNN (just W, B)
//***************************************************************

@interface RNN : NSObject {
    
    int nodes; // number of nodes
    GSLMatrix *W; // weight matrix
    GSLVector *B; // bias vector

}

// create an RNN
+ (id) rnnWithNodes:(int)nodes;

+ (id) rnnFromVector:(GSLVector *)vec;

+ (id) rnnFromVector:(GSLVector *)vec
	   withGraph:(Digraph *)graph;


// ==========================================================
// get the dimensionality of the problem

// === COMPLETE RNNs ===
// calculate the number of parameters of an RNN with N nodes
+ (int) calcDimForNodes:(int)n;

// calculate the number of parameters for a single node
+ (int) calcDimOfSingleNodeForNodes:(int)nodes;

// calculate how many nodes does the dimensionality imply
+ (int) calcNodesForDim:(int)dim;

// === PARTIAL RNNs ===
// calculate the number of parameters of an RNN that 
// corresponds to GRAPH
+ (int) calcDimForGraph:(Digraph *) graph;

// calculate the number of parameters of the specified node
// from the corresponding graph
+ (int) calcDimForNode:(int)node
	     withGraph:(Digraph *) graph;

// ==========================================================



// initialize an empty RNN
- (id) initWithNodes:(int)n;

// DESIGNATED
- (id) initWithW:(GSLMatrix *)w
	    andB:(GSLVector *)b;

- (void) reset;
- (void) resetNode:(int)n;

- (void) dealloc;


// getters
- (GSLMatrix *) W;
- (GSLVector *) B;
- (int) nodes;

// setters
- (void) setFromVector:(GSLVector *)vec;
- (void) setFromVector:(GSLVector *)vec
	     withGraph:(Digraph *)graph;

- (void) setFromVector:(GSLVector *)vec
	       forNode:(int)row;
- (void) setFromVector:(GSLVector *)vec
	     withGraph:(Digraph *)graph
	       forNode:(int)row;


// ===========================================================
//                  TRAINING FUNCTIONS

// train the RNN against TDYN (training data)
// returns the minimum achieved optimization error
- (double) trainUsingDynamics:(Dynamics *)tdyn
	      withPSOSettings:(pso_settings_t *)pso_settings;

// train the RNN against TDYN (training data)
//  **** problem decomposition strategy ****
// returns the minimum achieved optimization error
- (double) dtrainUsingDynamics:(Dynamics *)tdyn
	       withPSOSettings:(pso_settings_t *)pso_settings;


// train the RNN that corresponds to graph
// using TDYN (training data)
// returns the minimum achieved optimization error
- (double) trainUsingDynamics:(Dynamics *)tdyn
		    withGraph:(Digraph *)graph
	      withPSOSettings:(pso_settings_t *)pso_settings;

// train the RNN that corresponds to graph
// using TDYN (training data)
//  **** problem decomposition strategy ****
// returns the minimum achieved optimization error
- (double) dtrainUsingDynamics:(Dynamics *)tdyn
		     withGraph:(Digraph *)graph
	       withPSOSettings:(pso_settings_t *)pso_settings;

// ===========================================================



- (Dynamics *)simulateFromState:(GSLVector *)x0
		       forSteps:(int)tpoints;

- (Dynamics *)predict:(Dynamics *)adyn;
- (Dynamics *)predict:(Dynamics *)adyn
	    forTarget:(int)trg;

- (NSString *) description;

@end



//***************************************************************
//               RNN with Decay (adds T)
//***************************************************************


@interface DRNN : RNN {
    
    GSLVector *T; // time constants
    double delta_t;

}

// create an RNN
+ (id) rnnWithNodes:(int)nodes;
+ (id) rnnFromVector:(GSLVector *)vec;

+ (id) rnnFromVector:(GSLVector *)vec
	    andGraph:(Digraph *)graph;


// ==========================================================
// get the dimensionality of the problem

// === COMPLETE RNNs ===
// calculate the number of parameters of an RNN with N nodes
+ (int) calcDimForNodes:(int)n;

// calculate the number of parameters for a single node
+ (int) calcDimOfSingleNodeForNodes:(int)nodes;

// calculate how many nodes does the dimensionality imply
+ (int) calcNodesForDim:(int)dim;

// === PARTIAL RNNs ===
// calculate the number of parameters of an RNN that 
// corresponds to GRAPH
+ (int) calcDimForGraph:(Digraph *) graph;

// calculate the number of parameters of the specified node
// from the corresponding graph
+ (int) calcDimForNode:(int)node
	     withGraph:(Digraph *) graph;

// ==========================================================



// initialize an empty RNN
- (id) initWithNodes:(int)n;

- (id) initWithW:(GSLMatrix *)w
	    andB:(GSLVector *)b
	    andT:(GSLVector *)t;

- (void) dealloc;

- (void) reset;
- (void) resetNode:(int)n;


// getters
- (GSLVector *) T;

- (void) setDeltaT:(double)val;



// setters
- (void) setFromVector:(GSLVector *)vec;
- (void) setFromVector:(GSLVector *)vec
	     withGraph:(Digraph *)graph;

- (void) setFromVector:(GSLVector *)vec
	       forNode:(int)row;
- (void) setFromVector:(GSLVector *)vec
	     withGraph:(Digraph *)graph
	       forNode:(int)row;




- (Dynamics *)simulateFromState:(GSLVector *)x0
		       forSteps:(int)tpoints;

- (Dynamics *)predict:(Dynamics *)adyn;
- (Dynamics *)predict:(Dynamics *)adyn
	    forTarget:(int)trg;

- (NSString *) description;

@end

#endif
