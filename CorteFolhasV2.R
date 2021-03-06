library(stringr)
library(EBImage)


###### DEFINIR diret�rio onde est�o as imagens #####

pasta= "C:/Users/HP/Google Drive/R/gitCorteFolhas/" # colocar aqui a pasta com as fotos que
## vc quer analisar de prefer�ncia em formato ".jpg"

file.namesF <- list.files(pasta, pattern = "*.jpg",
                          full.names = TRUE, recursive= FALSE) ## selecionando s� o que � ".jpg"
## sem pegar o que estiver dentro de subpastas



###### FUNCAO PARA TRANSFORMAR A IMAGEM EM PRETO E BRANCO ######

cortePB= function(CaminhoImg, threshMin= 0.30, threshMax= 0.65){
  
  imgBruta= readImage(CaminhoImg) ## carregando a figura
  #display(imgBruta)
  
  print("calculando 'threshold' para m�scara")
  
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
  fig[fig >= thresh] <- 1 ### usando o vaor de threshold para criar m�scara bin�ria (P & B)
 
  print("M�scara criada")
  return(fig)
  
} ## fun��o que transforma
## a imagem colorida em preto e branco. N�o mexer dentro da fun��o

TESTE= cortePB(CaminhoImg, threshMin= 0.30, threshMax= 0.65) ## colocar um valor m�nimo e m�ximo
## entre 0 e 1 para procurar valores limites (para definir o que � preto e branco) na imagem
## se n�o tiver certeza do que usar, deixar com os valores padr�o (ou sem esses argumentos),
## que funcionam bem para folhas na maioria das vezes.
display(TESTE)

###### FUNCAO PARA RETIRAR OBJETOS QUE SIRVAM DE ESCALA, COMO R�GUAS ###### 

#### caso as imagens escaneadas tiverem algo para servir de escala (como uma r�gua) escaneada
#### juntamente com as folhas, rodar daqui para baixo. Para funcionar, precisa ser um objeto comprido
#### de prefer�ncia do tamanho do suporte em que est�o as folhas, como no exemplo das imagens

