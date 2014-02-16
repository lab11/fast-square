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
from gnuradio.eng_option import eng_option
from gnuradio.fft import window
from gnuradio.filter import firdes
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

class uhd_fft(grc_wxgui.top_block_gui):

    def __init__(self, options, param_samp_rate, param_freq, param_gain, address):
        grc_wxgui.top_block_gui.__init__(self, title="UHD FFT")

        ##################################################
        # Parameters
        ##################################################
        self.param_samp_rate = param_samp_rate
        self.param_freq = param_freq
        self.param_gain = param_gain
        self.address = address

        ##################################################
        # Variables
        ##################################################
        self.chan0_lo_locked = chan0_lo_locked = uhd.sensor_value("", False, "")
        self.samp_rate = samp_rate = param_samp_rate
        self.lo_locked_probe = lo_locked_probe = chan0_lo_locked.to_bool()
        self.gain = gain = param_gain
        self.freq = freq = param_freq
        self.ant = ant = "J1"

        ##################################################
        # Blocks
        ##################################################
        self._samp_rate_text_box = forms.text_box(
        	parent=self.GetWin(),
        	value=self.samp_rate,
        	callback=self.set_samp_rate,
        	label="Sample Rate",
        	converter=forms.float_converter(),
        )
        self.GridAdd(self._samp_rate_text_box, 1, 0, 1, 3)
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
        _freq_sizer = wx.BoxSizer(wx.VERTICAL)
        self._freq_text_box = forms.text_box(
        	parent=self.GetWin(),
        	sizer=_freq_sizer,
        	value=self.freq,
        	callback=self.set_freq,
        	label="RX Tune Frequency",
        	converter=forms.float_converter(),
        	proportion=0,
        )
        self._freq_slider = forms.slider(
        	parent=self.GetWin(),
        	sizer=_freq_sizer,
        	value=self.freq,
        	callback=self.set_freq,
        	minimum=50e6,
        	maximum=6e9,
        	num_steps=1000,
        	style=wx.SL_HORIZONTAL,
        	cast=float,
        	proportion=1,
        )
        self.GridAdd(_freq_sizer, 3, 0, 1, 8)
        self._ant_chooser = forms.radio_buttons(
        	parent=self.GetWin(),
        	value=self.ant,
        	callback=self.set_ant,
        	label="Antenna",
        	choices=["J1","J2"],
        	labels=["J1","J2"],
        	style=wx.RA_HORIZONTAL,
        )
        self.GridAdd(self._ant_chooser, 1, 4, 1, 2)
        self.uhd_usrp_source_0 = uhd.usrp_source(
        	device_addr=address,
        	stream_args=uhd.stream_args(
        		cpu_format="fc32",
        		channels=range(1),
        	),
        )
        self.uhd_usrp_source_0.set_subdev_spec("A:0", 0)
        self.uhd_usrp_source_0.set_samp_rate(samp_rate)
        self.uhd_usrp_source_0.set_center_freq(freq, 0)
        self.uhd_usrp_source_0.set_gain(gain, 0)
        self.uhd_usrp_source_0.set_antenna(ant, 0)
        self.uhd_usrp_source_0.set_bandwidth(samp_rate, 0)
	if options.tofile == True:
		self.logfile0 = blocks.file_sink(gr.sizeof_gr_complex, "usrp_fft_iq.dat")
		self.connect(self.uhd_usrp_source_0, self.logfile0)
	
	g = self.uhd_usrp_source_0.get_gain_range()
	print "rx gain range is (%f,%f)" % (g.start(),g.stop())

        self.nb0 = self.nb0 = wx.Notebook(self.GetWin(), style=wx.NB_TOP)
        self.nb0.AddPage(grc_wxgui.Panel(self.nb0), "FFT")
        self.nb0.AddPage(grc_wxgui.Panel(self.nb0), "Waterfall")
        self.nb0.AddPage(grc_wxgui.Panel(self.nb0), "Scope")
        self.GridAdd(self.nb0, 0, 0, 1, 8)
        self.wxgui_waterfallsink2_0 = waterfallsink2.waterfall_sink_c(
        	self.nb0.GetPage(1).GetWin(),
        	baseband_freq=0,
        	dynamic_range=100,
        	ref_level=0,
        	ref_scale=2.0,
        	sample_rate=samp_rate,
        	fft_size=512,
        	fft_rate=15,
        	average=False,
        	avg_alpha=None,
        	title="Waterfall Plot",
        	size=((-1, 400)),
        )
        self.nb0.GetPage(1).Add(self.wxgui_waterfallsink2_0.win)
        self.wxgui_scopesink2_0 = scopesink2.scope_sink_c(
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
        self.nb0.GetPage(2).Add(self.wxgui_scopesink2_0.win)
        self._lo_locked_probe_static_text = forms.static_text(
        	parent=self.GetWin(),
        	value=self.lo_locked_probe,
        	callback=self.set_lo_locked_probe,
        	label="LO Locked",
        	converter=forms.str_converter(formatter=lambda x: x and "True" or "False"),
        )
        self.GridAdd(self._lo_locked_probe_static_text, 1, 7, 1, 1)
        self.fft = fftsink2.fft_sink_c(
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
        self.nb0.GetPage(0).Add(self.fft.win)
        def _chan0_lo_locked_probe():
        	while True:
        		val = self.uhd_usrp_source_0.get_sensor('lo_locked')
        		try: self.set_chan0_lo_locked(val)
        		except AttributeError, e: pass
        		time.sleep(1.0/(10))
        _chan0_lo_locked_thread = threading.Thread(target=_chan0_lo_locked_probe)
        _chan0_lo_locked_thread.daemon = True
        _chan0_lo_locked_thread.start()

        ##################################################
        # Connections
        ##################################################
        self.connect((self.uhd_usrp_source_0, 0), (self.wxgui_scopesink2_0, 0))
        self.connect((self.uhd_usrp_source_0, 0), (self.wxgui_waterfallsink2_0, 0))
        self.connect((self.uhd_usrp_source_0, 0), (self.fft, 0))


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
        self.uhd_usrp_source_0.set_samp_rate(self.samp_rate)
        self.uhd_usrp_source_0.set_bandwidth(self.samp_rate, 0)

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
        self.uhd_usrp_source_0.set_gain(self.gain, 0)

    def get_freq(self):
        return self.freq

    def set_freq(self, freq):
        self.freq = freq
        self._freq_slider.set_value(self.freq)
        self._freq_text_box.set_value(self.freq)
        self.uhd_usrp_source_0.set_center_freq(self.freq, 0)

    def get_ant(self):
        return self.ant

    def set_ant(self, ant):
        self.ant = ant
        self.uhd_usrp_source_0.set_antenna(self.ant, 0)
        self._ant_chooser.set_value(self.ant)

if __name__ == '__main__':
    parser = OptionParser(option_class=eng_option, usage="%prog: [options]")
    parser.add_option("-s", "--param-samp-rate", dest="param_samp_rate", type="eng_float", default=eng_notation.num_to_str(1e6),
        help="Set Sample Rate [default=%default]")
    parser.add_option("-f", "--param-freq", dest="param_freq", type="eng_float", default=eng_notation.num_to_str(960e6),
        help="Set Default Frequency [default=%default]")
    parser.add_option("-g", "--param-gain", dest="param_gain", type="eng_float", default=eng_notation.num_to_str(80),
        help="Set Default Gain [default=%default]")
    parser.add_option("-a", "--address", dest="address", type="string", default="serial=9R24X1U1",#7R24X9U1",#, fpga=usrp1_fast_square.rbf",
        help="Set IP Address [default=%default]")
    parser.add_option("--tofile", action="store_true", default=False,
        help="Push IQ data to file")
    (options, args) = parser.parse_args()
    tb = uhd_fft(options=options, param_samp_rate=options.param_samp_rate, param_freq=options.param_freq, param_gain=options.param_gain, address=options.address)
    tb.Start(True)
    tb.Wait()

