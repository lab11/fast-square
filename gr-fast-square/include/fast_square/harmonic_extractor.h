
#ifndef INCLUDED_FAST_SQUARE_HARMONIC_EXTRACTOR_H
#define INCLUDED_FAST_SQUARE_HARMONIC_EXTRACTOR_H

#include <fast_square/api.h>
#include <gnuradio/sync_block.h>
#include <gnuradio/msg_queue.h>

namespace gr {
  namespace fast_square {

    class FAST_SQUARE_API harmonic_extractor : virtual public gr::sync_block
    {
    public:
      typedef boost::shared_ptr<harmonic_extractor> sptr;

      static sptr make();
    };

  } /* namespace fast_square */
} /* namespace gr */

#endif /* INCLUDED_FAST_SQUARE_HARMONIC_EXTRACTOR_H */
