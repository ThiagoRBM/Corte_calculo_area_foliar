library(stringr)
library(dplyr)
library(EBImage)


###### DEFINIR diretório onde estão as imagens #####




pasta= "C:/Users/HP/Google Drive/R/gitCorteFolhas/" # colocar aqui a pasta com a espécie que
## vc quer analisar, 
## mas colocar o endereço ******* SEM o "/ind" *******, 
## porque vou usar o "/ind" logo abaixo

file.namesF <- list.files(pasta, pattern = "*.jpg",
                          full.names = TRUE, recursive= FALSE) ## selecionando só o que é ".jpg" e pegando
## o que está dentro de cada subpasta

#CaminhoImg= file.namesF[137]
#CaminhoImg= file.namesF[29]
#CaminhoImg= file.namesF[1]

###### FUNCAO PARA TRANSFORMAR A IMAGEM EM PRETO E BRANCO ######
CortePB= function(CaminhoImg, threshMin= 0.30, threshMax= 0.65){
  
  imgBruta= readImage(CaminhoImg) ## carregando a figura
  #display(imgBruta)
  
  print("calculando 'threshold' para máscara")
  
  for(i in seq(from= threshMin, to= threshMax, by=1/255)){ ## aqui, funcao para achar o threshold
    ## do jeito que o ImageJ faz (https://imagej.nih.gov/ij/docs/faqs.html#auto) quando vou em 
    ## PROCESS > BINARY > CREATE MASK, que funcionou muito bem no ovo24 (mas nao funciona bem em todos)
    
    thresh= i
    #print(i)
    
    acima= imgBruta[imgBruta > thresh]
    abaixo= imgBruta[imgBruta <= thresh]
    
    medAcima= ifelse(length(acima)>0, mean(acima), 0)
    medAbaixo= ifelse(length(abaixo)>0, mean(abaixo), 0)
    
    medAcAb= (medAcima + medAbaixo)/2
    
    
    
    if(thresh > medAcAb){
     print(paste0("threshold para imagem: ", thresh))
     break
      
    }
   }

  
  ifelse(!(thresh > medAcAb), print("treshold fora do intervalor especificado, resultado pode nao ser o esperado"), 
         print("treshold encontrado"))
  
  fig= imageData(channel(imgBruta, mode="blue"))
  fig<- 1-fig
  fig[fig < thresh] <- 0	
  fig[fig >= thresh] <- 1 ### usando o vaor de threshold para criar máscara binária (P & B)
 
  return(fig)
   
}

TESTE= CortePB(CaminhoImg, threshMin= 0.30, threshMax= 0.65) ## colocar um valor mínimo e máximo
## entre 0 e 1 para procurar valores limites (para definir o que é preto e branco) na imagem
## se não tiver certeza do que usar, deixar com os valores padrão (ou sem esses argumentos),
## que funcionam bem para folhas na maioria das vezes
display(TESTE)

###### FUNCAO PARA RETIRAR OBJETOS QUE SIRVAM DE ESCALA, COMO RÉGUAS ###### 

#### caso as imagens escaneadas tiverem algo para servir de escala (como uma régua) escaneada
#### juntamente com as folhas, rodar daqui para baixo. Para funcionar, precisa ser um objeto comprido
#### de preferência do tamanho do suporte em que estão as folhas, como no exemplo das imagens

soma= function(Imagem){ ## funcao para calcular as somas de colunas das figuras
  ## para encontrar onde está a régua na foto
  
  somaColuna= as.numeric("")
  for(i in 1:nrow(Imagem)){
    num= i
    somaColuna[i]= sum(Imagem[num,])
    # SomaColunaEsquerda= somaColuna[1:ceiling(length(somaColuna)*0.4)] ## pegando a região esquerda da figura
    # aproximadamente os 40% esquerdo da figura
  }
  
  return(somaColuna)
  
}

SomaPixels= soma(TESTE)
## verificando graficamente o final da regua (em vermelho na imagem)
barplot(SomaPixels, border = NA, col= paste(ifelse(SomaPixels > max(SomaPixels)*0.75, "red", "black")))
## visualizando as somas de pixel na vertical. A regua tera uma soma grande, por ser do tamanho da pagina
## a visualizacao mostra a soma dos pixels. Quanto maior no eixo y, mais pixels brancos tem na coluna

