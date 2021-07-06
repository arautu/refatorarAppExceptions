# Arquivo: libRefatorarAppException.awk
# Descrição: Funções para refatoração de ApplicationException. 
@include "sliic/libJavaParser";

# Interage com o usuário, através do terminal, para obter o identificador
# único do código de dicionário.
# Retorno:
# O identificador do código de dicionário.
function getId(   Oldrs, id) {
  Oldrs = RS;
  RS = "\n";
  
  printf "  Entre o id do código: " > "/dev/tty";
  getline id < "/dev/stdin";
  
  RS = Oldrs;

  return id;
}

# Classifica cada parte da instrução ApplicationException(), determinando
# o seu papel no contexto.
# Argumentos:
# * instrucao: Contém a instrução do tipo: ApplicationException("texto" + var, arg2);
# Retorno:
# * fatiado: Retorna um array contendo as partes da instrução, onde seu índice,
# classifica as partes de acordo com sua função no contexto. A classificação é a seguinte:
# "m" - Contém desde o início da instrução até a chamada do construtor, ex: 'new ApplicationException'
# "c" - Levam esta marca, variáveis, métodos ou funções chamadas como primeiro argumento do construtor.
# "t" - São classificados desta forma textos passados como primeiro argumento do construtor.
# "a" - O segundo argumento do construtor leva esta marca. 
function classificaPartes(instrucao, fatiado,   i) {
  rae_fatiaInstrucao(instrucao, apartes);
  delete fatiado;

  for (i in apartes) {
    switch (apartes[i]) {
      case /ApplicationException/ :
        fatiado[i]["m"] = apartes[i];
        break;
      case /^[\(+]/:
        gsub(/(^\()|[+\r\n]/, "", apartes[i]);
        gsub(/(^[[:space:]]*)|([[:space:]]*$)/, "", apartes[i]);
        if (!determinaParidade(apartes[i], "\\(", "\\)", i)) {
           sub(")$", "", apartes[i]);
        }
        if (apartes[i] != "") {
          fatiado[i]["c"] = apartes[i];
        }
        break;
      case /^"/:
        gsub("\"", "", apartes[i]);
        fatiado[i]["t"] = apartes[i];
        break;
      case /^,/:
        gsub(/[,\r\n ]/, "", apartes[i]);
        sub(")", "", apartes[i]);
        fatiado[i]["a"] = apartes[i];
        break;
    }
  }
}

# Retorna o código de dicionário de ApplicationException, sem texto.
# Argumentos:
# * modulo: Módulo que o arquivo fonte pertence.
# * classe: Nome da classe.
# * id: Identificador único do texto dentro da classe.
# Retorno:
# * O código de dicionário de exceção, sem texto. 
function getCodDicionario(modulo, classe, id,   codigo) {
  codigo = modulo "." classe ".exception." id;
  return codigo;
}

# Retorna o código de dicionário de ApplicationException, com texto.
# Argumentos:
# * codigo: O código de dicionário sem texto. 
# * fatiado: Array contendo os textos retirados da instruação original. 
# Retorno:
# * O código de dicionário de exceção e seu respectivo texto. 
function getCodDicionarioComTexto(codigo, fatiado,  i, j) {
  codigo = codigo "=";
  cArg = 0;
  for (i in fatiado) {
    for (j in fatiado[i]) {
      switch (j) {
        case "c" :
          codigo = codigo "{" cArg++ "}"
            break;
        case "t" :
          codigo = codigo fatiado[i]["t"];
          break;
      }
    }
  }
  return codigo;
}

# Retorna a refatoração de ApplicationException para BusinessException.
# Argumentos:
# * fatiado - Array contendo as partes da instrução original, classificadas
# de acordo com o contexto da instrução.
# * codigo - O código de dicionário correspondente a instrução original, 
# sem o texto.
# Retorno:
# Retorna o resultado da refatoração para BusinessException().
function getBizException(fatiado, codigo,   i, j, buz, instrucao) {
 rae_init(); 
  for (i in fatiado) {
    for (j in fatiado[i]) {
      switch (j) {
        case "m" :
          buz = gensub("ApplicationException", "BusinessException", "g", fatiado[i][j]);
          instrucao = buz "(\"" codigo "\");";
          break;
        case "c" :
          instrucao = gensub(/(\);)/,", " fatiado[i][j] "\\1", "g", instrucao);
          break;
        case "a" :
          instrucao = gensub(/(BusinessException\()/,"\\1" fatiado[i][j] ", ", "g", instrucao);
          break;
      }
    }
  }
  rae_end();
  return instrucao;
}

# Destrincha a instrução que contém ApplicationException() pelos seus
# elementos constitutivos como argumentos, objetos, etc.
# Argumentos:
# * instrucao - Linha contendo a criação do objeto ApplicationException.
# Retorno:
# * apartes - Um array com as partes da instrução. Veja a descrição no 
# código, para entender a separação.
function rae_fatiaInstrucao(instrucao, apartes,
apException, aspas, arg2,  elem1, elem2, fieldpat) {
  delete apartes;
# Captura inclusive com tabulações iniciais, ex: '  Throw new ApplicationException(...'
# Parte capturada = '  Throw new ApplicationException'
  apException=@/.*ApplicationException/;
# Captura texto entre aspas, ex: '... "blah blah" ...'.
# Parte capturada = '"blah blah"'  
  aspas=@/"[^"]+"/;
# Captura o segundo argumento do método 'ApplicationException(..., arg);'
# Parte capturada = ', arg'
  arg2=@/,.*)/;
# Captura variáveis e métodos no início do primeiro argumento, concatenados ou não.
# 'ApplicationException(foo() + ..., ...);'
# Parte capturada = 'foo() +'
  elem1=@/\([^"]+ ?+/;
# Captura variáveis e métodos concatenados no primeiro argumento que não estão no
# início.
# 'ApplicationException(... + foo() + ..., ...);'
# Parte capturada = '+ foo() +'
  elem2=@/+ ?[^",]+/;
  fieldpat = "("aspas")|("apException")|("arg2")|("elem1")|("elem2")";

  patsplit(instrucao, apartes, fieldpat);
}

function rae_init() {
  if ("sorted_in" in PROCINFO) {
    rae_save_sorted = PROCINFO["sorted_in"];
  }
  PROCINFO["sorted_in"] = "@ind_num_asc";
}

function rae_end() {
  if (rae_save_sorted) {
    PROCINFO["sorted_in"] = rae_save_sorted;
  }
}

