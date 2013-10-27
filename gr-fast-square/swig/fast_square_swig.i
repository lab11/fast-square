/* -*- c++ -*- */

#define FAST_SQUARE_API

%include "gnuradio.i"			// the common stuff

//load generated python docstrings
%include "fast_square_swig_doc.i"

%{
#include "fast_square/freq_stitcher.h"
%}


%include "fast_square/freq_stitcher.h"
GR_SWIG_BLOCK_MAGIC2(fast_square, freq_stitcher);
