
#ifndef INCLUDED_FAST_SQUARE_STREAM_PARSER_H
#define INCLUDED_FAST_SQUARE_STREAM_PARSER_H

#include <fast_square/api.h>
#include <gnuradio/sync_block.h>
#include <gnuradio/msg_queue.h>

namespace gr {
  namespace fast_square {

    class FAST_SQUARE_API stream_parser : virtual public gr::sync_block
    {
    public:
      // gr::digital::framer_sink_1::sptr
      typedef boost::shared_ptr<stream_parser> sptr;

      static sptr make();
    };

  } /* namespace fast_square */
} /* namespace gr */

#endif /* INCLUDED_FAST_SQUARE_STREAM_PARSER_H */
