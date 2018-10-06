.data
file: .asciiz "lena.bmp"
pixel: .word 0
tamx: .word 0
tamy: .word 0
offs: .word 0
byte: .byte 0
tam_blur: .word 1
img: .word 0x10040000
enter: .asciiz "\n"
fimlinha: .asciiz "\0"

menu: .asciiz "\nMENU\n1) Abrir imagem\n2) Blur effect\n3) Edge Extractor\n4) Thresholding\n5) Sair\nEscolha uma opcao:"
threshold: .asciiz "\n\nTHRESHOLDING\n"
R_max: .asciiz "Digite o valor maximo de vermelho: "
G_max: .asciiz "Digite o valor maximo de verde: "
B_max: .asciiz "Digite o valor maximo de azul: "
R_min: .asciiz "Digite o valor minimo de vermelho: "
G_min: .asciiz "Digite o valor minimo de verde: "
B_min: .asciiz "Digite o valor minimo de azul: "

salva: .asciiz "\nDigite o nome do arquivo: "
nome_salva: .asciiz "l.bmp"

blur: .asciiz "\nDigite o tamanho do kernel do blur: "
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
li $t1,0

move $a0,$s0
loop:
la $a1,pixel
li $a2,3
li $v0,14
syscall

lw $s1,pixel
sw $s1,0x10040000($t0)
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
beq $t1,1,abrir
beq $t1,2,blur_effect
beq $t1,3,edge_extractor
beq $t1,4,thresholding
beq $t1,6,salvar

# encerra o programa
li $v0,10
syscall

################################################################################
blur_effect:



################################################################################
edge_extractor:

# coloca imagem em greyscale
lw $t1,tamx
lw $t2,tamy
mul $s1,$t1,$t2
mul $s1,$s1,4


li $t0,0

# pega os valores das cores em cada pixel, faz a media simples e registra cada nivel de cor com esse valor
converte:
addi $s2,$t0,0x10040000
lbu $t1,1($s2)
lbu $t2,2($s2)
lbu $t3,3($s2)
add $s3,$t1,$t2
add $s3,$s3,$t3
div $s3,$s3,3
move $t3,$s3
mul $s3,$s3,0x0010101
sw $s3,($s2)


addi $t0,$t0,4

bne $t0,$s1,converte


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
mul $s4,$s4,0x00010000
mul $t4,$t4,0x0000100
add $s4,$s4,$t4
add $s4,$s4,$t5

# coloca em um unico registrador
mul $s5,$s5,0x00010000
mul $t6,$t6,0x00000100
add $s5,$s5,$t5
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
bge $t2,$s4,zero	# conefere se e menor que o maximo
bge $s5,$t2,zero	#confere se e maior que o minimo

sw $t4,($t3)
addi $t0,$t0,4
addi $t3,$t3,4
bge $s1,$t0,loop_thresh

zero:
sw $zero,($t3)

addi $t0,$t0,4
addi $t3,$t3,4
bge $s1,$t0,loop_thresh

j abre_menu   # volta para o menu

################################################################################
salvar:

li $v0,4
la $a0,salva
syscall

li $v0,8
la $a0,nome_salva
li $a1,80
syscall

li $t3,0
procura:
lbu $s5,nome_salva($t3)
addi $t3,$t3,1
beq $s5,13,troca
j procura

troca:
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









