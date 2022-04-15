library(stringr)
library(EBImage)


###### DEFINIR diretório onde estão as imagens #####

pasta= "C:/Users/HP/Google Drive/R/gitCorteFolhas/" # colocar aqui a pasta com as fotos que
## vc quer analisar de preferência em formato ".jpg"

file.namesF <- list.files(pasta, pattern = "*.jpg",
                          full.names = TRUE, recursive= FALSE) ## selecionando só o que é ".jpg"
## sem pegar o que estiver dentro de subpastas



###### FUNCAO PARA TRANSFORMAR A IMAGEM EM PRETO E BRANCO ######

cortePB= function(CaminhoImg, threshMin= 0.30, threshMax= 0.65){
  
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
  print("Máscara criada")
} ## função que transforma
## a imagem colorida em preto e branco. Não mexer dentro da função

TESTE= cortePB(CaminhoImg, threshMin= 0.30, threshMax= 0.65) ## colocar um valor mínimo e máximo
## entre 0 e 1 para procurar valores limites (para definir o que é preto e branco) na imagem
## se não tiver certeza do que usar, deixar com os valores padrão (ou sem esses argumentos),
## que funcionam bem para folhas na maioria das vezes.
display(TESTE)

###### FUNCAO PARA RETIRAR OBJETOS QUE SIRVAM DE ESCALA, COMO RÉGUAS ###### 

#### caso as imagens escaneadas tiverem algo para servir de escala (como uma régua) escaneada
#### juntamente com as folhas, rodar daqui para baixo. Para funcionar, precisa ser um objeto comprido
#### de preferência do tamanho do suporte em que estão as folhas, como no exemplo das imagens

corteRegua = function(Imagem, LadoRegua, tamanhoRegua= 0.18, pincel= 3) {
  
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
  
  SomaPixelsVertical= SomaPixelsVertical[c(1:(length(SomaPixelsVertical)*tamanhoRegua))] ## aqui,
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
                    ReguaUm)[1]
    
    corte= seq(from=1, to=ReguaFundo[ReguaUm]) ## criando uma sequência de 1 até o primeiro valor pequeno
    ## depois da régua, usando como base os índices obtidos acima
  }
  #print(i)
  if(sum(corte) != 0){ ## caso não tenha nada para cortar
    Imagem = as.matrix(Imagem[-corte,])} else {Imagem= Imagem}

  if(grepl("dir", LadoRegua, ignore.case=TRUE)){return(rotate(Imagem,180))}
  
  if(pincel > 0 ){
  Imagem= erode(Imagem, kern= makeBrush(size= pincel, shape="Gaussian", ))}
  
  return(Imagem)
  print("Régua removida")
  
} ## essa funcao retorna um valor de corte (na variável "corte"), que é o índice  que tem o valor máximo da régua
## verifica se o índice está do lado direito ou esquerdo da figura
## e o usa para cortar a imagem (se estiver do lado esquerdo, corta do lado esquerdo, se do direito,
## corta do lado direito). Não mexer dentro da função

TESTE2= corteRegua(Imagem= TESTE, LadoRegua= "esquerda", tamanhoRegua= 0.18, pincel= 3)
## na funcao acima, o ultimo comando indica o lado que esta o objeto que serve como escala
## se o argumento nao for colocado (ou tiver a palavra "esquerda"), a funcao vai rodar por
## padrao considerando que o objetco está no lado esquerdo da imagem
## argumento tamanhoRegua: mais ou menos a % da imagem que tem a régua, 15% é um valor que funciona bem
## e é o padrão, mas pode ser aumentado ou diminuído. Caso essa função de corte de régua tire um pedaço da folha,
## diminuir o valor padrão. Caso ainda sobre um pedaço da régua, aumentar o valor.
## o último argumento: pincel, diz o tamanho do "kern" usado na funcao "erode" (do pacote EBImage)
## essa função serve para tirar "sujeiras" nas imagens, como pixels isolados ou "cantos" nas imagens
## quanto maior for o valor do pincel, mais coisa é considerada "sujeira". Se for muito grande,
## pode reitrar uma área importante da folha e subestimar a área no cálculo. O padrão é um pincel
## de 3, mas é recomendado testar vários tamanhos (pode ser usado o valor de 0) e aí nada é retirado
display(TESTE2) ## visualizar imagem sem a régua de escala

