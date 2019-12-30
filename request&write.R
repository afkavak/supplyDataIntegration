library("RODBC")
library("rjson")
library("httr")
library("xlsx")

plantDictionary=read.csv("plantDictionary.csv",sep = ";",dec = ",",encoding = "UTF-8-BOM")

startDate="2019-01-04"
endDate="2019-02-04"

plant=1

methodName="production/aic"

url <- paste0("https://api.epias.com.tr/epias/exchange/transparency/",methodName,"?")
status="success"
count=1
while((count==1 | status=="fail") & count<=10) {
  res <- try(assign("response",GET(url = paste0(url,"startDate=",startDate,"&endDate=",endDate,"&organizationEIC=",plantDictionary[plant,6],"&uevcbEIC=",plantDictionary[plant,2]), add_headers(.headers=c("x-ibm-client-id"= "1f9e3bd7-de7c-4eb0-baa1-74257e22df93",Accept="application/json")),timeout(15))),silent = TRUE)
  if(class(res) == "try-error") {
    status="fail"
  } else {
    status="success"
  }
  print(paste0("trial ",count,", status: ",status))
  count=count+1
}

if(status=="success") {
  ff=fromJSON(content(response,as="text", encoding = "UTF-8"))
  
  if(length(ff$body$statistics)>0) {
    aicPart=data.frame(t(sapply(1:length(ff$body$aicList), function(i) unlist(ff$body$aicList[[i]]))))
  }
}

methodName="production/real-time-generation_with_powerplant"

url <- paste0("https://api.epias.com.tr/epias/exchange/transparency/",methodName,"?")
status="success"
count=1
while((count==1 | status=="fail") & count<=10) {
  res <- try(assign("response",GET(url = paste0(url,"startDate=",startDate,"&endDate=",endDate,"&powerPlantId=",plantDictionary[plant,7]), add_headers(.headers=c("x-ibm-client-id"= "1f9e3bd7-de7c-4eb0-baa1-74257e22df93",Accept="application/json")),timeout(15))),silent = TRUE)
  if(class(res) == "try-error") {
    status="fail"
  } else {
    status="success"
  }
  print(paste0("trial ",count,", status: ",status))
  count=count+1
}

if(status=="success") {
  ff=fromJSON(content(response,as="text", encoding = "UTF-8"))
  
  if(length(ff$body$statistics)>0) {
    supplyPart=data.frame(t(sapply(1:length(ff$body$hourlyGenerations), function(i) unlist(ff$body$hourlyGenerations[[i]]))))
  }
}

fileName=paste(getwd(),"produced",format(Sys.Date(),"%Y%m%d_KGUP&Uretim.xlsx"),sep = "/")

write.xlsx(data.frame(measDateTime=paste(substr(aicPart[,1],1,10),substr(aicPart[,1],12,16),sep = " "),apply(aicPart[,-1],2,as.numeric)),sheetName = "KGUP",file = fileName,row.names = F)
write.xlsx(data.frame(measDateTime=paste(substr(supplyPart[,1],1,10),substr(supplyPart[,1],12,16),sep = " "),apply(supplyPart[,-1],2,as.numeric)),sheetName = "Uretim",file = fileName,row.names = F,append = T)
