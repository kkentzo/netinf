#import <Foundation/Foundation.h>
#import <unistd.h>

#import "params.h"
#import "aco.h"
#import "pso.h"
#import "RNN.h"
#import "common.h"
#import "Dynamics.h"


void train() {
  // try to load the solution graph
  NSString *fname = [settings.log_path stringByAppendingPathComponent:GRAPH_FILE];
  Digraph *graph = [Digraph digraphFromFile:fname];
  if (! graph) {
    printf("Graph file %s does not exist in path: %s\nAborting..\n",
	   [fname UTF8String], [settings.log_path UTF8String]);
    return;
  }
  
  printf("Loaded graph from file : %s (%d nodes)\n", 
	 [fname UTF8String], [graph countNodes]);
  
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
  RNN *rnn = [settings.rnn_class rnnWithNodes:[graph countNodes]];
  double err;

  printf("Training RNN...\n");

  // train it
  if (settings.decomposition)
    err = [rnn dtrainUsingDynamics:settings.tdata
			 withGraph:graph
		   withPSOSettings:&pso_settings];
  else
    err = [rnn trainUsingDynamics:settings.tdata
			withGraph:graph
		  withPSOSettings:&pso_settings];

  // OK, save the parameters of the trained RNN
  fname = [settings.log_path stringByAppendingPathComponent:@"trained.rnn"];
  FILE *stream = fopen([fname UTF8String], "w");
  fprintf(stream, "%s", [[rnn description] UTF8String]);
  fclose(stream);
  

  // calculate and save predicted dynamics
  Dynamics *pdyn = [rnn predict:settings.tdata];
  fname = [settings.log_path stringByAppendingPathComponent:@"trained.rnn.prediction"];
  [pdyn saveToFile:fname];
  

}


int main(int argc, char **argv) {

  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

  // parse cmd line args (overrides default settings)
  int res = parse_settings(argc, argv);
  if (res) 
    return -1;

  // initialize RNG
  if (settings.seed)
    settings.rng = [[RNG alloc] initWithSeed:settings.seed];
  else {
    settings.rng = [[RNG alloc] init];
    settings.seed = [settings.rng seed];
  }

  // should we just train an RNN given a solution.graph and exit??
  if (settings.train) {
    train();
    return 0;
  }

	
  // save some stuff in settings.log_path
  if (settings.log_path) {
    // save settings to log_path
    // ** this will also create the directory **
    save_settings();
    // copy data file to log_path
    NSString *dest = [settings.log_path stringByAppendingPathComponent:DATA_FNAME];
    NSString *cmd = [NSString stringWithFormat:@"cp %@ %@", settings.dpath, dest];
    system([cmd UTF8String]);
  }

  // initialize lamda factor vector
  Dynamics *lamda = [[Dynamics alloc] initWithVars:settings.nodes
					andTPoints:settings.aco_steps];
  // run algorithm
  Solution *solution = netinf(lamda);

  // What to do with solution??
  if (settings.log_path) {
    // save solution in log_path
    [solution save];
    // save lamda vector in log_path
    [lamda saveToFile:[settings.log_path stringByAppendingPathComponent:@"lamda.mat"]];
    // compress log_path??
    if (settings.compress) 
      compress_dir(settings.log_path);
  } else
    // print solution
    printf("%s\n", [[solution description] UTF8String]);
    

  // release all
  [lamda release];
  [solution release];
  [settings.rng release];
  [settings.tdata release];
  [pool release];
  return 0;

}
