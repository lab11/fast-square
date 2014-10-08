
#ifdef HAVE_CONFIG_H
#include "config.h"
#endif

#include "prf_estimator_impl.h"
#include <gnuradio/io_signature.h>
#include <cstdio>
#include <string>
#include <fstream>

namespace gr {
namespace fast_square {

prf_estimator::sptr prf_estimator::make(){
	return gnuradio::get_initial_sptr
		(new prf_estimator_impl());
}

prf_estimator_impl::prf_estimator_impl()
	: sync_block("prf_estimator",
			io_signature::make(1, 1, sizeof(gr_complex)),
			io_signature::make(0, 1, sizeof(gr_complex)))
{
}

prf_estimator_impl::~prf_estimator_impl(){
}

int prf_estimator_impl::work(int noutput_items,
		gr_vector_const_void_star &input_items,
		gr_vector_void_star &output_items){

	const gr_complex *in = (const gr_complex *) input_items[0];
	gr_complex *out = (gr_complex *) output_items[0];
	int count=0;
	int out_count = 0;

	while(count < noutput_items){
	}   // while

	return noutput_items;
}

} /* namespace fast_square */
} /* namespace gr */
