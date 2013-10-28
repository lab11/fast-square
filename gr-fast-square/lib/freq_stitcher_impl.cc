
#ifdef HAVE_CONFIG_H
#include "config.h"
#endif

#include "freq_stitcher_impl.h"
#include <gnuradio/io_signature.h>
#include <cstdio>
#include <string>
#include <fstream>

#define STATE_RESET 0
#define STATE_RCV 1
#define STATE_DONE 2

namespace gr {
namespace fast_square {

freq_stitcher::sptr freq_stitcher::make(std::string cal_file, unsigned int num_freqs){
	return gnuradio::get_initial_sptr
		(new freq_stitcher_impl(cal_file, num_freqs));
}

freq_stitcher_impl::freq_stitcher_impl(std::string cal_file, unsigned int in_num_freqs)
	: sync_block("freq_stitcher",
			io_signature::make(1, 1, sizeof(gr_complex)),
			io_signature::make(0, 1, sizeof(gr_complex))),
	num_freqs(in_num_freqs)
{
	state = STATE_RESET;
	readCal(cal_file);
}

freq_stitcher_impl::~freq_stitcher_impl(){
}

void freq_stitcher_impl::readCal(std::string in_cal_file){
	std::ifstream calfile(in_cal_file.c_str());
	for(unsigned int ii=0; ii < num_freqs; ii++){
		float real, imag;
		calfile >> real >> imag;
		cal_data.push_back(gr_complex(real, imag));
//		std::cout << "cal_data[" << ii << "] = " << cal_data[cal_data.size()-1] << std::endl;
	}
	calfile.close();
//	std::cout << "num_freqs = " << num_freqs << std::endl;
}

int freq_stitcher_impl::work(int noutput_items,
		gr_vector_const_void_star &input_items,
		gr_vector_void_star &output_items){

	const gr_complex *in = (const gr_complex *) input_items[0];
	//gr_complex *out = (gr_complex *) output_items[0];
	int count=0;
	int out_count = 0;

	while(count < noutput_items){
		//Format of data: 0x8000 .... data0_0 data1_0 data2_0 data3_0 0x0000 ... data0_1 data1_1 data2_1 data3_1 0x000 ....
		gr_complex cur_data = in[count++];
		switch(state){
			case STATE_RESET:
				
				//Wait here until we receive something other than (-1,-1)'s
				if(cur_data.imag() != -1.0 || cur_data.real() != -1.0){
					subfreq_idx = 0;
					state = STATE_RCV;
				} else 
					break;
				//NOTE: This falls through to next state

			case STATE_RCV:
				if(cur_data.imag() == -1.0 && (cur_data.real() == -1.0 || cur_data.real() == 0.0)){
					if(subfreq_idx >= num_freqs)
						state = STATE_DONE;
				} else {
					cur_data = cur_data/cal_data[subfreq_idx++];
					//out[out_count++] = cur_data/cal_data[subfreq_idx++];
				}
				break;

			case STATE_DONE:
				//Wait here until we receive (-1,-1)'s again
				if(cur_data.imag() == -1.0 && cur_data.real() == -1.0)
					state = STATE_RESET;
				break;

		}
	}   // while

	return noutput_items;
}

} /* namespace fast_square */
} /* namespace gr */
