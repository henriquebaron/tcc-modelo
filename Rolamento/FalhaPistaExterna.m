% Calcula a vibracao em um rolamento com dano pontual na pista externa.

clearvars;

%----- Entrada de dados -----%
t0 = 0; % Instante inicial
tf = 0.2; % Instante final
N = 1800; % Velocidade de rotacao, em revolucoes por minuto

% Dados do rolamento - 6004 2RSH
Db = 6.35e-3; % Diametro das esferas, metros
Nb = 9; % Numero de esferas
m_b = 1.05e-3; % Massa de cada esfera, kg
alpha = 0; % Angulo de contato do rolamento
c_r = 7e-6; % Folga radial (radial clearance), metros
E = 200e9; % Modulo de elasticidade do aco dos aneis e esferas, Pa
ni = 0.3; % Coeficiente de Poisson para aneis e esferas
rolos = false; % Rolamento � de rolos?

% Propriedades do anel externo do rolamento
anelExt.D = 42e-3; % Diametro externo da pista externa, metros
anelExt.D2 = 37.19e-3; % Diametro interno da pista externa, metros
anelExt.m = 0.035; % Massa, kg
anelExt.mu = 0.289; % Massa linear, kg/m
anelExt.I = 31.802e-12; % Momento de inercia, m^4
anelExt.Rneu = 19.43e-3; % Raio da linha neutra, m
anelExt.rx = 18.68e-3; % Raio de curvatura no eixo X, m
anelExt.ry = 3.18e-3; % Raio de curvatura no eixo Y (groove), m

% Propriedades do anel interno do rolamento
anelInt.D = 20e-3; % Diametro interno da pista interna, metros
anelInt.D2 = 24.65e-3; % Diametro externo da pista interna, metros
anelInt.m = 0.022; % Massa, kg
anelInt.mu = 0.301; % Massa linear, kg/m
anelInt.I = 37.424e-12; % Momento de inercia, m^4
anelInt.Rneu = 11.65e-3; % Raio da linha neutra, m
anelInt.rx = 12.32e-3; % Raio de curvatura no eixo X, m
anelInt.ry = 3.18e-3; % Raio de curvatura no eixo Y (groove), m

% Propriedades do lubrificante - ISO VG 32 @ 40�C
visc = 32e-6; % Viscosidade cinematica, m^2/s (1 m^2/s = 10^6 centistokes)
rho = 861; % Massa especifica, kg/m^3
kf = 68.3; % Rigidez do filme de fluido a 1800 RPM, N/m^nf
nf = 1.388; % Expoente para calculo da forca de restauracao
cf = 18.027; % Amortecimento do filme de fluido a 1800 RPM, N*s/m

% Propriedades do defeito e carregamento
Cmax = 100; % Carga maxima aplicada no eixo, newtons
theta = 0; % Angulo entre a carga e o defeito na pista externa
d_def = 0.1e-3; % Tamanho do defeito, metros
da = 0; % Deslocamento axial provocado pelo defeito, metros
dr = 1e-3; % Deslocamento radial provocado pelo defeito, metros

%------------------------------------------------------------------------%
% Propriedades derivadas do rolamento
c_d = 2*c_r; % Folga diametral (diametral clearance), metros
Dp = (anelExt.D + anelInt.D)/2; % Pitch diameter, metros
rb = Db/2; % Raio das esferas, metros

% Velocidades angulares dos aneis interno e externo
% Como os rolamentos s�o embutidos no mancal, a velocidade angular do
% anel externo e sempre nula.
anelInt.omega = N*pi/30;
anelExt.omega = 0;

% Frequencias principais do rolamento
% Fundamental Train Frequency
FTF = 0.5*(anelInt.omega*(1-cos(alpha)*Db/Dp) + ...
        anelExt.omega*(1+cos(alpha)*Db/Dp));
% Ball Pass Frequency, Outer
BPFO = Nb/2*(anelInt.omega-anelExt.omega)*(1-cos(alpha)*Db/Dp);
% Ball Pass Frequency, Inner
BPFI = Nb/2*(anelInt.omega-anelExt.omega)*(1+cos(alpha)*Db/Dp);
% Ball Spin Frequency
BSF = Dp/(2*Db)*(anelInt.omega-anelExt.omega)*(1-cos(alpha)^2*Db^2/Dp^2);

% Propriedades da coleta de dados
% Frequ�ncia de amostragem � m�ltipla da frequ�ncia em que uma esfera
% incide sobre um defeito na pista externa.
Fs = 10*BPFO/(2*pi); 
T = 1/Fs; % Per�odo de cada amostra
L = (tf-t0)/T; % Comprimento do sinal
if mod(L,floor(L))>0 % Se L n�o for inteiro
    L = ceil(L);
end
if mod(L,2)>0 % Se L n�o for par
    L = L+1;
end
t = t0+(0:L-1)*T; % Vetor tempo

% Determinacao do carregamento estatico
epsilon = 1/2*(1+tan(alpha)*da/dr);

% Frequencias naturais - aneis externo e interno
% Segundo modo de vibra��o do anel considerado
FreqNatural = @(n,E,I,mu,R) n*(n^2-1)/sqrt(1+n^2)*sqrt(E*I/(mu*R^4));
anelExt.omega_n = FreqNatural(2,E,anelExt.I,anelExt.mu,anelExt.Rneu);
anelInt.omega_n = FreqNatural(2,E,anelInt.I,anelInt.mu,anelInt.Rneu);

% Rigidezes anel externo e interno
anelExt.k = anelExt.m*anelExt.omega_n^2;
anelInt.k = anelInt.m*anelInt.omega_n^2;

[Rx,Ry,R,Rd,IF,IE,k] = deal(zeros(2,1));

aneis = [anelInt anelExt];

for i=1:2
    [Rx(i),Ry(i),R(i),Rd(i)] = RaiosCurvatura(rb,rb,aneis(i).rx,aneis(i).ry);
    [IF(i),IE(i),k(i)] = ParametrosElipseContato(Rd(i));
end

Eef = E/(1-ni^2);
wz_max = ObterCargaMaximaEsfera(Cmax,Nb,c_d,Eef,R,IF,IE,k);

fd = ImpulsosImpacto(t,BPFO/(2*pi));