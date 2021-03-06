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

    def __init__(self, param_samp_rate, param_freq, param_gain, address):
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
        _gain_sizer = wx.BoxSizer(wx.VERTICAL)
        self._gain_text_box = forms.text_box(
        	parent=self.GetWin(),
        	sizer=_gain_sizer,
        	value=self.gain,
        	callback=self.set_gain,
        	label="RX Gain",
        	converter=forms.float_converter(),
        	proportion=0,
        )
        self._gain_slider = forms.slider(
        	parent=self.GetWin(),
        	sizer=_gain_sizer,
        	value=self.gain,
        	callback=self.set_gain,
        	minimum=0,
        	maximum=112.5,
        	num_steps=225,
        	style=wx.SL_HORIZONTAL,
        	cast=float,
        	proportion=1,
        )
        self.GridAdd(_gain_sizer, 2, 0, 1, 8)
	if self.test == False:
	        self.source = uhd.usrp_source(
	        	device_addr=address,
	        	stream_args=uhd.stream_args(
	        		cpu_format="fc32",
	        		channels=range(2),
	        	),
	        )

		#Channel 0
	        self.source.set_subdev_spec("A:0 B:0")
	        self.source.set_center_freq(freq, 0)
	        self.source.set_gain(gain, 0)
	        self.source.set_antenna(ant, 0)
	        self.source.set_bandwidth(samp_rate, 0)

		#Channel 1
		g = self.source.get_gain_range(1)
		print "rx gain range is (%f,%f)" % (g.start(),g.stop())
	        self.source.set_center_freq(self.if_freq, 1) #Mixer @ 4992 MHz
	        self.source.set_gain(g.stop(), 1)
	        #self.source.set_antenna(ant, 1)
	        self.source.set_bandwidth(36e6, 1)#Need Turbo mode!

	        self.source.set_samp_rate(samp_rate)

	else:
		self.source_pre = blocks.file_source(gr.sizeof_gr_complex, "test.dat", True)
		self.source = blocks.throttle(gr.sizeof_gr_complex*1, samp_rate)
		self.connect(self.source_pre, self.source)
		self.source_freqs_pre = blocks.file_source(gr.sizeof_gr_complex, "test_freqs.dat", True)
		self.source_freqs = blocks.throttle(gr.sizeof_gr_complex*1, samp_rate)
		self.connect(self.source_freqs_pre, self.source_freqs)


        self.nb0 = self.nb0 = wx.Notebook(self.GetWin(), style=wx.NB_TOP)
        self.nb0.AddPage(grc_wxgui.Panel(self.nb0), "FFT")
        self.nb0.AddPage(grc_wxgui.Panel(self.nb0), "Waterfall")
        self.nb0.AddPage(grc_wxgui.Panel(self.nb0), "Scope")
        self.GridAdd(self.nb0, 0, 0, 1, 8)
