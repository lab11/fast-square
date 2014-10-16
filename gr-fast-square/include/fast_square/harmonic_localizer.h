
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

      static sptr make(const std::string &phasor_tag_name, const std::string &hfreq_abs_tag_name, const std::string &hfreq_tag_name, const std::string &prf_tag_name, const std::string &gatd_host, int gatd_port, const std::string &gatd_id, int threads);

      virtual void gatd_connect(const std::string &host, int port) = 0;
      virtual void gatd_disconnect() = 0;
    };

  } /* namespace fast_square */
} /* namespace gr */

#endif /* INCLUDED_FAST_SQUARE_HARMONIC_LOCALIZER_H */
