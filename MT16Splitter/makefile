# change application name here (executable output name)
TARGET=MT16Splitter
 
# compiler
CC=gcc
# debug
DEBUG=-g
# optimisation
OPT=-O0
# warnings
WARN=-Wall
 
PTHREAD=-pthread
 
CCFLAGS=$(DEBUG) $(OPT) $(WARN) $(PTHREAD) -pipe
 
GTKLIB=`pkg-config --cflags --libs gtk+-3.0`

SNDLIB=`pkg-config --cflags --libs sndfile`
 
# linker
LD=gcc
LDFLAGS=$(PTHREAD) $(GTKLIB) $(SNDLIB) -export-dynamic
 
OBJS=    MT16Splitter.o
 
all: $(OBJS)
	$(LD) -o $(TARGET) $(OBJS) $(LDFLAGS)
    
MT16Splitter.o: src/MT16Splitter.c
	$(CC) -c $(CCFLAGS) src/MT16Splitter.c $(GTKLIB) $(SNDLIB) -o MT16Splitter.o
	
clean:
	rm -f *.o $(TARGET)
