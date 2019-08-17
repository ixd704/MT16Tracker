//
//  AppDelegate.m
//  BandLab Splitter
//
//  Created by Three MediaTech Co Pvt. Ltd
//  Copyright (c) 2014 Three MediaTech Co Pvt Ltd. All rights reserved.
//

#import "AppDelegate.h"


#define SAMPLING_RATE_44K	    44100
#define SAMPLING_RATE_48K	    48000
#define SAMPLING_RATE_96K	    96000
#define SAMPLING_RATE_44K_REV	43297
#define SAMPLING_RATE_96K_REV	86593
#define BIT_RATE		        24
#define MAX_CHANNELS		    16
#define MIN_CHANNELS            2

#define MP3_OFF_COMBINED    1
#define MP3_ON_COMBINED     0
#define DELETE              0


enum Status{
    SPLITTING=0,
    PROCESSED,
    RESAMPLING
};

enum Audio_Format{
    WAV=0,
    MP3
};

enum Record_Mode{
    SPLIT=0,
    COMBINED
};

enum Mapping_Mode{
    TRS=1,
    JAMHUB,
    SNAKE_CABLE
};


@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    
    NSView *view;
    // Insert code here to initialise your application
    [view enterFullScreenMode:[NSScreen mainScreen] withOptions:nil];
    [_progressBar setHidden:YES];

}

