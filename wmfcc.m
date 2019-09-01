function [WMFCC] = wmfcc(Digit,Fs,winS,winL)
   L = winL*Fs/1000; %% Frame Duration in Samples
   R = winS*Fs/1000; %% Frame Shift in Samples
   E = ((length(Digit)-L)/R)+1;
   [coeffs,delta,deltaDelta] = mfcc(Digit,Fs,'LogEnergy','Replace','WindowLength',L,'OverlapLength',L-R);
   [WMFCC] = coeffs + 1/3 * delta + 1/6 * deltaDelta;
end