/*
 ============================================================================
 Name        : MT16Splitter.c
 Author      : Ian Douglas
 Version     : 0.1
 Copyright   : Released to all with restrictions listed below
 Description : JamHub MT16 Tracker combined file splitter
 ============================================================================
 Contact steve.skillings@jamhub.com to get a MT16 Tracker sent to you.
 */


#include <gtk/gtk.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sndfile.h>
#include <pthread.h>

#define	BUFFER_LEN	4096
#define	MAX_CHANNELS	16


typedef struct {
	SNDFILE * infile ;
	SNDFILE * outfile [MAX_CHANNELS] ;

	union
	{	double	d [MAX_CHANNELS * BUFFER_LEN] ;
	int		i [MAX_CHANNELS * BUFFER_LEN] ;
	} din ;
	union
	{	double	d [BUFFER_LEN] ;
	int		i [BUFFER_LEN] ;
	} dout ;
	int channels ;
	char channelMap [MAX_CHANNELS][26];
} STATE ;

static void usage_exit (void) ;

static void deinterleave_int (STATE * state) ;
static void deinterleave_double (STATE * state) ;
gboolean inc_progress() ;
void* waitloop(void* arg);
int runit (char *thefile) ;

static float percent = 0.0;
char *filename;

GtkProgressBar *g_prg_bar_mt16;
GtkWidget *g_btn_filechooser;
GtkWidget *window;
int running = 0;

int main(int argc, char *argv[])
{
	GError *err = NULL;
	GtkBuilder      *builder;
	//GtkWidget       *window;

	pthread_t wait_thread;
	if(pthread_create(&wait_thread, NULL, waitloop, (void *) NULL)) {
		printf("Error creating thread\n");
		return 1;
	}

	gtk_init(&argc, &argv);

	builder = gtk_builder_new();

	if(0 == gtk_builder_add_from_file (builder, "glade/window_main.glade", &err))
	{
		/* Print out the error. You can use GLib's message logging */
		printf("Error adding build from file. Error: %s\n", err->message);
		/* Your error handling code goes here */
	}

	window = GTK_WIDGET(gtk_builder_get_object(builder, "window_main"));
	gtk_builder_connect_signals(builder, NULL);

	g_timeout_add(500, inc_progress, g_prg_bar_mt16);     // 300 ms

	// get pointers to the two labels
	g_prg_bar_mt16 = GTK_WIDGET(gtk_builder_get_object(builder, "prg_bar_mt16"));
	g_btn_filechooser = GTK_WIDGET(gtk_builder_get_object(builder, "btn_filechooser"));


	g_object_unref(builder);

	gtk_widget_show(window);
	gtk_main();

	return 0;
}

// called when window is closed
void on_window_main_destroy() {
	gtk_main_quit();
}

int on_btn_filechooser_clicked() {
	//gtk_label_set_text(GTK_LABEL(g_btn_filechooser), "Select a MT16 File!");
	GtkWidget *dialog;

	GtkFileChooserAction action = GTK_FILE_CHOOSER_ACTION_OPEN;
	gint res;

	dialog = gtk_file_chooser_dialog_new ("Open File",window,action,"Cancel",GTK_RESPONSE_CANCEL,"Open",GTK_RESPONSE_ACCEPT,NULL);

	res = gtk_dialog_run (GTK_DIALOG (dialog));
	if (res == GTK_RESPONSE_ACCEPT)
	{
		GtkFileChooser *chooser = GTK_FILE_CHOOSER (dialog);
		filename = gtk_file_chooser_get_filename (chooser);
	}

	gtk_widget_destroy (dialog);

	return 0;
}



gboolean inc_progress() {
	if (filename != NULL) {
		percent += 0.05;
		if(percent > 1.0)
			percent = 0.0;
		gtk_progress_bar_set_fraction( g_prg_bar_mt16, percent);
	}
	return TRUE;

}

void* waitloop(void * arg) {
	do  {
		percent = 0.0;
	} while (filename == NULL);
	runit(filename);

	return NULL;
}



// Note:  This modified section of code falls under the license as set out below.

