#import <Foundation/Foundation.h>


//***************************************************************************
@interface Edge : NSObject {

    id from;
    id to;

}

+ (id)edgeFrom:(id)source to:(id)dest;
- (id)initFrom:(id)source to:(id)dest;

- (id)from;
- (id)to;

@end



//***************************************************************************

/*
  Digraph : a class that represents a directed graph

  class members :

  ** nodes : a mutable array that stores the nodes in the order that 
             they were added in the graph (preserves the ordering)

  ** nattrs : a mutable dictionary of the form:
  {'A' : {'name' : 'node A', ...},
  'B' : {'name' : 'node B', ...},
  ...
  }

  ** edges : a mutable dictionary of the form:
  {'A' : {'B' : {'weight' : 0.5,...}

          'C' : {'weight' : 1.2,...}},
   'B' : {'B' : {'weight' : -0.5,...}},

   ...
  }

  ** cedges : maintains a count of the edges in the graph


 */

@interface Digraph : NSObject {

    // nodes
    NSMutableArray *nodes;
    NSMutableDictionary *nattrs;
    // edges
    NSMutableDictionary *outgoing; // outgoing edges 
    NSMutableDictionary *incoming; // incoming edges 
    int cedges; // number of edges

}


+ (id) digraphWithNodes:(int)nnodes;
+ (id) digraphFromFile:(NSString *)fname;

- (id) init;
- (id) initWithNodes:(int)nnodes;

- (void) dealloc;


// add nodes to the graph
- (void) addNode:(id)node;
- (void) addNode:(id)node withAttrs:(NSDictionary *)attrs;


// add edges to the graph
- (void) addEdgeFrom:(id)src To:(id)dest;
- (void) addEdgeFrom:(id)src To:(id)dest withAttrs:(NSDictionary *)attrs;

// remove edges from graph
- (void) removeEdgeFrom:(id)src To:(id)dest;
- (void) removeAllInEdgesOfNode:(id)dest;
- (void) removeAllOutEdgesOfNode:(id)src;
- (void) removeAllEdges;


// add attributes to existing nodes/edges
- (void) updateNode:(id)node 
	    withKey:(NSString *)key
	   andValue:(id)value;

- (void) updateEdge:(Edge *)edge 
	    withKey:(NSString *)key
	   andValue:(id)value;


// query nodes and edges for attributes
- (id) getAttr:(NSString *)attrname
       forNode:(id)node;

- (NSDictionary *) getAllAttrsForNode:(id)node;

- (id) getAttr:(NSString *)attrname
      fromNode:(id)src
	toNode:(id)dest;

- (id) getAttr:(NSString *)attrname
       forEdge:(Edge *)e;

- (NSDictionary *) getAllAttrsForEdge:(Edge *)e;
- (NSDictionary *) getAllAttrsFromNode:(id)src
				toNode:(id)dest;


// querying
- (NSArray *) nodes;
- (NSArray *) edges;

- (NSArray *) successorsOfNode:(id)src;
- (NSArray *) predecessorsOfNode:(id)dest;

- (int) inDegreeOfNode:(id)dest;
- (int) outDegreeOfNode:(id)src;

- (BOOL) hasNode:(id)node;
- (BOOL) hasEdge:(Edge *)edge;

// counting things
- (int) countNodes;
- (int) countEdges;

// graph description as a string
- (NSString *) description;

// save graph to file
- (void) saveToFile:(NSString *)fname;


@end
