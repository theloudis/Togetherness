
#################################################################################
#	
#	This code reads the raw time diary data, formally LISS time use module 122.
#	The raw data are organized in 10-minute intervals, in which the respondent
#	records how they used their time in the last 10 minutes. They select a time
#	use from a list of predefined uses in a break-down menu but they can also
# add a time use of their choice (i.e. free text). In this code we read the
#	10-minute intervals devoted to sleep, work, childcare, and various types of
# recreation and we aggregate them up to daily equivalents per respondent.
#	Each respondent is asked to record their time use on a randomly chosen 
#	weekday (day 1), a randomly chosen weekend day (day 2), and a same weekday
#	a week ahead (day 3) if day 1 was not fully filled out.
#	____________________________________________________________________________
#
#	Filename:  LISS_Time_Diary_Aggregation.R
#	Authors: 	 Charles Minard and Corentin Champarou
#				     for Alexandros Theloudis (a.theloudis@gmail.com)
#	Date: 		 Autumn 2021
#	Paper: 		 Togetherness in the Household 
#				     Sam Cosaert and Alexandros Theloudis and Bertrand Verheyden
#
#################################################################################

#	Read raw data - LISS time use module 122:
# Public access to the data is possible after creating an account 
# and signing the appropriate agreement on https://www.dataarchive.lissdata.nl.
data <- read.csv("/Users/atheloudis/Dropbox/WiP/CTV_Togetherness/my_Togetherness/Data/_Stata/Raw_data/LISS_Time_Use/LISS_TimeUse2013.csv", stringsAsFactors=FALSE)

table=matrix(rep(0,224*60),ncol=60)

category=NULL
i=12
while(i!=2014){
  category=unique(c(category,data[,i]))
  i=i+14
}
category=category[-which(category=="")]
# 	Table with category of activity
category=cbind(category,c(3,10,1,95,60,20,90,2,30,70,80,50,40,35))
category=category[order(as.numeric(category[,2])),]

# 	The main algorithm to write the table
day1=seq(16,16+143*14,14)
day2=seq(2125,2125+143*14,14)
day3=seq(4234,4234+143*14,14)

#	Read time intervals:
temp=Sys.time()
for(i in 1:length(table[,1])){
  for(k in day3){
    if(is.na(data[i,k])==F){
      if(data[i,k]!="" && data[i,k-4]!=""){
        
        table[i,which(category[,1]==data[i,k])*4-3]=table[i,which(category[,1]==data[i,k])*4-3]+5
        table[i,which(category[,1]==data[i,k-4])*4-3]=table[i,which(category[,1]==data[i,k-4])*4-3]+5
        
        if(data[i,k+1]=="Nee" && data[i,k+2]=="Ja"){
          table[i,which(category[,1]==data[i,k])*4]=table[i,which(category[,1]==data[i,k])*4]+5
          table[i,which(category[,1]==data[i,k-4])*4]=table[i,which(category[,1]==data[i,k-4])*4]+5
        }
        
        else if(data[i,k+2]=="Ja"){
          table[i,which(category[,1]==data[i,k])*4-1]=table[i,which(category[,1]==data[i,k])*4-1]+5
          table[i,which(category[,1]==data[i,k-4])*4-1]=table[i,which(category[,1]==data[i,k-4])*4-1]+5
        }
        else if(data[i,k+1]=="Nee"){
          table[i,which(category[,1]==data[i,k])*4-2]=table[i,which(category[,1]==data[i,k])*4-2]+5
          table[i,which(category[,1]==data[i,k-4])*4-2]=table[i,which(category[,1]==data[i,k-4])*4-2]+5
        } 
      }
      else if(data[i,k]!="" && data[i,k-4]==""){
        table[i,which(category[,1]==data[i,k])*4-3]=table[i,which(category[,1]==data[i,k])*4-3]+10
        if(data[i,k+1]=="Nee"){
          table[i,which(category[,1]==data[i,k])*4-2]=table[i,which(category[,1]==data[i,k])*4-2]+10
        }
        else if(data[i,k+2]=="Ja"){
          table[i,which(category[,1]==data[i,k])*4-1]=table[i,which(category[,1]==data[i,k])*4-1]+10
        }
        else if(data[i,k+1]=="Nee" && data[i,k+2]=="Ja"){
          table[i,which(category[,1]==data[i,k])*4]=table[i,which(category[,1]==data[i,k])*4]+10
        }
      }
      else if(data[i,k]=="" && data[i,k-4]!=""){
        table[i,which(category[,1]==data[i,k-4])*4-3]=table[i,which(category[,1]==data[i,k-4])*4-3]+10
        
        if(data[i,k+1]=="Nee" && data[i,k+2]=="Ja"){
          table[i,which(category[,1]==data[i,k-4])*4]=table[i,which(category[,1]==data[i,k-4])*4]+10
        }
        
        else if(data[i,k+2]=="Ja"){
          table[i,which(category[,1]==data[i,k-4])*4-1]=table[i,which(category[,1]==data[i,k-4])*4-1]+10
        }
        else if(data[i,k+1]=="Nee"){
          table[i,which(category[,1]==data[i,k-4])*4-2]=table[i,which(category[,1]==data[i,k-4])*4-2]+10
        }
      }
    }
    else{
      table[i,which(category[,1]==data[i,k-4])*4-3]=table[i,which(category[,1]==data[i,k-4])*4-3]+10
      
      if(data[i,k+1]=="Nee" && data[i,k+2]=="Ja"){
        table[i,which(category[,1]==data[i,k-4])*4]=table[i,which(category[,1]==data[i,k-4])*4]+10
      }
      
      else if(data[i,k+2]=="Ja"){
        table[i,which(category[,1]==data[i,k-4])*4-1]=table[i,which(category[,1]==data[i,k-4])*4-1]+10
      }
      else if(data[i,k+1]=="Nee"){
        table[i,which(category[,1]==data[i,k-4])*4-2]=table[i,which(category[,1]==data[i,k-4])*4-2]+10
      }
    }
  }
}
Sys.time()-temp

