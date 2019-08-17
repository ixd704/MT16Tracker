//-------------------------------------------------------------------------------------//
// converter.c                                                                         // 
// Copyright © 2015 Three Media Tech Co Pvt Ltd,All rights reserved
//
// Module Name      :   Converter
// Descriptions     :   Re-sampling,splitting and convert to .mp3 of Audio files	
// Input            :   Audio files(.bnd,.cmb,.trk)
// Output           :   wav or mp3 Audio files
// Return           :   -
// Initial version  :   1.0
// Modified         :   made changes for extenstion support
// Revision         :   1.1
//-------------------------------------------------------------------------------------


#include <sys/types.h>
#include <sys/stat.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>


#define SAMPLING_RATE_44K		44100
#define SAMPLING_RATE_48K		48000
#define SAMPLING_RATE_96K 		96000
#define SAMPLING_RATE_44K_REV   43297
#define SAMPLING_RATE_96K_REV   86593
#define BIT_RATE                24
#define MAX_CHANNELS            16
#define MIN_CHANNELS            2

	
#define DELETE	      			0
#define DEBUG				    0
#define Debug_print		        printf
#define MP3_ON                  0

enum Status{
    SPLITTING=0,
    PROCESSED,
    RESAMPLE    
};

enum Audio_Format{
    WAV=0,
    MP3    
};

enum Reocrd_Mode{
    SPLIT=0,
    COMBINED    
};

enum Mapping_Mode{
    TRS=1,
    JAMHUB,
    SNAKE_CABLE    
};

/* ------------------- LIST OF FUNCTION ---------------------- */

/* Parse info function is used to read .info file */
int* Parse_info_file(char*);
/* Tans-coder function is used to perform all action according to info file*/
int  Transcoder(char *,int *,char *,char*);
/* Sox function is used to re-sampling of raw audio file */
int  Sox_Execute (int*,char*);
/* De-interleave function is used to split raw audio file or wav file*/
int  Deintreleave_Execute(int*,char*,char*,int);
/* Lame function is used to convert wav file into mp3 format*/
int  Lame_Execute (char*,int*,char*,int);
/* Move_files function is used to move output audio file to given destination folder*/
int  Move_files(char*,int*,char*,int,int);
/* Delete_files function is used to delete temporary files */
int  Delete_files(char*,char*);

int data_info[8];

//////////////////////////////// Main Function ///////////////////////////////////////
// i/p: file name, Destination folder name
int main(int argc, char *argv[]) {
 	
	struct stat sys;
	int* info;
	char file_name[512],st[5]="\0",dest_folder[512];
    //char *p1,*p2;
   // p1=file_name;
   // p2=dest_folder;

	// 0--> status		    1--> audio format
	// 2--> record mode	    3--> channels
	// 4--> sampling rate	5--> mapping mode 
	if (argc < 4) 
    {
		printf("Usage:\n\t%s <path> <file name> -o <path of destination folder>\n\n\tE.g. %s /tmp/TAKE1.bnd -o /tmp/tmp1\n\n", argv[0], argv[0]);
		return -1;
	}
	if(argc == 4)
	{// start of if argc==4
		if((strcmp(argv[2],"-o"))==0)
		{ //start of if strcmp
			/*Check the source file exist or not*/
			if((stat(argv[1], &sys)) == -1)		//It return -1,...source file not exist...
			{
				printf("The Source file: %s does not exist..\n", argv[1]);
				return -1;
			}
			else
			{
                if(strcmp(argv[1],argv[3])==0)
                {
				    printf("The Source file and Destination folder can not be same\nplease assign another Destination folder name\n");
                }
                else
                {
                    memset(file_name, '\0', sizeof(file_name));
                    memset(dest_folder, '\0', sizeof(dest_folder));
                    strncpy(file_name,argv[1],strlen(argv[1])-4); //removing extensions of raw audio file
				    file_name[strlen(argv[1])-4]='\0';
                    strncpy(st,argv[1]+strlen(argv[1])-4,4);
                    st[strlen(st)]='\0';
                			 
				    strcpy(dest_folder,argv[3]);
                	//printf("extension=%s\n",st);
                    #if DEBUG
					    Debug_print("file name:%s\n",file_name);
                        Debug_print("extension=%s\n",st);
					    Debug_print("Destination folder:%s\n",dest_folder);
				    #endif		
				    info=Parse_info_file(file_name);  //calling read file function	
				    Transcoder(file_name,data_info,dest_folder,st); // calling Transcoder function                  
                }					
			}
		}// end of if strcmp
		else
		{
			printf("Error:command does not exist\n");
			printf("Usage:\n\t%s <path> <file name> -o <path of destination folder>\n\n\tE.g. %s /tmp/TAKE1.bnd -o /tmp/tmp1\n\n", argv[0], argv[0]);	
			exit(EXIT_FAILURE);
		}
	}//end of if argc==4
	else
	{
	    /*Check the source file exist or not*/
	    if((stat(argv[1], &sys)) == -1)		//It return -1,...source file not exist...
		{
		    printf("The Source file: %s does not exist..\n", argv[1]);
		    return -1;
		} 
		printf("Error:Destination folder is incorrect\n");
		exit(EXIT_FAILURE);	
	}
	return 0;	
}

