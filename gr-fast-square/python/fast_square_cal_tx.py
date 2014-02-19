#!/usr/bin/env python
##################################################
# Gnuradio Python Flow Graph
# Title: UHD Constant Wave
# Author: Example
# Description: Tune UHD Device
# Generated: Wed Oct 16 11:11:02 2013
##################################################

from gnuradio import analog
from gnuradio import eng_notation
from gnuradio import gr
from gnuradio import uhd
from gnuradio.eng_option import eng_option
from gnuradio.filter import firdes
from gnuradio.wxgui import forms
from grc_gnuradio import wxgui as grc_wxgui
from optparse import OptionParser
import time
import wx

class uhd_const_wave(grc_wxgui.top_block_gui):

    def __init__(self, samp_rate=1e6, gain=0, freq=960e6, address="serial=4cfc5bc8"):
        grc_wxgui.top_block_gui.__init__(self, title="UHD Constant Wave")

        ##################################################
        # Parameters
        ##################################################
        self.samp_rate = samp_rate
        self.gain = gain
        self.freq = freq
        self.address = address

        ##################################################
        # Variables
        ##################################################
        self.tun_gain = tun_gain = gain
        self.tun_freq = tun_freq = freq
        self.ampl = ampl = .1

        ##################################################
        # Blocks
        ##################################################
        _tun_gain_sizer = wx.BoxSizer(wx.VERTICAL)
        self._tun_gain_text_box = forms.text_box(
        	parent=self.GetWin(),
        	sizer=_tun_gain_sizer,
        	value=self.tun_gain,
        	callback=self.set_tun_gain,
        	label="UHD Gain",
        	converter=forms.float_converter(),
        	proportion=0,
        )
        self._tun_gain_slider = forms.slider(
        	parent=self.GetWin(),
        	sizer=_tun_gain_sizer,
        	value=self.tun_gain,
        	callback=self.set_tun_gain,
        	minimum=-20,
        	maximum=35,
        	num_steps=100,
        	style=wx.SL_HORIZONTAL,
        	cast=float,
        	proportion=1,
        )
        self.Add(_tun_gain_sizer)
        _tun_freq_sizer = wx.BoxSizer(wx.VERTICAL)
        self._tun_freq_text_box = forms.text_box(
        	parent=self.GetWin(),
        	sizer=_tun_freq_sizer,
        	value=self.tun_freq,
        	callback=self.set_tun_freq,
        	label="UHD Freq (Hz)",
        	converter=forms.float_converter(),
        	proportion=0,
        )
        self._tun_freq_slider = forms.slider(
        	parent=self.GetWin(),
        	sizer=_tun_freq_sizer,
        	value=self.tun_freq,
        	callback=self.set_tun_freq,
        	minimum=50e6,
        	maximum=2.2e9,
        	num_steps=100,
        	style=wx.SL_HORIZONTAL,
        	cast=float,
        	proportion=1,
        )
        self.Add(_tun_freq_sizer)
        _ampl_sizer = wx.BoxSizer(wx.VERTICAL)
        self._ampl_text_box = forms.text_box(
        	parent=self.GetWin(),
        	sizer=_ampl_sizer,
        	value=self.ampl,
        	callback=self.set_ampl,
        	label="Amplitude",
        	converter=forms.float_converter(),
        	proportion=0,
        )
        self._ampl_slider = forms.slider(
        	parent=self.GetWin(),
        	sizer=_ampl_sizer,
        	value=self.ampl,
        	callback=self.set_ampl,
        	minimum=0,
        	maximum=1,
        	num_steps=100,
        	style=wx.SL_HORIZONTAL,
        	cast=float,
        	proportion=1,
        )
        self.Add(_ampl_sizer)
        self.uhd_usrp_sink_0 = uhd.usrp_sink(
        	device_addr=address,
        	stream_args=uhd.stream_args(
        		cpu_format="fc32",
        		channels=range(1),
        	),
        )
        self.uhd_usrp_sink_0.set_subdev_spec("A:0", 0)
        self.uhd_usrp_sink_0.set_samp_rate(samp_rate)
        self.uhd_usrp_sink_0.set_center_freq(tun_freq, 0)
        self.uhd_usrp_sink_0.set_gain(tun_gain, 0)
        self.uhd_usrp_sink_0.set_antenna("J1", 0)
	
	g = self.uhd_usrp_sink_0.get_gain_range()
	print "tx gain range is (%f,%f)" % (g.start(),g.stop())

        self.analog_sig_source_x_0 = analog.sig_source_c(samp_rate, analog.GR_COS_WAVE, -100e3, ampl, 0)

        ##################################################
        # Connections
        ##################################################
        self.connect((self.analog_sig_source_x_0, 0), (self.uhd_usrp_sink_0, 0))


# QT sink close method reimplementation

    def get_samp_rate(self):
        return self.samp_rate

    def set_samp_rate(self, samp_rate):
        self.samp_rate = samp_rate
        self.analog_sig_source_x_0.set_sampling_freq(self.samp_rate)
        self.uhd_usrp_sink_0.set_samp_rate(self.samp_rate)

    def get_gain(self):
        return self.gain

    def set_gain(self, gain):
        self.gain = gain
        self.set_tun_gain(self.gain)

    def get_freq(self):
        return self.freq

    def set_freq(self, freq):
        self.freq = freq
        self.set_tun_freq(self.freq)

    def get_address(self):
        return self.address

    def set_address(self, address):
        self.address = address

    def get_tun_gain(self):
        return self.tun_gain

    def set_tun_gain(self, tun_gain):
        self.tun_gain = tun_gain
        self._tun_gain_slider.set_value(self.tun_gain)
        self._tun_gain_text_box.set_value(self.tun_gain)
        self.uhd_usrp_sink_0.set_gain(self.tun_gain, 0)

    def get_tun_freq(self):
        return self.tun_freq

    def set_tun_freq(self, tun_freq):
        self.tun_freq = tun_freq
        self._tun_freq_slider.set_value(self.tun_freq)
        self._tun_freq_text_box.set_value(self.tun_freq)
        self.uhd_usrp_sink_0.set_center_freq(self.tun_freq, 0)

    def get_ampl(self):
        return self.ampl

    def set_ampl(self, ampl):
        self.ampl = ampl
        self._ampl_slider.set_value(self.ampl)
        self._ampl_text_box.set_value(self.ampl)
        self.analog_sig_source_x_0.set_amplitude(self.ampl)

if __name__ == '__main__':
    parser = OptionParser(option_class=eng_option, usage="%prog: [options]")
    parser.add_option("-s", "--samp-rate", dest="samp_rate", type="eng_float", default=eng_notation.num_to_str(1e6),
        help="Set Sample Rate [default=%default]")
    parser.add_option("-g", "--gain", dest="gain", type="eng_float", default=eng_notation.num_to_str(28.5),
        help="Set Default Gain [default=%default]")
    parser.add_option("-f", "--freq", dest="freq", type="eng_float", default=eng_notation.num_to_str(964.1e6),
        help="Set Default Frequency [default=%default]")
    parser.add_option("-a", "--address", dest="address", type="string", default="serial=4cfc5bc8",
        help="Set IP Address [default=%default]")
    (options, args) = parser.parse_args()
    tb = uhd_const_wave(samp_rate=options.samp_rate, gain=options.gain, freq=options.freq, address=options.address)
    tb.Start(True)
    tb.Wait()

