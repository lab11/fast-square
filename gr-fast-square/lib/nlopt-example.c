#include <math.h>
#include <nlopt.h>
#include <iostream>
#include <time.h>

#define NUM_ANCHORS 4
#define NUM_ANTENNAS 5
#define TOT_ANTENNAS (NUM_ANCHORS*NUM_ANTENNAS)

typedef struct {
	float toas[TOT_ANTENNAS];
	float anchor_positions_x[TOT_ANTENNAS];
	float anchor_positions_y[TOT_ANTENNAS];
	float anchor_positions_z[TOT_ANTENNAS];
} my_function_data;

double myfunc(unsigned n, const double *x, double *grad, void *my_func_data)
{
	int ii,jj;
	double px = x[0];
	double py = x[1];
	double pz = x[2];
	double t = x[3];
	my_function_data *func_data = (my_function_data*)my_func_data;
	//std::cout << px << std::endl;
	//std::cout << py << std::endl;
	//std::cout << pz << std::endl;
	//std::cout << t << std::endl;
	//std::cout << grad << std::endl;

	double error_cum = 0.0;
	for(ii=0; ii < NUM_ANCHORS; ii++){
		for(jj=0; jj < NUM_ANTENNAS; jj++){
			int cur_idx = ii + jj*NUM_ANCHORS;
			error_cum += pow(sqrt((pow(px-func_data->anchor_positions_x[cur_idx],2) + 
			                       pow(py-func_data->anchor_positions_y[cur_idx],2) + 
			                       pow(pz-func_data->anchor_positions_z[cur_idx],2))) - (func_data->toas[cur_idx] - t),2);
			//std::cout << "cur_idx = " << cur_idx << " error_cum = " << error_cum << std::endl;
		}
	}
	//std::cout << "GOT CALLED, error_cum = " << error_cum << std::endl;
	
	return error_cum;
}

typedef struct {
    double a, b;
} my_constraint_data;

double myconstraint(unsigned n, const double *x, double *grad, void *data)
{
    my_constraint_data *d = (my_constraint_data *) data;
    double a = d->a, b = d->b;
    if (grad) {
        grad[0] = 3 * a * (a*x[0] + b) * (a*x[0] + b);
        grad[1] = -1.0;
    }
    return ((a*x[0] + b) * (a*x[0] + b) * (a*x[0] + b) - x[1]);
 }

int main(){
	int ii;
	//double lb[2] = { -HUGE_VAL, 0 }; /* lower bounds */
	nlopt_opt opt;
	
	opt = nlopt_create(NLOPT_LN_BOBYQA, 4); /* algorithm and dimensionality */
	//nlopt_set_lower_bounds(opt, lb);
	my_function_data objective_data = {
		{ 39.4969, 33.4257, 40.6328, 12.6834, 39.2581, 33.4527, 40.7725, 12.7014, 39.2400, 33.4708, 40.6238, 12.7330, 39.2445, 33.4302, 40.6328, 12.6608, 39.2851, 33.6195, 40.6643, 12.6744
		},
		{ 2.4250, 2.1360, 4.1060, 0.2130, 2.4250, 2.1240, 4.1060, 0.3110, 2.4250, 2.0440, 4.1060, 0.2610, 2.4000, 2.0440, 4.0440, 0.2610, 2.3340, 2.0440, 4.0850, 0.2610
		},
		{ 3.9100, 0.2500, 0.3730, 0.3280, 3.9100, 0.2470, 0.3730, 0.3280, 3.9100, 0.2390, 0.3730, 0.3280, 3.8080, 0.2390, 0.2910, 0.3280, 3.8550, 0.2390, 0.3450, 0.3280},
		{ 3.0080, 2.4790, 1.5220, 1.5360, 3.0080, 2.3840, 1.5220, 1.5360, 3.0080, 2.4390, 1.5220, 1.6250, 3.0080, 2.4390, 1.5360, 1.6250, 2.9450, 2.4390, 1.6150, 1.6250}
	};

	double measured_toa_errors[NUM_ANCHORS] = { 0, -3.0640, 2.8593, -25.1411 };

	for(ii=0; ii < NUM_ANCHORS*NUM_ANTENNAS; ii++)
		objective_data.toas[ii] -= measured_toa_errors[ii%NUM_ANCHORS];

	double prf_est = 3.999974964000008e+06;
	double target_toa = objective_data.toas[0];
	double mod_dist = 3e8/prf_est;
	for(ii=1; ii < NUM_ANCHORS*NUM_ANTENNAS; ii++){
		double cand_toa = objective_data.toas[ii];
		while(cand_toa < target_toa - mod_dist/2)
			cand_toa += mod_dist;
		while(cand_toa > target_toa + mod_dist/2)
			cand_toa -= mod_dist;
		objective_data.toas[ii] = cand_toa;
	}

	nlopt_set_min_objective(opt, myfunc, &objective_data);
	
	//my_constraint_data data[2] = { {2,0}, {-1,1} };
	
	//nlopt_add_inequality_constraint(opt, myconstraint, &data[0], 1e-8);
	//nlopt_add_inequality_constraint(opt, myconstraint, &data[1], 1e-8);
	
	nlopt_set_xtol_rel(opt, 1e-6);
	
	double x[4] = { 2.0, 2.0, 1.0, objective_data.toas[0] };  /* some initial guess */
	double minf; /* the minimum objective value, upon return */
	
	clock_t t;
	t = clock();
	if (nlopt_optimize(opt, x, &minf) < 0) {
	    std::cout << "nlopt failed!" << std::endl;
	}
	else {
	    std::cout << "found minimum at f(" << x[0] << "," << x[1] << "," << x[2] << ") = " << minf << std::endl;
	}
	t = clock() - t;
	std::cout << "took " << t << " clicks (" << ((float)t)/CLOCKS_PER_SEC << " seconds)" << std::endl;
	
	nlopt_destroy(opt);

}
