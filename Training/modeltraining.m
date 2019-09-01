function modeltraining()
clear
clf
cd(fileparts(which(mfilename)));
files = dir('*.wav'); 
cd ./../Trained;
for filenum=1:length(files)
    filename =files(filenum).name; 
    [speech,FsOrig]=audioread(filename);
    soundsc(speech,FsOrig);


%% Parameters Definition
Fs=8000;                    %% Sampling Frequency after downsample
nfft=1024;                  %% fft length used in spectral calculations
%f=Fs*[0:nfft/2-1]/nfft;    %% Frequency index used in x-axis of spectrums
hpforder=30;                %% order of highpass filter  
lowcut=100;                 %% low band reject frequency   (Hz)
highcut=200;                %% high band cut-off frequency (Hz)
                            % transition between lowcut-highcut
% step 4
NS=30;     
%% Frame Duration in ms
L=NS*Fs/1000;               %% Frame Duration in samples
MS=10;                      %% Frame Shift in ms
R=MS*Fs/1000;               %% Frame Shift in samples

%% Step 1
%% load speech file


%% preemphasis
B = [1,-0.95];
speech = filter(B,1,speech,[],2);
%% normalize data
speechMin=min(speech);
speechMax=max(speech);
speech=speech/max(speechMax,-speechMin);

%% Step 2
%% resample input signal
x=resample(speech,Fs,FsOrig);
%% Step 3
%% highpass filtering 
%% Band reject 0-100Hz
%% Band transition 100-200Hz
%% Bandpass 100-4000Hz
hpfilter=firpm(hpforder,[0 lowcut highcut Fs/2]/(Fs/2),[0 0 1 1]);
y=filter(hpfilter,1,x);

%% Step 5
%% Calculate logarithmic energy and zero crossing rate for every frame
totalSamples=length(y);
ss=1;
energy=[];
zerocrossings=[];
% retrieve frames from speech signal y 
while (ss+L-1 <= totalSamples)
    frame=y(ss:ss+L-1).*hamming(L);
    energy=[energy 10*log10(sum(frame.^2))];
    zerocrossings=[zerocrossings sum(abs(diff(sign(frame))))];
    ss=ss+R;
end
totalFrames=length(energy);
zerocrossings=zerocrossings*R/(2*L);

%% Step 6
%% Calculate average and standard deviation 
%% of energy and zerocrossing for background signal
%% e.g first 10 frame of signal
trainingFrames=10;              %% first 10 frames 
eavg=mean(energy(1:trainingFrames))
esig=std(energy(1:trainingFrames))
zcavg=mean(zerocrossings(1:trainingFrames))
zcsig=std(zerocrossings(1:trainingFrames))

%% Step 7
%% Calculate Detection Parameters
IF=35                       %% Constant Zero Crossing Threshold         
IZCT=max(IF,zcavg+3*zcsig)  %% Variable Zero Crossing Threshold
                            %% Depends on Training
IMX=max(energy)             %% Max Log Energy
ITU=IMX-20                  %% High Log Energy Threshold
ITL=max(eavg+3*esig, ITU-10)%% Low Log Energy Threshold
%% Step 8
%% Calculate Endpoints using endpints function
[B2,E2,B1,E1]=endpoints(energy,zerocrossings,ITU,ITL,IZCT);

digitstart = (B2-1)*R+1;
digitend = (E2-1)*R+L-1;
digit = y(digitstart:digitend);
winL = 25;
winS = 10;
[WMFCC] = wmfcc(digit,Fs,winS,winL);

filesavename = filename(1:6)+".mat";
save(filesavename,'WMFCC');
soundsc(digit,Fs);
end
end