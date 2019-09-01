
function [ALLB]=digitseparation(Er,ITU,ITR)
y1=get(gca,'ylim');
ALLB = [];
c = 1;
flag = 1;
window = 20;
Len = length(Er);
while(flag)
    flag = 1;
    while (flag) % find the start of silence
        if (c + 20 > Len)
            flag = 0;
            break;
        end
        flag = 0;
        for g=c:c+window-1
            if (Er(g) < ITU && flag == 0)
                flag = 0;
            else 
                flag = 1;
            end
        end
        if flag == 0
            start = c;
        end
        c = c+1;
    end
    flag = 1;
    while (flag) % find the end of silence
        
        while (Er(c)<=ITR)
           c=c+1;
           if (c > Len)
                finish = Len;
                break;
           end
        end
        if c > Len
            break;
        end
        B1=c;
        finish = c;
        flag=0;
        for c=B1+1:B1+3
            if c>Len
                break;
            end
            if Er(c)<ITU
                flag=1;            
                break;        
            end
        end
        if flag
            c=B1+1;
        else
            break;
        end
    end
    flag = 1;
    if c >= Len
        flag = 0;
    end
    subplot(312)
    plot([start start],y1,'r');
    plot([finish finish],y1,'r');
    
    ALLB = [ALLB  round((start+finish)/2)];
    
end
end
