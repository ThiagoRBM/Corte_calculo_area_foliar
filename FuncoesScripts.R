## funcoes isoladas dos arquivos 
## CorteFolhasV2.R
## CalculoAreaFoliar
## 

cortePB = function(CaminhoImg,
                   threshMin = 0.30,
                   threshMax = 0.65) {
  imgBruta = readImage(CaminhoImg) ## carregando a figura
  #display(imgBruta)
  
  print("calculando 'threshold' para máscara")
  
  for (i in seq(from = threshMin,
                to = threshMax,
                by = 1 / 255)) {
    ## aqui, funcao para achar o threshold
    ## do jeito que o ImageJ faz (https://imagej.nih.gov/ij/docs/faqs.html#auto) quando vou em
    ## PROCESS > BINARY > CREATE MASK, que funcionou muito bem no ovo24 (mas nao funciona bem em todos)
    
    thresh = i
    #print(i)
    
    acima = imgBruta[imgBruta > thresh]
    abaixo = imgBruta[imgBruta <= thresh]
    
    medAcima = ifelse(length(acima) > 0, mean(acima), 0)
    medAbaixo = ifelse(length(abaixo) > 0, mean(abaixo), 0)
    
    medAcAb = (medAcima + medAbaixo) / 2
    
    
    
    if (thresh > medAcAb) {
      print(paste0("threshold para imagem: ", thresh))
      break
      
    }
  }
  
  
  ifelse(
    !(thresh > medAcAb),
    print(
      "treshold fora do intervalor especificado, resultado pode nao ser o esperado"
    ),
    print("treshold encontrado")
  )
  
  fig = imageData(channel(imgBruta, mode = "blue"))
  fig <- 1 - fig
  fig[fig < thresh] <- 0
  fig[fig >= thresh] <- 1 ### usando o vaor de threshold para criar máscara binária (P & B)
  
  print("Máscara criada")
  return(fig)
  
}

corteRegua = function(Imagem,
                      LadoRegua,
                      Regua,
                      tamanhoRegua = 0.18,
                      pincel = 3) {
  SomaPixelsVertical = as.numeric("")
  for (i in 1:nrow(Imagem)) {
    num = i
    SomaPixelsVertical[i] = sum(Imagem[num, ])
  } ## calculo da soma das linhas (eixo X) da imagem. Objetos para escala, como régua
  ## são compridos, então terão soma grande, provavelmente maior que a das folhas
  
  if (missing(LadoRegua)) {
    LadoRegua = "esquerda"
  } ## comportamento "padrão" é procurar a
  ## régua no lado ESQUERDO da imagem.
  
  if (missing(Regua)) {
    Regua = "cortar"
  } ## comportamento "padrão" CORTAR a regua da imagem
  
  if (grepl("dir", LadoRegua, ignore.case = TRUE)) {
    Imagem = rotate(Imagem, 180)
    SomaPixelsVertical = rev(SomaPixelsVertical)
  }
  
  corte = 0
  
  SomaPixelsVertical = SomaPixelsVertical[c(1:(length(SomaPixelsVertical) *
                                                 tamanhoRegua))] ## aqui,
  ## restringindo o vetor com as somas de pixel para 6% do tamanho dele
  ## para melhorar as chances de considerar apenas a área que a régua está na
  ## parte logo abaixo
  
  maxRegua = ifelse(length(which(
    SomaPixelsVertical == max(SomaPixelsVertical)
  )) == 1,
  which(SomaPixelsVertical == max(SomaPixelsVertical)),
  0)
  ## índice do valor máximo se tiver 1 pixel de largura (será a régua), caso contrário, provavelmente é
  ## parte de folha e será ignorado, recebendo o valor de 0
  
  if (maxRegua != 0) {
    ReguaFundo = sort(c(maxRegua,
                        which(
                          SomaPixelsVertical < length(SomaPixelsVertical) * 0.5
                        ))) ## vetor com índices de
    ## valores baixos E o valor da régua, ordenado de forma crescente
    ReguaUm = which(ReguaFundo == maxRegua) + 3 ## pegando o índice do valor seguinte ao máximo (que será o primeiro
    ## valor pequeno depois da régua)
    ReguaUm = ifelse(ReguaUm >= length(ReguaFundo),
                     length(ReguaFundo),
                     ReguaUm)[1]
    corte = seq(from = 1, to = ReguaFundo[ReguaUm]) ## criando uma sequência de 1 até o primeiro valor pequeno
    ## depois da régua, usando como base os índices obtidos acima
  }
  
  #print(i)
  if ((sum(corte) != 0) &
      grepl("cort", Regua, ignore.case = TRUE)) {
    ## caso não tenha nada para cortar
    Imagem = as.matrix(Imagem[-corte, ])
    print("Régua removida")
  }
  else if ((sum(corte) != 0) &
           grepl("apag", Regua, ignore.case = TRUE)) {
    Imagem[corte, ] = 0
    print("Régua apagada")
  }
  else {
    Imagem = Imagem
    print("Sem régua na imagem")
  }
  
  if (grepl("dir", LadoRegua, ignore.case = TRUE)) {
    return(rotate(Imagem, 180))
  }
  
  if (pincel > 0) {
    Imagem = erode(Imagem, kern = makeBrush(size = pincel, shape = "Gaussian",))
  }
  return(Imagem)
}

corteFaixa = function(Imagem, PosicaoFaixa, Faixa) {
  SomaPixelsHorizontal = as.numeric("")
  for (i in 1:ncol(Imagem)) {
    num = i
    SomaPixelsHorizontal[i] = sum(Imagem[, num]) ## somando as linhas na horizontal
  } ## funcao para calcular as somas das colunas (eixo Y), mesmo raciocínio
  ## usado para os objetos de escala, na função acima
  
  if (missing(PosicaoFaixa)) {
    PosicaoFaixa = "cima"
  } ## comportamento "padrão" é procurar a
  ## faixa no lado DE CIMA da imagem.
  
  if (missing(Faixa)) {
    Faixa = "cortar"
  } ## comportamento "padrão" é CORTAR a faixa da imagem
  
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
}

objetosNumero= function(Imagem){ 
  
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
}

areaFoliar= function(CaminhoImg, DPI){
  Img= readImage(CaminhoImg)
  DPIparaCM2= (DPI/2.54)^2
  areaFoliar= computeFeatures.shape(Img)[1]/DPIparaCM2
}

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
  mt[is.na(mt)] = 0
  return(mt)
}

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
  print("contorno extraido")
  mt[is.na(mt)] = 0
  return(mt)
  
}