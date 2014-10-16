
#ifndef INCLUDED_FAST_SQUARE_STREAM_PARSER_IMPL_H
#define INCLUDED_FAST_SQUARE_STREAM_PARSER_IMPL_H

#include <fast_square/stream_parser.h>
#include <fast_square/defines.h>

namespace gr {
namespace fast_square {

class stream_parser_impl : public stream_parser
{
private:
	int d_packet_id;
	std::vector<std::deque<gr_complex> > data_history;
	uint32_t getSequenceNum(gr_complex data);

protected:

public:
	stream_parser_impl();
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
