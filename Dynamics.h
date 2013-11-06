

@interface Dynamics : GSLMatrix {

    // rows : time points
    // cols : variables
    NSArray *labels;

}

+ (id) dynamicsWithVars:(int)vars andTPoints:(int)tpoints;

+ (id) dynamicsWithVars:(int)vars
	     andTPoints:(int)tpoints
	      andLabels:(NSArray *)names;

+ (id) dynamicsFromFile:(NSString *) fname;


- (id) init; // DO NOT USE

- (id) initWithVars:(int)vars 
	 andTPoints:(int)tpoints;

- (id) initWithVars:(int)vars 
	 andTPoints:(int)tpoints
	  andLabels:(NSArray *)names;

- (id) initFromFile:(NSString *)fname;

- (id) copy;

- (void) dealloc;

// matrix access
- (void) setValue:(double)val 
	    ofVar:(int)var 
	 atTPoint:(int)tpoint;
- (double) valueOfVar:(int)var 
	     atTPoint:(int)tpoint;


// getters/setters
- (NSArray *) labels;
- (void) setLabels:(NSArray *)names;

- (int) vars;
- (int) tpoints;


// calculations
- (double) calcMSEwith:(Dynamics *)other;
- (double) calcMSEwith:(Dynamics *)other
		 ofVar:(int)var;

- (GSLVector *) calcMSEVector:(Dynamics *)other;


@end
