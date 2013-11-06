#import  <Foundation/Foundation.h>
#import "GSL.h"
#import "Graph.h"
#import "Dynamics.h"


//***********************************************************************
//***********************************************************************
@interface Solution : NSObject {

    Digraph *graph; // the solution graph
    GSLVector *errors; // the errors per node

}

+ (id) generateWith:(GSLMatrix *)phero;

- (id) init;

- (id) initWithGraph:(Digraph *)g
	   andErrors:(GSLVector *)v;

- (void) dealloc;


- (Digraph *) graph;
- (GSLVector *) errors;

- (void) updateWith:(Solution *)other;

- (void) clear;

- (NSString *) description;

- (void) save;

@end


//***********************************************************************
//***********************************************************************

// the network inference function
Solution *netinf(Dynamics *lamda);
