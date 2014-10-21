
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

stream_parser::sptr stream_parser::make(){
	return gnuradio::get_initial_sptr
		(new stream_parser_impl());
}

stream_parser_impl::stream_parser_impl()
	: block("stream_parser",
			io_signature::make(4, 4, sizeof(gr_complex)),
			io_signature::make(4, 4, POW2_CEIL(NUM_STEPS*FFT_SIZE)*sizeof(gr_complex))),
	d_hsn(0), d_hsn_idx(0)
{
	d_output_per_seq = POW2_CEIL(NUM_STEPS*FFT_SIZE);

	data_history.resize(4);
}

stream_parser_impl::~stream_parser_impl(){
}

void stream_parser_impl::forecast(int noutput_items, gr_vector_int &ninput_items_required){
	for(int ii=0; ii < ninput_items_required.size(); ii++){
			ninput_items_required[ii] = noutput_items;
	}
}

int stream_parser_impl::general_work(int noutput_items,
		gr_vector_int &ninput_items,
		gr_vector_const_void_star &input_items,
		gr_vector_void_star &output_items){

	int out_count = 0;
	int output_offset = 0;

	//Loop over all anchors
	for(int ii=0; ii < input_items.size(); ii++){
		const gr_complex *in = (const gr_complex *) input_items[ii];

		//Loop over all new data
		for(int jj=0; jj < ninput_items[ii]; jj++){
			data_history[ii].push_back(in[jj]);
		}

		//Consume items from each input
		consume(ii, ninput_items[ii]);
	}

	//Pop elements off each deque until a subsequent restart is detected
	bool snapshot_flag = true;
	while(snapshot_flag){
		for(int ii=0; ii < input_items.size();){
			while(data_history[ii].size() > SAMPLES_PER_SEQ && data_history[ii][SAMPLES_PER_SEQ].imag() > -1.0){
				data_history[ii].pop_front();
			}
			//Check to see if there is enough data for a full snapshot.
			if(data_history[ii].size() <= SAMPLES_PER_SEQ){
				snapshot_flag = false;
				break;
			} else {
				uint32_t sequence_num = getSequenceNum(data_history[ii][SAMPLES_PER_SEQ-1]);
	
				//In case a sequence number has been skipped, delete any stale data
				if(sequence_num > d_hsn && ii > 0){
					std::cout << "ii = " << ii << " input_items.size() = " << input_items.size() << " SAMPLES_PER_SEQ = " << SAMPLES_PER_SEQ << " sequence_num = " << sequence_num << " imag = " << data_history[ii][SAMPLES_PER_SEQ-1].imag() << " real = " << data_history[ii][SAMPLES_PER_SEQ-1].real() << std::endl;
					d_hsn = sequence_num;
					d_hsn_idx = ii;
					ii = 0;
					continue;
				} else if(sequence_num < d_hsn){
					data_history[ii].erase(data_history[ii].begin(), data_history[ii].begin()+SAMPLES_PER_SEQ-1);
					ii = 0;
					continue;
				}
			}
			ii++;
		}
	
		//If snapshot_flag is set, it means we have a full snapshot and all data is aligned in data_history
		if(snapshot_flag){
			if(out_count < noutput_items){
			for(int ii=0; ii < input_items.size(); ii++){
				for(int jj=0; jj < NUM_STEPS; jj++){
					int cur_data_idx = SKIP_SAMPLES + SAMPLES_PER_FREQ*jj;

					//Have to use std::copy since deque isn't contiguous
					std::copy(data_history[ii].begin() + cur_data_idx, data_history[ii].begin() + (cur_data_idx + FFT_SIZE), ((gr_complex *)(output_items[ii])) + jj*FFT_SIZE+output_offset);
				}
				data_history[ii].erase(data_history[ii].begin(), data_history[ii].begin()+SAMPLES_PER_SEQ-1);
			}
			output_offset += d_output_per_seq;
			out_count++;
			}
	
			////Prepare an outgoing message containing all data
			//pmt::pmt_t new_message_dict = pmt::make_dict();
			//for(int ii=0; ii < input_items.size(); ii++){
			//	pmt::pmt_t key = pmt::from_long((long)(d_packet_id+ii));
			//	pmt::pmt_t value = pmt::init_c32vector(SAMPLES_PER_SEQ, &data_history[d_hsn_idx][0]);
			//	new_message_dict = pmt::dict_add(new_message_dict, key, value);
			//}
			//pmt::pmt_t new_message = pmt::cons(new_message_dict, pmt::PMT_NIL);
			//message_port_pub(pmt::mp("sequence_data_out"), new_message);
		}
	}

	return out_count;
}

uint32_t stream_parser_impl::getSequenceNum(gr_complex data){
	float real_f = data.real()*32767;
	float imag_f = data.imag()*32767;

	uint32_t real = (real_f < 0.0) ? (uint32_t)(real_f + 65536) : (uint32_t)(real_f);
	uint32_t imag = (imag_f < 0.0) ? (uint32_t)(imag_f + 65536) : (uint32_t)(imag_f);
	return real + 65536*imag;
}

} /* namespace fast_square */
} /* namespace gr */