corteRegua = function(Imagem,
                      LadoRegua,
                      Regua,
                      tamanhoRegua = 0.18,
                      pincel = 3) {
  SomaPixelsVertical = as.numeric("")
  for (i in 1:nrow(Imagem)) {
    num = i
    SomaPixelsVertical[i] = sum(Imagem[num, ])
  } ## calculo da soma das linhas (eixo X) da imagem. Objetos para escala, como r�gua
  ## s�o compridos, ent�o ter�o soma grande, provavelmente maior que a das folhas
  
  if (missing(LadoRegua)) {
    LadoRegua = "esquerda"
  } ## comportamento "padr�o" � procurar a
  ## r�gua no lado ESQUERDO da imagem.
  
  if (missing(Regua)) {
    Regua = "cortar"
  } ## comportamento "padr�o" CORTAR a regua da imagem
  
  if (grepl("dir", LadoRegua, ignore.case = TRUE)) {
    Imagem = rotate(Imagem, 180)
    SomaPixelsVertical = rev(SomaPixelsVertical)
  }
  
  corte = 0
  
  SomaPixelsVertical = SomaPixelsVertical[c(1:(length(SomaPixelsVertical) *
                                                 tamanhoRegua))] ## aqui,
  ## restringindo o vetor com as somas de pixel para 6% do tamanho dele
  ## para melhorar as chances de considerar apenas a �rea que a r�gua est� na
  ## parte logo abaixo
  
  maxRegua = ifelse(length(which(
    SomaPixelsVertical == max(SomaPixelsVertical)
  )) == 1,
  which(SomaPixelsVertical == max(SomaPixelsVertical)),
  0)
  ## �ndice do valor m�ximo se tiver 1 pixel de largura (ser� a r�gua), caso contr�rio, provavelmente �
  ## parte de folha e ser� ignorado, recebendo o valor de 0
  
  if (maxRegua != 0) {
    ReguaFundo = sort(c(maxRegua,
                        which(
                          SomaPixelsVertical < length(SomaPixelsVertical) * 0.5
                        ))) ## vetor com �ndices de
    ## valores baixos E o valor da r�gua, ordenado de forma crescente
    ReguaUm = which(ReguaFundo == maxRegua) + 3 ## pegando o �ndice do valor seguinte ao m�ximo (que ser� o primeiro
    ## valor pequeno depois da r�gua)
    ReguaUm = ifelse(ReguaUm >= length(ReguaFundo),
                     length(ReguaFundo),
                     ReguaUm)[1]
    corte = seq(from = 1, to = ReguaFundo[ReguaUm]) ## criando uma sequ�ncia de 1 at� o primeiro valor pequeno
    ## depois da r�gua, usando como base os �ndices obtidos acima
  }
  
  #print(i)
  if ((sum(corte) != 0) &
      grepl("cort", Regua, ignore.case = TRUE)) {
    ## caso n�o tenha nada para cortar
    Imagem = as.matrix(Imagem[-corte, ])
    print("R�gua removida")
  }
  else if ((sum(corte) != 0) &
           grepl("apag", Regua, ignore.case = TRUE)) {
    Imagem[corte, ] = 0
    print("R�gua apagada")
  }
  else {
    Imagem = Imagem
    print("Sem r�gua na imagem")
  }
  
  if (grepl("dir", LadoRegua, ignore.case = TRUE)) {
    return(rotate(Imagem, 180))
  }
  
  if (pincel > 0) {
    Imagem = erode(Imagem, kern = makeBrush(size = pincel, shape = "Gaussian",))
  }
  return(Imagem)
} ## essa funcao retorna um valor de corte (na vari�vel "corte"), que � o �ndice  que tem o valor m�ximo da r�gua
## verifica se o �ndice est� do lado direito ou esquerdo da figura
## e o usa para cortar a imagem (se estiver do lado esquerdo, corta do lado esquerdo, se do direito,
## corta do lado direito). N�o mexer dentro da fun��o

TESTE2= corteRegua(Imagem= TESTE, Regua= "cortar", LadoRegua= "esquerda", tamanhoRegua= 0.18, pincel= 3)
## na funcao acima, o ultimo comando indica o lado que esta o objeto que serve como escala
## se o argumento nao for colocado (ou tiver a palavra "esquerda"), a funcao vai rodar por
## padrao considerando que o objetco est� no lado esquerdo da imagem
## argumento Regua: se a regua deve ser apagada (substituida por pixel pretos) ou cortada (pixels da regua removidos
## deixando a imagem final menor que a inicial). O padr�o � cortar
## argumento tamanhoRegua: mais ou menos a % da imagem que tem a r�gua, 15% � um valor que funciona bem
## e � o padr�o, mas pode ser aumentado ou diminu�do. Caso essa fun��o de corte de r�gua tire um peda�o da folha,
## diminuir o valor padr�o. Caso ainda sobre um peda�o da r�gua, aumentar o valor.
## o �ltimo argumento: pincel, diz o tamanho do "kern" usado na funcao "erode" (do pacote EBImage)
## essa fun��o serve para tirar "sujeiras" nas imagens, como pixels isolados ou "cantos" nas imagens
## quanto maior for o valor do pincel, mais coisa � considerada "sujeira". Se for muito grande,
## pode reitrar uma �rea importante da folha e subestimar a �rea no c�lculo. O padr�o � um pincel
## de 3, mas � recomendado testar v�rios tamanhos (pode ser usado o valor de 0) e a� nada � retirado
display(TESTE2) ## visualizar imagem sem a r�gua de escala

