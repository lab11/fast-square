
#ifndef INCLUDED_FAST_SQUARE_PRF_ESTIMATOR_IMPL_H
#define INCLUDED_FAST_SQUARE_PRF_ESTIMATOR_IMPL_H

#include <fast_square/prf_estimator.h>

namespace gr {
  namespace fast_square {

    class prf_estimator_impl : public prf_estimator
    {
    private:

    protected:

    public:
      prf_estimator_impl();
      ~prf_estimator_impl();

      int work(int noutput_items,
	       gr_vector_const_void_star &input_items,
	       gr_vector_void_star &output_items);
    };

  } /* namespace fast_square */
} /* namespace gr */

#endif /* INCLUDED_FAST_SQUARE_FREQ_STITCHER_IMPL_H */
