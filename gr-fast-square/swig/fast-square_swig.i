/* -*- c++ -*- */

#define FAST-SQUARE_API

%include "gnuradio.i"			// the common stuff

//load generated python docstrings
%include "fast-square_swig_doc.i"

%{
#include "fast-square/freq_stitcher.h"
%}


%include "fast-square/freq_stitcher.h"
GR_SWIG_BLOCK_MAGIC2(fast-square, freq_stitcher);