//////////////////////////////// Read info File Function ///////////////////////////////////////
/*
	Parse_info_file to read info file and will returns char * status_info
	i/p: file name;
	o/p: info file 
*/
int* Parse_info_file(char* file_name)
{
	FILE *fp;
    char tmp[512],tmp2[512],filename[512],status_info[10],ext[]=".info";
	char *pch,ch;
	int m=0,n=0,i=0,j=0;
	char file_info[][20]={"status","audio_format","record_mode","channels","rate","mapping_mode","ch_map_"};

	strcpy(filename,file_name);	
	strcat(filename,ext); //adding .info ext to tracker file
	#if DEBUG
		Debug_print("info file name:%s\n",filename);
	#endif
	fp=fopen(filename,"r"); //opening .info file	
	if( fp == NULL )
   	{
        perror("Error while opening the file.\n");
        exit(EXIT_FAILURE);
   	}
	while( ( ch = fgetc(fp) ) != EOF ) // reading info file
    {
		tmp[i]=ch;
		i++;	
	}
	tmp[i]='\0';
	#if DEBUG
		Debug_print("info file:%s\n",tmp);
        Debug_print("after split info file\n");
	#endif
	/// splitting all info from info file ///////////
	for(j=0;j<7;j++)
	{ // start of for loop
		for(i=0;i<MAX_CHANNELS;i++)
		{
       		if (pch=strstr(tmp+m,file_info[j]))// searching for status,audio format etc. 
			{
			    m= pch-tmp;
			    strcpy(tmp2,tmp+m);		
			    m=m+1;
			}		
		}
		if(pch=strchr(tmp2,'\n'))
		{// start of if strchr
			n=pch-tmp2;
			strncpy(tmp,tmp2,n);
			tmp[n]='\0';
            #if DEBUG
		        Debug_print("tmp:%s\n",tmp);
	        #endif
			if(pch=strstr(tmp,file_info[6]))// searching for no. of ch_map
			{
				n=pch-tmp;
				strcpy(tmp2,tmp+strlen(file_info[6]));
				tmp2[strlen(file_info[6])+2]='\0';
                #if DEBUG
                    Debug_print("tmp2:%s\n",tmp2);
                #endif
				if(pch=strchr(tmp2,'='))
				{
					n=pch-tmp2;
					strncpy(tmp,tmp2,n);
					tmp[n]='\0';                    
					strcpy(status_info,tmp);
                    #if DEBUG
                        Debug_print("tmp:%s\n",tmp);
                        Debug_print("status_info:%s\n",status_info);
                    #endif			
				}			
			}
			else
			{
				if(pch=strchr(tmp,'='))
				{
					n=pch-tmp;
					strcpy(tmp2,tmp+n+1);                    
					strcpy(status_info,tmp2);
                    #if DEBUG
                        Debug_print("tmp:%s\n",tmp);
                        Debug_print("status_info:%s\n",status_info);
                    #endif			
				}				
			}			
		}// end of if strchr
		data_info[j]=atoi(status_info); //convert all parameters into integer
		#if DEBUG		
		    Debug_print("%s=%d\n",file_info[j],data_info[j]);
		#endif
	}// end of for loop		
    if(fp!=NULL) fclose(fp);
    return data_info;
}


