#import "Graph.h"
#import "GSL.h"
#import "common.h"


//***************************************************************************
@implementation Edge

+ (id)edgeFrom:(id)source to:(id)dest {

    return [[[Edge alloc] initFrom:source to:dest] autorelease];

}


- (id)initFrom:(id)source to:(id)dest {

    self = [super init];
    if (!self)
	return nil;
    from = source;
    to = dest;

    return self;

}

- (id) from {

    return from;

}


- (id) to {

    return to;

}


@end


//***************************************************************************

@implementation Digraph


+ (id) digraphWithNodes:(int)nnodes {
    
    return [[[Digraph alloc] initWithNodes:nnodes] autorelease];

}


+ (id) digraphFromFile:(NSString *)fname {

    // parse file lines into an array and get enumerator
    NSEnumerator *lines = [filelines(fname) objectEnumerator];
    NSString *line;
    // start in node-reading mode
    BOOL edge_mode = NO;
    NSArray *tokens;
    int reg, trg;

    Digraph *graph = [[Digraph alloc] init];

    while ((line = [lines nextObject])) {
	if ([line isEqualToString:@"-"]) {
	    // switch to edge-reading mode
	    edge_mode = YES;
	    continue;
	}
	if (edge_mode) {
	    tokens = [line componentsSeparatedByString:@" "];
	    NSAssert([tokens count] == 2, @"Problem in parsing graph file");
	    reg = [(NSString *)[tokens objectAtIndex:0] intValue];
	    trg = [(NSString *)[tokens objectAtIndex:1] intValue];
	    [graph addEdgeFrom:[NSNumber numberWithInt:reg]
			    To:[NSNumber numberWithInt:trg]];
	} else {
	    // parse node number
	    trg = [line intValue];
	    [graph addNode:[NSNumber numberWithInt:trg]];
	}
    }

    return [graph autorelease];
}
	    
	    



- (id) init {

    self = [super init];
    if (!self)
	return nil;

    nodes = [[NSMutableArray alloc] init];
    nattrs = [[NSMutableDictionary alloc] init];
    outgoing = [[NSMutableDictionary alloc] init];
    incoming = [[NSMutableDictionary alloc] init];

    cedges = 0;

    return self;

}



- (id) initWithNodes:(int)nnodes {

    self = [self init];
    if (!self)
	return nil;

    int i;

    for (i=0; i<nnodes; i++)
	[self addNode:[NSNumber numberWithInt:i]];

    return self;

}




- (void) dealloc {

    [nodes release];
    [nattrs release];
    [outgoing release];
    [incoming release];
    [super dealloc];

}


// add nodes to the graph
- (void) addNode:(id)node {

    [self addNode:node withAttrs:nil];

}


- (void) addNode:(id)node withAttrs:(NSDictionary *)attrs {

    // does node exist??
    if ([nattrs objectForKey:node]) {
	// update the node's attributes
	[[nattrs objectForKey:node] addEntriesFromDictionary:nattrs];
	// ...and exit
	return;
    }

    // add the node to nodes array
    [nodes addObject:node];

    // add the node to nodes dict (nattrs)
    if (attrs)
	// add provided attrs dict
	[nattrs setObject:attrs
		   forKey:node];
    else
	// initialize empty attrs dictionary
	[nattrs setObject:[NSMutableDictionary dictionary]
		   forKey:node];

    // add the node to outgoing dictionary (node is source)
    [outgoing setObject:[NSMutableDictionary dictionary]
    		 forKey:node];
    // add the node to incoming dictionary (node is dest)
    [incoming setObject:[NSMutableDictionary dictionary]
    		 forKey:node];

}




// add edges to the graph
- (void) addEdgeFrom:(id)src To:(id)dest {

    [self addEdgeFrom:src 
		   To:dest
	    withAttrs:nil];

}