# 	If 7th column = 3800:
for(i in 1:length(table[,1])){
  for(k in day3){
    if(is.na(data[i,k])==F){
      if(data[i,k]!="" && data[i,k-4]!="" && data[i,k-6]=="Verzorging en toezicht van kinderen (binnen eigen huishouden)" && data[i,k-2]!="Verzorging en toezicht van kinderen (binnen eigen huishouden)"){
        table[i,57]=table[i,57]+5
        if(data[i,k+1]=="Nee" && data[i,k+2]=="Ja"){
          table[i,60]=table[i,60]+5
        }
        else if(data[i,k+2]=="Ja"){
          table[i,59]=table[i,59]+5
        }
        else if(data[i,k+1]=="Nee"){
          table[i,58]=table[i,58]+5
        }
      }
      else if(data[i,k]!="" && data[i,k-4]=="" && data[i,k-2]!="Verzorging en toezicht van kinderen (binnen eigen huishouden)"){
        table[i,57]=table[i,57]+10
        if(data[i,k+1]=="Nee" && data[i,k+2]=="Ja"){
          table[i,60]=table[i,60]+10
        }
        else if(data[i,k+2]=="Ja"){
          table[i,59]=table[i,59]+10
        }
        else if(data[i,k+1]=="Nee"){
          table[i,58]=table[i,58]+10
        }
      }
      else if(data[i,k]=="" && data[i,k-4]!="" && data[i,k-6]=="Verzorging en toezicht van kinderen (binnen eigen huishouden)"){
        table[i,57]=table[i,57]+10
        if(data[i,k+1]=="Nee" && data[i,k+2]=="Ja"){
          table[i,60]=table[i,60]+10
        }
        else if(data[i,k+2]=="Ja"){
          table[i,59]=table[i,59]+10
        }
        else if(data[i,k+1]=="Nee"){
          table[i,58]=table[i,58]+10
        }
      }
    }
    else{
      if(data[i,k-4]!="" && data[i,k-6]=="Verzorging en toezicht van kinderen (binnen eigen huishouden)"){
        table[i,57]=table[i,57]+10
        if(data[i,k+1]=="Nee" && data[i,k+2]=="Ja"){
          table[i,60]=table[i,60]+10
        }
        else if(data[i,k+2]=="Ja"){
          table[i,59]=table[i,59]+10
        }
        else if(data[i,k+1]=="Nee"){
          table[i,58]=table[i,58]+10
        }
      }
    }
  }
}

# 	Algorithm for variable names:
table=cbind(data[,1],table)

res="id"

for(i in 1:length(category[,1])){
  res=c(res,c(paste(category[i,2],"_Total",sep=""),paste(category[i,2],"_Partner",sep=""),paste(category[i,2],"_Children",sep=""),paste(category[i,2],"_All",sep="")))
}

res=c(res,c("3800_total","3800_Partner","3800_Children","3800_All"))

colnames(table)=res

# 	File creation (CSV):
write.table(table,file="thirdday_sumtime.csv",sep = ";",row.names = F)