corteRegua = function(Imagem, LadoRegua) {
  
  SomaPixelsVertical= as.numeric("")
  for(i in 1:nrow(Imagem)){
    num= i
    SomaPixelsVertical[i]= sum(Imagem[num,])
    } ## calculo da soma das linhas (eixo X) da imagem. Objetos para escala, como régua
  ## são compridos, então terão soma grande, provavelmente maior que a das folhas
  
  
  if(missing(LadoRegua)){LadoRegua= "esquerda"} ## comportamento "padrão" é procurar a 
  ## régua no lado ESQUERDO da imagem.
  
  if(grepl("dir", LadoRegua, ignore.case=TRUE)){
    Imagem=rotate(Imagem, 180)
    SomaPixelsVertical= rev(SomaPixelsVertical)
  }
  
  corte=0
  
  SomaPixelsVertical= SomaPixelsVertical[c(1:(length(SomaPixelsVertical)*0.2))] ## aqui,
  ## restringindo o vetor com as somas de pixel para 6% do tamanho dele
  ## para melhorar as chances de considerar apenas a área que a régua está na
  ## parte logo abaixo
  
  maxRegua=ifelse(length(which(SomaPixelsVertical == max(SomaPixelsVertical)))==1, 
                  which(SomaPixelsVertical == max(SomaPixelsVertical)), 
                  0) 
  ## índice do valor máximo se tiver 1 pixel de largura (será a régua), caso contrário, provavelmente é 
  ## parte de folha e será ignorado, recebendo o valor de 0
  
  if(maxRegua != 0){
    
    ReguaFundo= sort(c(maxRegua,
                       which(SomaPixelsVertical < length(SomaPixelsVertical)*0.5))) ## vetor com índices de 
    ## valores baixos E o valor da régua, ordenado de forma crescente
    ReguaUm= which(ReguaFundo == maxRegua)+3 ## pegando o índice do valor seguinte ao máximo (que será o primeiro
    ## valor pequeno depois da régua)
    
    ReguaUm= ifelse(ReguaUm >= length(ReguaFundo), 
                    length(ReguaFundo),
                    ReguaUm)
    
    corte= seq(from=1, to=ReguaFundo[ReguaUm]) ## criando uma sequência de 1 até o primeiro valor pequeno
    ## depois da régua, usando como base os índices obtidos acima
  }
  #print(i)
  if(sum(corte) != 0){ ## caso não tenha nada para cortar
    Imagem = as.matrix(Imagem[-corte,])} else {Imagem= Imagem}

  if(grepl("dir", LadoRegua, ignore.case=TRUE)){return(rotate(Imagem,180))}
  
  return(Imagem)
  
} ## essa funcao retorna um valor de corte (na variável "corte"), que é o índice  que tem o valor máximo da régua
## verifica se o índice está do lado direito ou esquerdo da figura
## e o usa para cortar a imagem (se estiver do lado esquerdo, corta do lado esquerdo, se do direito,
## corta do lado direito)

TESTE2= corteRegua(Imagem= TESTE, LadoRegua= "esquerda")
## na funcao acima, o ultimo comando indica o lado que esta o objeto que serve como escala
## se o argumento nao for colocado (ou tiver a palavra "esquerda"), a funcao vai rodar por
## padrao considerando que o objetco está no lado esquerdo da imagem
display(TESTE2) ## visualizar imagem sem a régua de escala

###### FUNCAO PARA RETIRAR FAIXAS QUE TENHAM APARECIDO DURANTE O ESCANEAMENTO (E.G. QUANDO ###### 
###### O SUPORTE PARA AS FOLHAS É MENOR QUE O VIDRO DO SCANNE)  

somaFaixa= function(Imagem){ ## funcao para tirar a parte branca da imagem que não é folha
  ## mesmo raciocínio usado acima, para a régua, só mudando o sentido da soma, de vertical para
  ## horizontal
  
  somaLinha= as.numeric("")
  for(i in 1:ncol(Imagem)){
    num= i
    somaLinha[i]= sum(Imagem[,num]) ## somando as linhas na horizontal
    
  }
  
  return(somaLinha)
  
}

