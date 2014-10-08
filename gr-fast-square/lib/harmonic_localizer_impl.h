
#ifndef INCLUDED_FAST_SQUARE_HARMONIC_LOCALIZER_IMPL_H
#define INCLUDED_FAST_SQUARE_HARMONIC_LOCALIZER_IMPL_H

#include <fast_square/harmonic_localizer.h>

namespace gr {
  namespace fast_square {

    class harmonic_localizer_impl : public harmonic_localizer
    {
    private:

    protected:

    public:
      harmonic_localizer_impl();
      ~harmonic_localizer_impl();

      int work(int noutput_items,
	       gr_vector_const_void_star &input_items,
	       gr_vector_void_star &output_items);
    };

  } /* namespace fast_square */
} /* namespace gr */

#endif /* INCLUDED_FAST_SQUARE_HARMONIC_LOCALIZER_IMPL_H */
