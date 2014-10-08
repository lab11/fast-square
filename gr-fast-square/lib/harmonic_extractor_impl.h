
#ifndef INCLUDED_FAST_SQUARE_HARMONIC_EXTRACTOR_IMPL_H
#define INCLUDED_FAST_SQUARE_HARMONIC_EXTRACTOR_IMPL_H

#include <fast_square/harmonic_extractor.h>

namespace gr {
  namespace fast_square {

    class harmonic_extractor_impl : public harmonic_extractor
    {
    private:

    protected:

    public:
      harmonic_extractor_impl();
      ~harmonic_extractor_impl();

      int work(int noutput_items,
	       gr_vector_const_void_star &input_items,
	       gr_vector_void_star &output_items);
    };

  } /* namespace fast_square */
} /* namespace gr */

#endif /* INCLUDED_FAST_SQUARE_HARMONIC_EXTRACTOR_IMPL_H */
