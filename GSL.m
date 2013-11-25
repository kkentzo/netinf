#import <Foundation/Foundation.h>

#import <gsl/gsl_randist.h>
#import <gsl/gsl_sort_vector.h>
#import <gsl/gsl_statistics_double.h>
#import <stdio.h>

#import "GSL.h"

#import "common.h"




@implementation RNG



+ (id) rng {

  return [[[RNG alloc] init] autorelease];

}



- (id) init {

  self = [super init];
  if (!self)
    return nil;

  // setup gsl environment
  gsl_rng_env_setup();
  // init default generator
  rng = gsl_rng_alloc(gsl_rng_default);
  // get seed
  seed = lurand();
  if (rng) {
    // seed the generator
    gsl_rng_set(rng, seed);
    return self;
  } else
    return nil;
	

}



- (id) initWithSeed:(unsigned long) val {

  self = [self init];
  if (!self)
    return nil;
    
  // seed the generator
  gsl_rng_set(rng, val);
  // save seed
  seed = val;
  return self;
}




- (void) dealloc {
  // free rng
  gsl_rng_free(rng);
  [super dealloc];
}



- (unsigned long) seed {

  return seed;

}



- (gsl_rng *) rng {

  return rng;

}




- (unsigned long) getUniformInt {

  return gsl_rng_get(rng);

}



- (unsigned long) getUniformIntWithMax:(unsigned long)max {

  return gsl_rng_uniform_int(rng, max);

}



// return a random int in [0, max) excluding val
- (unsigned long) getUniformIntWithMax:(unsigned long)max
			excludingValue:(unsigned long)val
{

  unsigned long rnd = [self getUniformIntWithMax:max-1];

  return (rnd < val ? rnd : rnd + 1);

}




- (unsigned int) getPoissonWithRate:(double)rho {

  return gsl_ran_poisson(rng, rho);

}





- (unsigned int) getBinomialWithProb:(double)prob
			   andTrials:(unsigned int)trials
{

  return gsl_ran_binomial(rng, prob, trials);

}




- (double) getUniform {

  return gsl_rng_uniform(rng);

}




- (double) getUniformWithMin:(double)min andMax:(double)max {

  return min + (max-min) * gsl_rng_uniform(rng);

}



- (double) getUniformWithMax:(double)max {
    
  return max * gsl_rng_uniform(rng);

}



- (double) getGaussianWithSigma:(double)sigma {

  return gsl_ran_gaussian(rng, sigma);

}



@end



//====================================================
//====================================================

@implementation GSLVector



+ (id) vectorWithSize:(int)size {

  return [[[GSLVector alloc] initWithSize:size] autorelease];

}


+ (id) vectorWithSize:(int)size
	       andRNG:(RNG *)rng 
{

  GSLVector *vec = [[GSLVector alloc] initWithSize:size];
  int i;
  for (i=0; i<size; i++)
    [vec setValue:[rng getUniform]
	  atIndex:i];

  return [vec autorelease];
}




+ (id) vectorFromCArray:(double *)carr
	       withSize:(size_t)dim
{
  return [[[GSLVector alloc] initFromCArray:carr
				   withSize:dim]
	   autorelease];
}



+ (id) vectorFromFile:(NSString *)fname
	     withSize:(int)size 
{

  return [[[GSLVector alloc] initFromFile:fname
				 withSize:size]
	   autorelease];
}



+ (id) vectorFromFile:(NSString *)fname {
    
  return [[[GSLVector alloc] initFromFile:fname] autorelease];

}




+ (id) vectorFromVector:(GSLVector *)other {

  return [[other copy] autorelease];

}


+ (id) vectorFromArray:(NSArray *)arr
	  withSelector:(SEL)selector 
{

  int i, size = [arr count];
  GSLVector *vec = [[GSLVector alloc] initWithSize:size];
  NSInvocation *inv = [NSInvocation invocationWithMethodSignature:
					      [[arr objectAtIndex:0] methodSignatureForSelector:selector]];
  double *buf = malloc(sizeof(double));

  for (i=0; i<size; i++) {
    // set the target of invocation
    [inv setTarget:[arr objectAtIndex:i]];
    // set the selector
    [inv setSelector:selector];
    // invoke the method
    [inv invoke];
    // copy return value into buf
    [inv getReturnValue:buf];
    // save return value in vector
    [vec setValue:*buf
	  atIndex:i];
  }

  free(buf);
  return [vec autorelease];

}






