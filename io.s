.data

demande: .asciiz "Rentrez une image à ouvrir\n"
perror: .asciiz "Erreur d'ouverture du fichier\n"
perror2: .asciiz "Erreur de lecture de fichier\n"

.text

main:
jal dem
jal recup
jal chercheBSlashN
jal gereImage

dem:
la $a0 demande
li $v0 4
syscall
jr $ra

recup:
li $a0 50 # $a0 = 50
li $v0 9 # allocation de $a0 octets
syscall
li $a1 50
move $a0 $v0
li $v0 8 # read string
syscall
jr $ra

chercheBSlashN:
#Prologue
subu $sp $sp 12
sb $a1 8($sp)
sb $a0 4($sp)
sw $ra 0($sp)
#Corps de la fonction
li $t0 1
li $t1 10 # valeur de \n
li $t3 0
mul $a1 $a1 $t0
LoopCherche:
beq $t0 $a1 FinLoopCherche
add $t2 $a0 $t0
lw $t3 0($t2)
beq $t3 $t1 FinLoopCherche
j LoopCherche
FinLoopCherche:
move 

gereImage:
#ouverture
li $v0 13
li $a1 0 #ouvre pour lire
li $a2 0 #mode est ingoré
syscall
bltz $v0 ouv #teste si le fichier est ouvert (existe)
move $s6 $v0 #sauvegarde le descripteur de fichier
#lecture
li $a0 50 # 50 octets
li $v0 9 # allocation
syscall
move $a1 $v0
move $a0 $s6
li $v0 14
li $a2 49 # max de caractères à lire
syscall
bltz $v0 lect #teste si le fichier est ouvert (existe)
#affichage
move $a0 $a1
li $v0 4
syscall
#fermeture
li $v0 16 #close file
move $a0 $s6 #file descriptor à fermer
syscall
j Exit

Exit:
li $v0 10 #exit
syscall

ouv: #erreur d'ouverture
la $a0 perror
li $v0 4
syscall
j Exit

lect: #erreur de lecture
la $a0 perror2
li $v0 4
syscall
j Exit