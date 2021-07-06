# Arquivo: refatorarAppException.awk
# Descrição: Refatora ApplicationException("texto") para 
# BusinessException("código_de_dicionário")

@include "sliic/libLocProperties";
@include "sliic/libParserFilePath";
@include "sliic/libJavaParser";
@include "sliic/libConvIsoUtf";
@include "libRefatorarAppException";

# sliic-erp/Sliic_ERP/Sliic_ERP_Modulo_Configuracao/src/com/sliic/sliicerp/configuracao/task/GeradorPermissaoService.java
BEGIN {
# Quebra de linha por nova linha, exceto quando terminado # em '+\r\n'
# ou ',\r\n'.
  RS = "[^+,]\r\n";
  SUBSEP = "@";
  PROCINFO["sorted_in"] = "@ind_str_asc";
  findFiles(msgs_paths);
}

BEGINFILE {
  parserFilePath(FILENAME, aMetaFile);
  MsgProp = locProperties(aMetaFile, msgs_paths);

  if ("inplace::begin" in FUNCTAB) {
    convertIso8859ToUtf8();
  }
  print "\n==== Análise de ApplicationException ====\n" > "/dev/tty";
  print "Arquivo:", FILENAME > "/dev/tty";
  print " Properties:", MsgProp > "/dev/tty";
}

/(public|private) ?[[:alnum:]]* \<class\>/ {
  classe = getClass($0);
}

/ApplicationException\(.*"/ {
  
  if(!MsgProp) {
    print "Erro: Nenhum arquivo de dicionário encontrado." > "/dev/tty";
    nextfile;
  }

  fmt = removerIdentacao($0);
  printf " %s: %s\n", FNR, fmt > "/dev/tty";

  id = getId();

  classificaPartes($0, fatiado);

  codigo = getCodDicionario(aMetaFile["module"], classe, id);
   
  fmt = removerIdentacao($0);
  print " Refatorar:", fmt > "/dev/tty";
  $0 = getBizException(fatiado, codigo);
  fmt = removerIdentacao($0);
  printf " Para: %s\n", fmt > "/dev/tty";

  codigo = getCodDicionarioComTexto(codigo, fatiado);
  if ("inplace::begin" in FUNCTAB) {
    printf ("%s\r", codigo) >> MsgProp;
  }
  printf " Código: %s\n\n", codigo  > "/dev/tty";
}

{
  if ("inplace::begin" in FUNCTAB) {
    printf "%s%s", $0, RT;
  }
}

END {
  if ("inplace::begin" in FUNCTAB) {
    convertUtf8ToIso8859();
  }
}
