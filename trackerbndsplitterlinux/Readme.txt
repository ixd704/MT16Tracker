--------------------------------------JAMHUB Tracker MT16-------------------------------------------------------------
Software requirements:-
 ->	libsndfile
 ->	lame mp3 encoder
 ->	sox

	Installation procedure on linux system:-

1)	libsndfile
	
		./configure
		make
		make install

	Since libsndfile optionally links against libFLAC, libogg and libvorbis, you
	will need to install appropriate versions of these libraries before running
	configure as above.

2)	lame mp3 encoder
		./configure
		make
		make install

3)	sox
		./configure
		make
		make install

Create a object file of your program
	gcc filename.c -o objectfilename
 #converter argv[1] -o argv[3]

