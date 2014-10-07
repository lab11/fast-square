
#ifndef INCLUDED_FAST_SQUARE_STREAM_PARSER_IMPL_H
#define INCLUDED_FAST_SQUARE_STREAM_PARSER_IMPL_H

#include <fast_square/stream_parser.h>

namespace gr {
namespace fast_square {

class stream_parser_impl : public stream_parser
{
private:
	int *sequence_nums;
	int cur_sequence;
	std::vector<std::vector<gr_complex> > sequence_data;
	std::vector<std::vector<gr_complex> > sequence_history;

protected:

public:
	stream_parser_impl();
	~stream_parser_impl();

	int work(int noutput_items,
			gr_vector_const_void_star &input_items,
			gr_vector_void_star &output_items);
};

} /* namespace fast_square */
} /* namespace gr */

#endif /* INCLUDED_FAST_SQUARE_STREAM_PARSER_IMPL_H */