###### FUNCAO PARA RETIRAR FAIXAS QUE TENHAM APARECIDO DURANTE O ESCANEAMENTO (E.G. QUANDO ###### 
###### O SUPORTE PARA AS FOLHAS É MENOR QUE O VIDRO DO SCANNER)  

corteFaixa = function(Imagem, PosicaoFaixa) {
  
  SomaPixelsHorizontal= as.numeric("")
  for(i in 1:ncol(Imagem)){
    num= i
    SomaPixelsHorizontal[i]= sum(Imagem[,num]) ## somando as linhas na horizontal
  } ## funcao para calcular as somas das colunas (eixo Y), mesmo raciocínio
  ## usado para os objetos de escala, na função acima
  
  
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
  print("Faixa removida")
  
} ## funcao para tirar faixas contínuas da imagem
## na parte inferior ou superior. A faixa deve ocupar a imagem na horizontal quase completamente para 
## a funcao funcionar corretamente. Não mexer dentro da função


TESTE3= corteFaixa(TESTE2, PosicaoFaixa="cima")
## na funcao acima, no argumento PosicaoFaixa, se estiver com "baixo", a faixa será procurada na parte
## de baixo da imagem, se estiver com "cima" ou vazio, a faixa será procurada na parte de cima da imagem
display(TESTE3) ## visualizar imagem sem a régua de escala

#### APÓS A FOTO TER SIDO TRATADA (OU SEJA, OS OBJETOS QUE SERVE COMO ESCALA RETIRADOS E AS FAIXAS)
#### EM BRANCO), A PARTE ABAIXO DO SCRIPT CONTA OS OBJETOS QUE ESTÃO NA IMAGEM
#### 
#### 
#### 
#### 

obJetosNumero= function(Imagem){ 
  
  label = bwlabel(Imagem)
  caract= sort(table(label), decreasing= TRUE)[-1]
  
  folhasNumero= sort(caract[caract > max(caract)*0.05], decreasing= TRUE)
  ## aqui retirando o que é provavelmente defeito (considerei como sujeira o que tivesse menos de 5%
  ## do tamanho do objeto maior da imagem, em pixels)
  ## ou sujeira na foto.
  
  return(folhasNumero)
  
} ## funcao para identificar os objetos da imagem em PB (ja sem regua)
## e numerar cada um e já retirar os objetos que não são folha (defeitos na foto e etc). Não mexer
## dentro da função

numeracaoObjetos= obJetosNumero(TESTE3)
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
} ## funcao para cortar a imagem
## para cada um dos objetos da imagem numerada ImgNumerada é a IMAGEM
## com os objetos numerados obtidos com a funcao "bwlabel" acima
## e NObj é o VETOR com os números de objetos e
## área (em pixels) obtidos com a funcao "obJetosNumero", acima.
## Não mexer dentro da função

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

#### LOOP para manipular e cortar todas as fotos de um diretório de uma vez (pode não ser recomendado) ####
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
  print(paste0("Processando arquivo: ", CaminhoImg))
  
  ImgPB= cortePB(CaminhoImg, threshMin= 0.30, threshMax= 0.65)
  
  ImgCorteRegua= corteRegua(Imagem= ImgPB, LadoRegua= "esquerda", tamanhoRegua= 0.18, pincel= 3)
  
  ImgCorteFaixa= corteFaixa(Imagem= ImgCorteRegua, PosicaoFaixa="cima")
  
  numeracaoObjetos= obJetosNumero(ImgCorteFaixa)
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

