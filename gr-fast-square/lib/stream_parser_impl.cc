
#ifdef HAVE_CONFIG_H
#include "config.h"
#endif

#include "stream_parser_impl.h"
#include <gnuradio/io_signature.h>
#include <cstdio>
#include <string>
#include <fstream>

namespace gr {
namespace fast_square {

freq_stitcher::sptr freq_stitcher::make(){
	return gnuradio::get_initial_sptr
		(new stream_parser_impl());
}

stream_parser_impl::stream_parser_impl()
	: sync_block("stream_parser",
			io_signature::make(4, 4, sizeof(gr_complex)),
			io_signature::make(0, 0, sizeof(gr_complex)))
{
	sequence_nums = new int[4];
	cur_sequence = 0;
	sequence_data.resize(4);
}

stream_parser_impl::~stream_parser_impl(){
}

int stream_parser_impl::work(int noutput_items,
		gr_vector_const_void_star &input_items,
		gr_vector_void_star &output_items){

	gr_complex *out = (gr_complex *) output_items[0];
	int count=0;
	int out_count = 0;

	for(int ii=0; ii < input_items.size(); ii++){
		const gr_complex *in = (const gr_complex *) input_items[ii];
		for(int jj=0; jj < noutput_items; jj++){
			if(in[jj].real() == -1.0){
			
			}
		}
	}

	return noutput_items;
}

} /* namespace fast_square */
} /* namespace gr */
