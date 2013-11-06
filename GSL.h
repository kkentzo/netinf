#import <Foundation/Foundation.h>
#import <gsl/gsl_rng.h>
#import <gsl/gsl_vector.h>
#import <gsl/gsl_matrix.h>
#import <gsl/gsl_math.h>
#import <time.h>


#define GSL_VAL_FORMAT "%.5e"
#define ROW_SEP "\n"
#define COL_SEP "\t"


//====================================================
//====================================================
@interface RNG : NSObject {

    unsigned long seed;
    gsl_rng *rng;

}


+ (id) rng;

- (id) init;
- (id) initWithSeed:(unsigned long)val;
- (void) dealloc;

// accessor
- (unsigned long) seed;
- (gsl_rng *) rng;

// upper range limits are open!!

// return a random int
- (unsigned long) getUniformInt;

// return a random int in [0, max)
- (unsigned long) getUniformIntWithMax:(unsigned long)max;

// return a random int in [0, max) excluding val
// algorithm found in http://stackoverflow.com/questions/6443176/how-can-i-generate-a-random-number-within-a-range-but-exclude-some
- (unsigned long) getUniformIntWithMax:(unsigned long)max
			excludingValue:(unsigned long)val;

// return an int from the Poisson distribution
- (unsigned int) getPoissonWithRate:(double)rho;

// return an int from the binomial distribution
- (unsigned int) getBinomialWithProb:(double)prob
			   andTrials:(unsigned int)trials;


// return a random double in [0,1)
- (double) getUniform;

// return a random double in [min, max)
- (double) getUniformWithMin:(double)min andMax:(double)max;

// return a random double in [0,max)
- (double) getUniformWithMax:(double)max;

// return a double from the gaussian distribution with mu=0
- (double) getGaussianWithSigma:(double)sigma;

@end




//====================================================
//====================================================



@interface GSLVector : NSObject {

    gsl_vector *vec;

}


+ (id) vectorWithSize:(int)size;
+ (id) vectorWithSize:(int)size
	       andRNG:(RNG *)rng;
+ (id) vectorFromCArray:(double *)carr
	       withSize:(size_t)dim;
+ (id) vectorFromFile:(NSString *)fname
	     withSize:(int)size;
+ (id) vectorFromFile:(NSString *)fname;
+ (id) vectorFromVector:(GSLVector *)other;
+ (id) vectorFromArray:(NSArray *)arr
	  withSelector:(SEL)selector;



- (id) init; // DO NOT USE : raises Exception
- (id) initWithSize:(int)size;
- (id) initWithVec:(gsl_vector *)v; // DESIGNATED
- (id) initFromCArray:(double *)carr
	     withSize:(size_t)dim;


// initFromFile functions
- (id) initFromFile:(NSString *)fname
	   withSize:(int)size;
- (id) initFromFile:(NSString *)fname;

- (id) copy;

- (void) dealloc;

- (const gsl_vector *) vec;

- (int) count;
- (int) size; // synonymous with count

- (void) asort; // sort elements in place in ascending order
- (void) dsort; // sort elements in place in descending order

- (id) fillWithValue:(double)val;

- (id) fillFromCArray:(double *)arr
	     withSize:(int)length;

- (double) valueAtIndex:(int)index;
- (void) setValue:(double)val atIndex:(int)index;
- (void) addValue:(double)val atIndex:(int)index;
- (void) multiplyWithValue:(double)val atIndex:(int)index;
- (void) divideByValue:(double)val atIndex:(int)index;

- (void) addValue:(double)val;
- (void) multiplyWithValue:(double)val;
- (void) divideByValue:(double)val;

- (void) addVector:(GSLVector *)other;
- (void) multiplyWithVector:(GSLVector *)other;

- (GSLVector *)take:(NSArray *)indices;

- (double) sum;
- (double) max;
- (double) min;

