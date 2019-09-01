function digit = recognition()
    
    cd .. 
    load('WMFCC.mat');
    cd Trained
    files = dir('*.mat');
    size = length(files)/10;
    results = zeros(size,10);
    WMFCC = transpose(WMFCC);
   
    for filenum=1:length(files)
        filename =files(filenum).name; 
        ref = load(filename);
        ref =ref.WMFCC;
        ref= transpose(ref);
        [MatchingCost,BestPath,D,Pred]=DTWItakura(ref,WMFCC,0); 
        if filename(5)=='Z'
            index = 1;
        else 
            index = str2double(filename(5))+1;
        end
        flag = 0;
        for fill=1:size
            if results(fill,index)== 0
                results(fill,index) = MatchingCost;
                flag = 1;
            end
            if flag
                break;
            end
        end
        
        
    end
    average = zeros(1,10);
    avrg = 0;
%     for i=1:10
%         for j=1:size
%             avrg = avrg+results(j,i);
%         end
%         average(i) = avrg/size;
%         avrg = 0;
%     end
%     minimum = min(average);
%     digit =find(average==minimum);
%     digit=digit-1;
%     
        minimum = min(results(:));
        [row,col] =find(results==minimum);
        digit=col-1;
    
end