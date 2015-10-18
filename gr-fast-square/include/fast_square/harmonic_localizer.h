
#ifndef INCLUDED_FAST_SQUARE_HARMONIC_LOCALIZER_H
#define INCLUDED_FAST_SQUARE_HARMONIC_LOCALIZER_H

#include <fast_square/api.h>
#include <gnuradio/sync_block.h>
#include <gnuradio/msg_queue.h>

namespace gr {
  namespace fast_square {

    class FAST_SQUARE_API harmonic_localizer : virtual public gr::sync_block
    {
    public:
      typedef boost::shared_ptr<harmonic_localizer> sptr;

      static sptr make(const std::string &phasor_tag_name, const std::string &hfreq_tag_name, const std::string &prf_tag_name, const std::string &gatd_id, const std::string &seq_num_tag_name, int threads);

    };

  } /* namespace fast_square */
} /* namespace gr */

#endif /* INCLUDED_FAST_SQUARE_HARMONIC_LOCALIZER_H */