listaSomaLinha= somaFaixa(TESTE2)
## verificando onde está a borda branca da imagem que não é folha
barplot(listaSomaLinha, border = NA, col= paste(ifelse(listaSomaLinha > length(listaSomaLinha)*0.5, 
                                                            "red", "black")))
## visualizando a soma dos pixels na horizontal (mesmo raciocinio que fiz acima, para a regua)

corteFaixa = function(SomaPixelsHorizontal, Imagem, PosicaoFaixa) {## funcao para tirar faixas contínuas da imagem
  ## na parte inferior ou superior. A faixa deve ocupar a imagem na horizontal quase completamente para 
  ## a funcao funcionar corretamente
  
  if(missing(PosicaoFaixa)){PosicaoFaixa= "cima"} ## comportamento "padrão" é procurar a 
  ## faixa no lado DE CIMA da imagem.
  
  if(grepl("bai", PosicaoFaixa, ignore.case=TRUE)){
    Imagem=rotate(Imagem, 180)
    SomaPixelsHorizontal= rev(SomaPixelsHorizontal)
  } 
  
  
  colCorte= as.numeric("")
  x=0
  for(i in 1:length(SomaPixelsHorizontal)){
    
    if(SomaPixelsHorizontal[i] >= nrow(Imagem)*0.95){
      x= x+1
      colCorte[x]= i
      
    }

  }

   if(!is.na(sum(colCorte))){
     Imagem = as.matrix(Imagem[,-c(1:max(colCorte+5))])
   }
  
  if(grepl("bai", PosicaoFaixa, ignore.case=TRUE)){
  return(rotate(Imagem,180))} 
  
  return(Imagem)
  
  }


TESTE3= corteFaixa(listaSomaLinha, TESTE2, PosicaoFaixa="baixo")
## na funcao acima, no argumento PosicaoFaixa, se estiver com "baixo", a faixa será procurada na parte
## de baixo da imagem, se estiver com "cima" ou vazio, a faixa será procurada na parte de cima da imagem
display(TESTE3) ## visualizar imagem sem a régua de escala

#### APÓS A FOTO TR SIDO TRATADA (OU SEJA, OS OBJETOS QUE SERVE COMO ESCALA RETIRADOS E AS FAIXAS)
#### EM BRANCO), A PARTE ABAIXO DO SCRIPT CONTA OS OBJETOS QUE ESTÃO NA IMAGEM
#### 
#### 
#### 
#### 

obJetosNumero= function(Imagem){ ## funcao para identificar os objetos da imagem em PB (ja sem regua)
  ## e numerar cada um e já retirar os objetos que não são folha (defeitos na foto e etc)
  
  label = bwlabel(Imagem)
  caract= sort(table(label), decreasing= TRUE)[-1]
  
  
  
  folhasNumero= sort(caract[caract > max(caract)*0.05], decreasing= TRUE)
  ## aqui retirando o que é provavelmente defeito (considerei como sujeira o que tivesse menos de 5%
  ## do tamanho do objeto maior da imagem, em pixels)
  ## ou sujeira na foto.
  
  return(folhasNumero)
  
}

numeracaoObjetos= obJetosNumero(TESTE3)
numeracaoObjetos ## objetos encontados (desconsiderando sujeiras)

ImagemNumerada= bwlabel(TESTE3)
display(colorLabels(ImagemNumerada))

selecOBJT= function(ImgNumerada, NObj){ ## criando funcao para cortar a imagem
  ## para cada um dos objetos da imagem numerada ImgNumerada é a IMAGEM
  ## com os objetos numerados obtidos com a funcao "bwlabel" acima
  ## e NObj é o VETOR com os números de objetos e
  ## área (em pixels) obtidos com a funcao "obJetosNumero", acima
  
  num= names(NObj)
  coords= which(ImgNumerada == num, arr.ind=TRUE)
  
  minX= min(coords[,"col"])
  maxX= max(coords[,"col"])
  
  minY= min(coords[,"row"])
  maxY= max(coords[,"row"])
  
  corte= ImgNumerada[c(minY : maxY),
                     c(minX : maxX)]
  
  #return(corte)
  
  mt= matrix(nrow= nrow(corte), ncol= ncol(corte))
  for(i in 1:nrow(corte)){ ## criando uma matriz substituindo tudo o que não seja o objeto
    ## especificado em "n" / "num" por 0
    
    for(j in 1:ncol(corte)){
      
      if(corte[i,j] == num){
        
        mt[i,j] = num
        #print("numero")
        
      } else{
        
        mt[i,j] = 0
        
      }
      
    }
    
  }
  
  return(mt)
  
}