//////////////////////////////// Transcoder Function ///////////////////////////////////////
/*
	Transcoder function is used to check all info file information and do appropriate action
	i/p: file name, info file, destination folder name
	 
*/
int Transcoder(char *file_name,int *data_info,char *dest_folder,char *st)
{
	pid_t  pid; 
	int status_org=data_info[0];
	char ext[][5]={".bnd",".raw",".cmb"};
	char updated_file_name[512],new_file[512],cp_command[1024],sub_file_name[]="_tr",file_name_dlt[512];
	char l='L',r='R';
	int j=1,flag_move=0,flag_sucess=0,flag_set=0;
    int cnt=1,cnt1=0,tp=0;
	int ext_source=0;
    struct stat sys;

    strcpy(new_file,file_name);
     
    while(j)
    {// start of while loop for mutiple files
        //printf("%d\n",j);
	    if(data_info[0]==RESAMPLE) // checking for status
	    {// start of if	checking status = Resample	
		    pid = fork();
		    if (pid == 0) 
		    {
			    Sox_Execute(data_info,file_name); // calling sox command for re-sampling
			    data_info[0]=0;
			    flag_set=1;		
		    }
		    else
		    {
			    printf("Processing...\n"); 
			    int returnStatus;			    
        		waitpid(pid, &returnStatus, 0);
		    }
	    }// end of if checking status = Resample

	    if(data_info[0]==SPLITTING) // checking for status
	    {// start of if checking status = splitting				
		    pid = fork();
		    if (pid == 0)
		    {  				   	 	
			    Deintreleave_Execute(data_info,file_name,dest_folder,status_org); // calling De-interleave command for Splitting 
			    data_info[0]=1;
			    flag_set=1;
		    }
		    else
		    {// start of else checking status = splitting (fork else)
			    if(flag_set==0)
				{
			    	printf("Processing...\n");
				}
			    int returnStatus;       
			    waitpid(pid, &returnStatus, 0);  
			    if(data_info[1]==MP3) //check for .mp3 audio format
			    {// start of if checking audio format= mp3
				    if(data_info[4]==SAMPLING_RATE_44K || data_info[4]==SAMPLING_RATE_48K) // check for sampling rate 44k and 48k
				    {// start of if checking sampling rate = 44k or 48k
					    if(data_info[2]==SPLIT) //check for split record mode
					    {
							    Lame_Execute(file_name,data_info,dest_folder,status_org); // calling lame command for mp3 conversion
							    data_info[0]=1;
							    flag_set=2;							
							    printf("succeeded!!!\n");
                              	flag_sucess=1;
					    }	
					    else if(data_info[2]==COMBINED) //check for  combined record mode
					    {// start of else recorde mode = combined
                            #if MP3_ON
                                    Lame_Execute(file_name,data_info,dest_folder,status_org); // calling lame command for mp3 conversion
								    data_info[0]=1;					
								    printf("succeeded!!!\n");
                                    flag_sucess=1;
                            #else
						    if(data_info[6]<=MIN_CHANNELS) //check for channels less or equal to 2
						    {       
								    Lame_Execute(file_name,data_info,dest_folder,status_org); // calling lame command for mp3 conversion
								    data_info[0]=1;					
								    printf("succeeded!!!\n");
                                    flag_sucess=1;
						    }
                            #endif
						    else
						    {// start of else channels > 2
							    Move_files(file_name,data_info,dest_folder,status_org,flag_move);			
							    if(status_org==RESAMPLE) // check for status
							    {
								    #if DELETE
										sprintf(file_name_dlt,"%s%s",file_name,ext[2]);
										if(((stat(file_name_dlt, &sys)) == 0)) // check for another file exist or not
            							{	
											Delete_files(file_name,ext[1]);	// deleting temp files
											ext_source=2;
										}		
									    Delete_files(file_name,ext[ext_source]);	// deleting temp files
								    #endif	
							    }

							    printf("succeeded!!!\n");
                                flag_sucess=1;						
						    }// end of else channels > 2 							
					    }// end of else recorde mode = combined
				
				    }// end of if checking sampling rate = 44k or 48k
				    else
				    {// start of else sampling rate = 96k
					
				        Move_files(file_name,data_info,dest_folder,status_org,flag_move); // calling move file function
                        if(flag_set==1)
					    {
						    #if DELETE
							    sprintf(file_name_dlt,"%s%s",file_name,ext[2]);
								if(((stat(file_name_dlt, &sys)) == 0)) // check for another file exist or not
            					{
									Delete_files(file_name,ext[1]);	// deleting temp files
									ext_source=2;
								}		
								Delete_files(file_name,ext[ext_source]);	// deleting temp files	
						    #endif	
					    }
					    printf("succeeded!!!\n");
                    	flag_sucess=1;		
				    }// end of else sampling rate = 96k	
		
			    }// end of if checking audio format = mp3
			    else
			    {
				    if(flag_set==1)
				    {				
					    #if DELETE
						    sprintf(file_name_dlt,"%s%s",file_name,ext[2]);
							if(((stat(file_name_dlt, &sys)) == 0)) // check for another file exist or not
            					{
									Delete_files(file_name,ext[1]);	// deleting temp files
									ext_source=2;
								}		
								Delete_files(file_name,ext[ext_source]);	// deleting temp files
					    #endif						
				    }
				    printf("succeeded!!!\n");
                    flag_sucess=1;
			    }
		    }// end of else checking status = splitting (fork else)
	    }// end of if checking status = splitting

        if(flag_sucess==1)
        {// start  of if flag_success=1
            j++;
            if(j>2)
            {
                sprintf(cp_command,"rm -rf %s.info",file_name); // removing temp info file
                system(cp_command);
            }
            sprintf(updated_file_name,"%s_%d%s",new_file,j,st);

            if(((stat(updated_file_name, &sys)) == -1)) // check for another file exist or not
            {
               exit(0);
				             
            }
            else
            {
                printf("%s\n",updated_file_name);
                sprintf(file_name,"%s_%d",new_file,j);
                #if DEBUG
                    Debug_print("%s\n",file_name);
                #endif
                sprintf(cp_command,"cp -r %s.info %s.info",new_file,file_name);
                system(cp_command);
                data_info[0]=status_org;
                flag_move=0;
                flag_sucess=0;
                flag_set=0;    
            }
        }// end of if flag_success=1
        else
        {
            exit(0);            
        }
    }// end of while loop for multiple files

    return 0;
}

