### Script para calcular área de folhas escaneadas em preto e branco
### o Script "CorteFolhas.R" pode ser usado para criar essas imagens em preto e branco
### 

library(EBImage)

ImagensPB= list.files("C:/Users/HP/Google Drive/R/gitCorteFolhas/Cortes", full.names = TRUE,
                      pattern= "*.jpg") ## usando as imagens criadas pelo
## script "CorteFolhas.R" como exemplo



areaFoliar= function(CaminhoImg, DPI){
  Img= readImage(CaminhoImg)
  DPIparaCM2= (DPI/2.54)^2
  areaFoliar= computeFeatures.shape(Img)[1]/DPIparaCM2
  } ## Funcao para calcular a area foliar, com base no
## DPI da imagem. Não mexer dentro da funcao


TESTEarea= areaFoliar("C:/Users/HP/Google Drive/R/gitCorteFolhas/Cortes/cary_1_folha_1_.jpg",
                      DPI= 200) ## importante, em DPI, colocar o DPI que a imagem tinha quando foi escaneada
## atenção: caso a imagem tenha sido aberta em outro programa e manipulada pode ter acontecido de
## a imagem salva estar com o DPI alterado em relaçâo à original e isso fazer os cálculos ficarem incorretos

tabelaArea= list()
for(i in 1:length(ImagensPB)){
  
  nome= str_extract(ImagensPB[i], "([^/]*)$")
  
  area= round(areaFoliar(ImagensPB[i], 200),2)
  
  df=data.frame("arquivo"= nome,
                "area_cm2"= area)
  
  tabelaArea[[i]]= df
  
  print(paste0("calculo: ", nome))
  
  if(i == length(ImagensPB)){
    
    tabelaArea= do.call("rbind", tabelaArea)
    
    write.table(tabelaArea,
                file= paste0(gsub(nome, "", ImagensPB[i]), "AreaFoliar_", 
                             format(Sys.time(), "%d%m%Y"), 
                             ".txt"),
                sep= ";", dec= ".", quote= FALSE, row.names= FALSE, col.names= TRUE)
    
  }
  
}
