.data
file: .asciiz "lena.bmp"
pixel: .word 0
tamx: .word
tamy: .word
header: .space 56
offs: .word
byte: .byte

menu: .asciiz "MENU\n1) Abrir imagem\n2) Blur effect\n3) Edge Extractor\n4) Thresholding\n5) Sair\nEscolha uma opcao:"

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
la $t1,($v0)
beq $t1,1,abrir
beq $t1,2,blur_effect
beq $t1,3,edge_extractor
beq $t1,4,thresholding

# encerra o programa
li $v0,10
syscall

################################################################################
blur_effect:



################################################################################
edge_extractor:



################################################################################
thresholding:














