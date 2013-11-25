

//=================================================================
//                         CATEGORIES
//=================================================================

@interface NSArray (Operations)

+ (id) arrayFromArray:(NSArray *)arr withSelector:(SEL)sel;

// return an array with the NSNumbers from lo
// up to (and excluding) hi
+ (id) arrayWithRangeFrom:(int)lo
                       to:(int)hi;

// select and return a random object from self
- (id) selectWithRNG:(RNG *)rng;

// select n unique objects chosen at random from the array
// and return them in a new array
- (NSMutableArray *) select:(int)n
                    withRNG:(RNG *)rng;

// select n unique objects chosen at random from the array
// perform sel on them and add the resulting objects
// to a new array
- (NSMutableArray *) select:(int)n
                    withRNG:(RNG *)rng
            andSelectorName:(NSString *)sel_name;


@end


//=================================================================


@interface NSMutableArray (Operations)

// remove and return the array's last object
- (id) pop;

// remove and return the array's i^th object
- (id) popAtIndex:(int)index;

// remove and return a random object from the array
- (id) popWithRNG:(RNG *)rng;

// remove n unique objects chosen at random from the array
// and return them in a new array
- (NSMutableArray *) remove:(int)n
withRNG:(RNG *)rng;

@end



//=================================================================


@interface NSString (Operations)

// return a new (autoreleased) string by stripping st
+ (id) stringByStrippingString:(NSString *)st;

// tokenize a string -- see also tokenize() in pylib/utils.py
// returns an array of the String tokens by parsing the nested list
// eg tokenize('((a b) (c d) foo)')
// yields {'(a b)', '(c d)', 'foo'}
- (NSArray *) tokenize;


@end



//=================================================================
//                     A COUNTER CLASS
//=================================================================


@interface Counter : NSObject {

  int val;

}


+ (id) counter;
+ (id) counterWithValue:(int)val_;


- (id) init;
- (id) initWithValue:(int)val_;

- (void) inc;
- (void) incWithStep:(int)step;

- (void) dec;
- (void) decWithStep:(int)step;

- (void) updateWith:(Counter *)other; // add other to self

- (int) value;
- (void) reset;

- (NSString *) description;

@end



//=================================================================
//                     POOL CLASSES
//=================================================================
// Implements a pool of counted objects as a dictionary, with
// objects as keys and Counter objects as values


@interface PoolOfCounters : NSObject {

  NSMutableDictionary *pool;
  int totalCount;

}


// initialization / termination
+ (id) pool;
- (id) init;

- (void) dealloc;

// get info

// return the number of keys
- (int) count; 

// return the total count of occurences
- (int) totalCount; 

// return the count of obj
- (int) countOf:(id)obj; 

// return number of objects that correspond to zero values
- (int) countZeroEntries; 

// return number of objects that do not correspond to zero values
- (int) countNonZeroEntries;

// return the proportion of obj in the pool
// i.e. countOf:obj / totalCount
- (double) proportionOfObject:(id)obj; 

// return an array with all the objects (keys)
- (NSArray *) objects; 

// remove all entries (empty pool)
- (void) empty;

// update pool
- (void) inc:(id)obj;
- (void) inc:(id)obj
by:(int)step;
- (void) dec:(id)obj;
- (void) dec:(id)obj
by:(int)step;


// updates self with other's entries (obj,counter pairs)
- (void) updateWith:(PoolOfCounters *)other;

// return a description of the pool in a nested parentheses format
- (NSString *) description;


@end



//=================================================================
@interface PoolOfSums : NSObject {

  NSMutableDictionary *pool;
  double totalSum;

}


// initialization / termination
+ (id) pool;
- (id) init;

- (void) dealloc;

// get info
- (int) count; // return the number of keys
- (double) totalSum; // return the total sum
- (double) sumOf:(id)obj; // return the sum of obj

// return the proportion of obj in the pool
// i.e. countOf:obj / totalCount
- (double) proportionOfObject:(id)obj; 

- (NSArray *) objects; // return an array with all the objects (keys)

// remove all entries (empty pool)
- (void) empty;

// update pool
- (void) inc:(id)obj
by:(double)amount;

- (void) dec:(id)obj
by:(double)amount;



// return a description of the pool (object : count)
//- (NSString *) description;


@end


//=================================================================
//                     Useful Functions
//=================================================================


// converts seconds to a string of the form "Dd HH:MM:SS"
NSString *sec_to_nsstring(long sec);

// returns a random integer from /dev/urandom
//unsigned int urand();

// returns a random long from /dev/urandom
unsigned long lurand();

// returns an index of vec -- roulette wheel selection
// CAREFUL :: sum(probs) should be 1 - no check is performed
int gsl_roulette(const GSLVector *probs, RNG *rng);

// define default values for mu and lamda in sigmoidal functions
#define SIG_MU 1.
#define SIG_LAMDA 1.

// sigmoid (logistic) function -- result in (0, lamda)
// lamda is the scaling factor, mu the steepness of the curve
double sigmoid0(double x, double mu, double lamda);

// sigmoid (logistic) function -- result in (-lamda/2, lamda/2)
// lamda is the scaling factor, mu the steepness of the curve
double sigmoid1(double x, double mu, double lamda);

// parse a file line-by-line and store lines as strings in an array
// lines are stripped (i.e. no \n and whitespace at the edges)
NSArray *filelines(NSString *fname);

// compress a directory
void compress_dir(NSString *dpath);

// a destructor function for objc object (glib style)
void object_release(void *obj);


// =================== GSTRING FUNCTIONS =======================

//GString *g_string_new_from_file(const char *fname);

// remove any trailing whitespace from st
//GString *g_string_rstrip(GString *st);

// tokenize a string (C version)
// returns an array of GString pointers (tokens) by parsing the nested list
// eg tokenize('((a b) (c d) foo)')
// yields {'(a b)', '(c d)', 'foo'}
//GPtrArray *g_string_tokenize(GString *st);
