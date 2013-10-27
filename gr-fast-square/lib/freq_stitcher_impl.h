
#ifndef INCLUDED_FAST_SQUARE_FREQ_STITCHER_IMPL_H
#define INCLUDED_FAST_SQUARE_FREQ_STITCHER_IMPL_H

#include <fast_square/freq_stitcher.h>

namespace gr {
  namespace fast_square {

    class freq_stitcher_impl : public freq_stitcher
    {
    private:
      int state;
      int subfreq_idx;
      unsigned int num_freqs;
      std::vector<gr_complex> cal_data;
      void readCal(std::string in_cal_file);

    protected:

    public:
      freq_stitcher_impl(std::string cal_file, unsigned int num_freqs);
      ~freq_stitcher_impl();

      int work(int noutput_items,
	       gr_vector_const_void_star &input_items,
	       gr_vector_void_star &output_items);
    };

  } /* namespace fast_square */
} /* namespace gr */

#endif /* INCLUDED_FAST_SQUARE_FREQ_STITCHER_IMPL_H */
