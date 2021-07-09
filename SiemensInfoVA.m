function sinfo=SiemensInfoVA(info)
% This function reads the information from the Siemens Private tag 0021 1019 
% from a struct with all dicom info.
%
%
% dicominfo=dicominfo('example.dcm');
% info = SiemensInfoVA(dicominfo)
%
% Updated from  DJ Kroon's original: https://fr.mathworks.com/matlabcentral/fileexchange/27941-dicom-toolbox
%
% Any suggestion/correction to stanislas.rapacchi@univ-amu.fr
%

if(isfield(info,'Private_0021_1019'))
    str=char(info.Private_0021_1019(:))';
elseif(isfield(info,'Private_0029_1120'))
    str=char(info.Private_0029_1120(:))';
end
str2begin='### ASCCONV BEGIN ';
str2start='###';

a1=strfind(str,str2begin);
a11=strfind(str(a1+length(str2begin):end),str2start);
a2=strfind(str,'### ASCCONV END ###');
stra=str(1:(a1-1)); %this is the first part, an XML struct of the protocol
str=str((a1+length(str2begin)+a11+length(str2start)):a2-2);

request_lines = regexp(str, '\n+', 'split');
request_words = regexp(request_lines, '=', 'split');
sinfo=struct;
for i=1:length(request_lines)
    s=request_words{i};
    name=s{1};
    while(name(end)==' '); name=name(1:end-1); end
    while(name(1)==' '); name=name(2:end); end
    value=s{2}; value=value(2:end);
    if(any(value=='"'))
        valstr=true;
    else
        valstr=false;
    end
    names = regexp(name, '\.', 'split');
    ind=zeros(1,length(names));
    for j=1:length(names)
        name=names{j};
        %remove spaces
         while(name(end)==' '); name=name(1:end-1); end
         while(name(end)=='	'); name=name(1:end-1); end
         while(name(1)==' '); name=name(2:end); end
         while(name(1)=='	'); name=name(2:end); end
        ps=find(name=='[');
        if(~isempty(ps))
            pe=find(name==']');
            ind(j)=str2double(name(ps+1:pe-1))+1;
            name=name(1:ps-1);
        end
        names{j}=name;
    end
    try
    evalstr='sinfo';
    for j=1:length(names)
        if(strcmp(names{j},'__attribute__'))
            %skip
        else
        if(ind(j)==0)
            evalstr=[evalstr '.(names{' num2str(j) '})'];
        else
            evalstr=[evalstr '.(names{' num2str(j) '})(' num2str(ind(j)) ')'];
        end
        end
    end
    if(valstr)
        evalstr=[evalstr '=''' value ''';'];
    else
        if(contains(value,'0x'))
            evalstr=[evalstr '='  num2str(hex2dec(value(strfind(value,'0x')+2:end))) ';'];
        else
        evalstr=[evalstr '=' value ';'];
        end
    end
    if(strcmp(names{end},'size'))
        %dont run that, it will screw filling the array
    else
        eval(evalstr);
    end
    catch ME
        warning(ME.message);
    end
end
