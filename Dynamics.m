#import <Foundation/Foundation.h>
#import "GSL.h"


#import "Dynamics.h"


@implementation Dynamics


+ (id) dynamicsWithVars:(int)vars andTPoints:(int)tpoints {

    return [[[Dynamics alloc] initWithVars:vars
				  andTPoints:tpoints]
	       autorelease];

}



+ (id) dynamicsWithVars:(int)vars
	     andTPoints:(int)tpoints
	      andLabels:(NSArray *)names
{

    return [[[Dynamics alloc] initWithVars:vars
				andTPoints:tpoints
				 andLabels:names]
	       autorelease];

}



+ (id) dynamicsFromFile:(NSString *) fname {

    return [[[Dynamics alloc] initFromFile:fname] autorelease];

}





- (id) init {

    [self dealloc];
    @throw [NSException exceptionWithName:@"BadInitCall"
				   reason:@"Use initWith...: initializers"
				 userInfo:nil];

}




- (id) initWithVars:(int)vars 
	 andTPoints:(int)tpoints
{

    return [self initWithVars:vars
		   andTPoints:tpoints
		    andLabels:nil];

}


- (id) initWithVars:(int)vars 
	 andTPoints:(int)tpoints
	  andLabels:(NSArray *)names 
{

    // initialize super class (and mat)
    self = [super initWithRows:tpoints
		    andColumns:vars];
    if (!self)
	return nil;

    // initialize labels
    labels = [names retain];

    return self;
}



- (id) initFromFile:(NSString *)fname {

    self = [super initFromFile:fname];
    if (!self)
	return nil;

    // initialize labels
    labels = nil;

    return self;

}




- (id) copy {

    // copy matrix
    gsl_matrix *newmat = gsl_matrix_calloc(matrix->size1,
					   matrix->size2);
    // copy matrix elements
    gsl_matrix_memcpy(newmat, matrix);

    // create new Dynamics object
    Dynamics *newdyn = [[Dynamics alloc] initWithMatrix:newmat];
    [newdyn setLabels:labels];

    return newdyn;

}



- (void) dealloc {

    [labels release];
    [super dealloc];

}






- (void) setValue:(double)val 
	    ofVar:(int)var 
	 atTPoint:(int)tpoint
{

    [self setValue:val atRow:tpoint andColumn:var];

}


- (double) valueOfVar:(int)var 
	     atTPoint:(int)tpoint
{

    return [self valueAtRow:tpoint andColumn:var];

}






- (NSArray *) labels {

    return labels;

}



- (void) setLabels:(NSArray *)names {

    [names retain];
    [labels release];
    labels = names;

}



- (int) vars {

    // number of columns
    return [self columns];

}



- (int) tpoints {

    // number of rows
    return [self rows];

}



- (double) calcMSEwith:(Dynamics *)other {

    int i, j;
    int rows = [self rows];
    int cols = [self columns];
    double sdiff = 0;

    NSAssert((rows == [other rows] && \
	      cols == [other columns]),
	     @"Misaligned matrices");

    for (i=0; i<rows; i++)
	for (j=0; j<cols; j++)
	    sdiff += pow([self valueAtRow:i andColumn:j] - \
			 [other valueAtRow:i andColumn:j],
			 2);

    return sdiff / (rows * cols);

}



- (double) calcMSEwith:(Dynamics *)other
		 ofVar:(int)col
{

    int i;
    int rows = [self rows];
    double sdiff = 0;

    NSAssert((rows == [other rows] && \
	      [self columns] == [other columns]),
	     @"Misaligned matrices");

    for (i=0; i<rows; i++)
	sdiff += pow([self valueAtRow:i andColumn:col] - \
		     [other valueAtRow:i andColumn:col],
		     2);

    return sdiff / rows;

}


- (GSLVector *) calcMSEVector:(Dynamics *)other {

    int row, col;
    int rows = [self rows];
    int cols = [self columns];

    NSAssert((rows == [other rows] && \
	      cols == [other columns]),
	     @"Misaligned matrices");

    // initialize vector of errors
    GSLVector *errors = [GSLVector vectorWithSize:cols];

    // calc MSEs per variable (column)
    for (col=0; col<cols; col++)
	for (row=0; row<rows; row++)
	    [errors addValue:pow([self valueAtRow:row andColumn:col] - \
				 [other valueAtRow:row andColumn:col],
				 2)
		     atIndex:col];

    // calc mean of errors
    [errors divideByValue:rows];

    return errors;

}



@end
