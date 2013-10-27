/* 
 * USRP - Universal Software Radio Peripheral
 *
 * Copyright (C) 2003,2004 Free Software Foundation, Inc.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Boston, MA  02110-1301  USA
 */

#include "usrp_common.h"
#include "usrp_regs.h"
#include "usrp_commands.h"
#include "fpga.h"
#include "usrp_gpif_inline.h"
#include "timer.h"
#include "i2c.h"
#include "isr.h"
#include "usb_common.h"
#include "fx2utils.h"
#include "usrp_globals.h"
#include "usrp_i2c_addr.h"
#include <string.h>
#include "spi.h"
#include "eeprom_io.h"
#include "usb_descriptors.h"

/*
 * offsets into boot eeprom for configuration values
 */
#define	HW_REV_OFFSET		  5
#define SERIAL_NO_OFFSET	248
#define SERIAL_NO_LEN		  8


#define	bRequestType	SETUPDAT[0]
#define	bRequest	SETUPDAT[1]
#define	wValueL		SETUPDAT[2]
#define	wValueH		SETUPDAT[3]
#define	wIndexL		SETUPDAT[4]
#define	wIndexH		SETUPDAT[5]
#define	wLengthL	SETUPDAT[6]
#define	wLengthH	SETUPDAT[7]


unsigned char g_tx_enable = 0;
unsigned char g_rx_enable = 0;
unsigned char g_rx_overrun = 0;
unsigned char g_tx_underrun = 0;

unsigned char g_ping = 0;
xdata unsigned char temp_char[3];

/*
 * the host side fpga loader code pushes an MD5 hash of the bitstream
 * into hash1.
 */
#define	  USRP_HASH_SIZE      16
xdata at USRP_HASH_SLOT_1_ADDR unsigned char hash1[USRP_HASH_SIZE];

static void
get_ep0_data (void)
{
  EP0BCL = 0;			// arm EP0 for OUT xfer.  This sets the busy bit

  while (EP0CS & bmEPBUSY)	// wait for busy to clear
    ;
}

/*
 * Handle our "Vendor Extension" commands on endpoint 0.
 * If we handle this one, return non-zero.
 */
unsigned char
app_vendor_cmd (void)
{
  if (bRequestType == VRT_VENDOR_IN){

    /////////////////////////////////
    //    handle the IN requests
    /////////////////////////////////

    switch (bRequest){

    case VRQ_GET_STATUS:
      switch (wIndexL){

      case GS_TX_UNDERRUN:
	EP0BUF[0] = g_tx_underrun;
	g_tx_underrun = 0;
	EP0BCH = 0;
	EP0BCL = 1;
	break;

      case GS_RX_OVERRUN:
	EP0BUF[0] = g_rx_overrun;
	g_rx_overrun = 0;
	EP0BCH = 0;
	EP0BCL = 1;
	break;

      default:
	return 0;
      }
      break;

    case VRQ_I2C_READ:
      if (!i2c_read (wValueL, EP0BUF, wLengthL))
	return 0;

      EP0BCH = 0;
      EP0BCL = wLengthL;
      break;
      
    case VRQ_SPI_READ:
      if (!spi_read (wValueH, wValueL, wIndexH, wIndexL, EP0BUF, wLengthL))
	return 0;

      EP0BCH = 0;
      EP0BCL = wLengthL;
      break;

    default:
      return 0;
    }
  }

  else if (bRequestType == VRT_VENDOR_OUT){

    /////////////////////////////////
    //    handle the OUT requests
    /////////////////////////////////

    switch (bRequest){

    case VRQ_SET_LED:
      switch (wIndexL){
      case 0:
	set_led_0 (wValueL);
	break;
	
      case 1:
	set_led_1 (wValueL);
	break;
	
      default:
	return 0;
      }
      break;
      
    case VRQ_FPGA_LOAD:
      switch (wIndexL){			// sub-command
      case FL_BEGIN:
	return fpga_load_begin ();
	
      case FL_XFER:
	get_ep0_data ();
	return fpga_load_xfer (EP0BUF, EP0BCL);
	
      case FL_END:
	return fpga_load_end ();
	
      default:
	return 0;
      }
      break;
      

    case VRQ_FPGA_SET_RESET:
      fpga_set_reset (wValueL);
      break;
      
    case VRQ_FPGA_SET_TX_ENABLE:
      fpga_set_tx_enable (wValueL);
      break;
      
    case VRQ_FPGA_SET_RX_ENABLE:
      fpga_set_rx_enable (wValueL);
      break;

    case VRQ_FPGA_SET_TX_RESET:
      fpga_set_tx_reset (wValueL);
      break;
      
    case VRQ_FPGA_SET_RX_RESET:
      fpga_set_rx_reset (wValueL);
      break;

    case VRQ_I2C_WRITE:
      get_ep0_data ();
      if (!i2c_write (wValueL, EP0BUF, EP0BCL))
	return 0;
      break;

    case VRQ_SPI_WRITE:
      get_ep0_data ();

      //Hack to get the 9862s to be configured correctly (just intercept the message in-transit)
      if(wIndexH & SPI_ENABLE_CODEC_B){
        if(wValueL == 1) temp_char[0] = 0;
	if(wValueL == 2) temp_char[0] = 0;
	if(wValueL == 3) temp_char[0] = 0;
	if(wValueL == 4) temp_char[0] = 5;
	if(wValueL == 18) temp_char[0] = 0x4b;
	if(wValueL == 19) temp_char[0] = 0x11;
	if(wValueL == 20) temp_char[0] = 0;
	if (!spi_write (wValueH, wValueL, wIndexH, wIndexL, temp_char, 1))
	  return 0;
      }
      else {
	if (!spi_write (wValueH, wValueL, wIndexH, wIndexL, EP0BUF, EP0BCL))
	  return 0;
      }
      break;

    default:
      return 0;
    }

  }
  else
    return 0;    // invalid bRequestType

  return 1;
}

