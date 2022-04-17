library(EBImage)
library(dplyr)
library(reshape2)
library(ggplot2)
library(stringr)
source("C:/Users/HP/Google Drive/R/gitCorteFolhas/Scripts/FuncoesScripts.R")

pasta= "C:/Users/HP/Google Drive/R/gitCorteFolhas/"

file.namesF <- list.files(pasta, pattern = "*.jpg",
                          full.names = TRUE, recursive= FALSE)


PB= cortePB(file.namesF[136])
display(PB)
PB1= corteRegua(PB)
display(PB1)
PB2= corteFaixa(PB1)
display(PB2)

ImagemNumerada= bwlabel(PB2)
 
obj= objetosNumero(PB2)

removerSujeira = function(ImagemNumerada, VetorNumeros) {
  mt = matrix(nrow = nrow(ImagemNumerada),
              ncol = ncol(ImagemNumerada))
  for(linha in 1:ncol(ImagemNumerada)){
    vals= ImagemNumerada[,linha]
    if(sum(vals) > 0){
      for(x in 1:length(vals)){
        if(vals[x] %in% names(VetorNumeros)){
          mt[x,linha]= vals[x]
        } 
        else{mt[x,linha] = 0}
      } 
      
    } else{mt[x,length(vals)]=0}
  }
  print("imagem limpa")
  return(mt)
}

TESTE= removerSujeira(ImagemNumerada, obj)
display(TESTE)


extrairContorno= function(imagemLimpa){
  cont= ocontour(imagemLimpa)
  
  LISTA= list()
  for(i in 1:length(cont)){ ## transformando o objeto com os contornos (cont) em um data frame
    lis= cont[[i]] %>% 
      as.data.frame() %>% 
      mutate(obj= as.numeric(names(cont)[i])) %>% 
      rename(y= V1,
             x=V2)
    
    LISTA[[i]]= lis
    if(i == length(cont)){
      LISTA= do.call("rbind",LISTA)
    }
    
  }
  
  mt= matrix(nrow = nrow(imagemLimpa),
             ncol = ncol(imagemLimpa))
  for(i in 1:ncol(mt)){## pegando o contorno gerado na funcao ocontour e juntando como estava na imagem inicial
    df=LISTA[LISTA$x==i,]
    if(nrow(df)>0){
      for(x in 1:nrow(df)){
        y=df$y[x]
        mt[y,i]=df$obj[1]
      }
    }else{mt[c(1:nrow(mt)),i]=0}
    
    
  }
  print("controno extraido")
  return(mt)
  
}

TESTE2= extrairContorno(TESTE)
display(TESTE2)


## abaixo: exemplo de uso das funcoes em sequência, em todas as imagens de uma pasta
## contornos extraídos serão salvos em uma subpasta, onde estão as imagens originais,
## com o nome "Contornos"
## 
## 

pasta= "C:/Users/HP/Google Drive/R/gitCorteFolhas/"

file.namesF <- list.files(pasta, pattern = "*.jpg",
                          full.names = TRUE, recursive= FALSE)

for(i in 1:length(file.namesF)){
  
  CaminhoImg= file.namesF[i]
  
  PB= cortePB(file.namesF[i])
  PB1= corteRegua(PB, Regua="apaga")
  PB2= corteFaixa(PB1, Faixa="apaga")
  
  ImagemNumerada= bwlabel(PB2)
  obj= objetosNumero(PB2)
  
  TESTE= removerSujeira(ImagemNumerada, obj)
  TESTE2= extrairContorno(TESTE)
  
  caminho=  paste0(pasta,"/Contornos/",
                   gsub(".jpg", "", str_extract(CaminhoImg, '[^/]+$')), 
                   ".jpg") 
  
  writeImage(TESTE2, ## aqui, salvando a imagem
             caminho,
             quality = 100)
  
}