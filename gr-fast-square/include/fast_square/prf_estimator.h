
#ifndef INCLUDED_FAST_SQUARE_PRF_ESTIMATOR_H
#define INCLUDED_FAST_SQUARE_PRF_ESTIMATOR_H

#include <fast_square/api.h>
#include <gnuradio/sync_block.h>
#include <gnuradio/msg_queue.h>

namespace gr {
  namespace fast_square {

    class FAST_SQUARE_API prf_estimator : virtual public gr::sync_block
    {
    public:
      typedef boost::shared_ptr<prf_estimator> sptr;

      static sptr make(int fft_size, bool forward, const std::vector<float> &window, bool shift, int nthreads, const std::string &tag_name);
      
      virtual void set_nthreads(int n) = 0;

      virtual int nthreads() const = 0;

      virtual bool set_window(const std::vector<float> &window) = 0;
    };

  } /* namespace fast_square */
} /* namespace gr */

#endif /* INCLUDED_FAST_SQUARE_PRF_ESTIMATOR_H */
