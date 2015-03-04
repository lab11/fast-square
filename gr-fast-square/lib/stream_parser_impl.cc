
#ifdef HAVE_CONFIG_H
#include "config.h"
#endif

#include "stream_parser_impl.h"
#include <gnuradio/io_signature.h>
#include <volk/volk.h>
#include <cstdio>
#include <string>
#include <sys/time.h>

namespace gr {
namespace fast_square {

stream_parser::sptr stream_parser::make(){
	return gnuradio::get_initial_sptr
		(new stream_parser_impl());
}

stream_parser_impl::stream_parser_impl()
	: block("stream_parser",
			io_signature::make(4, 4, sizeof(gr_complex)),
			io_signature::make(0, 4, POW2_CEIL(NUM_STEPS*FFT_SIZE)*sizeof(gr_complex))),
	d_hsn(0), d_hsn_idx(0)
{
	d_output_per_seq = POW2_CEIL(NUM_STEPS*FFT_SIZE);

	for(int ii=0; ii < 4; ii++)
		d_restarted[ii] = false;
	d_wait_for_restart = false;

	data_history.resize(4);

	const int alignment_multiple =
		volk_get_alignment() / sizeof(float);
	set_alignment(std::max(1,alignment_multiple));

	//Open files to put timestamps in...
	char filename[40];
	for(int ii=0; ii < 4; ii++){
		std::ofstream *temp_ofstream = new std::ofstream();
		timestamp_files.push_back(temp_ofstream);
		sprintf(filename,"timestamps_anchor%d.txt",ii);
		timestamp_files[ii]->open(filename);
	}
}

stream_parser_impl::~stream_parser_impl(){
	for(int ii=0; ii < 4; ii++)
		timestamp_files[ii]->close();
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
		if(data_history[ii].size() < SAMPLES_PER_SEQ * 100){
			for(int jj=0; jj < ninput_items[ii]; jj++){
				data_history[ii].push_back(in[jj]);
			}
	
			//Consume items from each input
			consume(ii, ninput_items[ii]);
		}
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
				timeval cur_time;
				char micro_cstr[7];
				gettimeofday(&cur_time, NULL);
				sprintf(micro_cstr,"%06d",(int)cur_time.tv_usec);
				char *ct_out = ctime(&(cur_time.tv_sec));
				ct_out[19] = 0;

				*timestamp_files[ii] << sequence_num << " " << ct_out << "." << micro_cstr << std::endl;
	
				//TODO: Temporary code to allow for repeating log files
				if(d_wait_for_restart){
					if(sequence_num < (d_hsn - 100) && d_hsn > 100){
						d_restarted[ii] = true;
						bool all_restarted = true;
						for(int jj=0; jj < 4; jj++)
							all_restarted &= d_restarted[jj];
						if(all_restarted){
							std::cout << "ALL RESTARTED" << std::endl;
							d_hsn = sequence_num;
							d_wait_for_restart = false;
							for(int jj=0; jj < 4; jj++)
								d_restarted[jj] = false;
							ii = 0;
							continue;
						}
					} else {
						data_history[ii].erase(data_history[ii].begin(), data_history[ii].begin()+SAMPLES_PER_SEQ-1);
						ii = 0;
						continue;
					}
					
				} else {
					//In case a sequence number has been skipped, delete any stale data
					if(sequence_num > d_hsn && ii > 0){
						d_hsn = sequence_num;
						d_hsn_idx = ii;
						ii = 0;
						continue;
					} else if(sequence_num < d_hsn){
						//TODO: Temporary code to allow for repeating log files
						if(sequence_num < (d_hsn - 100) && d_hsn > 100){
							d_restarted[ii] = true;
							d_wait_for_restart = true;
						}else
							data_history[ii].erase(data_history[ii].begin(), data_history[ii].begin()+SAMPLES_PER_SEQ-1);
						ii = 0;
						continue;
					}
				}
			}
			ii++;
		}
	
		//If snapshot_flag is set, it means we have a full snapshot and all data is aligned in data_history
		if(snapshot_flag){
			if(out_count < noutput_items){
			for(int ii=0; ii < output_items.size(); ii++){
				for(int jj=0; jj < NUM_STEPS; jj++){
					int cur_data_idx = SKIP_SAMPLES + SAMPLES_PER_FREQ*jj;
					gr_complex *optr = ((gr_complex *)(output_items[ii])) + jj*FFT_SIZE + output_offset;

					//Have to use std::copy since deque isn't contiguous
					std::copy(data_history[ii].begin() + cur_data_idx, data_history[ii].begin() + (cur_data_idx + FFT_SIZE), optr);
					//If we're using image frequencies, make sure to take the complex conjugate...
					if(USE_IMAGE)
						volk_32fc_conjugate_32fc(optr, optr, FFT_SIZE);

				}
			}
			for(int ii=0; ii < input_items.size(); ii++){
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
