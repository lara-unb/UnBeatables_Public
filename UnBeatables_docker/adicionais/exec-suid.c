/*
 * exec-suid: Executa scripts com suid, que é, por default, inibido no kernel
 *
 * Este programa define o usuario para execução de scripts ou programas, com
 * base no suid bit mode e no usuário proprietário do arquivo.
 *
 * Para funcionar adequadamente, este programa deve ter 'root' como proprietário
 * e também deve ter setado o suid bit.
 *
 * Copyright (c) 2019 Tonyson Fonseca <vbfton@gmail.com>
 *
 * ESTE PROGRAMA É FORNECIDO "COMO ESTÁ", SEM GARANTIAS NEM CONDIÇÕES DE NENHUM 
 * TIPO, SEJAM ELAS EXPLÍCITAS OU IMPLÍCITAS, INCLUINDO, SEM LIMITAÇÃO, 
 * GARANTIAS OU CONDIÇÕES IMPLÍCITAS DE COMERCIABILIDADE, ADEQUAÇÃO A QUALQUER 
 * FIM ESPECÍFICO E DE NÃO VIOLAÇÃO.
 * O AUTOR NÃO SE RESPONSABILIZA POR ERROS OU OMISSÕES NAS INFORMAÇÕES OU NO 
 * PROGRAMA, OU EM QUALQUER OUTRO DOCUMENTO MENCIONADO OU VINCULADO A ESTE.
 * EM NENHUM CASO, O AUTOR SERÁ RESPONSÁVEL POR QUAISQUER DANOS ESPECIAIS, 
 * INCIDENTAIS, INDIRETOS OU CONSEQÜENCIAIS DE NENHUM TIPO, NEM POR QUAISQUER 
 * DANOS, SEJA QUAL FOR O MOTIVO (INCLUINDO, SEM LIMITAÇÃO, OS DANOS RESULTANTES 
 * DE PERDA DE USO, DADOS OU LUCROS, ATRASOS OU INTERRUPÇÃO DOS NEGÓCIOS, E 
 * QUALQUER RELAÇÃO DE RESPONSABILIDADE, PROVENIENTES OU RELACIONADOS AO USO OU
 * OU DESEMPENHO DESTE PROGRAMA), MESMO QUE O AUTOR TENHA SIDO ADVERTIDO DA 
 * POSSIBILIDADE DE TAIS DANOS.
 *
 * This program is free software; you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the Free
 * Software Foundation; either version 2 of the License, or (at your option)
 * any later version.
 *
 */

#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>

int main(int argc, char *argv[]) 
{
	struct stat statbuf;

	if(argc < 2) {
		printf("USAGE: %s <script_file>\n", argv[0]);
		exit(1);
	}

	if(stat(argv[1], &statbuf) != 0) {
		perror("FAIL");
		exit(1);
	}

	if(!(statbuf.st_mode & S_ISUID))
	{
		fprintf(stderr,"FAIL: file has not suid mode\n");
		exit(1);
	}

	if(setuid(statbuf.st_uid)) {
		perror("FAIL");
		exit(1);
	}

	return system(argv[1]);
}
