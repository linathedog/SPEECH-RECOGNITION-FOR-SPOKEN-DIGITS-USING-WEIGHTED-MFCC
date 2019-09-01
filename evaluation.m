
%% test_IWD1.m
%% Isolated Word Detector

clear
clf
cd(fileparts(which(mfilename)));
cd Samples
%modeltraining();
sequence = [];
matrix = zeros(10,10);
%% Parameters Definition
Fs=8000;         
%% Sampling Frequency after downsample
nfft=1024;                  %% fft length used in spectral calculations
%f=Fs*[0:nfft/2-1]/nfft;    %% Frequency index used in x-axis of spectrums
hpforder=30;                %% order of highpass filter  
lowcut=100;                 %% low band reject frequency   (Hz)
highcut=200;                %% high band cut-off frequency (Hz)
                            % transition between lowcut-highcut
% step 4
    
%% Frame Duration in ms
NS=30;                      %% Frame Duration in ms
L=NS*Fs/1000;               %% Frame Duration in samples
MS=10;                      %% Frame Shift in ms
R=MS*Fs/1000;               %% Frame Shift in samples


%% Step 1
%% load speech file
files = dir('*.wav'); 

for filenum=1:length(files)
    filename =files(filenum).name; 
    [speech,FsOrig]=audioread(filename);
    

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

subplot(221)
stem(speech)
xlabel('Sample')
ylabel('Amplitude')
title(['Original Speech Signal with Fs=' num2str(FsOrig) 'Hz'])
grid on

subplot(223)
stem(x)
xlabel('Sample')
ylabel('Amplitude')
title(['Reasmpled Speech Signal with new Fs=' num2str(Fs) 'Hz'])
grid on

subplot(222)
[Sspeech,f]=freqz(speech,1,1024,FsOrig);
plot(f,20*log10(abs(Sspeech)))
xlabel('Frequency (Hz)')
ylabel('Magnitude (dB)')
title(['Original Speech Signal Spectrum with Fs=' num2str(FsOrig) 'Hz'])
grid on

subplot(224)
[Sx,f]=freqz(x,1,1024,Fs);
plot(f,20*log10(abs(Sx)))
xlabel('Frequency (Hz)')
ylabel('Magnitude (dB)')
title(['Resampled Speech Signal Spectrum with new Fs=' num2str(Fs) 'Hz'])
grid on

 
%% Step 3
% highpass filtering 
% Band reject 0-100Hz
% Band transition 100-200Hz
% Bandpass 100-4000Hz
hpfilter=firpm(hpforder,[0 lowcut highcut Fs/2]/(Fs/2),[0 0 1 1]);
y=filter(hpfilter,1,x);

subplot(311)
[Sx,f]=freqz(x,1,1024,Fs);
plot(f,20*log10(abs(Sx)))
xlabel('Frequency (Hz)')
ylabel('Magnitude (dB)')
title(['Resampled Speech Signal and High Pass filter response'])
grid on
hold on
[HP,f]=freqz(hpfilter,1,1024,Fs);
plot(f,20*log10(abs(HP)),'r')

subplot(312)
[Sy,f]=freqz(y,1,1024,Fs);
plot(f,20*log10(abs(Sy)))
xlabel('Frequency (Hz)')
ylabel('Magnitude (dB)')
title(['High Pass Filtered Resampled Speech Signal Spectrum'])
grid on

subplot(313)
stem(y)
xlabel('Sample')
ylabel('Amplitude')
title(['High Pass Filtered Resampled Speech Signal'])
grid on

%% Step 4 
%% Frame Parameters Definition in the beginning section of this code


 
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
%zerocrossings = normalized (per 10 msec) zero crossings contour for utterance
clf
subplot(311)
stem(y)
maxAmpl=max(abs(y));
axis([1 totalFrames*R -abs(maxAmpl) abs(maxAmpl)])
xlabel('Sample')
ylabel('Amplitude')
title(['High Pass Filtered Resampled Speech Signal'])
grid on
hold on

subplot(312)
stem(energy)
hold on
axis([1 totalFrames min(energy) max(energy)])
xlabel('Frame')
ylabel('Energy')
title(['Logarimthmic Energy of Each Frame of speech signal'])
grid on

subplot(313)
stem(zerocrossings)
hold on
axis([1 totalFrames 0 50])
xlabel('Frame')
ylabel('Zerocrossings')
title(['Zerocrossings of Each Frame of speech signal'])
grid on


 
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

subplot(312)
plot(1:totalFrames,ITU*ones(totalFrames),'g')
plot(1:totalFrames,ITL*ones(totalFrames),'g')
title(['Logarimthmic Energy of Each Frame of speech signal and Thresholds'])
hold on

subplot(313)
plot(1:totalFrames,IZCT*ones(totalFrames),'g')
title(['Zerocrossings of Each Frame of speech signal and Threshold'])
hold on


%% Step 8
%% Using the digitsseperation function we seperate 
[separators] = digitseparation(energy,ITU,ITL);

for i=1:(length(separators)-1)
    digitEN=energy(separators(i):separators(i+1));
    digitZR=zerocrossings(separators(i):separators(i+1));
    %% Calculate Endpoints using endpints function
    [B2,E2,B1,E1]=endpoints(digitEN,digitZR,ITU,ITL,IZCT);
    % plot vertical red lines showing endpoints

    B2 = B2+separators(i)-1;
    B1 = B1+separators(i)-1;
    E1 = E1+separators(i)-1;
    E2 = E2+separators(i)-1;
    digitstart = (B2-1)*R+1;
    digitend = (E2-1)*R+L-1;
    digit = y(digitstart:digitend);
    winL = 25;
    winS = 10;
    
    digits = [B2 E2 digits];
    subplot(312)
    y1=get(gca,'ylim');
    plot([B1 B1],y1,'k')
    plot([E1 E1],y1,'k')
    plot([B2 B2],y1,'r')
    plot([E2 E2],y1,'r')
    [WMFCC] = wmfcc(digit,Fs,winS,winL);
    cd ..
    save('WMFCC.mat','WMFCC');
    cd Trained
    result=recognition();
    sequence = [ result sequence];
    if filename(5)=='Z'
        label = 1;
    else
        label = str2double(filename(5))+1;
    end
    matrix(result+1,label) = matrix(result+1,label) +1;
end
sequence
end
%% Step 9
%% Play extracted word
%startSample=(B2-1)*R+1;
%endSample=(E2-1)*R+L-1;
%     startSample = (digits(1)-1)*R+1;
%     endSample = (digits(2)-1)*R+L-1;
%     z=y(startSample:endSample);
%     soundsc(z,Fs);
% plot vertical red lines showing endpoints




