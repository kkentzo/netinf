#import  <Foundation/Foundation.h>
#import "GSL.h"
#import "Graph.h"


// Digraph *_edsf_model_(GSLMatrix *phero);
// Digraph *_phero_model_(GSLMatrix *phero);
// double pso_obj_fun(double *vec, size_t dim);


// graphs generation function
Digraph *generate_graph(GSLMatrix *phero);

// graph evaluation function (using PSO)
GSLVector *evaluate_graph(Digraph *g);