const unsigned char int_div_0[8] = {
//  (47513 & 3),
//  (8192 & 3),
//  (34406 & 3),
//  (60620 & 3),
   (8192 & 3),
  (21299 & 3),
   (34406 & 3),
  (47513 & 3),
   (60620 & 3),
  (8192 & 3),
   (21299 & 3),
  (34406 & 3)
};

const unsigned char int_div_1[8] = {
//  (202 >> 4),
//  (205 >> 4),
//  (207 >> 4),
//  (209 >> 4),
   (211 >> 4),
  (212 >> 4),
   (213 >> 4),
  (214 >> 4),
   (215 >> 4),
  (217 >> 4),
   (218 >> 4),
  (219 >> 4)
};

const unsigned char int_div_2[8] = {
//  (202 << 4) | 3,
//  (205 << 4) | 3,
//  (207 << 4) | 3,
//  (209 << 4) | 3,
   (211 << 4) | 3,
  (212 << 4) | 3,
   (213 << 4) | 3,
  (214 << 4) | 3,
   (215 << 4) | 3,
  (217 << 4) | 3,
   (218 << 4) | 3,
  (219 << 4) | 3
};

const unsigned char frac_div_0[8] = {
//  (47513 & 0xfffc) >> 14,
//  (8192 & 0xfffc) >> 14,
//  (34406 & 0xfffc) >> 14,
//  (60620 & 0xfffc) >> 14,
   (8192 & 0xfffc) >> 14,
  (21299 & 0xfffc) >> 14,
   (34406 & 0xfffc) >> 14,
  (47513 & 0xfffc) >> 14,
   (60620 & 0xfffc) >> 14,
  (8192 & 0xfffc) >> 14,
   (21299 & 0xfffc) >> 14,
  (34406 & 0xfffc) >> 14
};

const unsigned char frac_div_1[8] = {
//  (47513 & 0xfffc) >> 6,
//  (8192 & 0xfffc) >> 6,
//  (34406 & 0xfffc) >> 6,
//  (60620 & 0xfffc) >> 6,
   (8192 & 0xfffc) >> 6,
  (21299 & 0xfffc) >> 6,
   (34406 & 0xfffc) >> 6,
  (47513 & 0xfffc) >> 6,
   (60620 & 0xfffc) >> 6,
  (8192 & 0xfffc) >> 6,
   (21299 & 0xfffc) >> 6,
  (34406 & 0xfffc) >> 6
};

const unsigned char frac_div_2[8] = {
//  ((47513 & 0xfffc) << 2) | 4,
//  ((8192 & 0xfffc) << 2) | 4,
//  ((34406 & 0xfffc) << 2) | 4,
//  ((60620 & 0xfffc) << 2) | 4,
   ((8192 & 0xfffc) << 2) | 4,
  ((21299 & 0xfffc) << 2) | 4,
   ((34406 & 0xfffc) << 2) | 4,
  ((47513 & 0xfffc) << 2) | 4,
   ((60620 & 0xfffc) << 2) | 4,
  ((8192 & 0xfffc) << 2) | 4,
   ((21299 & 0xfffc) << 2) | 4,
  ((34406 & 0xfffc) << 2) | 4
};

const unsigned char bspll_0_1[8] = {
//  0x82,
//  0x86,
//  0x86,
//  0x86,
   0x86,
  0x86,
   0x86,
  0x86,
   0x86,
  0x86,
   0x86,
  0x86
};

