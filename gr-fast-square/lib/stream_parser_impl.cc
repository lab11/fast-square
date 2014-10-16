
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
			io_signature::make(4, 4, POW2_CEIL(FFT_SIZE)*sizeof(gr_complex)))
{
//	//Register message port for outgoing data packets
//	message_port_register_out(pmt::mp("sequence_data_out"));

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

	gr_complex *out = (gr_complex *) output_items[0];
	int out_count = 0;

	//Loop over all anchors
	for(int ii=0; ii < input_items.size(); ii++){
		const gr_complex *in = (const gr_complex *) input_items[ii];

		//Loop over all new data
		for(int jj=0; jj < ninput_items[ii]; jj++){
			data_history[ii].push_back(in[jj]);
		}
	}

	//Pop elements off each deque until a subsequent restart is detected
	bool snapshot_flag = true;
	uint32_t hsn = 0; //hsn = highest sequence num
	int hsn_idx = 0;
	while(snapshot_flag){
		for(int ii=0; ii < input_items.size();){
			while(data_history[ii].size() > SAMPLES_PER_SEQ && data_history[ii][SAMPLES_PER_SEQ].imag() == -1.0){
				data_history[ii].pop_front();
			}
			//Check to see if there is enough data for a full snapshot.
			if(data_history[ii].size() <= SAMPLES_PER_SEQ){
				snapshot_flag = false;
				break;
			} else {
				uint32_t sequence_num = getSequenceNum(data_history[ii][SAMPLES_PER_SEQ-1]);
				std::cout << "sequence_num = " << sequence_num << std::endl;
	
				//In case a sequence number has been skipped, delete any stale data
				if(sequence_num > hsn && ii > 0){
					data_history[hsn_idx].erase(data_history[hsn_idx].begin(), data_history[hsn_idx].begin()+SAMPLES_PER_SEQ);
					ii = 0;
					continue;
				} else if(sequence_num < hsn){
					data_history[ii].erase(data_history[ii].begin(), data_history[ii].begin()+SAMPLES_PER_SEQ);
					ii = 0;
					continue;
				}
			}
			ii++;
		}
	
		//If snapshot_flag is set, it means we have a full snapshot and all data is aligned in data_history
		if(snapshot_flag){
			for(int ii=0; ii < input_items.size(); ii++){
				memcpy(((gr_complex *) output_items[ii]), &data_history[ii][0], FFT_SIZE*sizeof(gr_complex));
			}
			out_count++;
	
			////Prepare an outgoing message containing all data
			//pmt::pmt_t new_message_dict = pmt::make_dict();
			//for(int ii=0; ii < input_items.size(); ii++){
			//	pmt::pmt_t key = pmt::from_long((long)(d_packet_id+ii));
			//	pmt::pmt_t value = pmt::init_c32vector(SAMPLES_PER_SEQ, &data_history[hsn_idx][0]);
			//	new_message_dict = pmt::dict_add(new_message_dict, key, value);
			//}
			//pmt::pmt_t new_message = pmt::cons(new_message_dict, pmt::PMT_NIL);
			//message_port_pub(pmt::mp("sequence_data_out"), new_message);
		}
	}

	return out_count;
}

uint32_t stream_parser_impl::getSequenceNum(gr_complex data){
	uint32_t real = (uint32_t)(data.real()*32767+65536);
	uint32_t imag = (uint32_t)(data.imag()*32767+65536);
	return real + 65536*imag;
}

} /* namespace fast_square */
} /* namespace gr */
