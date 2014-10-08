
#ifndef INCLUDED_FAST_SQUARE_MESSAGE_FFT_H
#define INCLUDED_FAST_SQUARE_MESSAGE_FFT_H

#include <fast_square/api.h>
#include <gnuradio/sync_block.h>
#include <gnuradio/msg_queue.h>

namespace gr {
  namespace fast_square {

    class FAST_SQUARE_API message_fft : virtual public gr::sync_block
    {
    public:
      typedef boost::shared_ptr<message_fft> sptr;

      static sptr make();
    };

  } /* namespace fast_square */
} /* namespace gr */

#endif /* INCLUDED_FAST_SQUARE_MESSAGE_FFT_H */