- (void) addEdgeFrom:(id)src To:(id)dest withAttrs:(NSDictionary *)attrs {

    // does edge exist??
    NSMutableDictionary *d = [[outgoing objectForKey:src] objectForKey:dest];
    if (d) // is d non nil??
	// just update the attributes of existing node
	[d addEntriesFromDictionary:attrs];
    else if (attrs) { // is attrs non nil?? 
	// add entry for edge associated with attrs
	[[outgoing objectForKey:src] setObject:attrs
					forKey:dest];
	[[incoming objectForKey:dest] setObject:attrs
					 forKey:src];
	// increase edge counter
	cedges += 1;
    
    } else {
	// add entry for edge with empty attributes
	[[outgoing objectForKey:src] setObject:[NSMutableDictionary dictionary]
					forKey:dest];
	[[incoming objectForKey:dest] setObject:[NSMutableDictionary dictionary]
					 forKey:src];

	// increase edge counter
	cedges += 1;
    }

}



- (void) removeEdgeFrom:(id)src To:(id)dest {

    NSMutableDictionary *d = [[outgoing objectForKey:src] objectForKey:dest];
    // does edge exist??
    if (d) {
	[[outgoing objectForKey:src] removeObjectForKey:dest];
	[[incoming objectForKey:dest] removeObjectForKey:src];
	// reduce edge count
	cedges -= 1;
    }

}



- (void) removeAllInEdgesOfNode:(id)dest {

    NSArray *preds = [self predecessorsOfNode:dest];
    int i;
    id src;
    
    // remove entries of the form (src, dest) in outgoing dict
    for (i=0; i < [preds count]; i++) {
	// get source node for dest
	src = [preds objectAtIndex:i];
	// remove entry 
	[[outgoing objectForKey:src] removeObjectForKey:dest];
	// decrease edge count
	cedges -= 1;
    }

    // remove all src for dest in incoming dict
    [[incoming objectForKey:dest] removeAllObjects];

}


- (void) removeAllOutEdgesOfNode:(id)src {

    NSArray *succs = [self successorsOfNode:src];
    int i;
    id dest;
    
    // remove entries of the form (src, dest) in incoming dict
    for (i=0; i < [succs count]; i++) {
	// get dest node for src
	dest = [succs objectAtIndex:i];
	// remove entry 
	[[incoming objectForKey:dest] removeObjectForKey:src];
	// decrease edge count
	cedges -= 1;
    }

    // remove all dests for src in outgoing dict
    [[outgoing objectForKey:src] removeAllObjects];

}


- (void) removeAllEdges {

    NSArray *keys;
    int i;

    // remove all edges from outgoing dictionary
    keys = [outgoing allKeys];
    for (i=0; i<[keys count]; i++)
	[[outgoing objectForKey:[keys objectAtIndex:i]] removeAllObjects];

    // remove all edges from incoming dictionary
    keys = [incoming allKeys];
    for (i=0; i<[keys count]; i++)
	[[incoming objectForKey:[keys objectAtIndex:i]] removeAllObjects];

    // reset edges counter
    cedges = 0;

}




// add attributes to existing nodes/edges
- (void) updateNode:(id)node 
	    withKey:(NSString *)key
	   andValue:(id)value
{

    [[nattrs objectForKey:node] setObject:value
				   forKey:key];

}


- (void) updateEdge:(Edge *)edge 
	    withKey:(NSString *)key
	   andValue:(id)value
{

    [[[outgoing objectForKey:[edge from]] // first-level dictionary
	objectForKey:[edge to]] // second-level dictionary
	   setObject:value // set key-value pair
	      forKey:key];

    [[[incoming objectForKey:[edge to]] // first-level dictionary
	objectForKey:[edge from]] // second-level dictionary
	   setObject:value // set key-value pair
	      forKey:key];

}



- (id) getAttr:(NSString *)attrname
       forNode:(id)node 
{
    return [[nattrs objectForKey:node] objectForKey:attrname];

}


- (NSDictionary *) getAllAttrsForNode:(id)node {

    return [nattrs objectForKey:node];

}


- (id) getAttr:(NSString *)attrname
      fromNode:(id)src
	toNode:(id)dest 
{

    Edge *e = [Edge edgeFrom:src to:dest];
    return [self getAttr:attrname forEdge:e];

}




