#define _GNU_SOURCE
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/syscall.h>
#include <sys/mman.h>
#include <assert.h>
#include <ctype.h>
#include <stdio.h>
#include <fcntl.h>
#include <string.h>
#include <unistd.h>
#include <stdlib.h>
#include <signal.h>
#include <netinet/in.h>

#if defined (__i386__)
#include <sys/vm86.h>
#include <sys/io.h>
#endif
#if defined (__i386__) || defined (__x86_64__)
#include "vbe.h"
#include "include/lrmi.h"
#endif
#include <byteswap.h>
#include "common.h"
#include "vesamode.h"

char *snip(char *string)
{
	int i;
	
	/* This is always a 13 character buffer */
	/* and it's not always terminated. */
	string[12] = '\0';
	
	while(((i = strlen(string)) > 0) &&
	       (isspace(string[i - 1]) ||
	        (string[i - 1] == '\n') ||
	        (string[i - 1] == '\r'))) {
		string[i - 1] = '\0';
	}
	return string;
}

int main(int argc, char **argv)
{
	struct edid1_info *edid_info = NULL;
	char manufacturer[4];
	int i;
	struct vbe_parent_info *vbe_parent_info = NULL;
	struct vbe_info *vbe_info = NULL;
#if defined (__i386__) || defined (__x86_64__)
	u_int16_t *mode_list = NULL;
#endif /* __i386__ */
	unsigned char *timings;
	struct edid_monitor_descriptor *monitor;
	unsigned char *timing;

#if defined (__i386__) || defined (__powerpc__) || defined (__x86_64__)
	assert(sizeof(struct edid1_info) == 256);
	assert(sizeof(struct edid_detailed_timing) == 18);
	assert(sizeof(struct edid_monitor_descriptor) == 18);
	assert(sizeof(struct vbe_info) == 512);
#endif

	vbe_parent_info = vbe_get_vbe_info();
	vbe_info = &vbe_parent_info->vbe;
	if(vbe_info == NULL) {
		fprintf(stderr, "VESA BIOS Extensions not detected.\n");
		exit(1);
	}
        else {
#ifdef __powerpc__
	       printf("oem: %s\n", vbe_parent_info->oem_name_string);
	       printf("memory: %dkb\n", vbe_info->memory_size);
	}
#elif defined (__i386__) || defined (__x86_64__)
		/* Signature. */
		printf("vbe: %c%c%c%c %d.%d detected.\n",
		       vbe_info->signature[0], vbe_info->signature[1],
		       vbe_info->signature[2], vbe_info->signature[3],
		       vbe_info->version[1], vbe_info->version[0]);

		/* OEM Strings. */
		printf("oem: %s\n", vbe_parent_info->oem_name_string);
		if(vbe_info->version[1] >= 3) {
			printf("vendor: %s\n",
			       vbe_parent_info->vendor_name_string);
			printf("product: %s %s\n",
			       vbe_parent_info->product_name_string,
			       vbe_parent_info->product_revision_string);
		}

	       if (strcasestr(vbe_parent_info->oem_name_string, "intel")
		   && strstr(vbe_parent_info->oem_name_string, "810")) {
		       printf("memory: %dkb\n", vbe_info->memory_size * 64);
		       printf("memory: 4096kb\n");
	       } else
		       printf("memory: %dkb\n", vbe_info->memory_size * 64);

		/* List supported standard modes. */
		mode_list = vbe_parent_info->mode_list_list;
		for(;*mode_list != 0xffff; mode_list++) {
			int i;
			for(i = 0; known_vesa_modes[i].x != 0; i++) {
				if(known_vesa_modes[i].number == *mode_list) {
					printf("mode: %s\n", known_vesa_modes[i].text);
				}
			}
		}
	}
#else
                fprintf(stderr, "Sorry, unsupported architecture\n");
                exit(1);
        }
