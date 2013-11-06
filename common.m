#import <Foundation/Foundation.h>
#import <math.h>
#import <stdio.h>
#import <unistd.h> // for chdir()

#import "GSL.h"

#import "common.h"




//=================================================================
//                         CATEGORIES
//=================================================================


@implementation NSArray (Operations)

+ (id) arrayFromArray:(NSArray *)arr withSelector:(SEL)sel {

    int len = [arr count];
    int i;
    NSMutableArray *newarr = [NSMutableArray arrayWithCapacity:len];

    for (i=0; i<len; i++)
	[newarr insertObject:[[arr objectAtIndex:i] performSelector:@selector(sel)] atIndex:i];

    return newarr;
    
}


+ (id) arrayWithRangeFrom:(int)lo
		       to:(int)hi
{

    NSAssert(hi-lo>=0, @"hi-lo should be >= 0");
    NSMutableArray *arr = [NSMutableArray arrayWithCapacity:hi-lo];
    int i;

    for (i=lo; i<hi; i++)
	[arr addObject:[NSNumber numberWithInt:i]];

    return arr;
}



// select and return a random object from self
- (id) selectWithRNG:(RNG *)rng {

    return [self objectAtIndex:[rng getUniformIntWithMax:[self count]]];

}
    



- (NSMutableArray *) select:(int)n
		    withRNG:(RNG *)rng 
{

    return [self select:n
		withRNG:rng
		 andSelectorName:nil];

}




- (NSMutableArray *) select:(int)n
		    withRNG:(RNG *)rng
    	    andSelectorName:(NSString *)sel_name
{


    if (n > [self count])
	return nil;
    
    // create the new array
    NSMutableArray *arr = [NSMutableArray arrayWithCapacity:n];
    // create selector (could be 0x0 if sel_name is nil)
    SEL sel = NSSelectorFromString(sel_name);

    // form array of indices
    NSMutableArray *indices = [NSArray arrayWithRangeFrom:0 
						       to:[self count]];

    while ([arr count] < n)
	if (sel)
	    [arr addObject:[[self objectAtIndex:[[indices popWithRNG:rng] intValue]]
			       performSelector:sel]];
	else
	    [arr addObject:[self objectAtIndex:[[indices popWithRNG:rng] intValue]]];

    return arr;
}



@end




//=================================================================




@implementation NSMutableArray (Operations)

- (id) pop {

    id obj = [[self lastObject] retain];
    if (obj)
	[self removeLastObject];

    return [obj autorelease];

}




- (id) popAtIndex:(int)index {

    id obj = [[self objectAtIndex:index] retain];
    if (obj)
	[self removeObjectAtIndex:index];

    return [obj autorelease];

}


- (id) popWithRNG:(RNG *)rng {

    return [self popAtIndex:[rng getUniformIntWithMax:[self count]]];

}



- (NSMutableArray *) remove:(int)n
	     withRNG:(RNG *)rng
{

    if (n > [self count])
	return nil;

    NSMutableArray *arr = [NSMutableArray arrayWithCapacity:n];

    while ([arr count] < n) 
	[arr addObject:[self popWithRNG:rng]];

    return arr;
}

@end



//=================================================================
// struct and function used in NSString's tokenize: function below

typedef struct {

    NSMutableString *token;
    NSMutableString *rest;

} tuple_t;



void _get_next_token_(tuple_t *tuple) {

    // strip rest
    tuple->rest = [NSMutableString stringByStrippingString:tuple->rest];
    // iterate over string characters
    int i, ctr = 0, len=[tuple->rest length];
    unichar ch;
    for (i=0; i<len; i++) {
	// get character from rest
	ch = [tuple->rest characterAtIndex:i];
	if (ch == '(')
	    ctr += 1; // push parenthesis
	if (ch == ')')
	    ctr -= 1; // pop parenthesis
	// add character to token
	// NSString *ccc = [NSString stringWithFormat:@"%c", ch];
	// printf("%s\n", [ccc UTF8String]);
	// [tuple->token appendString:ccc];
	[tuple->token appendFormat:@"%c", ch];
	if (ctr == 0 && isspace(ch)) {
	    tuple->token = [NSMutableString stringByStrippingString:tuple->token];
	    tuple->rest = (NSMutableString *)[tuple->rest substringFromIndex:i+1]; 
	    return;
	}
    }

    // final token return - strip and return
    tuple->token = [NSMutableString stringByStrippingString:tuple->token];
    tuple->rest = [NSMutableString stringWithString:@""];

}


//=================================================================
//=================================================================

@implementation NSString (Operations)



+ (id) stringByStrippingString:(NSString *)st {

    return [st stringByTrimmingCharactersInSet:
		   [NSCharacterSet whitespaceAndNewlineCharacterSet]];

}


