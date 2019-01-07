# Combines any Left and Right mono tracks to a stereo track.  Needs sox installed.

for file1 in ./*L.wav; do 
   file2=`echo $file1 | sed 's_\(.*\)L.wav_\1R.wav_'`;
   out=`echo $file1 | sed 's_\(.*\)L.wav_\1.wav_'`;
   sox "$file1" "$file2" --channels 2 --combine merge "$out" mixer 0.8,0.2,0.2,0.8
   mv "$file1" mono; mv "$file2" mono;
done

#To save space, convert the files to mp3.  Requires lame installed.
for i in *.wav;
   do lame --preset standard $i `basename $i .wav`.mp3;
done

#Clean up
rm *.wav
