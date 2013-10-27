
#ifndef INCLUDED_FAST_SQUARE_FREQ_STITCHER_H
#define INCLUDED_FAST_SQUARE_FREQ_STITCHER_H

#include <fast_square/api.h>
#include <gnuradio/sync_block.h>
#include <gnuradio/msg_queue.h>

namespace gr {
  namespace fast_square {

    class FAST_SQUARE_API freq_stitcher : virtual public gr::sync_block
    {
    public:
      // gr::digital::framer_sink_1::sptr
      typedef boost::shared_ptr<freq_stitcher> sptr;

      static sptr make(std::string cal_file, unsigned int num_freqs);
    };

  } /* namespace fast_square */
} /* namespace gr */

#endif /* INCLUDED_FAST_SQUARE_FREQ_STITCHER_H */
