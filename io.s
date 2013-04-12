.data

demande: .asciiz "Rentrez une chaine de caractère\n"
perror: .asciiz "Erreur d'ouverture du fichier\n"
perror2: .asciiz "Erreur de lecture de fichier\n"

.text

main:
jal dem
jal recup
jal cherchePoint
jal rajouteBMP
jal chercheBSlashN
jal affiche


Exit:
li $v0 10 #exit
syscall

dem:
la $a0 demande
li $v0 4
syscall
jr $ra

recup:
li $a0 50 # $a0 = 50
li $v0 9 # allocation de $a0 octets
syscall
li $a1 50 # maximum de caractère à lire
move $a0 $v0 # $a0 = adresse allouée
li $v0 8 # read string
syscall
jr $ra

cherchePoint:
#Prologue
subiu $sp $sp 12
sw $a1 8($sp)
sw $a0 4($sp)
sw $ra 0($sp)
#Corps de la fonction
li $t1 46 # valeur du .
li $t2 67 # C
li $t3 111 # o
li $t4 110 # n
li $t5 116 # t
li $t6 111 # o
li $t7 117 # u
li $t8 114 # r
li $t9 46 # .
LoopCherchePoint:
lb $t0 0($a0)
beq $t0 $t1 RemplacePoint
addiu $a0 $a0 1 # incrément $t0
j LoopCherchePoint
RemplacePoint:
sb $t2 0($a0)
addiu $a0 $a0 1
sb $t3 0($a0)
addiu $a0 $a0 1
sb $t4 0($a0)
addiu $a0 $a0 1
sb $t5 0($a0)
addiu $a0 $a0 1
sb $t6 0($a0)
addiu $a0 $a0 1
sb $t7 0($a0)
addiu $a0 $a0 1
sb $t8 0($a0)
addiu $a0 $a0 1
sb $t9 0($a0)
j FinLoopCherchePoint
FinLoopCherchePoint:
#Epilogue
lb $t9 0($a0)
move $v0 $t9
lw $a1 8($sp)
lw $a0 4($sp)
lw $ra 0($sp)
addiu $sp $sp 12
jr $ra

rajouteBMP:
#Prologue
subiu $sp $sp 12
sw $a1 8($sp)
sw $a0 4($sp)
sw $ra 0($sp)
#Corps de la fonction
li $t1 46 # valeur du .
li $t2 98 # b
li $t3 109 # m
li $t4 112 # p
LoopCherchePointBIS:
lb $t0 0($a0)
beq $t0 $t1 ajoutBMP
addiu $a0 $a0 1 # incrément $t0
j LoopCherchePointBIS
ajoutBMP:
sb $t1 0($a0)
addiu $a0 $a0 1
sb $t2 0($a0)
addiu $a0 $a0 1
sb $t3 0($a0)
addiu $a0 $a0 1
sb $t4 0($a0)
j FinLoopCherchePointBMP
FinLoopCherchePointBMP:
#Epilogue
lb $t4 0($a0)
move $v0 $t9
lw $a1 8($sp)
lw $a0 4($sp)
lw $ra 0($sp)
addiu $sp $sp 12
jr $ra

chercheBSlashN:
#Prologue
subiu $sp $sp 12
sw $a1 8($sp)
sw $a0 4($sp)
sw $ra 0($sp)
#Corps de la fonction
li $t1 10 # valeur de \n
li $t4 0 # valeur de \0
LoopCherche:
lb $t0 0($a0)
beqz $t0 FinLoopCherche # teste si $t3 = 10
beq $t0 $t1 SupprimerChariot
addi $a0 $a0 1 # incrément $t0
j LoopCherche
SupprimerChariot:
sb $t4 0($a0)
j FinLoopCherche
FinLoopCherche:
#Epilogue
lb $t0 0($a0)
move $v0 $t0
lw $a1 8($sp)
lw $a0 4($sp)
lw $ra 0($sp)
addiu $sp $sp 12
jr $ra

affiche:
li $v0 4
syscall
j Exit