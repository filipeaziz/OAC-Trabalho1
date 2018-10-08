.data
file: .asciiz "lena.bmp"
pixel: .word 0
tamx: .word 0
tamy: .word 0
offs: .word 0
tam_blur: .word 1
img: .word 0x10040000
kernel: .word 0
func: .word 0
tamimg: .word 0
iniimg: .word 0

menu: .asciiz "\nMENU\n1) Abrir imagem\n2) Blur effect\n3) Edge Extractor\n4) Thresholding\n5) Sair\nEscolha uma opcao:"
threshold: .asciiz "\n\nTHRESHOLDING\n"
R_max: .asciiz "Digite o valor maximo de vermelho: "
G_max: .asciiz "Digite o valor maximo de verde: "
B_max: .asciiz "Digite o valor maximo de azul: "
R_min: .asciiz "Digite o valor minimo de vermelho: "
G_min: .asciiz "Digite o valor minimo de verde: "
B_min: .asciiz "Digite o valor minimo de azul: "

salva: .asciiz "\n\nGostaria de salvar a imagem? \nSim = 1 e Nao = 0: "
digite_salva: .asciiz "\nDigite o nome do arquivo: "
nome_salva: .asciiz "nome.bmp"
.align 2

blur: .asciiz "\nDigite o tamanho do kernel do blur: "
byte: .byte 0
.align 2
header: .space 56

.text

j abre_menu   # vai primeiro para o menu

################################################################################
# Abre a imagem

abrir:
li   $v0, 13       # system call for open file
la   $a0, file     # board file name
li   $a1, 0        # Open for reading
li   $a2, 0
syscall            # open a file (file descriptor returned in $v0)
move $s0, $v0      # save the file descriptor 


# Le todo o cabecalho
move $a0,$s0
la $a1,header+2    # soma 2 para alinhar a memoria
li $a2,54
li $v0,14
syscall


# Armazena o offset, o tamanho em x e o tamanho em y da imagem
lw $s1,header+12
sw $s1,offs
lw $s2,header+20
sw $s2,tamx
lw $s3,header+24
sw $s3,tamy
mul $s4,$s2,$s3
sw $s4,tamimg

# salva onde comeca a segunda imagem
mul $t5,$s4,4
addi $t5,$t5,0x10040000 
sw $t5,iniimg

# Anda no arquivo ate comecarem os bits de pixel

addi $s1,$s1,-54
pula:
beqz $s1,abre
move $a0,$s0
la $a1,byte
li $a2,1
li $v0,14
syscall
addi $s1,$s1,-1
j pula


# Coloca no contador o endereco, primeiramente, do primeiro elemento da ultima linha
abre:
addi $s3,$s3,-1
mul $t0,$s2,$s3
mul $t0,$t0,4
lw $t3,tamimg
mul $t3,$t3,4
add $t3,$t3,$t0
li $t1,0

move $a0,$s0
loop:
la $a1,pixel
li $a2,3
li $v0,14
syscall

lw $s1,pixel
sw $s1,0x10040000($t0)
sw $s1,0x10040000($t3)
addi $t3,$t3,4
addi $t0,$t0,4
addi $t1,$t1,1

bge $t1,$s2,abre    # verifica se chegou no fim da linha
bne $v0,$zero,loop  # verifica se a imagem terminou

li   $v0, 16       # system call for close file
move $a0, $s0      # file descriptor to close
syscall            # close file


j abre_menu   # volta para o menu

################################################################################
abre_menu:

# imprime na tela o menu
la $a0,menu
li $v0,4
syscall

# recebe do usuario um inteiro
li $v0,5
syscall

# determina qual funcao realizar
move $t1,$v0
sw $t1,func
beq $t1,1,abrir
beq $t1,2,blur_effect
beq $t1,3,edge_extractor
beq $t1,4,thresholding

# encerra o programa
li $v0,10
syscall

################################################################################
blur_effect:

# pergunta o tamanho do kernel
la $a0,blur
li $v0,4
syscall

# recebe do usuario um inteiro
li $v0,5
syscall

sw $v0,kernel
move $s0,$v0

# cria o kernel
mul $s0,$s0,$s0
mul $s0,$s0,4

li $s1,0
addiu $s1,$s1,1
li $t0,0
preenche:
sw $s1,0x10000000($t0)
addi $t0,$t0,4
bgt $s0,$t0,preenche

# faz a convolucao
j convolucao
termina:

# passa imagem para heap visivel
jal move_imagem

li $v0,4
la $a0,salva
syscall