- (id) getAttr:(NSString *)attrname
       forEdge:(Edge *)edge
{

    return [[[outgoing objectForKey:[edge from]]
	       objectForKey:[edge to]]
	       objectForKey:attrname];

}



- (NSDictionary *) getAllAttrsForEdge:(Edge *)e {

    return [[outgoing objectForKey:[e from]]
		      objectForKey:[e to]];

}



- (NSDictionary *) getAllAttrsFromNode:(id)src
				toNode:(id)dest
{

    return [[outgoing objectForKey:src] objectForKey:dest];

}



// querying
- (NSArray *) nodes {

    return [NSArray arrayWithArray:nodes];

}


- (NSArray *) edges {

    NSMutableArray *e = [NSMutableArray arrayWithCapacity:cedges];
    NSArray *dests; // successor nodes
    id cnode; // current node
    int i, j;

    for (i=0; i<[nodes count]; i++) {
	// get current node
	cnode = [nodes objectAtIndex:i];
	// get successors for node i
	dests = [[outgoing objectForKey:cnode] allKeys];
	// create edge objects and add them to e
	for (j=0; j<[dests count]; j++)
	    [e addObject:[Edge edgeFrom:cnode
				     to:[dests objectAtIndex:j]]];
    }

    // return array of edges
    return e;
}



- (NSArray *) successorsOfNode:(id)src {

    return [[outgoing objectForKey:src] allKeys];

}


- (NSArray *) predecessorsOfNode:(id)dest {

    return [[incoming objectForKey:dest] allKeys];

}



- (int) inDegreeOfNode:(id) dest {

    return [[incoming objectForKey:dest] count];

}



- (int) outDegreeOfNode:(id) src {

    return [[outgoing objectForKey:src] count];

}





- (BOOL) hasNode:(id)node {

    return [nodes containsObject:node];

}



- (BOOL) hasEdge:(Edge *)edge {

    return [[outgoing objectForKey:[edge from]] objectForKey:[edge to]];

}




- (int) countNodes {

    return [nodes count];

}


- (int) countEdges {

    return cedges;

}


- (NSString *) description {

    NSMutableString *desc = [NSMutableString string];
    NSArray *E = [self edges];
    NSDictionary *attrs;
    NSArray *keys;
    id key;
    Edge *e;
    int i, j;
    
    // write the nodes (along with attributes)
    for (i=0; i<[nodes count]; i++) {
	[desc appendString:[NSString stringWithFormat:@"%@", [nodes objectAtIndex:i]]];
	// get node attrs dictionary
	attrs = [nattrs objectForKey:[nodes objectAtIndex:i]];
	keys = [attrs allKeys];
	for (j=0; j<[keys count]; j++) {
	    key = [keys objectAtIndex:j];
	    [desc appendString:[NSString stringWithFormat:@" %@=%@", 
					 key,
				      [attrs objectForKey:key]]];
	}
	[desc appendString:@"\n"];
    }

    // write separator
    [desc appendString:@"-\n"];

    // write the edges (along with attributes)
    for (i=0; i<[E count]; i++) {
	// write edge
	e = [E objectAtIndex:i];
	[desc appendString:[NSString stringWithFormat:@"%@ %@", [e from], [e to]]];
	// write edge attributes
	// get dictionary of attributes for current edge
	attrs = [self getAllAttrsForEdge:e];
	// get array of keys
	keys = [attrs allKeys];
	for (j=0; j<[keys count]; j++) {
	    key = [keys objectAtIndex:j];
	    [desc appendString:[NSString stringWithFormat:@" %@=%@", 
					 key,
				      [attrs objectForKey:key]]];
	}
	[desc appendString:@"\n"];
    }

    return desc;

}


- (void) saveToFile:(NSString *)fname {

    FILE *stream = fopen([fname UTF8String], "w");
    fprintf(stream, "%s", [[self description] UTF8String]);
    fclose(stream);

}


@end