###### FUNCAO PARA RETIRAR FAIXAS QUE TENHAM APARECIDO DURANTE O ESCANEAMENTO (E.G. QUANDO ###### 
###### O SUPORTE PARA AS FOLHAS � MENOR QUE O VIDRO DO SCANNER)  

corteFaixa = function(Imagem, PosicaoFaixa, Faixa) {
  SomaPixelsHorizontal = as.numeric("")
  for (i in 1:ncol(Imagem)) {
    num = i
    SomaPixelsHorizontal[i] = sum(Imagem[, num]) ## somando as linhas na horizontal
  } ## funcao para calcular as somas das colunas (eixo Y), mesmo racioc�nio
  ## usado para os objetos de escala, na fun��o acima
  
  if (missing(PosicaoFaixa)) {
    PosicaoFaixa = "cima"
  } ## comportamento "padr�o" � procurar a
  ## faixa no lado DE CIMA da imagem.
  
  if (missing(Faixa)) {
    Faixa = "cortar"
  } ## comportamento "padr�o" � CORTAR a faixa da imagem
  
  if (grepl("bai", PosicaoFaixa, ignore.case = TRUE)) {
    Imagem = rotate(Imagem, 180)
    SomaPixelsHorizontal = rev(SomaPixelsHorizontal)
  }
  
  colCorte = as.numeric("")
  x = 0
  for (i in 1:ceiling(length(SomaPixelsHorizontal) * 0.2)) {
    if (SomaPixelsHorizontal[i] >= nrow(Imagem) * 0.75) {
      x = x + 1
      colCorte[x] = i
    }
  }
  
  if (!(is.na(sum(colCorte))) &
      grepl("cort", Faixa, ignore.case = TRUE)) {
    Imagem = as.matrix(Imagem[, -c(1:max(colCorte + 5))])
    print("Faixa removida")
  }
  else if (!(is.na(sum(colCorte))) &
           grepl("apag", Faixa, ignore.case = TRUE)) {
    Imagem[, c(1:max(colCorte + 5))] = 0
    print("Faixa apagada")
  }
  else{
    Imagem = Imagem
    print("Sem faixa na imagem")
  }
  
  if (grepl("bai", PosicaoFaixa, ignore.case = TRUE)) {
    return(rotate(Imagem, 180))
  }
  
  return(Imagem)
} ## funcao para tirar faixas cont�nuas da imagem
## na parte inferior ou superior. A faixa deve ocupar a imagem na horizontal quase completamente para 
## a funcao funcionar corretamente. N�o mexer dentro da fun��o


TESTE3= corteFaixa(TESTE2, Faixa= "cortar", PosicaoFaixa="cima")
## na funcao acima, no argumento PosicaoFaixa, se estiver com "baixo", a faixa ser� procurada na parte
## de baixo da imagem, se estiver com "cima" ou vazio, a faixa ser� procurada na parte de cima da imagem
## ## argumento Faixa: se a faixa deve ser apagada (substituida por pixel pretos) ou cortada 
## (pixels da regua removidos). O padr�o � cortar.
## deixando a imagem final menor que a inicial)
display(TESTE3) ## visualizar imagem sem a r�gua de escala

#### AP�S A FOTO TER SIDO TRATADA (OU SEJA, OS OBJETOS QUE SERVE COMO ESCALA RETIRADOS E AS FAIXAS)
#### EM BRANCO), A PARTE ABAIXO DO SCRIPT CONTA OS OBJETOS QUE EST�O NA IMAGEM
#### 
#### 
#### 
#### 

objetosNumero= function(Imagem){ 
  
  label = bwlabel(Imagem)
  caract= sort(table(label), decreasing= TRUE)[-1]
  
  folhasNumero= sort(caract[caract > max(caract)*0.05], decreasing= TRUE)
  ## aqui retirando o que � provavelmente defeito (considerei como sujeira o que tivesse menos de 5%
  ## do tamanho do objeto maior da imagem, em pixels)
  ## ou sujeira na foto.
  
  return(folhasNumero)
  
} ## funcao para identificar os objetos da imagem em PB (ja sem regua)
## e numerar cada um e j� retirar os objetos que n�o s�o folha (defeitos na foto e etc). N�o mexer
## dentro da fun��o

