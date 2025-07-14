%ImageToCOE - Generates an initialization file for Xilinx Block RAM Memory
%
% USAGE: In the command window (do not run ImageToCOE.m file in MATLAB!) you can run it as
% ImageToCOE(ImgName). For example we can run the following in the command window
%   ImageToCOE("epfl")
%
% INPUT PARAMETERS:
%   ImgName - Name of input file, e.g. "epfl", the bmp extension is added by the function

function ImageToCOE(ImgName)

  ImgWidth  = fix(1024 / 4);
  ImgHeight = fix(768 / 4);

  A = imread(sprintf("%s.bmp",ImgName));
  A = imresize(A,[ImgHeight,ImgWidth]);
  A = double(A);

  Amax = max(A, [], 'all');

  A = round((15*A)/Amax); % Saves as 4-bit numbers, single HEX characters (0-15), pre-scale with this
  image(uint8(15*A));

  % Concatenate dimensions by shifting and storing together
  Aout   = A(:,:,1)*2^8+A(:,:,2)*2^4+A(:,:,3)*2^0;
  fileID = fopen(sprintf("%s.coe",ImgName),'w');

  fprintf(fileID,"memory_initialization_radix=16;\n");
  fprintf(fileID,"memory_initialization_vector=\n");
  fprintf(fileID,'%3X,',Aout');
  fprintf(fileID,'%;\n',Aout');
  fclose(fileID);
end