- (id) init {

  [self dealloc];
  @throw [NSException exceptionWithName:@"BadInitCall"
				 reason:@"Use initWith...: initializers"
			       userInfo:nil];
}



- (id) initWithSize:(int)size {

  // self = [super init];
  // if (!self)
  // 	return nil;

  // allocate vector
  //vec = gsl_vector_calloc(size); // calloc zeroes the vector as well
  return [self initWithVec:gsl_vector_calloc(size)];

}


- (id) initWithVec:(gsl_vector *)v {

  self = [super init];
  if (!self) {
    gsl_vector_free(v);
    return nil;
  }

  vec = v;

  return self;

}



- (id) initFromCArray:(double *)carr
	     withSize:(size_t)dim
{

  self = [self initWithSize:dim];
  if (!self)
    return nil;

  // set the elements
  int i;
  for (i=0; i<dim; i++)
    gsl_vector_set(vec, i, carr[i]);

  return self;
}




// initFromFile functions
- (id) initFromFile:(NSString *)fname
	   withSize:(int)size 
{

  self = [self initWithSize:size];
  if (!self)
    return nil;

  // read file
  FILE *stream = fopen([fname UTF8String], "r");
  if (gsl_vector_fscanf(stream, vec)) {
    // error in reading the file
    [self release];
    self = nil;
  }

  fclose(stream);
  return self;

}



- (id) initFromFile:(NSString *)fname
{

  NSArray *lines = filelines(fname);
  // there should be at least 2 lines in the array
  // i.e. a vector of size 1
  if ([lines count] < 2)
    return nil;
  // read in size
  int size = [[lines objectAtIndex:0] integerValue];
  // initialize vector
  self = [self initWithSize:size];
  if (!self)
    return nil;

  // read in vector
  int i;
  for (i=0; i<size; i++)
    [self setValue:[[lines objectAtIndex:(i+1)] doubleValue]
	   atIndex:i];

  return self;
    
}



- (id) copy {

  // allocate memory for copy
  gsl_vector *newvec = gsl_vector_calloc(vec->size);
  // copy vector elements
  gsl_vector_memcpy(newvec, vec);
  // initialize and return new vector object
  return [[GSLVector alloc] initWithVec:newvec];

}




- (void) dealloc {

  // free vector
  gsl_vector_free(vec);
  [super dealloc];

}




- (const gsl_vector *) vec {

  return vec;

}



- (int) count {

  return vec->size;

}


- (int) size {

  return vec->size;

}



- (void) asort {

  gsl_sort_vector(vec);

}


- (void) dsort {

  gsl_sort_vector(vec);
  gsl_vector_reverse(vec);

}



- (id) fillWithValue:(double)val {

  gsl_vector_set_all(vec, val);
  return self;

}



- (id) fillFromCArray:(double *)arr
	     withSize:(int)length
{

  NSAssert(length <= vec->size, @"Size mismatch!!");
  int i;
  for (i=0; i<length; i++)
    gsl_vector_set(vec, i, arr[i]);
  return self;
}




- (double) valueAtIndex:(int)index {

  return gsl_vector_get(vec, index);

}



- (void) setValue:(double)val atIndex:(int)index {

  gsl_vector_set(vec, index, val);

}


- (void) addValue:(double)val atIndex:(int)index {

  gsl_vector_set(vec, index, val + gsl_vector_get(vec, index));

}


- (void) multiplyWithValue:(double)val atIndex:(int)index {

  gsl_vector_set(vec, index, val * gsl_vector_get(vec, index));

}


- (void) divideByValue:(double)val atIndex:(int)index {

  if (val != 0.)
    gsl_vector_set(vec, index, gsl_vector_get(vec, index) / val);

}


- (void) addValue:(double)val {

  gsl_vector_add_constant(vec, val);

}


- (void) multiplyWithValue:(double)val {

  int i;
  for (i=0; i<vec->size; i++)
    [self multiplyWithValue:val atIndex:i];

}


