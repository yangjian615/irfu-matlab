function [methodinfo,structs,enuminfo,ThunkLibName]=libcef_mfile
%LIBCEF_MFILE Create structures to define interfaces found in 'libcef'.

%This function was generated by loadlibrary.m parser version  on Tue Nov 29 10:49:34 2016
%perl options:'libcef.i -outfile=libcef_mfile.m -thunkfile=libcef_thunk_glnxa64.c -header=libcef.h'
ival={cell(1,0)}; % change 0 to the actual number of functions to preallocate the data.
structs=[];enuminfo=[];fcnNum=1;
fcns=struct('name',ival,'calltype',ival,'LHS',ival,'RHS',ival,'alias',ival,'thunkname', ival);
MfilePath=fileparts(mfilename('fullpath'));
ThunkLibName=fullfile(MfilePath,['libcef_thunk_' lower(computer)]);
% int cef_read ( char * filename ); 
fcns.thunkname{fcnNum}='int32cstringThunk';fcns.name{fcnNum}='cef_read'; fcns.calltype{fcnNum}='Thunk'; fcns.LHS{fcnNum}='int32'; fcns.RHS{fcnNum}={'cstring'};fcnNum=fcnNum+1;
% int cef_close ( void ); 
fcns.thunkname{fcnNum}='int32voidThunk';fcns.name{fcnNum}='cef_close'; fcns.calltype{fcnNum}='Thunk'; fcns.LHS{fcnNum}='int32'; fcns.RHS{fcnNum}=[];fcnNum=fcnNum+1;
% void cef_verbosity ( int level ); 
fcns.thunkname{fcnNum}='voidint32Thunk';fcns.name{fcnNum}='cef_verbosity'; fcns.calltype{fcnNum}='Thunk'; fcns.LHS{fcnNum}=[]; fcns.RHS{fcnNum}={'int32'};fcnNum=fcnNum+1;
% mxArray * cef_metanames ( void ); 
fcns.thunkname{fcnNum}='voidPtrvoidThunk';fcns.name{fcnNum}='cef_metanames'; fcns.calltype{fcnNum}='Thunk'; fcns.LHS{fcnNum}='MATLAB array'; fcns.RHS{fcnNum}=[];fcnNum=fcnNum+1;
% mxArray * cef_meta ( char * meta ); 
fcns.thunkname{fcnNum}='voidPtrcstringThunk';fcns.name{fcnNum}='cef_meta'; fcns.calltype{fcnNum}='Thunk'; fcns.LHS{fcnNum}='MATLAB array'; fcns.RHS{fcnNum}={'cstring'};fcnNum=fcnNum+1;
% mxArray * cef_gattributes ( void ); 
fcns.thunkname{fcnNum}='voidPtrvoidThunk';fcns.name{fcnNum}='cef_gattributes'; fcns.calltype{fcnNum}='Thunk'; fcns.LHS{fcnNum}='MATLAB array'; fcns.RHS{fcnNum}=[];fcnNum=fcnNum+1;
% mxArray * cef_vattributes ( char * varname ); 
fcns.thunkname{fcnNum}='voidPtrcstringThunk';fcns.name{fcnNum}='cef_vattributes'; fcns.calltype{fcnNum}='Thunk'; fcns.LHS{fcnNum}='MATLAB array'; fcns.RHS{fcnNum}={'cstring'};fcnNum=fcnNum+1;
% mxArray * cef_gattr ( char * attribute ); 
fcns.thunkname{fcnNum}='voidPtrcstringThunk';fcns.name{fcnNum}='cef_gattr'; fcns.calltype{fcnNum}='Thunk'; fcns.LHS{fcnNum}='MATLAB array'; fcns.RHS{fcnNum}={'cstring'};fcnNum=fcnNum+1;
% mxArray * cef_vattr ( char * varname , char * attribute ); 
fcns.thunkname{fcnNum}='voidPtrcstringcstringThunk';fcns.name{fcnNum}='cef_vattr'; fcns.calltype{fcnNum}='Thunk'; fcns.LHS{fcnNum}='MATLAB array'; fcns.RHS{fcnNum}={'cstring', 'cstring'};fcnNum=fcnNum+1;
% mxArray * cef_var ( char * varname ); 
fcns.thunkname{fcnNum}='voidPtrcstringThunk';fcns.name{fcnNum}='cef_var'; fcns.calltype{fcnNum}='Thunk'; fcns.LHS{fcnNum}='MATLAB array'; fcns.RHS{fcnNum}={'cstring'};fcnNum=fcnNum+1;
% mxArray * cef_varnames ( void ); 
fcns.thunkname{fcnNum}='voidPtrvoidThunk';fcns.name{fcnNum}='cef_varnames'; fcns.calltype{fcnNum}='Thunk'; fcns.LHS{fcnNum}='MATLAB array'; fcns.RHS{fcnNum}=[];fcnNum=fcnNum+1;
% mxArray * cef_depends ( char * varname ); 
fcns.thunkname{fcnNum}='voidPtrcstringThunk';fcns.name{fcnNum}='cef_depends'; fcns.calltype{fcnNum}='Thunk'; fcns.LHS{fcnNum}='MATLAB array'; fcns.RHS{fcnNum}={'cstring'};fcnNum=fcnNum+1;
% mxArray * milli_to_isotime ( mxArray * var , int digits ); 
fcns.thunkname{fcnNum}='voidPtrvoidPtrint32Thunk';fcns.name{fcnNum}='milli_to_isotime'; fcns.calltype{fcnNum}='Thunk'; fcns.LHS{fcnNum}='MATLAB array'; fcns.RHS{fcnNum}={'MATLAB array', 'int32'};fcnNum=fcnNum+1;
methodinfo=fcns;