// statistical measures
- (double) meanOld; // mean
- (double) mean; // mean
- (double) std; // standard deviation
- (double) stdWithMean:(double)m;
- (double) var; // variance
- (double) varWithMean:(double)m;

- (BOOL) isCompatibleTo:(GSLVector *)other;

// save vector to file (txt format)
- (void) dump:(NSString *)fname;
// save vector to file (including size info)
- (void) saveToFile:(NSString *)fname;
// save first SIZE elements of vector to file (txt format)
- (void) saveToFile:(NSString *)fname withSize:(int)size;

- (NSString *) description;

@end

//====================================================
//====================================================



@interface GSLMatrix : NSObject {

    gsl_matrix *matrix;

}


+ (id) matrixWithRows:(int)rows andColumns:(int)cols;
+ (id) meanMatrixFromArray:(NSArray *)marr
		  withRows:(int)rows
		andColumns:(int)cols;
+ (id) varMatrixFromArray:(NSArray *)marr
		 withRows:(int)rows
	       andColumns:(int)cols;
+ (id) stdMatrixFromArray:(NSArray *)marr
		 withRows:(int)rows
	       andColumns:(int)cols;

+ (id) matrixFromFile:(NSString *)fname
	     withRows:(int)rows
	   andColumns:(int)cols;
+ (id) matrixFromFile:(NSString *)fname;
+ (id) matrixFromMatrix:(GSLMatrix *)mat;


- (id) init; // DO NOT USE : raises Exception
- (id) initWithRows:(int)rows andColumns:(int)cols;
- (id) initWithMatrix:(gsl_matrix *)mat; // DESIGNATED

- (id) initFromFile:(NSString *)fname
	   withRows:(int)rows
	 andColumns:(int)cols;
- (id) initFromFile:(NSString *)fname;

- (id) copy;

- (void) dealloc;

- (const gsl_matrix *) matrix;

- (int) rows;
- (int) columns;

- (id) fillWithValue:(double)val;

- (double) valueAtRow:(int)row andColumn:(int)col;
- (void) setValue:(double)val atRow:(int)row andColumn:(int)col;
- (void) addValue:(double)val atRow:(int)row andColumn:(int)col;


- (void) multiplyWithValue:(double)val 
		     atRow:(int)row
		 andColumn:(int)col;

- (void) divideByValue:(double)val 
		 atRow:(int)row
	     andColumn:(int)col;


- (void) addValue:(double)val;
- (void) multiplyWithValue:(double)val;
- (void) divideByValue:(double)val;


- (void) addMatrix:(GSLMatrix *)other;
- (void) multiplyMatrix:(GSLMatrix *)other;


- (void) fillRow:(int)row
       withValue:(double)val;

- (void) replaceRow:(int)row
	 fromVector:(GSLVector *)vec;

- (void) replaceRow:(int)row1 
	    withRow:(int)row2 
	 fromMatrix:(GSLMatrix *)other;


- (void) fillColumn:(int)col
       withValue:(double)val;

- (void) replaceColumn:(int)col
	    fromVector:(GSLVector *)vec;

- (void) replaceColumn:(int)col1
	    withColumn:(int)col2
	    fromMatrix:(GSLMatrix *)other;


- (BOOL) isCompatibleTo:(GSLMatrix *)other;

- (double) sum;
- (GSLVector *) sumAcrossRows; // similar to numpy's sum(axis=0)
- (GSLVector *) sumAcrossColumns; // similar to numpy's sum(axis=1)

- (double) max;
- (GSLVector *) maxAcrossRows; // similar to numpy's max(axis=0)
- (GSLVector *) maxAcrossColumns; // similar to numpy's max(axis=1)

- (double) min;
- (GSLVector *) minAcrossRows; // similar to numpy's min(axis=0)
- (GSLVector *) minAcrossColumns; // similar to numpy's min(axis=1)
- (double) mean;
//- (double) std;


- (void) dump:(NSString *)fname;
- (void) saveToFile:(NSString *)fname;

- (NSString *) description;

@end
