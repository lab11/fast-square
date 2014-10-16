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
import fast_square

class uhd_fft(grc_wxgui.top_block_gui):

    def __init__(self, param_samp_rate, param_freq, param_gain, address, address2):
        grc_wxgui.top_block_gui.__init__(self, title="REAL-TIME HARMONIA")

        ##################################################
        # Parameters
        ##################################################
	param_freq = 5.792e9
	self.bbg=0
	self.gc1=70
	self.if_freq = 990e6
	self.bw = 64e6#40e6
	self.square_freq = 4e6
	self.num_steps = 32
	self.lo_start_freq = 5.312e9
        self.param_samp_rate = param_samp_rate
        self.param_freq = param_freq
        self.param_gain = param_gain
        self.address = address
	self.address2 = address2
	self.dead_on_freq = 5.792e9
	self.tag_freq = 5.792042e9#5.7919847e9
	self.tune_freq = self.if_freq+self.tag_freq-self.dead_on_freq

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
	self.fromfile = options.fromfile
	self.tofile = options.tofile

        ##################################################
        # Blocks
        ##################################################
	if self.fromfile == False:
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
	        self.source.set_center_freq(self.tune_freq, 0)
	        self.source.set_gain(gain, 0)
		#self.source.set_antenna("RX2", 0)
		#self.source.set_gain(self.bbg, "BBG", 0)
		#self.source.set_gain(self.gc1, "GC1", 0)
	        self.source.set_bandwidth(self.bw, 0)

		#Channel 1
		g = self.source.get_gain_range(1)
	        self.source.set_center_freq(self.tune_freq, 1) #Mixer @ 4992 MHz
	        self.source.set_gain(gain, 1)
		#self.source.set_antenna("RX2", 1)
		#self.source.set_gain(self.bbg, "BBG", 1)
		#self.source.set_gain(self.gc1, "GC1", 1)
	        self.source.set_bandwidth(self.bw, 1)


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
	        self.source2.set_center_freq(self.tune_freq, 0)
	        self.source2.set_gain(gain, 0)
		#self.source2.set_antenna("RX2", 0)
		#self.source2.set_gain(self.bbg, "BBG", 0)
		#self.source2.set_gain(self.gc1, "GC1", 0)
	        self.source2.set_bandwidth(self.bw, 0)

		#Channel 1
		g = self.source2.get_gain_range(1)
	        self.source2.set_center_freq(self.tune_freq, 1) #Mixer @ 4992 MHz
	        self.source2.set_gain(gain, 1)
		#self.source2.set_antenna("RX2", 1)
		#self.source2.set_gain(self.bbg, "BBG", 1)
		#self.source2.set_gain(self.gc1, "GC1", 1)
	        self.source2.set_bandwidth(self.bw, 1)

        ##################################################
        # Connections
        ##################################################

	#Actual demo code
	#self.stitcher = fast_square.freq_stitcher("cal.dat",14*4)

	if self.tofile == True:
		self.logfile0 = blocks.file_sink(gr.sizeof_gr_complex, "usrp_chan0.dat")
		self.connect((self.source, 0), self.logfile0)
		self.logfile1 = blocks.file_sink(gr.sizeof_gr_complex, "usrp_chan1.dat")
		self.connect((self.source, 1), self.logfile1)
		self.logfile2 = blocks.file_sink(gr.sizeof_gr_complex, "usrp_chan2.dat")
		self.connect((self.source2, 0), self.logfile2)
		self.logfile3 = blocks.file_sink(gr.sizeof_gr_complex, "usrp_chan3.dat")
		self.connect((self.source2, 1), self.logfile3)
	else:
		self.parser = fast_square.stream_parser()
		if self.fromfile == True:
			self.logfile0 = blocks.file_source(gr.sizeof_gr_complex, "usrp_chan0.dat")
			self.logfile1 = blocks.file_source(gr.sizeof_gr_complex, "usrp_chan1.dat")
			self.logfile2 = blocks.file_source(gr.sizeof_gr_complex, "usrp_chan2.dat")
			self.logfile3 = blocks.file_source(gr.sizeof_gr_complex, "usrp_chan3.dat")
			self.connect(self.logfile0, (self.parser, 0))
			self.connect(self.logfile1, (self.parser, 1))
			self.connect(self.logfile2, (self.parser, 2))
			self.connect(self.logfile3, (self.parser, 3))
			self.ns0 = blocks.null_sink(1024*gr.sizeof_gr_complex)
			self.ns1 = blocks.null_sink(1024*gr.sizeof_gr_complex)
			self.ns2 = blocks.null_sink(1024*gr.sizeof_gr_complex)
			self.ns3 = blocks.null_sink(1024*gr.sizeof_gr_complex)
			self.connect((self.parser, 0), self.ns0)
			self.connect((self.parser, 1), self.ns1)
			self.connect((self.parser, 2), self.ns2)
			self.connect((self.parser, 3), self.ns3)
		else:
			self.connect((self.source, 0), (self.parser, 0))
			self.connect((self.source, 1), (self.parser, 1))
			self.connect((self.source2, 0), (self.parser, 2))
			self.connect((self.source2, 1), (self.parser, 3))
	#self.connect((self.source, 1), self.stitcher)

if __name__ == '__main__':
    parser = OptionParser(option_class=eng_option, usage="%prog: [options]")
    parser.add_option("-s", "--param-samp-rate", dest="param_samp_rate", type="eng_float", default=eng_notation.num_to_str(4e6),
        help="Set Sample Rate [default=%default]")
    parser.add_option("-f", "--param-freq", dest="param_freq", type="eng_float", default=eng_notation.num_to_str(5.786666666667e9),
        help="Set Default Frequency [default=%default]")
    parser.add_option("-g", "--param-gain", dest="param_gain", type="eng_float", default=eng_notation.num_to_str(70),
        help="Set Default Gain [default=%default]")
    parser.add_option("-a", "--address", dest="address", type="string", default="serial=9R24X1U1, fpga=usrp1_bb_comb_2mhz.rbf",
        help="Set IP Address [default=%default]")
    parser.add_option("--address2", dest="address2", type="string", default="serial=7R24X9U1, fpga=usrp1_bb_comb_2mhz.rbf",
        help="Set IP Address [default=%default]")
    parser.add_option("--tofile", action="store_true", default=False,
        help="Push channel 2 data to file")
    parser.add_option("--fromfile", action="store_true", default=False,
        help="Read USRP data stream from file")
    (options, args) = parser.parse_args()
    tb = uhd_fft(param_samp_rate=options.param_samp_rate, param_freq=options.param_freq, param_gain=options.param_gain, address=options.address, address2=options.address2)
    tb.Start(True)
    time.sleep(100.0)
    tb.lock()
    tb.stop()
    #tb.Wait()

