#!/usr/bin/env python
##################################################
# Gnuradio Python Flow Graph
# Title: UHD FFT
# Author: Example
# Description: UHD FFT Waveform Plotter
# Generated: Wed Oct 16 11:11:13 2013
##################################################

from gnuradio import eng_notation
from gnuradio import gr
from gnuradio import uhd
from gnuradio import wxgui
from gnuradio import blocks
from gnuradio import analog
import fast_square
from gnuradio.eng_option import eng_option
from gnuradio.fft import window
from gnuradio import filter
from gnuradio.wxgui import fftsink2
from gnuradio.wxgui import forms
from gnuradio.wxgui import scopesink2
from gnuradio.wxgui import waterfallsink2
from grc_gnuradio import wxgui as grc_wxgui
from optparse import OptionParser
import numpy
import threading
import time
import wx
import math
import scopesink_cir

class uhd_fft(grc_wxgui.top_block_gui):

    def __init__(self, param_samp_rate, param_freq, param_gain, address, address2):
        grc_wxgui.top_block_gui.__init__(self, title="UHD FFT")

        ##################################################
        # Parameters
        ##################################################
	param_freq = 5.792e9
	self.if_freq = 960e6
	self.square_freq = 4e6
	self.num_steps = 32
	self.lo_start_freq = 5.312e9
        self.param_samp_rate = param_samp_rate
        self.param_freq = param_freq
        self.param_gain = param_gain
        self.address = address
	self.address2 = address2

	self.offset_freq = 10e3


        ##################################################
        # Variables
        ##################################################
        self.chan0_lo_locked = chan0_lo_locked = uhd.sensor_value("", False, "")
        self.samp_rate = samp_rate = param_samp_rate
        self.lo_locked_probe = lo_locked_probe = chan0_lo_locked.to_bool()
        self.gain = gain = param_gain
        self.freq = freq = param_freq
        self.ant = ant = "J1"
	self.test = options.test
	self.tofile = options.tofile

        ##################################################
        # Blocks
        ##################################################
	if self.test == False:
	        self.source = uhd.usrp_source(
	        	device_addr=address,
	        	stream_args=uhd.stream_args(
	        		cpu_format="fc32",
	        		channels=range(2),
	        	),
	        )

		#Channel 0
		g = self.source.get_gain_range(0)
		print "rx gain range is (%f,%f)" % (g.start(),g.stop())
	        self.source.set_subdev_spec("A:0 B:0")
	        self.source.set_center_freq(self.if_freq, 0)
	        self.source.set_gain(g.stop(), 0)
	        self.source.set_bandwidth(64e6, 0)

		#Channel 1
		g = self.source.get_gain_range(1)
	        self.source.set_center_freq(self.if_freq, 1) #Mixer @ 4992 MHz
	        self.source.set_gain(g.stop(), 1)
	        self.source.set_bandwidth(64e6, 1)

		#self.source.set_samp_rate(samp_rate)

	        self.source2 = uhd.usrp_source(
	        	device_addr=address2,
	        	stream_args=uhd.stream_args(
	        		cpu_format="fc32",
	        		channels=range(2),
	        	),
	        )

		#Channel 0
		g = self.source2.get_gain_range(0)
		print "rx gain range is (%f,%f)" % (g.start(),g.stop())
	        self.source2.set_subdev_spec("A:0 B:0")
	        self.source2.set_center_freq(self.if_freq, 0)
	        self.source2.set_gain(g.stop(), 0)
	        self.source2.set_bandwidth(64e6, 0)

		#Channel 1
		g = self.source2.get_gain_range(1)
	        self.source2.set_center_freq(self.if_freq, 1) #Mixer @ 4992 MHz
	        self.source2.set_gain(g.stop(), 1)
	        self.source2.set_bandwidth(64e6, 1)

		#self.source2.set_samp_rate(samp_rate)


	else:
		self.source_pre = blocks.file_source(gr.sizeof_gr_complex, "test.dat", True)
		self.source = blocks.throttle(gr.sizeof_gr_complex*1, samp_rate)
		self.connect(self.source_pre, self.source)
		self.source_freqs_pre = blocks.file_source(gr.sizeof_gr_complex, "test_freqs.dat", True)
		self.source_freqs = blocks.throttle(gr.sizeof_gr_complex*1, samp_rate)
		self.connect(self.source_freqs_pre, self.source_freqs)


        ##################################################
        # Connections
        ##################################################

	#Actual demo code
	#self.stitcher = fast_square.freq_stitcher("cal.dat",14*4)

	if self.test == True:
		self.connect(self.source_freqs, self.stitcher)
	else:
		if self.tofile == True:
			self.logfile0 = blocks.file_sink(gr.sizeof_gr_complex, "usrp_chan0.dat")
			self.connect((self.source, 0), self.logfile0)
			self.logfile1 = blocks.file_sink(gr.sizeof_gr_complex, "usrp_chan1.dat")
			self.connect((self.source, 1), self.logfile1)
			self.logfile2 = blocks.file_sink(gr.sizeof_gr_complex, "usrp_chan2.dat")
			self.connect((self.source2, 0), self.logfile2)
			self.logfile3 = blocks.file_sink(gr.sizeof_gr_complex, "usrp_chan3.dat")
			self.connect((self.source2, 1), self.logfile3)
		#self.connect((self.source, 1), self.stitcher)

if __name__ == '__main__':
    parser = OptionParser(option_class=eng_option, usage="%prog: [options]")
    parser.add_option("-s", "--param-samp-rate", dest="param_samp_rate", type="eng_float", default=eng_notation.num_to_str(4e6),
        help="Set Sample Rate [default=%default]")
    parser.add_option("-f", "--param-freq", dest="param_freq", type="eng_float", default=eng_notation.num_to_str(5.786666666667e9),
        help="Set Default Frequency [default=%default]")
    parser.add_option("-g", "--param-gain", dest="param_gain", type="eng_float", default=eng_notation.num_to_str(40),
        help="Set Default Gain [default=%default]")
    parser.add_option("-a", "--address", dest="address", type="string", default="serial=9R24X1U1, fpga=usrp1_bb_comb.rbf",
        help="Set IP Address [default=%default]")
    parser.add_option("--address2", dest="address2", type="string", default="serial=7R24X9U1, fpga=usrp1_bb_comb.rbf",
        help="Set IP Address [default=%default]")
    parser.add_option("--test", action="store_true", default=False,
        help="Feed with data from test file")
    parser.add_option("--tofile", action="store_true", default=False,
        help="Push channel 2 data to file")
    (options, args) = parser.parse_args()
    tb = uhd_fft(param_samp_rate=options.param_samp_rate, param_freq=options.param_freq, param_gain=options.param_gain, address=options.address, address2=options.address2)
    tb.Start(True)
    tb.Wait()