TESTE4= selecOBJT(ImagemNumerada, numeracaoObjetos[1])
display(TESTE4) ## testando com uma imagem apenas


dir.create(file.path(paste0(pasta,"/Cortes")))
listaFolhas=list()
for(i in 1:length(numeracaoObjetos)){ ## loop para cortar cada um dos objetos da imagem
  ## automaticamente e colocar em um objeto do tipo lista (listaFolhas)
  
  num= numeracaoObjetos[i]
  crt= selecOBJT(ImagemNumerada, num)
  
  listaFolhas[[i]]= crt
  
  caminho=  paste0(pasta,"/Cortes/",
                   gsub(".jpg", "", str_extract(CaminhoImg, '[^/]+$')), 
                   "_folha_" , i , "_.jpg") 
  
  writeImage(crt, ## aqui, salvando a imagem
             caminho,
             quality = 100)
  
  print(paste0("obj: ", names(numeracaoObjetos[i])))
  
}

#### LOOP para fazer todas as fotos de um diretório de uma vez (pode não ser recomendado)
#### caso as imagens sejam muito variáveis, por exemplo, com escalas em diferentes lugares
####
####
####
####
####
####

pasta= "C:/Users/HP/Google Drive/R/gitCorteFolhas/"

file.namesF <- rev(list.files(pasta, pattern = "*.jpg",
                          full.names = TRUE, recursive= FALSE))

dir.create(file.path(paste0(pasta,"/Cortes")))


for(ARQUIVO in 1:length(file.namesF)){
  
  CaminhoImg=  file.namesF[ARQUIVO]
  print(paste0("Processando arquivo:", CaminhoImg))
  
  ImgPB= CortePB(CaminhoImg, threshMin= 0.30, threshMax= 0.65)
  print("Máscara criada")
  
  SomaRegua= soma(ImgPB)
  ImgCorteRegua= corteRegua4(SomaPixelsVertical= SomaRegua, Imagem= ImgPB, LadoRegua= "esquerda")
  print("Régua removida")
  
  SomaFaixa= somaFaixa(ImgCorteRegua)
  ImgCorteFaixa= corteFaixa(SomaPixelsHorizontal= SomaFaixa, Imagem= ImgCorteRegua, PosicaoFaixa="cima")
  print("Faixa removida")
  
  numeracaoObjetos= obJetosNumero(ImgCorteFaixa)
  ImagemNumerada= bwlabel(ImgCorteFaixa)
  print(paste0("Objetos numerados ", length(numeracaoObjetos), " folhas encontradas"))
  
  listaFolhas=list()
  for(i in 1:length(numeracaoObjetos)){ ## loop para cortar cada um dos objetos da imagem
    ## automaticamente e colocar em um objeto do tipo lista (listaFolhas)
    
    num= numeracaoObjetos[i]
    crt= selecOBJT(ImagemNumerada, num)
    
    listaFolhas[[i]]= crt
    
    caminho=  paste0(pasta,"/Cortes/",
                     gsub(".jpg", "", str_extract(CaminhoImg, '[^/]+$')), 
                     "_folha_" , i , "_.jpg") 
    
    writeImage(crt, ## aqui, salvando a imagem
               caminho,
               quality = 100)
    
    print(paste0("folha salva: ", i))
    
  }
  
}



########################
########################
########################
########################
########################


##### NESSA PARTE DO SCRIPT, AS FOLHAS SEPARADAS TEM AS CARACTERÍSTICAS DE INTERESSE CALCULADAS
#####  adaptado do "folha", feito pelo Leandro Maracahipes
##### 
##### 
##### 
##### 
##### 
##### 
##### 
##### 
##### 
##### 
##### 
##### 