- (NSArray *) tokenize {

    // create array to be returned
    NSMutableArray *tokens = [NSMutableArray array];
    
    if ([self length] == 0 ||  // self should not be empty
	(! ([self characterAtIndex:0] == '(' && // it should start with a '('
	    [self characterAtIndex:[self length]-1] == ')'))) // and end with a ')'
	return tokens;

    tuple_t tuple; 
    NSRange range;
    range.location = 1;
    range.length = [self length] - 2;
    tuple.token = [NSMutableString string];
    tuple.rest = (NSMutableString *)[self substringWithRange:range];
    while (! [tuple.rest isEqualToString:@""]) {
	// parse next token and store it in tuple.token
	// store rest in tuple.rest
	_get_next_token_(&tuple);
	//printf("TOKEN : __%s__\n", [tuple.token UTF8String]);
	// add token to tokens list
	[tokens addObject:tuple.token];
	// reset token
	tuple.token = [NSMutableString string];
    }

    return tokens;

}


@end




//=================================================================
//             A CLASS TO ENCAPSULATE C OBJECTS
//=================================================================
@implementation Capsule

+ (id) capsule:(void *)ptr {

    return [[[Capsule alloc] initWithPointer:ptr]
	       autorelease];

}

- (id) initWithPointer:(void *)ptr_ {

    self = [super init];
    if (!self)
	return nil;

    ptr = ptr_;

    return self;

}


- (void) dealloc {

    free(ptr);
    [super dealloc];

}


- (void *) get {

    return ptr;

}


@end





//=================================================================
//                         COUNTER CLASS
//=================================================================


@implementation Counter


+ (id) counter {

    return [[[Counter alloc] init] autorelease];

}


+ (id) counterWithValue:(int)val_ {

    return [[[Counter alloc] initWithValue:val_] autorelease];
}




- (id) init {

    self = [self initWithValue:0];
    return self;

}


- (id) initWithValue:(int)val_ {

    self = [super init];
    if (!self) 
	return nil;

    val = val_;

    return self;

}


- (void) inc {
    ++val;
}
    
- (void) incWithStep:(int)step {
    val += step;
}


- (void) dec {
    --val;
}


- (void) decWithStep:(int)step {
    val -= step;
}


- (void) updateWith:(Counter *)other {

    val += [other value];

}


- (int) value {
    return val;
}


- (void) reset {

    val = 0;

}



- (NSString *) description {

    return [NSString stringWithFormat:@"%d", val];

}

@end




//=================================================================
//                       A POOL CLASS
//=================================================================




@implementation PoolOfCounters

+ (id) pool {

    return [[[PoolOfCounters alloc] init] autorelease];

}



- (id) init {

    self = [super init];
    if (!self)
	return nil;

    // initialize dictionary
    pool = [[NSMutableDictionary alloc] init];
    totalCount = 0;

    return self;

}


- (void) dealloc {

    [pool release];
    [super dealloc];

}



- (int) count {

    return [pool count];

}



- (int) totalCount {

    return totalCount;

}



- (int) countOf:(id)obj {

    return [(Counter *)[pool objectForKey:obj] value];

}



- (int) countZeroEntries {

    NSArray *values = [pool allValues];
    int i, count = 0;

    for (i=0; i<[values count]; i++)
	if ([(Counter *)[values objectAtIndex:i] value] == 0)
	    count ++;

    return count;

}



- (int) countNonZeroEntries {

    return [self count] - [self countZeroEntries];

}



- (double) proportionOfObject:(id)obj {

    return 1. * [self countOf:obj] / totalCount;

}



- (NSArray *) objects {

    return [pool allKeys];

}




- (void) empty {

    [pool removeAllObjects];

}



// update pool
- (void) inc:(id)obj {

    [self inc:obj by:1];
    // ** totalCount is updated in inc:by:

}



- (void) inc:(id)obj 
	  by:(int)step
{

    // does object exist in pool??
    Counter *cnt = [pool objectForKey:obj];
    if (cnt)
	// yes : increase counter by step
	[cnt incWithStep:step];
    else 
	// no : add entry for object with a count of step
	[pool setObject:[Counter counterWithValue:step]
		 forKey:obj];

    // increase total count
    totalCount += step;
}



- (void) dec:(id)obj {

    [self dec:obj by:1];
    // ** totalCount is updated in dec:by:

}



- (void) dec:(id)obj
	  by:(int)step
{

    // does object exist in pool??
    Counter *cnt = [pool objectForKey:obj];
    if (cnt) {
	NSAssert([cnt value] >= step, @"Error in dec:by:");

	// yes : decrease counter by step
	[cnt decWithStep:step];
	// update totalCount
	totalCount -= step;
	// has count reached 0??
	if ([cnt value] == 0)
	    // remove object from pool
	    [pool removeObjectForKey:obj];
    } else
	// this shouldn't have happened!!
	NSLog(@"Error in Pool dec: object does not exist!");
	
}