const unsigned char bspll_1_1[8] = {
//  0x8A,
//  0x8E,
//  0x8E,
//  0x8E,
   0x8E,
  0x8E,
   0x8E,
  0x8E,
   0x8E,
  0x8E,
   0x8E,
  0x8E
};


void write2450reg(const xdata unsigned char *mlbuf){
  spi_write(0,0,SPI_ENABLE_RX_A,SPI_FMT_MSB | SPI_FMT_HDR_0, mlbuf, 3); 
}

void change2450freq(unsigned char channel, unsigned char reset){
  static xdata unsigned char mlbuf[3];
  static xdata unsigned char int_div;
  if(reset){
    //bandselpll
    mlbuf[0] = 3;
    mlbuf[1] = 0xF6;
    mlbuf[2] = 0x35;
    write2450reg(mlbuf);
    //reg_frac_div
    mlbuf[0] = 0;
    mlbuf[1] = 0;
    mlbuf[2] = 4;
    write2450reg(mlbuf);
  }
  int_div = 232-channel;
  //reg_int_div
  mlbuf[0] = 0;
  mlbuf[1] = int_div >> 4;
  mlbuf[2] = (int_div << 4) | 3;
  write2450reg(mlbuf);
}

static xdata unsigned char xbuf2[1];

void
write_9862_alt (unsigned char which, unsigned char regno, unsigned char value)
{
  xbuf2[0] = value;
  
  spi_write (0, regno & 0x3f,
	     which == 0 ? SPI_ENABLE_CODEC_A : SPI_ENABLE_CODEC_B,
	     SPI_FMT_MSB | SPI_FMT_HDR_1,
	     xbuf2, 1);
}


int start_wait = 0;
#define WAIT_TIME 1500
static void
main_loop (void)
{
  static unsigned char ping_idx = 0;
  static unsigned char last_rxu = 0;
  unsigned char cur_rxu = 0;
  setup_flowstate_common ();

  while (1){
//    if(start_wait == 1500){
//      write_9862_alt(0, 1, 0);
//      write_9862_alt(0, 2, 0);
//      write_9862_alt(0, 3, 0);
//      write_9862_alt(0, 4, 5);
//      write_9862_alt(0, 16, 255);
//      write_9862_alt(0, 20, 0);
//      start_wait++;
//    }

    //State chagne of the incr line
    cur_rxu = (USRP_PA & bmPA_RX_OVERRUN);
    if (cur_rxu != last_rxu && cur_rxu != 0){
      //g_ping = 0;
      //Reset if the appropriate line is toggled
      if(USRP_PA & bmPA_TX_UNDERRUN) ping_idx = 0;
      ping_idx = ping_idx + 1;

//TODO: This shouldn't be needed, correct?
//      if(ping_idx >= 8) ping_idx = 0;

//      //Start PLL
//      mlbuf[0] = 3;
//      mlbuf[1] = 0xF6;//bspll_1_1[ping_idx];
//      mlbuf[2] = 0x35;
//      write2450reg(mlbuf);
      change2450freq(ping_idx, ping_idx==0);
/*      udelay(2000);
      //reg_int_div
      mlbuf[0] = int_div_0[0];
      mlbuf[1] = int_div_1[0];
      mlbuf[2] = int_div_2[0];
      write2450reg(mlbuf);
      //reg_frac_div
      mlbuf[0] = frac_div_0[0];
      mlbuf[1] = frac_div_1[0];
      mlbuf[2] = frac_div_2[0];
      write2450reg(mlbuf);

      //reg_int_div
      mlbuf[0] = 0;
      mlbuf[1] = 217 >> 4;
      mlbuf[2] = (217 << 4) | 3;
      write2450reg(mlbuf);
      //reg_frac_div
      mlbuf[0] = (32768 >> 14);
      mlbuf[1] = 0;
      mlbuf[2] = 4;
      write2450reg(mlbuf);
      //bandselpll
      mlbuf[0] = 3;
      mlbuf[1] = 0x86;
      mlbuf[2] = 0x35;
      write2450reg(mlbuf);
      mlbuf[1] = 0x8E;
      write2450reg(mlbuf);*/
    }
//    else if(cur_rxu != last_rxu){
//      change2450freq(0);
//    }
    last_rxu = cur_rxu;//USRP_PA & bmPA_RX_OVERRUN;

    if (usb_setup_packet_avail ())
      usb_handle_setup_packet ();
    
  
    if (GPIFTRIG & bmGPIF_IDLE){

      // OK, GPIF is idle.  Let's try to give it some work.

      // First check for underruns and overruns

/*      if (UC_BOARD_HAS_FPGA && (USRP_PA & (bmPA_TX_UNDERRUN | bmPA_RX_OVERRUN))){
      
	// record the under/over run
	if (USRP_PA & bmPA_TX_UNDERRUN)
	  g_tx_underrun = 1;

	if (USRP_PA & bmPA_RX_OVERRUN)
	  g_rx_overrun = 1;

	// tell the FPGA to clear the flags
	fpga_clear_flags ();
      }*/

      // Next see if there are any "OUT" packets waiting for our attention,
      // and if so, if there's room in the FPGA's FIFO for them.

      if (g_tx_enable && !(EP24FIFOFLGS & 0x02)){  // USB end point fifo is not empty...

	if (fpga_has_room_for_packet ()){	   // ... and FPGA has room for packet

	  GPIFTCB1 = 0x01;	SYNCDELAY;
	  GPIFTCB0 = 0x00;	SYNCDELAY;

	  setup_flowstate_write ();

	  SYNCDELAY;
	  GPIFTRIG = bmGPIF_EP2_START | bmGPIF_WRITE; 	// start the xfer
	  SYNCDELAY;

	  while (!(GPIFTRIG & bmGPIF_IDLE)){
	    // wait for the transaction to complete
	  }
	}
      }

      // See if there are any requests for "IN" packets, and if so
      // whether the FPGA's got any packets for us.

      if (g_rx_enable && !(EP6CS & bmEPFULL)){	// USB end point fifo is not full...

	if (fpga_has_packet_avail ()){		// ... and FPGA has packet available

	  GPIFTCB1 = 0x01;	SYNCDELAY;
	  GPIFTCB0 = 0x00;	SYNCDELAY;

	  setup_flowstate_read ();

	  SYNCDELAY;
	  GPIFTRIG = bmGPIF_EP6_START | bmGPIF_READ; 	// start the xfer
	  SYNCDELAY;

	  while (!(GPIFTRIG & bmGPIF_IDLE)){
	    // wait for the transaction to complete
	  }

	  SYNCDELAY;
	  INPKTEND = 6;	// tell USB we filled buffer (6 is our endpoint num)
	}
      }
    }
  }
}


