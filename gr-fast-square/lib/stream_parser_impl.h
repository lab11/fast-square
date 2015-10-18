
#ifndef INCLUDED_FAST_SQUARE_STREAM_PARSER_IMPL_H
#define INCLUDED_FAST_SQUARE_STREAM_PARSER_IMPL_H

#include <fast_square/stream_parser.h>
#include <fast_square/defines.h>
#include <fstream>

namespace gr {
namespace fast_square {

class stream_parser_impl : public stream_parser
{
private:
	int d_packet_id;
	int d_output_per_seq;
	uint32_t d_hsn; //hsn = highest sequence num
	int d_hsn_idx;
	std::vector<std::deque<gr_complex> > data_history;
	uint32_t getSequenceNum(gr_complex data);
	bool d_restarted[4];
	bool d_wait_for_restart;
	std::vector<std::ofstream*> timestamp_files;
	pmt::pmt_t d_seq_num_key;

protected:

public:
	stream_parser_impl(const std::string &seq_num_tag_name);
	~stream_parser_impl();

	void forecast(int noutput_items, gr_vector_int &ninput_items_required);
	int general_work(int noutput_items,
			gr_vector_int &ninput_items,
			gr_vector_const_void_star &input_items,
			gr_vector_void_star &output_items);
};

} /* namespace fast_square */
} /* namespace gr */

#endif /* INCLUDED_FAST_SQUARE_STREAM_PARSER_IMPL_H */
