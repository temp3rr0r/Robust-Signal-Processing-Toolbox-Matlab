function [th_hat, P_min, P, parameter] = ekf_toa(r_ges,theta_init,BS,parameter)
% EKF for tracking with time-of-arrival (ToA) estimates.
% 
%% INPUTS
% r_ges:    measured distances (M x N)
% theta_init:  initial state estimate
% BS:   base station positions
%
%% OUTPUTS
% th_hat:             state estimates
% P_min:              apriori covariance
% P:                  aposteriori covariance
%%  created by Michael Muma
%   Based on a function written by Ulrich Hammes, Signal Processing Group, TU Darmstadt, February 2009
%   version 30 May 2018
%   When using code, cite our work:
%
%   "Robust Statistics for Signal Processing"
%   Zoubir, A.M. and Koivunen, V. and Ollila, E. and Muma, M.
%   Cambridge University Press, 2018.
%
%   and 
%
%  "Robust Tracking and Geolocation for Wireless Networks in NLOS Environments." 
%   Hammes, U., Wolsztynski, E., and Zoubir, A.M.
%   IEEE Journal on Selected Topics in Signal Processing, 3(5), 889-901, 2009.



if (nargin<2)
      error('Not enough input arguments')
end
if (nargin<4)
     disp('parameters are set to default')
     sigma_v = 1;
     M  = length(BS(:,1));          % M numer of BS, N number of samples
     P0 = diag([100 100 10 10]);    % initial state covariance
     R  = 150^2*diag(ones(1,M));    % measurement covariance
     Ts = 0.2;                      % sampling frequency
     A  = [1 0 Ts 0; 0 1 0 Ts; 0 0 1 0; 0 0 0 1];   % state transition matrix
     Q = sigma_v^2*eye(2);
     G = [Ts^2/2*eye(2); Ts*eye(2)];
     parameter.dim = length(BS(1,:));             % dimension of positions, default is 2 
     parameter.var_est=1;          % to be estimated in line 88
end
if (nargin==4)
     P0 = parameter.P0;
     R  = parameter.R;
     Q = parameter.Q;
     G = parameter.G;
     A = parameter.A;
end
 

if ((2*parameter.dim~=length(theta_init(:,1))) || (2*parameter.dim~=length(P0(:,1))) )
            error('State vector or state covariance do not match the dimensions of the BS')
end

x = BS(:,1);
y = BS(:,2); 

M = length(x);
N = length(r_ges(1,:));

P(:,:,1) = P0;
th_hat(:,1) = theta_init;
th_hat_min(4,N) = 0;
P_min(4,4,N) = 0;
H(M,4) = 0;
h_min(M) = 0;
sigma2(N) = 0;



for kk=2:N
    th_hat_min(:,kk) = A*th_hat(:,kk-1);
    
    
    for ii=1:M
        H(ii,:) = [(th_hat_min(1,kk)-x(ii))/sqrt((th_hat_min(1,kk)-x(ii))^2+ (th_hat_min(2,kk)-y(ii))^2)...
           (th_hat_min(2,kk) -y(ii))/sqrt((th_hat_min(1,kk)-x(ii))^2+ (th_hat_min(2,kk)-y(ii))^2) 0 0  ];
        h_min(ii)= sqrt((th_hat_min(1,kk)-x(ii))^2 + (th_hat_min(2,kk)-y(ii))^2);
    end
   
    
   % covariance estimation 
   if (parameter.var_est==1) 
        sigma = 1.483*mad(r_ges(:,kk) -h_min'); 
        sigma2(kk) = sigma^2;
        R = sigma2(kk)*eye(M);
   end
   
    P_min(:,:,kk) = A*P(:,:,kk-1)*A'  + G*Q*G';
    K = P_min(:,:,kk)*H'*inv(H*P_min(:,:,kk)*H'+R);
    
    th_hat(:,kk) = th_hat_min(:,kk) + K*(r_ges(:,kk) -h_min');
    P(:,:,kk) = (eye(4) - K*H)*P_min(:,:,kk);
        
end
 parameter.Rest = sigma2;
 parameter.K    = K;

return