/*
 * called at 100 Hz from timer2 interrupt
 *
 * Toggle led 0
 */
void
isr_tick (void) interrupt
{
  static unsigned char	count = 1;
  if(start_wait < WAIT_TIME) start_wait++;
  
  if (--count == 0){
    count = 10;
    USRP_LED_REG ^= bmLED0;
    g_ping = 1;
  }

  clear_timer_irq ();
}

/*
 * Read h/w rev code and serial number out of boot eeprom and
 * patch the usb descriptors with the values.
 */
void
patch_usb_descriptors(void)
{
  static xdata unsigned char hw_rev;
  static xdata unsigned char serial_no[8];
  unsigned char i;

  eeprom_read(I2C_ADDR_BOOT, HW_REV_OFFSET, &hw_rev, 1);	// LSB of device id
  usb_desc_hw_rev_binary_patch_location_0[0] = hw_rev;
  usb_desc_hw_rev_binary_patch_location_1[0] = hw_rev;
  usb_desc_hw_rev_ascii_patch_location_0[0] = hw_rev + '0';     // FIXME if we get > 9

  eeprom_read(I2C_ADDR_BOOT, SERIAL_NO_OFFSET, serial_no, SERIAL_NO_LEN);

  for (i = 0; i < SERIAL_NO_LEN; i++){
    unsigned char ch = serial_no[i];
    if (ch == 0xff)	// make unprogrammed EEPROM default to '0'
      ch = '0';
    usb_desc_serial_number_ascii[i << 1] = ch;
  }
}

void
main (void)
{
#if 0
  g_rx_enable = 0;	// FIXME (work around initialization bug)
  g_tx_enable = 0;
  g_rx_overrun = 0;
  g_tx_underrun = 0;
#endif

  memset (hash1, 0, USRP_HASH_SIZE);	// zero fpga bitstream hash.  This forces reload
  
  init_usrp ();
  init_gpif ();
  
  // if (UC_START_WITH_GSTATE_OUTPUT_ENABLED)
  IFCONFIG |= bmGSTATE;			// no conflict, start with it on

  set_led_0 (0);
  set_led_1 (0);
  
  EA = 0;		// disable all interrupts

  patch_usb_descriptors();

  setup_autovectors ();
  usb_install_handlers ();
  hook_timer_tick ((unsigned short) isr_tick);

  EIEX4 = 1;		// disable INT4 FIXME
  EA = 1;		// global interrupt enable

  fx2_renumerate ();	// simulates disconnect / reconnect

  main_loop ();
}