- (void) divideByValue:(double)val {

  if (val == 0.) 
    return;

  int i;
  for (i=0; i<vec->size; i++)
    [self divideByValue:val atIndex:i];
    
}



- (void) addVector:(GSLVector *)other {

  if ([self isCompatibleTo:other])
    gsl_vector_add(vec, [other vec]);
}



- (void) multiplyWithVector:(GSLVector *)other {

  if ([self isCompatibleTo:other])
    gsl_vector_mul(vec, [other vec]);

}



- (GSLVector *)take:(NSArray *)indices {

  int i, len = [indices count];
  GSLVector *new = [GSLVector vectorWithSize:len];
  double val;

  for (i=0; i<len; i++) {
    val = [self valueAtIndex:[[indices objectAtIndex:i] intValue]];
    [new setValue:val
	  atIndex:i];
  }

  return new;

}





- (double) sum {

  int i, len=[self count];
  double s = 0.;

  for (i=0; i<len; i++)
    s += [self valueAtIndex:i];

  return s;

}

- (double) max {
    
  return gsl_vector_max(vec);

}



- (double) min {

  return gsl_vector_min(vec);

}



- (double) meanOld {

  return [self sum] / [self count];

}


- (double) mean {

  return gsl_stats_mean(vec->data, vec->stride, vec->size);

}



- (double) std {

  return gsl_stats_sd(vec->data, vec->stride, vec->size);

}



- (double) stdWithMean:(double)m {

  return gsl_stats_sd_m(vec->data, vec->stride, vec->size, m);

}


    
- (double) var {

  return gsl_stats_variance(vec->data, vec->stride, vec->size);

}

    
- (double) varWithMean:(double)m {

  return gsl_stats_variance_m(vec->data, vec->stride, vec->size, m);

}



- (BOOL) isCompatibleTo:(GSLVector *)other {

  return [self count] == [other count];
    
}



- (void) dump:(NSString *)fname {

  FILE *stream = fopen([fname UTF8String], "w");
  gsl_vector_fprintf(stream, vec, GSL_VAL_FORMAT);
  fclose(stream);

}



- (void) saveToFile:(NSString *)fname {

  FILE *stream = fopen([fname UTF8String], "w");
  // write size info
  fprintf(stream, "%d\n", [self count]);
  // write the vector
  gsl_vector_fprintf(stream, vec, GSL_VAL_FORMAT);
  // close file
  fclose(stream);

}


- (void) saveToFile:(NSString *)fname withSize:(int)size {

  if (size > vec->size)
    size = vec->size;

  int i;
  FILE *stream = fopen([fname UTF8String], "w");
  for (i=0; i<size; i++) {
    fprintf(stream, GSL_VAL_FORMAT, [self valueAtIndex:i]);
    fprintf(stream, "\n");
  }
  fclose(stream);

}



- (NSString *) description {

  int i;
  int size = [self count];

  NSMutableString *st = [NSMutableString string];

  for (i=0; i<size; i++) 
    [st appendString:
	  [NSString stringWithFormat:@"%.2f ", 
		  [self valueAtIndex:i]]];

  return st;
    

}




@end



//====================================================
//====================================================


@implementation GSLMatrix


+ (id) matrixWithRows:(int)rows andColumns:(int)cols {

  return [[[GSLMatrix alloc] initWithRows:rows
			       andColumns:cols]
	   autorelease];

}



+ (id) meanMatrixFromArray:(NSArray *)marr
		  withRows:(int)rows
		andColumns:(int)cols
{

  GSLMatrix *mean = [GSLMatrix matrixWithRows:rows
				   andColumns:cols];
  NSEnumerator *matrices = [marr objectEnumerator];
  GSLMatrix *mat;

  // add matrices
  while ((mat = [matrices nextObject])) 
    [mean addMatrix:mat];

  // divide by count
  [mean divideByValue:[marr count]];

  return mean;

}