//////////////////////////////// Sox execution function ///////////////////////////////////////
/*
	Sox_Execute is used to re-sampling raw audio file
	i/p: info file,file name
	o/p: .bnd file after re-sampling  
*/

int Sox_Execute(int * data_info,char *file_name)
{
	char sox_new[2048],sox_raw[1024],file_name_bnd[512];
	char ext[][5]={".trk",".bnd",".raw",".cmb"};
	int ext_source=0,ext_dest=3;
	struct stat sys;
	//char ext2[]=".cmb";
	sprintf(file_name_bnd,"%s%s",file_name,ext[1]);
	if((stat(file_name_bnd, &sys)) == 0)		//It return -1,...source file not exist...
	{
		sprintf(sox_raw,"sox %s%s --bits %d --encoding signed-integer --endian little -c %d %s%s",file_name,ext[1],BIT_RATE,data_info[3],file_name,ext[2]);
		//printf("%s\n",sox_raw);
		system(sox_raw);
		ext_source=2;
	}
	
	if(data_info[4]==SAMPLING_RATE_96K) // sox command for 96K
	{
		sprintf(sox_new,"sox -t raw -r %d -L -e signed-integer -b %d -c %d %s%s -r  %d -t wav -L -e signed-integer -b %d -c %d %s%s",SAMPLING_RATE_96K_REV,BIT_RATE,data_info[3],file_name,ext[ext_source],data_info[4],BIT_RATE,data_info[3],file_name,ext[ext_dest]);
        #if DEBUG
			Debug_print("sox_command:%s\n",sox_new);
		#endif
	}
	else if(data_info[4]==SAMPLING_RATE_44K) // sox command for 44K
	{
		sprintf(sox_new,"sox -t raw -r %d -L -e signed-integer -b %d -c %d %s%s -r  %d -t wav -L -e signed-integer -b %d -c %d %s%s",SAMPLING_RATE_44K_REV,BIT_RATE,data_info[3],file_name,ext[ext_source],data_info[4],BIT_RATE,data_info[3],file_name,ext[ext_dest]);
       	 #if DEBUG
			Debug_print("sox_command:%s\n",sox_new);
		#endif
	}
	system(sox_new); /// system call for sox command
    return 0;		
}

//////////////////////////////// De-interleave execution Function ///////////////////////////////////////
/*
	De-interleave function is used to sound de-interleave raw audio file and split into .wav format
	i/p: file name, info file,destination folder name, status
	o/p: .wav file after splitting 
*/
	