#        self.scopesink_0 = scopesink2.scope_sink_c(
#        	self.nb0.GetPage(0).GetWin(),
#        	title="Scope Plot",
#        	sample_rate=samp_rate,
#        	v_scale=0,
#        	v_offset=0,
#        	t_scale=0,
#        	ac_couple=False,
#        	xy_mode=False,
#        	num_inputs=1,
#        	trig_mode=wxgui.TRIG_MODE_AUTO,
#        	y_axis_label="Counts",
#        )
#        self.nb0.GetPage(0).Add(self.scopesink_0.win)
        self.scopesink_0 = fftsink2.fft_sink_c(
        	self.nb0.GetPage(0).GetWin(),
        	baseband_freq=0,
        	y_per_div=10,
        	y_divs=15,
        	ref_level=0,
        	ref_scale=2.0,
        	sample_rate=samp_rate,
        	fft_size=1024,
        	fft_rate=15,
        	average=False,
        	avg_alpha=None,
        	title="FFT Plot",
        	peak_hold=False,
        	size=((-1, 400)),
        )
        self.nb0.GetPage(0).Add(self.scopesink_0.win)

        self.scopesink_1 = scopesink2.scope_sink_c(
        	self.nb0.GetPage(1).GetWin(),
        	title="Scope Plot",
        	sample_rate=samp_rate,
        	v_scale=0,
        	v_offset=0,
        	t_scale=0,
        	ac_couple=False,
        	xy_mode=False,
        	num_inputs=1,
        	trig_mode=wxgui.TRIG_MODE_AUTO,
        	y_axis_label="Counts",
        )
        self.nb0.GetPage(1).Add(self.scopesink_1.win)
        self.scopesink_2 = scopesink2.scope_sink_c(
        	self.nb0.GetPage(2).GetWin(),
        	title="Scope Plot",
        	sample_rate=samp_rate,
        	v_scale=0,
        	v_offset=0,
        	t_scale=0,
        	ac_couple=False,
        	xy_mode=False,
        	num_inputs=1,
        	trig_mode=wxgui.TRIG_MODE_AUTO,
        	y_axis_label="Counts",
        )
        self.nb0.GetPage(2).Add(self.scopesink_2.win)

        ##################################################
        # Connections
        ##################################################

	#Actual demo code
	self.multiply_0 = blocks.multiply_vcc(1)
        self.multiply_1 = blocks.multiply_vcc(1)
        self.carrier_est = analog.sig_source_c(samp_rate, analog.GR_COS_WAVE, 100000, 1, 0)
        self.subcarrier_est = analog.sig_source_c(samp_rate, analog.GR_COS_WAVE, -300000, 1, 0)
	chan_coeffs = filter.firdes.low_pass(1.0, 1.0, 0.05, 0.05, filter.firdes.WIN_HANN)
	self.carrier_tracking_filter = filter.fft_filter_ccc(1, chan_coeffs)
        self.carrier_tracking = analog.pll_refout_cc(0.0003, .15, -.15)
	self.carrier_tracking_conj = blocks.conjugate_cc()
	self.subcarrier_tracking_filter = filter.fft_filter_ccc(1, chan_coeffs)
        self.subcarrier_tracking = analog.pll_carriertracking_cc(0.0005, .001, -0.001)
	self.stitcher = fast_square.freq_stitcher("cal.dat",14*4)


	if self.test == True:
		self.connect(self.source_freqs, self.stitcher)
	else:
		if self.tofile == True:
			self.logfile0 = blocks.file_sink(gr.sizeof_gr_complex, "usrp_chan0.dat")
			self.connect((self.source, 0), self.logfile0)
			self.logfile1 = blocks.file_sink(gr.sizeof_gr_complex, "usrp_chan1.dat")
			self.connect((self.source, 1), self.logfile1)
		self.connect((self.source, 1), self.stitcher)

	self.connect((self.source, 0), (self.multiply_0,0))
	self.connect(self.carrier_est, (self.multiply_0,1))
	self.connect(self.multiply_0, self.carrier_tracking_filter, self.carrier_tracking, self.carrier_tracking_conj)
	self.connect(self.carrier_tracking_conj, (self.multiply_1,0))
	self.connect((self.source, 0), (self.multiply_1,1))
	self.connect(self.subcarrier_est, (self.multiply_1,2))
	self.connect(self.multiply_1, self.subcarrier_tracking_filter, self.subcarrier_tracking)

#	self.connect((self.source, 0), self.scopesink_0)
	self.connect(self.multiply_1, self.scopesink_0)
	self.connect(self.subcarrier_tracking, self.scopesink_1)
#	self.connect(self.subcarrier_tracking, self.scopesink_2)

        def _freq_tracker():
		loop_count = 0
        	while True:
			loop_count = loop_count + 1

			#TODO: Is this whole calculation section correct?
			carrier_freq = self.carrier_tracking.get_frequency()/2/math.pi*self.samp_rate
			subcarrier_freq = self.subcarrier_tracking.get_frequency()/2/math.pi*self.samp_rate

			print "carrier_freq = %f, \t subcarrier_freq = %f" % (carrier_freq, subcarrier_freq)
			
			#TODO: DEBUG ONLY
			#if loop_count > 100:
			#	print "GOING DOWN"
			#	#carrier_freq = self.offset_freq
			#	carrier_freq = carrier_freq + self.offset_freq
			#	self.offset_freq = self.offset_freq - 1e2

			#Translate to absolute frequency
			carrier_freq = self.param_freq+carrier_freq-100e3
			subcarrier_freq = self.square_freq+subcarrier_freq

			#Figure out what harmonic we will be centered on
			next_harmonic = math.ceil(((self.lo_start_freq+self.if_freq)-(self.param_freq+self.square_freq))/self.square_freq/2)
			next_harmonic_freq = self.param_freq + self.square_freq + next_harmonic*self.square_freq*2
			target_freq = next_harmonic_freq - self.square_freq
			actual_freq = carrier_freq+next_harmonic*subcarrier_freq*2
			carrier_mixer_freq = -(actual_freq-target_freq)
			subcarrier_mixer_freq = subcarrier_freq

			carrier_reg = carrier_mixer_freq/64e6
			if carrier_reg < 0:
				carrier_reg = carrier_reg + 1.0
			carrier_reg = int(carrier_reg*(2**32))
			if self.test == False:
				self.source.set_user_register(64+0,carrier_reg)    #Write to FR_USER_0 (Carrier offset reg)

			subcarrier_reg = subcarrier_mixer_freq/64e6 #Subcarrier freq register is absolute freq, not error
			subcarrier_reg = int(subcarrier_reg*(2**32))
			if self.test == False:
				self.source.set_user_register(64+1,subcarrier_reg) #Write to FR_USER_1 (Subcarrier freq reg)

			freq_step = ((self.square_freq - subcarrier_freq)*8)/64e6
			if freq_step < 0:
				freq_step = freq_step + 1.0
			freq_step_reg = int(freq_step*(2**32))
			if self.test == False:
				self.source.set_user_register(64+2,freq_step_reg)

			print "carrier_freq = %f, \t subcarrier_freq = %f, \t freq_step = %f, \t carrier_reg = %d, \t subcarrier_reg = %d, \t freq_step_reg = %d" % (carrier_freq, subcarrier_freq, freq_step, carrier_reg, subcarrier_reg, freq_step_reg)

        		time.sleep(1.0/(10))

        _freq_tracker_thread = threading.Thread(target=_freq_tracker)
        _freq_tracker_thread.daemon = True
        _freq_tracker_thread.start()