+ (id) varMatrixFromArray:(NSArray *)marr
		 withRows:(int)rows
	       andColumns:(int)cols 
{

  GSLMatrix *var = [GSLMatrix matrixWithRows:rows
				  andColumns:cols];
  NSEnumerator *matrices = [marr objectEnumerator];
  GSLMatrix *mat;

  // we need the mean matrix as well
  GSLMatrix *mean = [GSLMatrix meanMatrixFromArray:marr
					  withRows:rows
					andColumns:cols];

  double m, val;
  int row, col;

  while ((mat = [matrices nextObject])) 
	
    for (row=0; row<rows; row++)
      for (col=0; col<cols; col++) {
	// get mean value
	m = [mean valueAtRow:row
		   andColumn:col];
	// get current value of curreent matrix at row,col
	val = [mat valueAtRow:row andColumn:col];
	// add the square of difference to var entry
	[var addValue:(m-val)*(m-val)
		atRow:row
	    andColumn:col];
      }

  // divide matrix by N
  [var divideByValue:[marr count]];

  return var;
		

}




+ (id) stdMatrixFromArray:(NSArray *)marr
		 withRows:(int)rows
	       andColumns:(int)cols 
{

  // take the variance matrix
  GSLMatrix *var = [GSLMatrix varMatrixFromArray:marr
					withRows:rows
				      andColumns:cols];

  int row, col;
  double val;

  for (row=0; row<rows; row++)
    for (col=0; col<cols; col++) {
      // take the square root of the var entry
      val = sqrt([var valueAtRow:row
		       andColumn:col]);
      [var setValue:val
	      atRow:row
	  andColumn:col];
    }

  return var;

}





+ (id) matrixFromFile:(NSString *)fname
	     withRows:(int)rows
	   andColumns:(int)cols {

  return [[[GSLMatrix alloc] initFromFile:fname
				 withRows:rows
			       andColumns:cols]
	   autorelease];
}


+ (id) matrixFromFile:(NSString *)fname {

  return [[[GSLMatrix alloc] initFromFile:fname] autorelease];

}



+ (id) matrixFromMatrix:(GSLMatrix *)other {

  return [[other copy] autorelease];

}






- (id) init {

  [self dealloc];
  @throw [NSException exceptionWithName:@"BadInitCall"
				 reason:@"Use initWith...: initializers"
			       userInfo:nil];
}



- (id) initWithRows:(int)rows andColumns:(int)cols {

  return [self initWithMatrix:gsl_matrix_calloc(rows, cols)];

}


- (id) initWithMatrix:(gsl_matrix *)mat {

  self = [super init];
  if (!self) {
    gsl_matrix_free(mat);
    return nil;
  }

  matrix = mat;

  return self;
}


- (id) initFromFile:(NSString *)fname
	   withRows:(int)rows
	 andColumns:(int)cols
{

  self = [self initWithRows:rows 
		 andColumns:cols];
  if (!self)
    return nil;

  // read in file
  FILE *stream = fopen([fname UTF8String], "r");
  if (gsl_matrix_fscanf(stream, matrix)) {
    // problem in parsing file
    [self release];
    // assign nil to self
    self = nil;
  }

  // OK, close stream and return self
  fclose(stream);
  return self;

}



- (id) initFromFile:(NSString *)fname {

  NSArray *lines = filelines(fname);
  // there should be at least 3 lines in the array
  // i.e. a matrix of size 1x1
  if ([lines count] < 3)
    return nil;
  // read in rows and columns
  int rows = [[lines objectAtIndex:0] integerValue];
  int cols = [[lines objectAtIndex:1] integerValue];

  // initialize vector
  self = [self initWithRows:rows
		 andColumns:cols];
  if (!self)
    return nil;

  // read in matrix
  int i, j;
  int ctr = 2;
  for (i=0; i<rows; i++)
    for (j=0; j<cols; j++) {
      [self setValue:[[lines objectAtIndex:ctr] doubleValue] 
	       atRow:i
	   andColumn:j];
      ++ctr;
    }

  return self;

}



- (id) copy {

  // allocate memory for copy
  gsl_matrix *newmat = gsl_matrix_calloc(matrix->size1, matrix->size2);
  // copy matrix elements
  gsl_matrix_memcpy(newmat, matrix);
  // initialize and return new matrix object
  return [[GSLMatrix alloc] initWithMatrix:newmat];

}



- (void) dealloc {

  gsl_matrix_free(matrix);
  [super dealloc];

}



- (const gsl_matrix *) matrix {

  return matrix;

}



- (int) rows {

  return matrix->size1;

}

	
- (int) columns {

  return matrix->size2;

}