int Deintreleave_Execute(int *data_info,char* file_name,char* dest_folder,int status_org)
{
	struct stat sys;
	char Snd_command[1024],file_name_cmb[512];
	char ext[][5]={".cmb",".bnd"};
	int flag_move=0, ext_source=1;
	sprintf(file_name_cmb,"%s%s",file_name,ext[0]);	
	if((stat(file_name_cmb, &sys)) == 0)		//It return -1,...source file not exist...
	{
		ext_source=0;
	}
	if(data_info[4]==SAMPLING_RATE_48K) // de-interleave command for 48k
	{
		sprintf(Snd_command,"sndfile-deinterleave %s%s",file_name,ext[ext_source]);
        #if DEBUG
		    Debug_print("De-interleave command:%s\n",Snd_command);
		#endif
	}
	else if(data_info[4]==SAMPLING_RATE_44K || data_info[4]==SAMPLING_RATE_96K) // de-interleave command for 44k and 96k 
	{
		sprintf(Snd_command,"sndfile-deinterleave %s%s",file_name,ext[ext_source]);
        #if DEBUG
		    Debug_print("De-interleave command:%s\n",Snd_command);
		#endif
	}
	system(Snd_command);
		
	if(data_info[1]==WAV) // checking for WAV audio format
	{
		Move_files(file_name,data_info,dest_folder,status_org,flag_move);	
	}
    return 0;    
}

//////////////////////////////// Lame execution Function ///////////////////////////////////////
/*
	Lame_Execute is used to convert .wav audio file to .mp3 file
	i/p: file name, info file,destination folder name, status
	o/p: .mp3 conversion of .wav file 
*/

int Lame_Execute(char* file_name,int* data_info,char *dest_folder,int status_org)
{
	struct stat sys;
	char Lame_command[1024];
	char ext[][5]={".wav",".mp3",".bnd",".raw",".cmb"};
	char sub_file_name[]="_tr";
	char l='L',r='R';
	int i,flag_move=0,ext_source=2;
	char updated_file_name[512],file_name_cmb[512];

	

	if(data_info[5]==TRS || data_info[5]==SNAKE_CABLE) // check for mapping mode
	{// start of if checking mapping mode = TRS or Sanke Cable
		for(i=1;i<=data_info[6];i++)
		{
			sprintf(Lame_command,"lame --quiet %s%s%d%s %s%s%d%s",file_name,sub_file_name,i,ext[0],file_name,sub_file_name,i,ext[1]);
			sprintf(updated_file_name,"%s%s%d%s",file_name,sub_file_name,i,ext[1]);
            #if DEBUG
		        Debug_print("Lame command:%s\n",Lame_command);
                Debug_print("Moving file name:%s\n",updated_file_name);
	        #endif            					
			system(Lame_command); // system call for lame commands
			flag_move=1;
			Move_files(updated_file_name,data_info,dest_folder,status_org,flag_move); // calling move file function
			sprintf(updated_file_name,"%s%s%d",file_name,sub_file_name,i);
			#if DELETE
                #if DEBUG
                    Debug_print("Delete file name:%s\n",updated_file_name);
		        #endif
		        Delete_files(updated_file_name,ext[0]); // calling delete file function
			#endif
	        }
	}// end of if checking mapping mode = TRS or Sanke Cable
	else if(data_info[5]==JAMHUB) // check for mapping mode
	{ // start of else if checking mapping mode = Jamhub
		char temp;
		int t1=1;
		for(i=1;i<=data_info[6];i++)
		{ // start of for loop for no. of ch_map
			if(i%2==0)
			{
				temp=r;		
			}
			else
			{
				temp=l;							
			}
			sprintf(Lame_command,"lame --quiet %s%s%d%c%s %s%s%d%c%s",file_name,sub_file_name,t1,temp,ext[0],file_name,sub_file_name,t1,temp,ext[1]);			
			sprintf(updated_file_name,"%s%s%d%c%s",file_name,sub_file_name,t1,temp,ext[1]);
            
            #if DEBUG
    		    Debug_print("Lame command:%s\n",Lame_command);
                Debug_print("Moving file name:%s\n",updated_file_name);
		    #endif		

			system(Lame_command); // system call for lame commands
			flag_move=1;
			Move_files(updated_file_name,data_info,dest_folder,status_org,flag_move); // calling move file function
			sprintf(updated_file_name,"%s%s%d%c",file_name,sub_file_name,t1,temp);
			if(temp=='R')
			{
				t1++;
			}
			#if DELETE
                #if DEBUG
                    Debug_print("Delete file name:%s\n",updated_file_name);
		        #endif	
				Delete_files(updated_file_name,ext[0]); // calling delete file function
			#endif
		}// end of for loop for no. of ch_map
	}// end of else if checking mapping mode = Jamhub

	if(status_org==RESAMPLE)
	{
		#if DELETE
            #if DEBUG
                Debug_print("Delete file name:%s\n",updated_file_name);
		    #endif
			sprintf(file_name_cmb,"%s%s",file_name,ext[4]);	
			if((stat(file_name_cmb, &sys)) == 0)		//It return -1,...source file not exist...
			{
				Delete_files(file_name,ext[3]); // deleting temp files
				ext_source=4;
			}
			Delete_files(file_name,ext[ext_source]); // deleting temp files
		#endif
	}		
	return 0;
}

