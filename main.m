#import <Foundation/Foundation.h>
#import <unistd.h>

#import "params.h"
#import "aco.h"
#import "common.h"
#import "Dynamics.h"


int main(int argc, char **argv) {

    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    // parse cmd line args (overrides default settings)
    int res = parse_settings(argc, argv);
    if (res) 
    	return -1;

    // initialize RNG
    if (settings.seed)
	settings.rng = [[RNG alloc] initWithSeed:settings.seed];
    else {
	settings.rng = [[RNG alloc] init];
	settings.seed = [settings.rng seed];
    }

	
    // save some stuff in settings.log_path
    if (settings.log_path) {
	// save settings to log_path
	// ** this will also create the directory **
	save_settings();
	// copy data file to log_path
	NSString *dest = [settings.log_path stringByAppendingPathComponent:DATA_FNAME];
	NSString *cmd = [NSString stringWithFormat:@"cp %@ %@", settings.dpath, dest];
	system([cmd UTF8String]);
    }

    // initialize lamda factor vector
    Dynamics *lamda = [[Dynamics alloc] initWithVars:settings.nodes
					  andTPoints:settings.aco_steps];
    // run algorithm
    Solution *solution = netinf(lamda);

    // What to do with solution??
    if (settings.log_path) {
	// save solution in log_path
	[solution save];
	// save lamda vector in log_path
	[lamda saveToFile:[settings.log_path stringByAppendingPathComponent:@"lamda.mat"]];
	// compress log_path??
	if (settings.compress) 
	    compress_dir(settings.log_path);
    } else
	// print solution
	printf("%s\n", [[solution description] UTF8String]);
    

    // release all
    [lamda release];
    [solution release];
    [settings.rng release];
    [settings.tdata release];
    [pool release];
    return 0;

}