numeracaoObjetos= objetosNumero(TESTE3)
numeracaoObjetos ## objetos encontrados (desconsiderando sujeiras)

ImagemNumerada= bwlabel(TESTE3) ## contagem de objetos

selecOBJT= function(ImgNumerada, NObj){ 
  
  num= names(NObj)
  coords= which(ImgNumerada == num, arr.ind=TRUE)
  
  minX= min(coords[,"col"])
  maxX= max(coords[,"col"])
  
  minY= min(coords[,"row"])
  maxY= max(coords[,"row"])
  
  corte= ImgNumerada[c(minY : maxY),
                     c(minX : maxX)]
  
  mt= matrix(nrow= nrow(corte), ncol= ncol(corte))
  for(i in 1:nrow(corte)){ ## criando uma matriz substituindo tudo o que n�o seja o objeto
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
} ## funcao para cortar a imagem
## para cada um dos objetos da imagem numerada ImgNumerada � a IMAGEM
## com os objetos numerados obtidos com a funcao "bwlabel" acima
## e NObj � o VETOR com os n�meros de objetos e
## �rea (em pixels) obtidos com a funcao "obJetosNumero", acima.
## N�o mexer dentro da fun��o

TESTE4= selecOBJT(ImagemNumerada, numeracaoObjetos[3])
display(TESTE4) ## testando com uma imagem apenas, no segundo argumento
## para cortar outra folha, mudar o "[1]" por algum outro numero
## para cortar todas as folhas de uma vez, ver loop logo abaixo

## loop para cortar todas as folhas de um imagem, colocar numa lista e salvar no computador
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

#### LOOP para manipular e cortar todas as fotos de um diret�rio de uma vez (pode n�o ser recomendado) ####
#### caso as imagens sejam muito vari�veis, por exemplo, com escalas em diferentes lugares
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
  print(paste0("Processando arquivo: ", CaminhoImg))
  
  ImgPB= cortePB(CaminhoImg, threshMin= 0.30, threshMax= 0.65)
  
  ImgCorteRegua= corteRegua(Imagem= ImgPB, LadoRegua= "esquerda", tamanhoRegua= 0.18, pincel= 3)
  
  ImgCorteFaixa= corteFaixa(Imagem= ImgCorteRegua, PosicaoFaixa="cima")
  
  numeracaoObjetos= objetosNumero(ImgCorteFaixa)
  ImagemNumerada= bwlabel(ImgCorteFaixa)
  print(paste0("Objetos numerados, ", length(numeracaoObjetos), " folhas encontradas"))
  
  listaFolhas=list()
  for(i in 1:length(numeracaoObjetos)){ ## loop para cortar cada um dos objetos da imagem
    ## automaticamente e colocar em um objeto do tipo lista (listaFolhas) e salvar
    
    num= numeracaoObjetos[i]
    crt= selecOBJT(ImagemNumerada, num)
    
    listaFolhas[[i]]= crt
    
    caminho=  paste0(pasta,"/Cortes/",
                     gsub(".jpg", "", str_extract(CaminhoImg, '[^/]+$')), 
                     "_folha_" , i , "_2.jpg") 
    
    writeImage(crt, ## aqui, salvando a imagem
               caminho,
               quality = 100)
    
    print(paste0("folha salva: ", i))
    
  }
  
  print(paste0("CORTE DE ", str_extract(CaminhoImg, '[^/]+$'), " COMPLETO"))
  cat("\n\n")
  
  if(ARQUIVO == length(file.namesF)){
    cat("\n\n")
    print(paste0("Terminado, cortes das folhas salvos em: ",
                 paste0(pasta,"/Cortes/")))
  }
  
}