li $v0,5
syscall
bnez $v0, salvar

j abre_menu   # volta para o menu

################################################################################
edge_extractor:

jal greyscale

# tamanho do kernel
li $s1,3
sw $s1,kernel


# cria kernel
li $s0,0
li $s1,0
addiu $s1,$s1,1
li $s2,0
addiu $s2,$s2,2
li $s3,-1
li $s4,-2
li $t0,0
sw $s2,0x10000000($t0)
li $t0,4
sw $s1,0x10000000($t0)
li $t0,8
sw $s4,0x10000000($t0)
li $t0,12
sw $s1,0x10000000($t0)
li $t0,16
sw $s0,0x10000000($t0)
li $t0,20
sw $s3,0x10000000($t0)
li $t0,24
sw $s2,0x10000000($t0)
li $t0,28
sw $s3,0x10000000($t0)
li $t0,32
sw $s4,0x10000000($t0)

# faz convolucao
j convolucao
termina2:

# binariza imagem


# passa imagem para heap visivel
jal move_imagem

li $v0,4
la $a0,salva
syscall

li $v0,5
syscall
bnez $v0, salvar

j abre_menu   # volta para o menu

################################################################################
thresholding:

la $a0,threshold
li $v0,4
syscall


# Valor maximo
la $a0,R_max
li $v0,4
syscall
li $v0,5
syscall
move $s4,$v0

la $a0,G_max
li $v0,4
syscall
li $v0,5
syscall
move $t4,$v0

la $a0,B_max
li $v0,4
syscall
li $v0,5
syscall
move $t5,$v0


# Valor minimo
la $a0,R_min
li $v0,4
syscall
li $v0,5
syscall
move $s5,$v0

la $a0,G_min
li $v0,4
syscall
li $v0,5
syscall
move $t6,$v0

la $a0,B_min
li $v0,4
syscall
li $v0,5
syscall
move $t7,$v0



limiar:
# coloca em um unico registrador
sll $s4,$s4, 16
sll $t4,$t4, 8
add $s4,$s4,$t4
add $s4,$s4,$t5

# coloca em um unico registrador
sll $s5,$s5,16
sll $t6,$t6,8
add $s5,$s5,$t6
add $s5,$s5,$t7



lw $s2,tamx
lw $s3,tamy
mul $s1,$s2,$s3
mul $s1,$s1,4

li $t3,0x10040000
lw $t0,img
add $s1,$s1,$t0
li $t4,0x00ffffff


loop_thresh:
lw $t2, ($t0)
bgt $t2,$s4,zero	# conefere se e menor que ao maximo
blt $t2,$s5,zero	# confere se e maior que o minimo

sw $t4,($t3)
addi $t0,$t0,4
addi $t3,$t3,4
bge $s1,$t0,loop_thresh

zero:
sw $zero,($t3)

addi $t0,$t0,4
addi $t3,$t3,4
bge $s1,$t0,loop_thresh

li $v0,4
la $a0,salva
syscall

li $v0,5
syscall
bnez $v0, salvar

j abre_menu   # volta para o menu

################################################################################
salvar:

li $v0,4
la $a0,digite_salva
syscall

li $v0,8
la $a0,nome_salva
li $a1,24
syscall

li $t3,0
procura:
lbu $s5,nome_salva($t3)
addi $t3,$t3,1
beq $s5,10,troca
j procura

troca:
addi $t3,$t3,-1

li $s5,0
sb $s5,nome_salva($t3)


li $v0,13
la $a0,nome_salva
li $a1,1
li $a2,0
syscall
move $s0,$v0

li $v0,15
move $a0,$s0
la $a1,header+2
li $a2,54
syscall


lw $s2,tamx
lw $s3,tamy
move $s4,$s3
li $t2,0

muda_linha:
addi $s3,$s3,-1
mul $t0,$s2,$s3
mul $t0,$t0,4
li $t1,0
addi $t2,$t2,1


loop_salvar:
la $a1,0x10040000($t0)
li $a2,3
li $v0,15
syscall


addi $t0,$t0,4
addi $t1,$t1,1

bge $t1,$s2,muda_linha    # verifica se chegou no fim da linha
bge $s4,$t2,loop_salvar  # verifica se a imagem terminou



li   $v0, 16       # system call for close file
move $a0, $s0      # file descriptor to close
syscall 

j abre_menu   # volta para o menu

################################################################################
greyscale:

lw $t1,tamx
lw $t2,tamy
mul $s1,$t1,$t2
mul $s1,$s1,4


li $t0,0

