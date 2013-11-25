#import "aco.h"
#import "graphs.h"
#import "params.h"

#import "common.h"

#import <math.h>


#define ERR_FUN(X) ((X)>5 ? 5 : log10((X)) / (log10((X)) - 1))

//***********************************************************************
//***********************************************************************
@implementation Solution


+ (id) generateWith:(GSLMatrix *)phero {

  // generate graph
  Digraph *g = generate_graph(phero);
  // evaluate graph
  GSLVector *v = evaluate_graph(g);

  // return Solution object
  return [[[Solution alloc] initWithGraph:g
				andErrors:v]
	   autorelease];

}



- (id) init {

  // create empty graph
  Digraph *g = [Digraph digraphWithNodes:settings.nodes];
  // create vector of errors
  GSLVector *v = [GSLVector vectorWithSize:settings.nodes];
  // fill with max error
  [v fillWithValue:DBL_MAX];

  self = [self initWithGraph:g andErrors:v];
  if (!self) {
    [g release];
    [v release];
  }

  return self;

}


- (id) initWithGraph:(Digraph *)g
	   andErrors:(GSLVector *)v 
{

  self = [super init];
  if (!self)
    return nil;

  graph = [g retain];
  errors = [v retain];

  return self;

}


- (void) dealloc {

  [graph release];
  [errors release];
  [super dealloc];

}



- (Digraph *) graph {

  return graph;

}



- (GSLVector *) errors {

  return errors;

}



- (void) updateWith:(Solution *)other {

  int reg, trg;
  NSNumber *target;
  NSArray *regs;

  for (trg=0; trg<settings.nodes; trg++) 
    if ([[other errors] valueAtIndex:trg] < [errors valueAtIndex:trg]) {
      // create target node object
      target = [NSNumber numberWithInt:trg];
      // remove all incoming edges of target
      [graph removeAllInEdgesOfNode:target];
      // get regulators from other
      regs = [[other graph] predecessorsOfNode:target];
      // add (reg,trg) edges to [self graph]
      for (reg=0; reg<[regs count]; reg++)
	[graph addEdgeFrom:[regs objectAtIndex:reg]
			To:target];
      // update error for target
      [errors setValue:[[other errors] valueAtIndex:trg]
	       atIndex:trg];
    }

}


- (void) clear {

  // remove all graph edges
  [graph removeAllEdges];
  // reset errors
  [errors fillWithValue:DBL_MAX];

}


- (NSString *) description {

  return [graph description];

}



- (void) save {

  // save the graph in log_path (FACT: it exists!)
  NSString *fname = [settings.log_path stringByAppendingPathComponent:GRAPH_FILE];
  [graph saveToFile:fname];

  fname = [settings.log_path stringByAppendingPathComponent:ERRORS_FILE];
  [errors saveToFile:fname];
}

@end

//***********************************************************************
//***********************************************************************

void update_lamda(Dynamics *lamda, GSLMatrix *phero, int step) {

  double tau, lamda_factor;
  GSLVector *tau_min = [phero minAcrossRows];
  GSLVector *tau_max = [phero maxAcrossRows];
  double tmin, tmax;
  int trg, reg;

  for (trg=0; trg<settings.nodes; trg++) {
    lamda_factor = 0.;
    // determine threshold for i^th gene
    tmin = [tau_min valueAtIndex:trg];
    tmax = [tau_max valueAtIndex:trg];
    tau =  tmin + settings.aco_lamda * (tmax - tmin);
    // calculate lamda factor for i^th gene
    for (reg=0; reg<settings.nodes; reg++) 
      if ([phero valueAtRow:reg andColumn:trg] > tau)
	lamda_factor += 1;
    // record lamda_factor
    [lamda setValue:lamda_factor
	      ofVar:trg
	   atTPoint:step];
  }
    
    

}


void update_phero(GSLMatrix *phero, Solution *sol) {

  NSArray *edges = [[sol graph] edges];
  Edge *e;
  int i;
    
  for (i=0; i<[edges count]; i++) {
    // get edge
    e = [edges objectAtIndex:i];
    // update corresponding pheromone matrix entry
    // with target error
    [phero addValue:ERR_FUN([[sol errors] valueAtIndex:[[e to] intValue]])
	      atRow:[[e from] intValue]
	  andColumn:[[e to] intValue]];
  }
}



void evaporate_phero(GSLMatrix *phero) {

  int i,j;
  int rows = [phero rows];
  int cols = [phero columns];
  double val;

  for (i=0; i<rows; i++)
    for (j=0; j<cols; j++) {
      val = [phero valueAtRow:i
		    andColumn:j];
      [phero addValue:-settings.aco_rho * val
		atRow:i
	    andColumn:j];
    }

}


Solution *netinf(Dynamics *lamda) {

  // initialize pheromone matrix
  GSLMatrix *phero = [[GSLMatrix alloc] initWithRows:settings.nodes
					  andColumns:settings.nodes];
  [phero fillWithValue:settings.aco_phero_val];

  // initialize global best solution
  Solution *gbest = [[Solution alloc] init];
  // initialize local best solution
  Solution *lbest = [[Solution alloc] init];
  // declare a solution
  Solution *solution;
  // declare autorelease pool
  NSAutoreleasePool *pool;
  // mark starting time
  settings.start = [[NSDate alloc] init];
  int step, ant;

  printf("ACO steps :\n");

  for (step=0; step<settings.aco_steps; step++) {

    // print step info
    printf("Step %d\n", step);

    // reset lbest
    [lbest clear];

    for (ant=0; ant<settings.aco_ants; ant++) {
      // allocate new pool
      pool = [[NSAutoreleasePool alloc] init];
      // generate solution
      solution = [Solution generateWith:phero];
      // update lbest
      [lbest updateWith:solution];
      // empty pool
      [pool release];
    }

    // update pheromone matrix with lbest
    update_phero(phero, lbest);
    // update gbest with lbest
    [gbest updateWith:lbest];
    // update pheromone matrix with gbest
    update_phero(phero, gbest);
    // perform pheromone evaporation
    evaporate_phero(phero);
    // update vector of mean lamda factor 
    update_lamda(lamda, phero, step);

  }

  // calculate and store duration
  settings.duration = labs(round([settings.start timeIntervalSinceNow]));
  // print duration
  printf("\nFinished :-)\nDuration : %s\n", [sec_to_nsstring(settings.duration) UTF8String]);

  // release objects
  [lbest release];
  [phero release];

  // return global best solution
  return gbest;
}
