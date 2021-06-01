fref = 100e6;
f0 = 5e9;   %Currently unused
fbw = 10e6;   %Arbitrary
S1MHz = -120;   %Arbitrary
N = 10;

KVCO_SS = 8.484e9;    
KVCO_NN = 11.403e9;
KVCO_FF = 16.289e9;   

b = 25;

zero1 = fbw / sqrt(b);
zero2 = fbw * sqrt(b);

PM = atand((sqrt(b)-1/sqrt(b))/2); 
IcpR = (b/(b-1))*(2*pi*N*fbw/KVCO_NN);
RC2 = sqrt(b)/(2*pi*fbw);

%% Calculate Capacitances + Resistance + Icp based on max area
Cmax = 20e-12;
C2 = Cmax*(b-1)/b;
C1 = C2/(b-1);
R = RC2/C2;
Icp = IcpR / R;

%% Open Loop Response
Tau2 = RC2;
Taup = Tau2/b;
K = ((b-1)/b)*IcpR*KVCO_NN/(2*pi*N);

n = [K*Tau2, K];
d = [Tau2*Taup, Tau2, 0, 0];
T = tf(n,d);
figure(1);
bode(T);

%% Closed Loop Response
n = [Tau2, 1];
d = [(Tau2*Taup/K), (Tau2/K), (Tau2), 1];
APLL = tf(N*n,d);
APHI = tf(n,d);
figure(2);
bode(APLL);
%freqs(n,d,w);

%% Calculate Jitter

%Reference
PhiRef = 10^-10*tf([1/10^6, 2/1000, 1],[1,0,0]); 
%freqs((10^-10).*[1/10^6, 2/1000, 1],[1,0,0]); %Verify Shape
REF_TF = N*APLL;
PhaseNoiseREF = PhiRef*REF_TF;
figure(3);
freqs(PhaseNoiseREF.numerator{1,1}, PhaseNoiseREF.denominator{1,1});

%LPF
k = 1.38*10^-23; %Boltzmann
T = 300.15;      %Temp
vnLPF = (b-1)/b*tf(1,[Taup,1])*4*k*T*R;
Fs = R*(b-1)/b*tf([Tau2,1],[Tau2*Taup,Tau2,0]);
LPF_TF = 2*pi/Icp*(1/Fs)*APLL;
PhaseNoiseLPF = vnLPF*LPF_TF;
figure(4);
freqs(PhaseNoiseLPF.numerator{1,1}, PhaseNoiseLPF.denominator{1,1});

%VCO %Behavioral Fix?
PSD_VCO = tf(10^10*[10^-24,(10^-18+10^-15),(2*10^-9+10^-6),1],[1,0,0,0]);
%freqs(10^10*[10^-24,(10^-18+10^-15),(2*10^-9+10^-6),1],[1,0,0,0],logspace(3,12));%Verifyshape
VCO_TF = tf([Taup*Tau2/K,Tau2/K,0,0],[Tau2*Taup/K, Tau2/K, Tau2, 1]);
PhaseNoiseVCO = PSD_VCO*VCO_TF;
figure(5);
freqs(PhaseNoiseVCO.numerator{1,1}, PhaseNoiseVCO.denominator{1,1});