/*
** Copyright (C) 2009-2017 Erik de Castro Lopo <erikd@mega-nerd.com>
**
** All rights reserved.
**
** Redistribution and use in source and binary forms, with or without
** modification, are permitted provided that the following conditions are
** met:
**
**     * Redistributions of source code must retain the above copyright
**       notice, this list of conditions and the following disclaimer.
**     * Redistributions in binary form must reproduce the above copyright
**       notice, this list of conditions and the following disclaimer in
**       the documentation and/or other materials provided with the
**       distribution.
**     * Neither the author nor the names of any contributors may be used
**       to endorse or promote products derived from this software without
**       specific prior written permission.
**
** THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
** "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
** TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
** PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
** CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
** EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
** PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
** OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
** WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
** OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
** ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

int runit (char *thefile) {
	STATE state ;

	SF_INFO sfinfo ;

	char pathname [512], ext [32], *cptr ;
	int ch, double_split ;

	memset (&state, 0, sizeof (state)) ;
	memset (&sfinfo, 0, sizeof (sfinfo)) ;

	// set some base mapping.  This is for a direct JamHub connection.
	strcpy(state.channelMap[0],"6R");
	strcpy(state.channelMap[1],"2R");
	strcpy(state.channelMap[2],"4R");
	strcpy(state.channelMap[3],"0R");
	strcpy(state.channelMap[4],"6L");
	strcpy(state.channelMap[5],"2L");
	strcpy(state.channelMap[6],"4L");
	strcpy(state.channelMap[7],"0L");
	strcpy(state.channelMap[8],"7R");
	strcpy(state.channelMap[9],"3R");
	strcpy(state.channelMap[10],"5R");
	strcpy(state.channelMap[11],"1R");
	strcpy(state.channelMap[12],"7L");
	strcpy(state.channelMap[13],"3L");
	strcpy(state.channelMap[14],"5L");
	strcpy(state.channelMap[15],"1L");

	if ((state.infile = sf_open (thefile, SFM_READ, &sfinfo)) == NULL)
	{	printf ("\nError : Not able to open input file '%s'\n%s\n", thefile, sf_strerror (NULL)) ;
	exit (1) ;
	} ;

	if (sfinfo.channels < 2)
	{	printf ("\nError : Input file '%s' only has one channel.\n", thefile) ;
	exit (1) ;
	} ;

	if (sfinfo.channels > MAX_CHANNELS)
	{	printf ("\nError : Input file '%s' has too many (%d) channels. Limit is %d.\n",
			thefile, sfinfo.channels, MAX_CHANNELS) ;
	exit (1) ;
	} ;

	state.channels = sfinfo.channels ;
	sfinfo.channels = 1 ;

	if (snprintf (pathname, sizeof (pathname), "%s", thefile) > (int) sizeof (pathname))
	{	printf ("\nError : Length of provided filename '%s' exceeds MAX_PATH (%d).\n", thefile, (int) sizeof (pathname)) ;
	exit (1) ;
	} ;

	if ((cptr = strrchr (pathname, '.')) == NULL)
		ext [0] = 0 ;
	else
	{	snprintf (ext, sizeof (ext), "%s", cptr) ;
	cptr [0] = 0 ;
	} ;

	char mapfile[250];
	snprintf (mapfile, sizeof (mapfile), "%s.map", pathname);
	FILE *map;

	map = fopen(mapfile,"r");
	if (map==NULL)
	{
		printf("No map file \n");
	} else
	{
		for (int x = 0; x < MAX_CHANNELS; x++)
			fscanf (map, "%25s", state.channelMap[x]);

		printf("Map file : %s\n", mapfile);
	}

	printf ("Input file : %s\n", pathname) ;
	puts ("Output files :") ;

	for (ch = 0 ; ch < state.channels ; ch++)
	{	char filename [520] ;

	snprintf (filename, sizeof (filename), "%s_%s.wav", pathname, state.channelMap[ch]) ;
	//snprintf (filename, sizeof (filename), "%s_%02d.wav", pathname, ch) ;

	if ((state.outfile [ch] = sf_open (filename, SFM_WRITE, &sfinfo)) == NULL)
	{	printf ("Not able to open output file '%s'\n%s\n", filename, sf_strerror (NULL)) ;
	exit (1) ;
	} ;

	printf ("    %s\n", filename) ;
	} ;

	switch (sfinfo.format & SF_FORMAT_SUBMASK)
	{	case SF_FORMAT_FLOAT :
	case SF_FORMAT_DOUBLE :
	case SF_FORMAT_VORBIS :
		double_split = 1 ;
		break ;

	default :
		double_split = 0 ;
		break ;
	} ;

	if (double_split)
		deinterleave_double (&state) ;
	else
		deinterleave_int (&state) ;

	sf_close (state.infile) ;
	for (ch = 0 ; ch < MAX_CHANNELS ; ch++)
		if (state.outfile [ch] != NULL)
			sf_close (state.outfile [ch]) ;

	gtk_main_quit();
	return 0 ;
} /* main */

/*------------------------------------------------------------------------------
 */

static void usage_exit (void){
	puts ("\nUsage : sndfile-deinterleave <filename>\n") ;
	puts (
			"Split a mutli-channel file into a set of mono files.\n"
			"\n"
			"If the input file is named 'a.wav', the output files will be named\n"
			"a_00.wav, a_01.wav and so on.\n"
	) ;

	printf ("Using %s.\n\n", sf_version_string ()) ;

	exit (1) ;
} /* usage_exit */

static void deinterleave_int (STATE * state) {
	int read_len ;
	int ch, k ;

	do
	{
		read_len = sf_readf_int (state->infile, state->din.i, BUFFER_LEN) ;

		for (ch = 0 ; ch < state->channels ; ch ++)
		{
			for (k = 0 ; k < read_len ; k++)
				state->dout.i [k] = state->din.i [k * state->channels + ch] ;
			sf_write_int (state->outfile [ch], state->dout.i, read_len) ;
		} ;
	}
	while (read_len > 0) ;

} /* deinterleave_int */

static void deinterleave_double (STATE * state) {
	int read_len ;
	int ch, k ;

	do
	{
		read_len = sf_readf_double (state->infile, state->din.d, BUFFER_LEN) ;

		for (ch = 0 ; ch < state->channels ; ch ++)
		{
			for (k = 0 ; k < read_len ; k++)
				state->dout.d [k] = state->din.d [k * state->channels + ch] ;
			sf_write_double (state->outfile [ch], state->dout.d, read_len) ;
		} ;
	}
	while (read_len > 0) ;

} /* deinterleave_double */