# QT sink close method reimplementation

    def get_param_samp_rate(self):
        return self.param_samp_rate

    def set_param_samp_rate(self, param_samp_rate):
        self.param_samp_rate = param_samp_rate
        self.set_samp_rate(self.param_samp_rate)

    def get_param_freq(self):
        return self.param_freq

    def set_param_freq(self, param_freq):
        self.param_freq = param_freq
        self.set_freq(self.param_freq)

    def get_param_gain(self):
        return self.param_gain

    def set_param_gain(self, param_gain):
        self.param_gain = param_gain
        self.set_gain(self.param_gain)

    def get_address(self):
        return self.address

    def set_address(self, address):
        self.address = address

    def get_chan0_lo_locked(self):
        return self.chan0_lo_locked

    def set_chan0_lo_locked(self, chan0_lo_locked):
        self.chan0_lo_locked = chan0_lo_locked
        self.set_lo_locked_probe(self.chan0_lo_locked.to_bool())

    def get_samp_rate(self):
        return self.samp_rate

    def set_samp_rate(self, samp_rate):
        self.samp_rate = samp_rate
        self.wxgui_scopesink2_0.set_sample_rate(self.samp_rate)
        self.fft.set_sample_rate(self.samp_rate)
        self.wxgui_waterfallsink2_0.set_sample_rate(self.samp_rate)
        self._samp_rate_text_box.set_value(self.samp_rate)
        self.source.set_samp_rate(self.samp_rate)
        self.source.set_bandwidth(self.samp_rate, 0)

    def get_lo_locked_probe(self):
        return self.lo_locked_probe

    def set_lo_locked_probe(self, lo_locked_probe):
        self.lo_locked_probe = lo_locked_probe
        self._lo_locked_probe_static_text.set_value(self.lo_locked_probe)

    def get_gain(self):
        return self.gain

    def set_gain(self, gain):
        self.gain = gain
        self._gain_slider.set_value(self.gain)
        self._gain_text_box.set_value(self.gain)
        self.source.set_gain(self.gain, 0)

    def get_freq(self):
        return self.freq

    def set_freq(self, freq):
        self.freq = freq
        self.fft.set_baseband_freq(self.freq)
        self._freq_slider.set_value(self.freq)
        self._freq_text_box.set_value(self.freq)
        self.source.set_center_freq(self.freq, 0)

    def get_ant(self):
        return self.ant

    def set_ant(self, ant):
        self.ant = ant
        self.source.set_antenna(self.ant, 0)
        self._ant_chooser.set_value(self.ant)

if __name__ == '__main__':
    parser = OptionParser(option_class=eng_option, usage="%prog: [options]")
    parser.add_option("-s", "--param-samp-rate", dest="param_samp_rate", type="eng_float", default=eng_notation.num_to_str(1e6),
        help="Set Sample Rate [default=%default]")
    parser.add_option("-f", "--param-freq", dest="param_freq", type="eng_float", default=eng_notation.num_to_str(5.786666666667e9),
        help="Set Default Frequency [default=%default]")
    parser.add_option("-g", "--param-gain", dest="param_gain", type="eng_float", default=eng_notation.num_to_str(40),
        help="Set Default Gain [default=%default]")
    parser.add_option("-a", "--address", dest="address", type="string", default="serial=7R24X9U1, fpga=usrp1_fast_square.rbf",
        help="Set IP Address [default=%default]")
    parser.add_option("--test", action="store_true", default=False,
        help="Feed with data from test file")
    parser.add_option("--tofile", action="store_true", default=False,
        help="Push channel 2 data to file")
    (options, args) = parser.parse_args()
    tb = uhd_fft(param_samp_rate=options.param_samp_rate, param_freq=options.param_freq, param_gain=options.param_gain, address=options.address)
    tb.Start(True)
    tb.Wait()