//////////////////////////////// Move_files Function ///////////////////////////////////////
/*
	Move files is used to Move new processed audio files file into given destination
	folder.
	i/p: file name, info file,destination folder name, status
	o/p: create directory and move output files
	 
*/
int Move_files(char *file_name,int *data_info,char *dest_folder,int status_org,int flag_move)
{	
	//int status_org=data_info[0];
	char ext[][5]={".cmb",".bnd",".wav"};
	char updated_file_name[512];
	char sub_file_name[]="_tr";
	char l='L',r='R';
	int i;
	char move_command[1024];
	struct stat sys;
	
	if((stat(dest_folder, &sys)) == -1) //It return -1,...destination directory not exist...
	{			
		mkdir(dest_folder,0777); //cerate a destination directory
	}
	
	if(flag_move==1)
	{
		sprintf(move_command,"mv -f %s %s",file_name,dest_folder);
        #if DEBUG
            Debug_print("Move Command:%s\n",move_command);
	    #endif

        if(((stat(file_name, &sys)) == -1)) // check for another file exist or not
        {
            //exit(0);
				             
        }
        else
        {
		    system(move_command);
        }
        flag_move=0;	
	}
	else
	{// start of else flag_moves = 0
		if(data_info[5]==TRS || data_info[5]==SNAKE_CABLE) // check for mapping mode
		{// start of if checking mapping mode = TRS or Snake cable
			for(i=1;i<=data_info[6];i++)
			{
				sprintf(updated_file_name,"%s%s%d%s",file_name,sub_file_name,i,ext[2]);
				sprintf(move_command,"mv -f %s %s",updated_file_name,dest_folder);
                #if DEBUG
                    Debug_print("Move Command:%s\n",move_command);
	            #endif

                if(((stat(updated_file_name, &sys)) == -1)) // check for another file exist or not
                {
                   //exit(0);
				             
                }
                else
                {
				    system(move_command);
                }	
			}
		}// end of if checking mapping mode = TRS or snake cable
		else if(data_info[5]==JAMHUB) // check for mapping mode
		{// start of else if checking mapping mode = Jamhub
			char temp;
			int t1=1;
			for(i=1;i<=data_info[6];i++)
			{// start of for loop for no. of ch_map
				if(i%2==0)
				{
					temp=r;								
				}
				else
				{
					temp=l;
				}
				sprintf(updated_file_name,"%s%s%d%c%s",file_name,sub_file_name,t1,temp,ext[2]);
				if(temp==r)
				{
					t1++;				
				}		
				sprintf(move_command,"mv -f %s %s",updated_file_name,dest_folder);
                #if DEBUG
                    Debug_print("Move Command:%s\n",move_command);
	            #endif

                if(((stat(updated_file_name, &sys)) == -1)) // check for another file exist or not
                {
                //exit(0);
				             
                }
                else
                {
				    system(move_command);
                }
			}// end of for loop	for no. of ch_map	
		}// end of else if checking mapping mode = Jamhub
	}// end of else flag_move = 0		
	return 0;																
}

//////////////////////////////// Delete file Function ///////////////////////////////////////
/*
	Delete files is used to delete re-sample/split tmp file
	i/p: file name,extension
	o/p: delete temporary or unnecessary files 
*/
int Delete_files(char *file_name,char* ext)
{
	char Del_command[1024];
    struct stat sys;

    sprintf(Del_command,"%s%s",file_name,ext);
    if(((stat(Del_command, &sys)) == -1)) // check for another file exist or not
    {
        //exit(0);
				             
    }
    else
    {
	    sprintf(Del_command,"rm %s%s",file_name,ext);
        system(Del_command);
    }
    #if DEBUG
        Debug_print("Delete Command:%s\n",Del_command);
        
	#endif
	//system(Del_command);
    return 0;		
}	