- (id) fillWithValue:(double)val {

  gsl_matrix_set_all(matrix, val);
  return self;

}



- (double) valueAtRow:(int)row andColumn:(int)col {

  return gsl_matrix_get(matrix, row, col);

}


- (void) setValue:(double)val atRow:(int)row andColumn:(int)col {

  gsl_matrix_set(matrix, row, col, val);

}


- (void) addValue:(double)val atRow:(int)row andColumn:(int)col {

  gsl_matrix_set(matrix, row, col, gsl_matrix_get(matrix, row, col) + val);

}


- (void) multiplyWithValue:(double)val 
		     atRow:(int)row
		 andColumn:(int)col 
{

  gsl_matrix_set(matrix, row, col, val * gsl_matrix_get(matrix, row, col));

}


- (void) divideByValue:(double)val 
		 atRow:(int)row
	     andColumn:(int)col {

  if (val != 0.)
    gsl_matrix_set(matrix, row, col, gsl_matrix_get(matrix, row, col) / val);

}



- (void) addValue:(double)val {

  gsl_matrix_add_constant(matrix, val);

}




- (void) multiplyWithValue:(double)val {

  int i, j;

  for (i=0; i<matrix->size1; i++)
    for (j=0; j<matrix->size2; j++)
      [self multiplyWithValue:val
			atRow:i
		    andColumn:j];

}



- (void) divideByValue:(double)val {

  if (val == 0.)
    return;

  int i, j;

  for (i=0; i<matrix->size1; i++)
    for (j=0; j<matrix->size2; j++)
      [self divideByValue:val
		    atRow:i
		andColumn:j];

}




- (void) addMatrix:(GSLMatrix *)other {

  if ([self isCompatibleTo:other])
    gsl_matrix_add(matrix, [other matrix]);

}




- (void) multiplyMatrix:(GSLMatrix *)other {

  if ([self isCompatibleTo:other])
    gsl_matrix_mul_elements(matrix, [other matrix]);

}




- (void) fillRow:(int)row
       withValue:(double)val
{

  int col;
  for (col=0; col<matrix->size2; col++)
    gsl_matrix_set(matrix, row, col, val);

}


- (void) replaceRow:(int)row
	 fromVector:(GSLVector *)vec
{

  NSAssert(matrix->size2 == [vec count],
	   @"Vector is incompatible with matrix");

  int col;

  for (col=0; col<matrix->size2; col++)
    gsl_matrix_set(matrix, row, col,
		   [vec valueAtIndex:col]);
    
}



- (void) replaceRow:(int)row1 
	    withRow:(int)row2 
	 fromMatrix:(GSLMatrix *)other 
{

  NSAssert([self isCompatibleTo:other],
	   @"Incompatible matrices");
  int col;

  for (col=0; col<matrix->size2; col++)
    gsl_matrix_set(matrix, row1, col, 
		   [other valueAtRow:row2
			   andColumn:col]);
    
}



- (void) fillColumn:(int)col
	  withValue:(double)val
{

  int row;
  for (row=0; row<matrix->size1; row++)
    gsl_matrix_set(matrix, row, col, val);
}



- (void) replaceColumn:(int)col
	    fromVector:(GSLVector *)vec
{

  NSAssert(matrix->size1 == [vec count],
	   @"Vector is incompatible with matrix");

  int row;

  for (row=0; row<matrix->size1; row++)
    gsl_matrix_set(matrix, row, col,
		   [vec valueAtIndex:row]);


}



- (void) replaceColumn:(int)col1
	    withColumn:(int)col2
	    fromMatrix:(GSLMatrix *)other 
{

  NSAssert([self isCompatibleTo:other],
	   @"Incompatible matrices");
  int row;

  for (row=0; row<matrix->size1; row++)
    gsl_matrix_set(matrix, row, col1, 
		   [other valueAtRow:row
			   andColumn:col2]);

}



- (BOOL) isCompatibleTo:(GSLMatrix *)other {

  return (matrix->size1 == [other rows]) && 
    (matrix->size2 == [other columns]);

}
	





- (double) sum {

  int i, j;
  double s = 0;

  for (i=0; i<matrix->size1; i++)
    for (j=0; j<matrix->size2; j++)
      s += gsl_matrix_get(matrix, i, j);

  return s;

}