#endif 

	if(!get_edid_supported()) {
		printf("noedid\n");
		exit(0);
	}

	edid_info = get_edid_info();

    printf("edid: %s\n", edid_info);

	/* Interpret results. */
	if((edid_info == NULL) || (edid_info->version == 0)) {
		printf("edidfail\n");
		exit(0);
	}

	if ((edid_info->version == 0xff && edid_info->revision == 0xff)
	    || (edid_info->version == 0 && edid_info->revision == 0)) {
		printf("edidfail\n");
		exit(0);
	}	    

	printf("edid: %d %d\n",
	       edid_info->version, edid_info->revision);

	manufacturer[0] = edid_info->manufacturer_name.char1 + 'A' - 1;
	manufacturer[1] = edid_info->manufacturer_name.char2 + 'A' - 1;
	manufacturer[2] = edid_info->manufacturer_name.char3 + 'A' - 1;
	manufacturer[3] = '\0';
	printf("id: %04x\n", edid_info->product_code);
	printf("eisa: %s%04x\n", manufacturer, edid_info->product_code);
	
	if(edid_info->serial_number != 0xffffffff) {
		if(strcmp(manufacturer, "MAG") == 0) {
			edid_info->serial_number -= 0x7000000;
		}
		if(strcmp(manufacturer, "OQI") == 0) {
			edid_info->serial_number -= 456150000;
		}
		if(strcmp(manufacturer, "VSC") == 0) {
			edid_info->serial_number -= 640000000;
		}
	}
	printf("serial: %08x\n", edid_info->serial_number);

	printf("manufacture: %d %d\n",
	       edid_info->week, edid_info->year + 1990);

	printf("input: %s%s%s%s.\n",
	       edid_info->video_input_definition.separate_sync ?
	       "separate sync, " : "",
	       edid_info->video_input_definition.composite_sync ?
	       "composite sync, " : "",
	       edid_info->video_input_definition.sync_on_green ?
	       "sync on green, " : "",
	       edid_info->video_input_definition.digital ?
	       "digital signal" : "analog signal");

	printf("screensize: %d %d\n",
	       edid_info->max_size_horizontal,
	       edid_info->max_size_vertical);

	printf("gamma: %f\n", edid_info->gamma / 100.0 + 1);

	printf("dpms: %s, %s%s, %s%s, %s%s\n",
	       edid_info->feature_support.rgb ? "RGB" : "non-RGB",
	       edid_info->feature_support.active_off ? "" : "no ", "active off",
	       edid_info->feature_support.suspend ? "" : "no ", "suspend",
	       edid_info->feature_support.standby ? "" : "no ", "standby");

	if(edid_info->established_timings.timing_720x400_70)
		printf("timing: 720x400@70 Hz (VGA 640x400, IBM)\n");
	if(edid_info->established_timings.timing_720x400_88)
		printf("timing: 720x400@88 Hz (XGA2)\n");
	if(edid_info->established_timings.timing_640x480_60)
		printf("timing: 640x480@60 Hz (VGA)\n");
	if(edid_info->established_timings.timing_640x480_67)
		printf("timing: 640x480@67 Hz (Mac II, Apple)\n");
	if(edid_info->established_timings.timing_640x480_72)
		printf("timing: 640x480@72 Hz (VESA)\n");
	if(edid_info->established_timings.timing_640x480_75)
		printf("timing: 640x480@75 Hz (VESA)\n");
	if(edid_info->established_timings.timing_800x600_56)
		printf("timing: 800x600@56 Hz (VESA)\n");
	if(edid_info->established_timings.timing_800x600_60)
		printf("timing: 800x600@60 Hz (VESA)\n");
	if(edid_info->established_timings.timing_800x600_72)
		printf("timing: 800x600@72 Hz (VESA)\n");
	if(edid_info->established_timings.timing_800x600_75)
		printf("timing: 800x600@75 Hz (VESA)\n");
	if(edid_info->established_timings.timing_832x624_75)
		printf("timing: 832x624@75 Hz (Mac II)\n");
	if(edid_info->established_timings.timing_1024x768_87i)
		printf("timing: 1024x768@87 Hz Interlaced (8514A)\n");
	if(edid_info->established_timings.timing_1024x768_60)
		printf("timing: 1024x768@60 Hz (VESA)\n");
	if(edid_info->established_timings.timing_1024x768_70)
		printf("timing: 1024x768@70 Hz (VESA)\n");
	if(edid_info->established_timings.timing_1024x768_75)
		printf("timing: 1024x768@75 Hz (VESA)\n");
	if(edid_info->established_timings.timing_1280x1024_75)
		printf("timing: 1280x1024@75 (VESA)\n");

	/* Standard timings. */
	for(i = 0; i < 8; i++) {
		double aspect = 1;
		unsigned int x, y;
		unsigned char xres, vfreq;
		xres = edid_info->standard_timing[i].xresolution;
		vfreq = edid_info->standard_timing[i].vfreq;
		if((xres != vfreq) ||
		   ((xres != 0) && (xres != 1)) ||
		   ((vfreq != 0) && (vfreq != 1))) {
			switch(edid_info->standard_timing[i].aspect) {
				case 0: aspect = 1; break; /*undefined*/
				case 1: aspect = 0.750; break;
				case 2: aspect = 0.800; break;
				case 3: aspect = 0.625; break;
			}
			x = (xres + 31) * 8;
			y = x * aspect;
			printf("ctiming: %dx%d@%d\n", x, y,
			       (vfreq & 0x3f) + 60);
		}
	}

	/* Detailed timing information. */
	/* The original dtiming code didn't actually work at all, so I've
	 * removed it and replaced it with my own dtiming code, which is derived
	 * from the VESA spec and parse-edid.c. How well it works on monitors
	 * with multiple dtimings is unknown, since I don't have one. -daniels */
	timings = (unsigned char *)&edid_info->monitor_details.detailed_timing;
	monitor = NULL;
	for(i = 0; i < 4; i++) {
		timing = &(timings[i*18]);
		if (timing[0] == 0 && timing[1] == 0) {
			monitor = &edid_info->monitor_details.monitor_descriptor[i];
			if (monitor->type == edid_monitor_descriptor_serial)
				printf("monitorserial: %s\n", snip(monitor->data.string));
			else if (monitor->type == edid_monitor_descriptor_ascii)
				printf("monitorid: %s\n", snip(monitor->data.string));
			else if (monitor->type == edid_monitor_descriptor_name)
				printf("monitorname: %s\n", snip(monitor->data.string));
			else if (monitor->type == edid_monitor_descriptor_range)
				printf("monitorrange: %d-%d, %d-%d\n",
				       monitor->data.range_data.horizontal_min,
				       monitor->data.range_data.horizontal_max,
				       monitor->data.range_data.vertical_min,
				       monitor->data.range_data.vertical_max);
		}
		else {
			int h_active_high, h_active_low, h_active;
			int h_blanking_high, h_blanking_low, h_blanking;
			int v_active_high, v_active_low, v_active;
			int v_blanking_high, v_blanking_low, v_blanking;
			int pixclock_high, pixclock_low, pixclock;
			int h_total, v_total, vfreq;
			pixclock_low = timing[0];
			pixclock_high = timing[1];
			pixclock = ((pixclock_high << 8) | pixclock_low) * 10000;
			h_blanking_high = ((1|2|4|8) & (timing[4])) >> 4;
			h_blanking_low = timing[3];
			h_blanking = ((h_blanking_high) << 8) | h_blanking_low;
			h_active_high = ((128|64|32|16) & (timing[4])) >> 4;
			h_active_low = timing[2];
			h_active = ((h_active_high) << 8) | h_active_low;
			h_total = h_active + h_blanking;
			v_blanking_high = ((1|2|4|8) & (timing[7])) >> 4;
			v_blanking_low = timing[6];
			v_blanking = ((v_blanking_high) << 8) | v_blanking_low;
			v_active_high = ((128|64|32|16) & (timing[7])) >> 4;
			v_active_low = timing[5];
			v_active = ((v_active_high) << 8) | v_active_low;
			v_total = v_active + v_blanking;
			vfreq = (double)pixclock/((double)v_total*(double)h_total);
			printf("dtiming: %dx%d@%d\n", h_active, v_active, vfreq);
		}
	}

	return 0;
}

