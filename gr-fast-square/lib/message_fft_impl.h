
#ifndef INCLUDED_FAST_SQUARE_MESSAGE_FFT_IMPL_H
#define INCLUDED_FAST_SQUARE_MESSAGE_FFT_IMPL_H

#include <fast_square/message_fft.h>

namespace gr {
  namespace fast_square {

    class message_fft_impl : public message_fft
    {
    private:

    protected:

    public:
      message_fft_impl();
      ~message_fft_impl();

      int work(int noutput_items,
	       gr_vector_const_void_star &input_items,
	       gr_vector_void_star &output_items);
    };

  } /* namespace fast_square */
} /* namespace gr */

#endif /* INCLUDED_FAST_SQUARE_MESSAGE_FFT_IMPL_H */