- (GSLVector *) sumAcrossRows // similar to numpy's sum(axis=0)
{

  GSLVector *vec = [GSLVector vectorWithSize:matrix->size2];
  int row, col;
  double s;

  for (col=0; col<matrix->size2; col++) {
    s = 0;
    for (row=0; row<matrix->size1; row++)
      s += gsl_matrix_get(matrix, row, col);
    [vec setValue:s atIndex:col];
  }

  return vec;
    
}



- (GSLVector *) sumAcrossColumns // similar to numpy's sum(axis=1)
{

  GSLVector *vec = [GSLVector vectorWithSize:matrix->size1];
  int row, col;
  double s;

  for (row=0; row<matrix->size1; row++) {
    s = 0;
    for (col=0; col<matrix->size2; col++)
      s += gsl_matrix_get(matrix, row, col);
    [vec setValue:s atIndex:row];
  }

  return vec;

}




- (double) max {

  return gsl_matrix_max(matrix);

}



- (GSLVector *) maxAcrossRows { // similar to numpy's max(axis=0)

  int i, cols = matrix->size2;
  GSLVector *vec = [GSLVector vectorWithSize:cols];
  gsl_vector_view column;

  for (i=0; i<cols; i++) {
    // get view of i^th column
    column = gsl_matrix_column(matrix, i);
    // find max of column and add it to vec
    [vec setValue:gsl_vector_max(&column.vector)
	  atIndex:i];
  }

  return vec;

}


- (GSLVector *) maxAcrossColumns { // similar to numpy's max(axis=1)

  int i, rows = matrix->size1;
  GSLVector *vec = [GSLVector vectorWithSize:rows];
  gsl_vector_view row;

  for (i=0; i<rows; i++) {
    // get view of i^th column
    row = gsl_matrix_row(matrix, i);
    // find max of row and add it to vec
    [vec setValue:gsl_vector_max(&row.vector)
	  atIndex:i];
  }

  return vec;

}




- (double) min {

  return gsl_matrix_min(matrix);

}



- (GSLVector *) minAcrossRows { // similar to numpy's min(axis=0)

  int i, cols = matrix->size2;
  GSLVector *vec = [GSLVector vectorWithSize:cols];
  gsl_vector_view column;

  for (i=0; i<cols; i++) {
    // get view of i^th column
    column = gsl_matrix_column(matrix, i);
    // find min of column and add it to vec
    [vec setValue:gsl_vector_min(&column.vector)
	  atIndex:i];
  }

  return vec;

}


- (GSLVector *) minAcrossColumns { // similar to numpy's min(axis=1)

  int i, rows = matrix->size1;
  GSLVector *vec = [GSLVector vectorWithSize:rows];
  gsl_vector_view row;

  for (i=0; i<rows; i++) {
    // get view of i^th column
    row = gsl_matrix_row(matrix, i);
    // find min of row and add it to vec
    [vec setValue:gsl_vector_min(&row.vector)
	  atIndex:i];
  }

  return vec;

}



- (double) mean {

  return [self sum] / (matrix->size1 * matrix->size2);

}
//- (double) std;



- (void) dump:(NSString *)fname {

  FILE *stream = fopen([fname UTF8String], "w");
  gsl_matrix_fprintf(stream, matrix, GSL_VAL_FORMAT);
  fclose(stream);

}



- (void) saveToFile:(NSString *)fname {

  FILE *stream = fopen([fname UTF8String], "w");
  // write rows and columns info
  fprintf(stream, "%d\n%d\n", [self rows], [self columns]);
  // write the vector
  gsl_matrix_fprintf(stream, matrix, GSL_VAL_FORMAT);
  // close file
  fclose(stream);


}


- (NSString *) description {

  int i, j;
  int rows = matrix->size1;
  int cols = matrix->size2;

  NSMutableString *st = [NSMutableString string];

  for (i=0; i<rows; i++) {
    for (j=0; j<cols; j++)
      [st appendString:
	    [NSString stringWithFormat:@"%.5e ", 
		      [self valueAtRow:i
			     andColumn:j]]];
    if (i<rows-1)
      [st appendString:@"\n"];
  }

  return st;
    

}


@end