- (void) updateWith:(PoolOfCounters *)other {

    NSEnumerator *okeys = [[other objects] objectEnumerator];
    id obj;

    while ((obj = [okeys nextObject]))
	[self inc:obj by:[other countOf:obj]];


}


- (NSString *) description {

    NSMutableString *desc = [NSMutableString string];
    // open parenthesis
    [desc appendString:@"("];

    if (totalCount > 0) {
	NSEnumerator *keys = [pool keyEnumerator];
	id key;

	while ((key = [keys nextObject]))
	    [desc appendFormat:@"(%@ %d) ", 
		  [key description], 
		 [self countOf:key]];

	// remove last space
	NSRange range;
	range.location = [desc length] - 1;
	range.length = 1;
	[desc deleteCharactersInRange:range];
    }

    // close parenthesis
    [desc appendString:@")"];

    return desc;
}

@end



//=================================================================
@implementation PoolOfSums


// initialization / termination
+ (id) pool {

    return [[[PoolOfSums alloc] init] autorelease];

}



- (id) init {

    self = [super init];
    if (!self)
	return nil;

    // initialize dictionary
    pool = [[NSMutableDictionary alloc] init];
    totalSum = 0.;

    return self;

}    


- (void) dealloc {

    [pool release];
    [super dealloc];

}


// get info
- (int) count {

    return [pool count];

}



- (double) totalSum {

    return totalSum;

}



- (double) sumOf:(id)obj {

    return [(NSNumber *)[pool objectForKey:obj] doubleValue];

}



// return the proportion of obj in the pool
// i.e. countOf:obj / totalCount
- (double) proportionOfObject:(id)obj {

    return 1. * [self sumOf:obj] / totalSum;

}



- (NSArray *) objects {

    return [pool allKeys];

}



// remove all entries (empty pool)
- (void) empty {

    [pool removeAllObjects];

}



// update pool



- (void) inc:(id)obj
	  by:(double)amount 
{

    // does object exist in pool??
    NSNumber *sum = [pool objectForKey:obj];
    if (sum)
	// yes : increase sum by amount
	[pool setObject:[NSNumber numberWithDouble:[sum doubleValue] + amount]
		 forKey:obj];
    else 
	// no : add entry for object with a sum of amount
	[pool setObject:[NSNumber numberWithDouble:amount]
		 forKey:obj];

    // increase total sum
    totalSum += amount;


}

- (void) dec:(id)obj
	  by:(double)amount 
{

    // does object exist in pool??
    NSNumber *sum = [pool objectForKey:obj];
    if (sum) {
	// yes : decrease sum by amount
	[pool setObject:[NSNumber numberWithDouble:[sum doubleValue] - amount]
		 forKey:obj];
	// update total sum
	totalSum -= amount;

    } else
	// this shouldn't have happened!!
	NSLog(@"Error in PoolOfSums dec: object does not exist!");

}



// return a description of the pool (object : count)
//- (NSString *) description;


@end




//=================================================================
//                     Useful Functions
//=================================================================



NSString *sec_to_nsstring(long sec) {

    long days, hours, mins;
    ldiv_t res;

    sec = labs(sec);

    //NSLog(@"%ld", sec);
    
    res = ldiv(sec, 60);
    mins = res.quot;
    sec = res.rem;

    res = ldiv(mins, 60);
    hours = res.quot;
    mins = res.rem;

    res = ldiv(hours, 24);
    days = res.quot;
    hours = res.rem;

    return [NSString stringWithFormat:
			 @"%ldd %02ld:%02ld:%02ld", days, hours, mins, sec];

}



// unsigned int urand() {

//     unsigned int val;
//     FILE *fp = fopen("/dev/urandom", "rb");
//     fread(&val, sizeof val, 1, fp);
//     fclose(fp);

//     return val;

// }


unsigned long lurand() {

    unsigned long val;
    FILE *fp = fopen("/dev/urandom", "rb");
    fread(&val, sizeof val, 1, fp);
    fclose(fp);

    return val;

}


int gsl_roulette(const GSLVector *probs, RNG *rng) {

    int i;
    double r, csum;
    int size = [probs count];

    // draw a random number in [0,1]
    r = [rng getUniform];
    // spin the wheel
    csum = 0.;
    for (i=0; i < size; i++) {
	csum += [probs valueAtIndex:i];
	if (r < csum)
	    return i;
    }

    // return last vector index
    return --i;

}


double sigmoid0(double x, double mu, double lamda) {

    return lamda / (1 + exp(- mu * x));

}


double sigmoid1(double x, double mu, double lamda) {

    double h = exp(-mu*x);

    return lamda * (1 - h) / (2 * (1 + h));

}