folhasPBcortadas= "C:/Users/HP/Pictures/alexandra/TestesCortes/" ## colocar o MESMO CAMINHO em que suas folhas
## cortadas em PB foram salvas


areaCm2= function(dpi){ ## formula para calcular quantos pixels por cm2 de acordo com o DPI
  
  cm= dpi/2.54
  cm2= cm^2
  
  return(cm2)
  
} 

pix= areaCm2(200) ## em 200 DPI, cada cm2 vai ter 6200.012 pixels

calculos= function(herbivorada, preenchida, pix){
  
  #arquivo= names(preenchida)[1]
  herb <- computeFeatures.shape(herbivorada) # folha ocupada
  preench <- computeFeatures.shape(preenchida) # folha total 
  
  herb.cm<-(-sum(herb[,1])+sum(preench[,1]))/pix
  totfol.cm<-(sum(preench[,1])/pix)
  dossel<- (herb.cm/totfol.cm)*100
  
  out= data.frame(list(#arquivo= arquivo, 
    herb.cm=herb.cm, 
    totfol.cm=totfol.cm,
    dossel=dossel))
  
  return(out)
  
}
#testeCALCULOS= calculos(PBherb[[14]], PBpreenchida[[14]], 9440) ## testando com um arquivo só


kern= makeBrush(1, shape="box", step=TRUE)
#display(kern)



fPBcompleta= list.files(folhasPBcortadas, pattern= "*.jpg", full.names= TRUE)

fPB= fPBcompleta[c(1)]


PBcorte= sapply(fPB, function(x) readImage(x), simplify= FALSE,
                 USE.NAMES= TRUE) ## abrindo as imagens PB cortadas no pasta
#names(PBcorte)= fPB
display(PBcorte[[16]])


PBherb= sapply(PBcorte, function(x) bwlabel(x), simplify= FALSE,
               USE.NAMES= TRUE)
display(PBherb[[16]])

PBherb= sapply(PBherb, function(x) erode(x, kern), simplify= FALSE,
               USE.NAMES= TRUE)
display(PBherb[[16]])

PBherb= sapply(PBherb, function(x) bwlabel(x), simplify= FALSE,
               USE.NAMES= TRUE)
display(PBherb[[16]])

PBpreenchida= sapply(PBherb, function(x) fillHull(x), simplify= FALSE,
                     USE.NAMES= TRUE)
display(PBpreenchida[[16]])


DFfinal= vector("list", length(PBherb))
for( i in 1:length(PBherb) ){ ## essa funcao faz os calculos e ao fim salva uma tabela em txt
  ## no endereço que é mostrado
  
  
  herbivorada= PBherb[[i]]
  preenchida= PBpreenchida[[i]]
  pix = pix ## pix calculado lá em cima com a funcao areaCm2
  
  if(names(PBherb)[i] == names(PBpreenchida)[i]){
    
    df= calculos(herbivorada, preenchida, pix)
    
    DFfinal[[i]]= df
    names(DFfinal)[i]= names(PBherb)[i]
    
    print(paste0("Calculos: ", names(PBherb)[i]))
    
  } else{ print(paste0("herbivorada e preenchida são diferentes, erro no numero: ", i)) }
  
  if(i == length(PBherb)){
    
    tabCalculosFinal= do.call("rbind", DFfinal)
    tabCalculosFinal$arquivo = rownames(tabCalculosFinal)
    rownames(tabCalculosFinal) = NULL
    tabCalculosFinal= tabCalculosFinal %>% 
      select(c(4, 1:3))
    
    write.table(tabCalculosFinal,
                file= paste0(folhasPBcortadas, "calculos_folhas_",
                format(Sys.time(), "%d%m%Y"), "_.txt"),
                sep= ";", dec= ".", quote= TRUE, row.names= FALSE, col.names= TRUE)
    
    
    print("----------------------------------------------------------------------------------")
    cat(sep="\n\n")
    print(paste0("Calculos completados, arqvuio salvo em: ", folhasPBcortadas))
    
    }
  
}

tabCalculosFinal ## ver o que tambem foi salvo como txt