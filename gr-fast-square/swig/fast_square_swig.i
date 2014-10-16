/* -*- c++ -*- */

#define FAST_SQUARE_API

%include "gnuradio.i"			// the common stuff

//load generated python docstrings
%include "fast_square_swig_doc.i"

%{
#include "fast_square/harmonic_extractor.h"
#include "fast_square/harmonic_localizer.h"
#include "fast_square/prf_estimator.h"
#include "fast_square/stream_parser.h"
#include "fast_square/stream_parser_ports.h"
%}


%include "fast_square/harmonic_extractor.h"
GR_SWIG_BLOCK_MAGIC2(fast_square, harmonic_extractor);

%include "fast_square/harmonic_localizer.h"
GR_SWIG_BLOCK_MAGIC2(fast_square, harmonic_localizer);

%include "fast_square/prf_estimator.h"
GR_SWIG_BLOCK_MAGIC2(fast_square, prf_estimator);

%include "fast_square/stream_parser.h"
GR_SWIG_BLOCK_MAGIC2(fast_square, stream_parser);

%include "fast_square/stream_parser_ports.h"
GR_SWIG_BLOCK_MAGIC2(fast_square, stream_parser_ports);