-(BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender	{
    return YES;
}

//// start copy



//// end copy



-(void)open:(id)sender {
    NSOpenPanel *panel;
    NSArray* fileTypes = [[NSArray alloc] initWithObjects:@"bnd", @"BND", @"trk",@"TRK", @"cmb", @"CMB",nil];
    
    // Use libsndfile utilities
    //NSString *deinterleave = @"/Volumes/BandlabSplitter/bin/sndfile-deinterleave";
    //NSString *rename = @"/Volumes/BandlabSplitter/bin/rename-bnd.sh";

    NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:@"OK"]	;
    [alert setMessageText:@"File Splitting Completed"];
    [alert setAlertStyle:NSWarningAlertStyle];
    
    
    NSAlert *alert1 = [[NSAlert alloc] init];
    [alert1 addButtonWithTitle:@"OK"]	;
    [alert1 setMessageText:@"File Splitting and Mp3 conversion Completed"];
    [alert1 setAlertStyle:NSWarningAlertStyle];

    
    NSAlert *alertinfo = [[NSAlert alloc] init];
    [alertinfo addButtonWithTitle:@"OK"]	;
    [alertinfo setMessageText:@" No Info File In Current Directory !!!!"];
    [alertinfo setAlertStyle:NSWarningAlertStyle];

    

    [_progressBar setIndeterminate:YES];
    [_progressBar setStyle:0];
    [_progressBar startAnimation:sender];
    [_progressBar setHidden:YES];
    [_progressView setHidden:YES];
    [_progressView addSubview:_progressBar];


    panel = [NSOpenPanel openPanel];
    [panel setFloatingPanel:YES];
    [panel setCanChooseDirectories:NO];
    [panel setCanChooseFiles:YES];
    [panel setAllowsMultipleSelection:NO];   // Limited to 1 file at a time here
    [panel setAllowedFileTypes:fileTypes];


    [panel beginWithCompletionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton) {//start of if -a

            // Multiple files case
            // NSInteger count = [[panel URLs] count];
            
            // Go through all input files - replace objectAtIndex:0 with objectAtIndex:count
            //for (int i=0; i<count; i++) {
            //NSArray *args1 = [NSArray arrayWithObjects:[[panel URLs] objectAtIndex:0], nil];

            NSArray *args1 = [NSArray arrayWithObjects:[[panel URL] path], nil];
            // [[NSTask launchedTaskWithLaunchPath:deinterleave arguments:args1] waitUntilExit];
             NSArray* outputfile = [[NSArray alloc] initWithArray:args1];
            
            /* Code for reading the info file and doing the resampling for 96k Case only*/
            
            // copy the trk file name to the string
            NSString *infofilepath = [[args1 valueForKey:@"description"] componentsJoinedByString:@""];
            
            NSString *OutfileName = [[args1 valueForKey:@"description"] componentsJoinedByString:@""];
            
            //NSString *file_extension = @".trk";
            //NSRange result2 = [infofilepath rangeOfString:file_extension];

            
            // change the extension to .info.
            infofilepath = [infofilepath stringByReplacingOccurrencesOfString:@".trk" withString:@".info"];
            infofilepath = [infofilepath stringByReplacingOccurrencesOfString:@".cmb" withString:@".info"];
            infofilepath = [infofilepath stringByReplacingOccurrencesOfString:@".bnd" withString:@".info"];
            
            // check if info file exists
            
            NSFileManager *fileManager = [NSFileManager defaultManager];
            
            if ([fileManager fileExistsAtPath:infofilepath]){
                
            }
            else{
                
                if ([alertinfo runModal] == NSAlertFirstButtonReturn)
                {
                    return ;
                    
                };
            }
            NSError *error;
            //// flag initialisation
            short flag_status=-1,flag_audio_format=-1,flag_record_mode=-1,flag_mapping_mode=0,
            flag_move=-1,flag_status_org=-1,j=1,flag_mp3_convert=0;
            NSInteger chnl_int=0,flag_rate=0,flag_file_ext=-1;
            NSString* copy_dest,*copy_src;
            // read the content of file
            NSString *myText = [NSString stringWithContentsOfFile:infofilepath
                                                         encoding:NSUTF8StringEncoding
                                                            error:&error];
            
            // search for status in info file
            NSString *status_2 = @"status=2";
            NSString *status_0 = @"status=0";
            
            NSRange st_result=[myText rangeOfString:status_2];
            if (st_result.location!=NSNotFound) {
                flag_status=flag_status_org=2;
            }
            else { // start of else
                st_result = [myText rangeOfString:status_0];
                if (st_result.location!=NSNotFound) {
                    flag_status=0;
                }
            
            }// end of else
            
            // search for  sampling rate in info file
            NSString *rate_96 = @"rate=96000";
            NSString *rate_44 = @"rate=44100";
            NSString *rate_48 = @"rate=48000";
            
            // search for  sampling rate=96k
            NSRange result = [myText rangeOfString:rate_96];
            if (result.location!=NSNotFound) {
                flag_rate=96000;
            }
            else{ //start of else 44k
                result = [myText rangeOfString:rate_44];
                // search for  sampling rate=44K
                if (result.location!=NSNotFound) {
                    flag_rate=44100;
                }
                else { //start of else for 48K
                    result = [myText rangeOfString:rate_48];
                    // search for  sampling rate=48k
                    if (result.location!=NSNotFound) {
                        flag_rate=48000;
                    }
                }// end of else for 48K
            }// end of else 44K
            
            
            //// counting actual channel mapped
            NSUInteger count_channel = 0, length = [myText length];
            NSRange range = NSMakeRange(0, length);
            while(range.location != NSNotFound)
            {
                range = [myText rangeOfString: @"ch_map_" options:0 range:range];
                if(range.location != NSNotFound)
                {
                    range = NSMakeRange(range.location + range.length, length - (range.location + range.length));
                    count_channel++;
                }
            }

            [_progressBar setHidden:NO];
            [_progressView setHidden:NO];
            
            // convert channel into integer
            NSString *chnl_str = @"channels=";
            
            // Search the file contents for the given string, put the results into an NSRange structure
            //NSRange result = [myText rangeOfString:rate];
            NSRange result1 = [myText rangeOfString:chnl_str];
            
            NSUInteger indexOfChnl = result1.location +result1.length;
            NSString *chnl_cnt = [myText substringWithRange:NSMakeRange(indexOfChnl, 2)];
            chnl_cnt = [[chnl_cnt componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]] componentsJoinedByString:@""];
            // call the sox utility for resampling the file
            chnl_int = [chnl_cnt integerValue];
            
            // rangeOfString returns the location of the string NSRange.location or NSNotFound.
            //checking for status = 2 for resampling
            /// start of  Main while loop for multiple files
            while(j)
            {/// start of while loop
                if (flag_status== RESAMPLING) { //start of if for status= resampling
                    NSString* soxinputarg,*soxoutputarg,*sox_raw_input,*sox_raw_output;
                    NSArray *tmp_nsar1,*tmp_nsar2,*tmp_nsar3,*tmp_nsar4;
                    NSMutableArray* args3,*args4;
                    NSMutableArray* newarray;
                    // set flag value for splitting
                    flag_status=SPLITTING;
                
                    // check for sampling rate =96k
                    
                    //NSString *string = @"";
                    if ([OutfileName rangeOfString:@"trk"].location == NSNotFound) {
                        flag_file_ext=1;
                        
                        sox_raw_input=OutfileName;
                        sox_raw_output=[sox_raw_input stringByReplacingOccurrencesOfString:@".bnd" withString:@".raw"];
                        sox_raw_input=[sox_raw_input stringByAppendingString:@" --bits 24 --encoding signed-integer --endian little -c "];
                        sox_raw_input = [sox_raw_input stringByAppendingString:chnl_cnt];
                           NSLog(@"%@\n",sox_raw_input);
                        tmp_nsar3 = [sox_raw_input componentsSeparatedByString:@" "];
                        tmp_nsar4 = [sox_raw_output componentsSeparatedByString:@" "];
                        
                        args4 = [[NSMutableArray alloc]init];
                        [args4 addObjectsFromArray:tmp_nsar3];
                        [args4 addObjectsFromArray:tmp_nsar4];
                        //NSLog(@"\n\n\%@",args4);
                        

                        NSTask *SoXtask1 = [[NSTask alloc] init];
                        
                        [SoXtask1 setLaunchPath:[[NSBundle mainBundle] pathForResource:@"sox" ofType:@""]];
                        [SoXtask1 setArguments:args4];
                        [SoXtask1 launch];
                        [SoXtask1 waitUntilExit];
                        [SoXtask1 terminate];
                        
                    }
                    if(flag_rate==SAMPLING_RATE_96K) { // start of if for Sampling rate 96k
                        // Prepare the input argument
                        
                        soxinputarg = @"-t raw -r 86593 -L -e signed-integer -b 24 -c ";
                        soxinputarg = [soxinputarg stringByAppendingString:chnl_cnt];
                
                        // Prepare the output argument
                
                        soxoutputarg = @"-r 96000 -t wav -L -e signed-integer -b 24 -c ";
                        soxoutputarg = [soxoutputarg stringByAppendingString:chnl_cnt];
                
                        // Convert NSString to NSArray.. as the seArgument takes NSArray
                        tmp_nsar1 = [soxinputarg componentsSeparatedByString:@" "];
                        tmp_nsar2 = [soxoutputarg componentsSeparatedByString:@" "];
                
                        args3 = [[NSMutableArray alloc]init];
                        [args3 addObjectsFromArray:tmp_nsar1];
                        
                
                        // NSMutableArray* outputfile = [[NSMutableArray alloc] initWithArray:args1];
                        newarray = [[NSMutableArray alloc] initWithArray:0];
                        if(flag_file_ext==1)
                        {
                            [args3 addObjectsFromArray:tmp_nsar4];
                            for(NSString __strong *mystr in outputfile){
                            mystr = [mystr stringByReplacingOccurrencesOfString:@"bnd"
                                                             withString:@"cmb"];
                            [newarray addObject:mystr];
                            // [outputfile replaceObjectAtIndex:numObjects withObject:mystr];
                            NSLog(@"rate found in file");
                            }
                        }
                        else
                        {
                            [args3 addObjectsFromArray:args1];
                            for(NSString __strong *mystr in outputfile){
                            mystr = [mystr stringByReplacingOccurrencesOfString:@"trk"
                                                                     withString:@"cmb"];
                            [newarray addObject:mystr];
                            // [outputfile replaceObjectAtIndex:numObjects withObject:mystr];
                            NSLog(@"rate found in file");
                            
                            }
                        }
                
                        [args3 addObjectsFromArray:tmp_nsar2];
                        [args3 addObjectsFromArray:newarray];
                        
                        NSTask *SoXtask = [[NSTask alloc] init];
                        
                        [SoXtask setLaunchPath:[[NSBundle mainBundle] pathForResource:@"sox" ofType:@""]];
                        [SoXtask setArguments:args3];
                        [SoXtask launch];
                        [SoXtask waitUntilExit];
                        [SoXtask terminate];
                    
                    } //end of if for sampling rate 96k
                    // check for sampling rate =44k
                    else if(flag_rate==SAMPLING_RATE_44K) { //start of else if for sampling rate 44k
                        // Prepare the output argument
                        soxinputarg = @"-t raw -r 43297 -L -e signed-integer -b 24 -c ";
                        soxinputarg = [soxinputarg stringByAppendingString:chnl_cnt];
                        
                        // Prepare the output argument
                        // Change the outfile name to .bnd
                        //OutfileName = [OutfileName stringByReplacingOccurrencesOfString:@".trk" withString:@".bnd"];
                        
                        soxoutputarg = @"-r 44100 -t wav -L -e signed-integer -b 24 -c ";
                        
                        soxoutputarg = [soxoutputarg stringByAppendingString:chnl_cnt];
                    
                        
                        // Convert NSString to NSArray.. as the seArgument takes NSArray
                        tmp_nsar1 = [soxinputarg componentsSeparatedByString:@" "];
                        tmp_nsar2 = [soxoutputarg componentsSeparatedByString:@" "];
                    
                        args3 = [[NSMutableArray alloc]init];
                        [args3 addObjectsFromArray:tmp_nsar1];
                        
                        
                        
                        // NSMutableArray* outputfile = [[NSMutableArray alloc] initWithArray:args1];
                        newarray = [[NSMutableArray alloc] initWithArray:0];
                        if(flag_file_ext==1)
                        {
                            [args3 addObjectsFromArray:tmp_nsar4];
                            for(NSString __strong *mystr in outputfile){
                                mystr = [mystr stringByReplacingOccurrencesOfString:@"bnd"
                                                                         withString:@"cmb"];
                                [newarray addObject:mystr];
                                // [outputfile replaceObjectAtIndex:numObjects withObject:mystr];
                                NSLog(@"rate found in file");
                            }
                        }
                        else
                        {
                            [args3 addObjectsFromArray:args1];
                            for(NSString __strong *mystr in outputfile){
                                mystr = [mystr stringByReplacingOccurrencesOfString:@"trk"
                                                                         withString:@"cmb"];
                                [newarray addObject:mystr];
                                // [outputfile replaceObjectAtIndex:numObjects withObject:mystr];
                                NSLog(@"rate found in file");
                                
                            }
                        }
                        
                        [args3 addObjectsFromArray:tmp_nsar2];
                        [args3 addObjectsFromArray:newarray];
                    

                    
                    } // end of else if for sampling rate 44k
                    //// calling Sox command for re-sampling
                    NSTask *SoXtask = [[NSTask alloc] init];
                    
                    [SoXtask setLaunchPath:[[NSBundle mainBundle] pathForResource:@"sox" ofType:@""]];
                    [SoXtask setArguments:args3];
                    [SoXtask launch];
                    [SoXtask waitUntilExit];
                    [SoXtask terminate];
                    // prepare input arg for snd-interleave
                    if(flag_file_ext==1)
                    {
                    
                        OutfileName = [OutfileName stringByReplacingOccurrencesOfString:@".bnd" withString:@".cmb"];
                        NSFileManager *fileManager2 = [NSFileManager defaultManager];
                            [fileManager2 removeItemAtPath:sox_raw_output error:&error];
                        
                    }
                    else
                    {
                        OutfileName = [OutfileName stringByReplacingOccurrencesOfString:@".trk" withString:@".cmb"];
                    }
                    outputfile = [[NSArray alloc] initWithArray:newarray];
                    
                } // end of if for status= resampling
                // End of code for SoX resampling
            
                //// start of code for De-interlave
                /// checking for status=splitting
                    if (flag_status==SPLITTING) { // start of if status=splitting
                        /// calling snd-interleave command for splitting
                        flag_move=0;
                        NSTask *task1 = [[NSTask alloc] init];
                        [task1 setLaunchPath:[[NSBundle mainBundle] pathForResource:@"snd_new" ofType:@""]];
                        [task1 setArguments:outputfile];
                        [task1 launch];
                        [task1 waitUntilExit];
                        
                        if(flag_status_org==RESAMPLING)
                        {
                            NSFileManager *fileManager3 = [NSFileManager defaultManager];
                                [fileManager3 removeItemAtPath:OutfileName error:&error];
                        }
                        
                        // search for audio format=.mp3 in info file
                        NSString *audio_format = @"audio_format=1";
                        NSRange af_result = [myText rangeOfString:audio_format];
                        if (af_result.location!=NSNotFound) {
                            flag_audio_format=MP3;
                        }
                
                        // search for mapping mode in info file
                        NSString *mapping_mode_TRS = @"mapping_mode=1";
                        NSString *mapping_mode_JAMHUB = @"mapping_mode=2";
                        NSString *mapping_mode_SC = @"mapping_mode=3";
                
                        NSRange mm_result = [myText rangeOfString:mapping_mode_TRS];
                        // search for mapping mode=TRS
                        if (mm_result.location!=NSNotFound){
                            flag_mapping_mode=TRS;
                        }
                        else{ //start of else mapping mode = JAMHUB
                            NSRange mm_result = [myText rangeOfString:mapping_mode_JAMHUB];
                            // search for mapping mode=JAMHUB
                            if (mm_result.location!=NSNotFound){
                                flag_mapping_mode=JAMHUB;
                            }
                            else{ //start of else mapping mode= Snake Cable
                                NSRange mm_result = [myText rangeOfString:mapping_mode_SC];
                                // search for mapping mode= Sanke Cable
                                if (mm_result.location!=NSNotFound) {
                                    flag_mapping_mode=SNAKE_CABLE;
                                }
                            }// end of else mapping mode= Snake Cable
                        } // end of else mapping mode= JAMHUB
                
                        //check for audio format = mp3
                        if (flag_audio_format==MP3) { //start of if audio format = mp3
                            //check for sampling rate < 96k
                            if (flag_rate<SAMPLING_RATE_96K) { //start of if sampling rate 96k
                     
                                //search for record mode in info file
                                NSString *record_mode_split = @"record_mode=0";
                                NSString *record_mode_combined = @"record_mode=1";
                                NSRange rm_result = [myText rangeOfString:record_mode_split];
                                //search for record mode= split
                                if (rm_result.location!=NSNotFound) {
                                    flag_record_mode=SPLIT;
                                }
                                else { //start of else record mode combine
                                    NSRange rm_result = [myText rangeOfString:record_mode_combined];
                                    //search for record mode= combined
                                    if(rm_result.location!=NSNotFound){
                                        flag_record_mode=COMBINED;
                                    }
                                }// end of else recode mode combined
                                if(flag_record_mode ==COMBINED)
                                {
                                    if(count_channel<=MIN_CHANNELS)
                                    {
                                        flag_mp3_convert=MP3;
                                    }
                                }
                                //check for record mode = split
                            #if MP3_OFF_COMBINED
                                if (flag_record_mode==SPLIT || flag_mp3_convert==MP3)
                            #endif
                                { //start of if record mode = split
                                    flag_move=1;
                                    int i=1;
                                    NSString *move_dest,*theFileName,*input_lame,*output_lame;
                                    NSString *newString = [OutfileName substringToIndex:[OutfileName length]-4];
                            
                                    /// create directory for moving output files
                                    NSError *error;
                                    NSFileManager *filemgr;
                            
                                    filemgr = [NSFileManager defaultManager];
                                    if (![[NSFileManager defaultManager] createDirectoryAtPath:newString
                                                                   withIntermediateDirectories:NO
                                                                                    attributes:nil
                                                                                         error:&error])
                                    {
                                        NSLog(@"Create directory error: %@", error);
                                    }
                                    /// check for mapping mode TRS or Sanke cable
                                    if(flag_mapping_mode==TRS || flag_mapping_mode==SNAKE_CABLE)
                                    {// start of if mapping mode TRS/Snake Cable
                                        for (i=1; i<=count_channel; i++) // loop for lame command for each wav file
                                        {// start of for loop
                                            // prepare input arg for lame command
                                            input_lame = [NSString stringWithFormat:@"%@_tr%d.wav",newString,i];
                                            // prepare output arg for lame command
                                            output_lame=[input_lame stringByReplacingOccurrencesOfString:@".wav" withString:@".mp3"];
                            
                                            // Convert NSString to NSArray.. as the seArgument takes NSArray
                                            NSArray *tmp_nsar1 = [input_lame componentsSeparatedByString:@" "];
                                            NSArray *tmp_nsar2 = [output_lame componentsSeparatedByString:@" "];
                                    
                                            NSMutableArray* args3 = [[NSMutableArray alloc]init];
                                            [args3 addObjectsFromArray:tmp_nsar1];
                                            [args3 addObjectsFromArray:tmp_nsar2];
                                
                                            // calling lame command to convert .wav file into .mp3
                                            NSTask *Lametask = [[NSTask alloc] init];
                                            [Lametask setLaunchPath:[[NSBundle mainBundle] pathForResource:@"lame" ofType:@""]];
                                            [Lametask setArguments:args3];
                                            [Lametask launch];
                                            [Lametask waitUntilExit];
                                            [Lametask terminate];
                                    
                                            //// move command for moving output to destination folder
                                            // prepare output arg for move command
                                            move_dest = [NSString stringWithFormat:@"%@/",newString];
                                            theFileName = [output_lame lastPathComponent] ;
                                            move_dest = [NSString stringWithFormat:@"%@%@",move_dest,theFileName];
                                            /// calling move command
                                            NSLog(@"src=%@\n dest=%@",output_lame,move_dest);
                                            if ([filemgr moveItemAtPath:output_lame toPath:move_dest error: NULL]  == YES) {
                                                NSLog (@"move successful");
                                            }
                                            else {
                                                NSLog (@"move failed");
                                            }
                                            // calling remove file to delete tmp files
                                            [filemgr removeItemAtPath:input_lame error:&error];
                                        } //end of for loop
                                    }// end of if mapping mode TRS/Snake Cable
                                    // checking mapping mode = JAMHUB
                                    else if(flag_mapping_mode==JAMHUB)
                                    { // start of else mapping mode JAMHUB
                                        int t1=1;
                                        char sub_ext='L';
                                        for (i=1; i<=count_channel; i++) /// loop to convert each wav file into mp3
                                        { // start of for loop
                                            if(i%2==0)
                                            {
                                                sub_ext='R';
                                            }
                                            else
                                            {
                                                sub_ext='L';
                                            }
                                            // prepare input arg for lame command
                                            input_lame = [NSString stringWithFormat:@"%@_tr%d%c.wav",newString,t1,sub_ext];
                                            // prepare output arg for lame command
                                            output_lame=[input_lame stringByReplacingOccurrencesOfString:@".wav" withString:@".mp3"];
                                            if(sub_ext=='R')
                                            {
                                                t1++;
                                            }
                                            // Convert NSString to NSArray.. as the seArgument takes NSArray
                                            NSArray *tmp_nsar1 = [input_lame componentsSeparatedByString:@" "];
                                            NSArray *tmp_nsar2 = [output_lame componentsSeparatedByString:@" "];
                                            NSMutableArray* args3 = [[NSMutableArray alloc]init];
                                            [args3 addObjectsFromArray:tmp_nsar1];
                                            [args3 addObjectsFromArray:tmp_nsar2];
                                    
                                            // calling lame command to convert .wav file into .mp3
                                            NSTask *Lametask = [[NSTask alloc] init];
                                            [Lametask setLaunchPath:[[NSBundle mainBundle] pathForResource:@"lame" ofType:@""]];
                                            [Lametask setArguments:args3];
                                            [Lametask launch];
                                            [Lametask waitUntilExit];
                                            [Lametask terminate];
                                    
                                    
                                            //// move command for moving output to destination folder
                                            // prepare output arg for move command
                                            move_dest = [NSString stringWithFormat:@"%@/",newString];
                                            theFileName = [output_lame lastPathComponent] ;
                                            move_dest = [NSString stringWithFormat:@"%@%@",move_dest,theFileName];
                                            /// calling move command
                                            NSLog(@"src=%@\n dest=%@",output_lame,move_dest);
                                            if ([filemgr moveItemAtPath:output_lame toPath:move_dest error: NULL]  == YES) {
                                                NSLog (@"move successful");
                                            }
                                            else {
                                                NSLog (@"move failed");
                                            }
                                            // calling remove file to delete tmp files
                                            [filemgr removeItemAtPath:input_lame error:&error];
                                    
                                        } // end of for loop
                                    } // end of else mapping mode JAMHUB
                                } // end of if record mode = split
                            } // end of if sampling rate 96k
                        } /// end of if audio format = mp3
                    } // end of if status=splitting
                //// end of code for De-interleave and lame
                //checking for flag_move =0 for moving splitter files
                if(flag_move==0){ // start of if move =0
                    // moving o directory for wav format
                    NSError *error;
                    NSFileManager *filemgr;
                    int i=1;
                    NSString *move_src,*move_dest,*theFileName;
                
                    /// creating directory to move output files
                    // preparing for folder name
                    NSString *folder_name = [OutfileName substringToIndex:[OutfileName length]-4];
                    filemgr = [NSFileManager defaultManager];
                    if (![[NSFileManager defaultManager] createDirectoryAtPath:folder_name
                                                            withIntermediateDirectories:NO
                                                                            attributes:nil
                                                                            error:&error])
                    {
                        NSLog(@"Create directory error: %@", error);
                    }
                    /// checking mapping mode = TRS or Snake cable
                    if(flag_mapping_mode==TRS || flag_mapping_mode==SNAKE_CABLE)
                    { //start of if mapping mode =TRS/Snake Cable
                        for (i=1; i<=count_channel; i++) //loop for moving each .wav files into folder
                        { //start of for loop
                            // prepare input arg for src for move command
                            move_src = [NSString stringWithFormat:@"%@_tr%d.wav",folder_name,i];
                            // prepare output arg for lame command
                            move_dest = [NSString stringWithFormat:@"%@/",folder_name];
                            theFileName = [move_src lastPathComponent] ;
                            move_dest = [NSString stringWithFormat:@"%@%@",move_dest,theFileName];
                            // calling move command
                            if ([filemgr moveItemAtPath:move_src toPath:move_dest error: NULL]  == YES)
                            {
                                NSLog (@"move successful");
                            }
                            else
                            {
                                NSLog (@"move failed");
                            }
                        } //end of for loop
                    }// end of if mapping mode = TRS/Snake Cable
                    /// checking mapping mode = JAMHUB
                    else if(flag_mapping_mode==JAMHUB)
                    { //start of else if mapping mode = JAMHUB
                        int t1=1;
                        char sub_ext='L';
                        for (i=1; i<=count_channel; i++) //loop for moving each .wav files into folder
                        { // start of for loop
                            if(i%2==0){
                                sub_ext='R';
                            }
                            else{
                                sub_ext='L';
                            }
                            // prepare input arg for src for move command
                            move_src = [NSString stringWithFormat:@"%@_tr%d%c.wav",folder_name,t1,sub_ext];
                            // prepare output arg for lame command
                            move_dest = [NSString stringWithFormat:@"%@/",folder_name];
                            theFileName = [move_src lastPathComponent] ;
                            move_dest = [NSString stringWithFormat:@"%@%@",move_dest,theFileName];
                            // calling move command
                            if ([filemgr moveItemAtPath:move_src toPath:move_dest error: NULL]  == YES)
                            {
                                NSLog (@"move successful");
                            }
                            else
                            {
                                NSLog (@"move failed");
                            }
                            if(sub_ext=='R')
                            {
                                t1++;
                            }
                        }// end of for loop
                    }// end of else if mapping mode = JAMHUB
                } // end of if move =0
                j++;
                //// check for more than one part if file have
                NSFileManager *fileManager1 = [NSFileManager defaultManager];
                /// check for loop and delete temp info file
                if(j>2)
                {
                    [fileManager1 removeItemAtPath:copy_dest error:&error];
                }
                //// prepare for info tmp info file for more part of tracker file
                NSString *file_part_trk = [NSString stringWithFormat:@"_%d.trk",j];
                NSString *file_part_bnd = [NSString stringWithFormat:@"_%d.bnd",j];
                NSString *file_part_cmb = [NSString stringWithFormat:@"_%d.cmb",j];
                NSString *fil_part_info =[NSString stringWithFormat:@"_%d.info",j];
                OutfileName = [[args1 valueForKey:@"description"] componentsJoinedByString:@""];
                OutfileName=[OutfileName stringByReplacingOccurrencesOfString:@".trk" withString:file_part_trk];
                OutfileName=[OutfileName stringByReplacingOccurrencesOfString:@".bnd" withString:file_part_bnd];
                OutfileName=[OutfileName stringByReplacingOccurrencesOfString:@".cmb" withString:file_part_cmb];

                //// outputfile is now jth part of tracker file
                outputfile = [OutfileName componentsSeparatedByString:@" "];
                NSFileManager *filemgr = [NSFileManager defaultManager];
                //// checking for other part of file is present or not
                if ([filemgr fileExistsAtPath:OutfileName]){
                    //NSLog(@"file:%@\n",OutfileName);
                    //NSLog(@"file exist\n");
                    /// prepare input for copy info file
                    copy_src = [NSString stringWithFormat:@"%@",infofilepath];
                    /// prepare output for copy info file
                    copy_dest = [infofilepath stringByReplacingOccurrencesOfString:@".info" withString:fil_part_info];
                    
                    // calling copy command
                    if ([filemgr copyItemAtPath:copy_src toPath:copy_dest error: NULL]  == YES) {
                        NSLog (@"move successful");
                    }
                    else {
                        NSLog (@"move failed");
                    }
                    
                    flag_status=flag_status_org;

                }
                else{
                    
                    break;
                }
            
            }//// End of while loop
            [_progressBar setHidden:YES];
            if(flag_move==0)
            {
                if ([alert runModal] == NSAlertFirstButtonReturn)
                {

                };
            }
            else if(flag_move==1)
            {
                if ([alert1 runModal] == NSAlertFirstButtonReturn)
                {
                    
                };
            }
        } // end of if -a
    }];
}

@end