# pega os valores das cores em cada pixel, faz a media simples e registra cada nivel de cor com esse valor
lw $s2,iniimg
converte:
lbu $t1,1($s2)
lbu $t2,2($s2)
lbu $t3,3($s2)
add $s3,$t1,$t2
add $s3,$s3,$t3
div $s3,$s3,3
move $t3,$s3
mul $s3,$s3,0x0010101
sw $s3,($s2)

addi $s2,$s2,4
addi $t0,$t0,4

bne $t0,$s1,converte

jr $ra

################################################################################
convolucao:

li $s0,0   # contador de linhas da imagem
li $s1,0   # contador de colunas da imagem
li $s2,0   # contador de linhas do kernel
li $s3,0   # contador de colunas do kernel


convloop:
li $s4,0   # contador para percorer o kernel
li $s5,0   # registra soma dos R
li $s6,0   # registra soma dos G
li $s7,0   # registra soma dos B

j coordenadas

poscoordenadas:

lw $t0,func
bne $t0,2,cont   # caso seja blur, faz a media da soma, caso seja edge extractor, pula
lw $t1,kernel
mul $t1,$t1,$t1
div $s5,$s5,$t1
div $s6,$s6,$t1
div $s7,$s7,$t1

# associa cada cor a uma word (32bits)
cont:
mul $s5,$s5,0x00010000
mul $s6,$s6,0x00000100

# soma todas as cores em uma word apenas
add $t2,$s5,$s6
add $t2,$t2,$s7

# acha posicao onde deve ser colocado a nova word de cores
lw $t3,tamx
lw $t5,iniimg
mul $t6,$t3,$s0
add $t6,$t6,$s1
mul $t6,$t6,4
add $t6,$t6,$t5

# insere nova word de cores na imagem
#li $t2,0x00325700
sw $t2,($t6)

# confere se ja terminou a convolucao
addi $s1,$s1,1
bgt $t3,$s1,convloop  # se esta na ultima coluna, confere a linha
lw $t7,tamy
addi $s0,$s0,1
blt $s0,$t7,modifica  # se esta na ultima linha, acaba, caso nao, ajusta coordenadas  para continuar
lw $s0,func
beq $s0,2,termina   # termina a convolucao e volta para blur
beq $s0,3,termina2   # termina a convolucao e volta para edge extractor

# ajusta numero de linha e coluna no kernel
modifica:
li $s1,0
j convloop

################################################################################
coordenadas:

# relacionando a posicao na leitura do kernel com a posicao na imagem
lw $t0,kernel
div $t0,$t0,2
sub $t1,$s2,$t0
sub $t2,$s3,$t0
add $t1,$t1,$s0
add $t2,$t2,$s1

# confere se a posicao existe na imagem
lw $t3,tamx
lw $t4,tamy
bltz $t1,zera
bltz $t2,zera
bgt $t1,$t3,zera
bgt $t2,$t4,zera
j continua
# carrega zero como valer de cores por estar fora da imagem
zera:
li $t6,0
li $t7,0
li $t8,0
j soma

# pega valores das cores na memoria caso o ponto esteja na imagem
continua:
mul $t5,$t3,$t1
add $t5,$t5,$t2
mul $t5,$t5,4
addi $t5,$t5,0x10040000
lbu $t6,1($t5)
lbu $t7,2($t5)
lbu $t8,3($t5)

# soma o valor de cada cor ao somador de cada cor
soma:
addi $t9,$s4,0x10000000
lw $t0,($t9)
mul $t1,$t0,$t6
add $s5,$s5,$t1
mul $t1,$t0,$t7
add $s6,$s6,$t1
mul $t1,$t0,$t8
add $s7,$s7,$t1

# confere se ja terminou de passar o kernel
addi $s4,$s4,4
addi $s3,$s3,1
lw $t2,kernel
bgt $t2,$s3,coordenadas  # se esta na ultima coluna, confere a coluna
addi $s2,$s2,1
blt $s2,$t2,ajusta  # se esta na ultima linha, acaba, caso nao, ajusta coordenadas  para continuar
j poscoordenadas

# ajusta numero de linha e coluna no kernel
ajusta:
li $s3,0
j coordenadas


################################################################################
move_imagem:

lw $s0,tamimg
mul $s0,$s0,4

li $t0,0
lw $s1,iniimg
transfere:
lw $s2,($s1)
sw $s2,0x10040000($t0)
addi $s1,$s1,4
addi $t0,$t0,4
bne $t0,$s0,transfere

jr $ra

################################################################################