// // ============= filelines() function ==================

#ifdef __APPLE__

NSArray *filelines(NSString *fname) {


    // read file contents
    NSString *contents = 
	[NSString stringWithContentsOfFile:fname
				  encoding:NSASCIIStringEncoding
				     error:NULL];
    // parse file lines into array
    NSMutableArray *lines = 
	[NSMutableArray arrayWithArray:
			    [contents componentsSeparatedByString:@"\n"]];
    //[NSCharacterSet newlineCharacterSet]]];

    // discard empty lines
    int i;
    for (i=0; i<[lines count]; i++)
	if ([(NSString *)[lines objectAtIndex:i] length] == 0) {
	    [lines removeObjectAtIndex:i];
	    --i;
	}

    return lines;

}	
				   
#elif linux


NSArray *filelines(NSString *fname) {

    FILE *stream = fopen([fname UTF8String], "r");
    // was open successful??
    if (!stream)
	return nil;

    // initialize array
    NSMutableArray *arr = [NSMutableArray array];
    NSCharacterSet *cset = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    char *line = NULL;
    size_t len = 0;
    ssize_t bytes_read;
    NSString *st;


    while ( ( bytes_read = getline(&line, &len, stream)) != -1 ) {
	st = [[NSString stringWithCString:line
				 encoding:NSASCIIStringEncoding]
		 stringByTrimmingCharactersInSet:cset];

	// if the line is empty skip string
	// otherwise add it to array
	if ([st length])
	    [arr addObject:st];
	
    }

    // free the line pointer
    free(line);
    // close file
    fclose(stream);
    return arr;

}

#endif


// a destructor function for objc object (glib style)
void object_release(void *obj) {

    [(id)obj release];

}


// ============= end of filelines() function ==================

// // compress a directory
void compress_dir(NSString *dpath) {

    // change directory
    chdir([[dpath stringByAppendingPathComponent:@".."] UTF8String]);
    // get last path component of log_path for the tar file
    NSString *lpath = [dpath lastPathComponent];
    // generate compressed dir
    NSString *cmd = [NSString stringWithFormat:@"tar cjf %@.tar.bz2 %@/",
			      lpath, lpath];
    system([cmd UTF8String]);
    // delete uncompressed dir
    cmd = [NSString stringWithFormat:@"rm -rf %@/", lpath];
    system([cmd UTF8String]);
    
}




// void g_string_free_func(gpointer data) {

//     g_string_free((GString *)data, TRUE);

// }



// GString *g_string_new_from_file(const char *fname) {

//     // load and read file into string
//     FILE *fp = fopen(fname, "r");
//     // did file open succeed??
//     if (! fp) 
// 	return NULL;

//     // create string of file contents
//     GString *contents = g_string_new(NULL);

//     // read file into contents string
//     char ch;
//     while ((ch = fgetc(fp)) != EOF)
// 	g_string_append_c(contents, ch);

//     // close file
//     fclose(fp);

//     return contents;
// }



// // remove any trailing whitespace from st
// GString *g_string_rstrip(GString *st) {

//     int pos = st->len;
    
//     while (pos--)
// 	if (! isspace(st->str[pos]))
// 	    break;

//     return g_string_set_size(st, pos+1);

// }


// // tokenize a string (C version)
// // returns an array of GString pointers (tokens) by parsing the nested list
// // eg tokenize('((a b) (c d) foo)')
// // yields {'(a b)', '(c d)', 'foo'}
// GPtrArray *g_string_tokenize(GString *st) {

//     GString *get_next_token(int *pos) {
	
// 	int ctr=0;
// 	char ch;
// 	// create token
// 	GString *token = g_string_new(NULL);

// 	while ( (*pos) < st->len - 1 ) {
// 	    ch = st->str[*pos];
// 	    if (ch == '(')
// 		ctr += 1;
// 	    if (ch == ')')
// 		ctr -= 1;
// 	    g_string_append_c(token, ch);
// 	    (*pos)++;
// 	    if (ctr == 0 && isspace(ch)) 
// 		return g_string_rstrip(token);
// 	}

// 	return g_string_rstrip(token);

//     }

//     // check that the supplied string begins and ends with a parenthesis
//     if (st->len <= 2)
// 	return NULL;
//     if ( ! (st->str[0] == '(' && st->str[st->len - 1] == ')') )
// 	return NULL;

//     // initialize the array of tokens
//     //GPtrArray *tokens = g_ptr_array_new_with_free_func(g_string_free_func);
//     GPtrArray *tokens = g_ptr_array_new();
//     // initialize the position
//     int pos = 1; // ignore the opening parenthesis
//     while (pos < st->len - 1) { // ignore the closing parenthesis
// 	g_ptr_array_add(tokens, get_next_token(&pos));
//     }

//     return tokens;

// }
