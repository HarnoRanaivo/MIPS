.data
    FICHIER:    .asciiz "lena32.bmp"
    DESTINA:    .asciiz "lena2.bmp"
    TEST:       .asciiz "test.txt"
    TESTN:      .asciiz "test_copie.txt"
    ERROPEN:    .asciiz "Erreur lors de l'ouverture du fichier."
    ERRREAD:    .asciiz "Erreur lors de la lecture du fichier."

.text

# Test.txt
#    la $a0 TEST
#    li $a1 0
#    jal OuvrirFichier
#    move $s0 $v0
#
#    li $v0 9
#    li $a0 10
#    syscall
#
#    move $a0 $s0
#    move $a1 $v0
#    li $a2 10
#    jal LireFichier
#    
#    la $a0 TESTN
#    move $a2 $v0
#    jal EcrireFichier

    la $a0 FICHIER
    li $a1 0
    jal LireImage

    la $a0 DESTINA
    move $a1 $v0
    lwr $s2 2($a1)       # s2 : Taille totale du fichier
    jal EcrireFichier

Exit:
    li $v0 10
    syscall

###############################################################################
# OuvrirFichier{{{
# Paramètres :
# a0 : Chemin vers le fichier à ouvrir.
# a1 : Flag (0 : lecture, 1 : écriture)
#
# Retour:
# v0 : Descripteur de fichier.

OuvrirFichier:
# Prologue
    subiu $sp $sp 12
    sw $ra 0($sp)
    sw $a0 4($sp)
    sw $a1 8($sp)

# Corps
    li $a2 0
    li $v0 13
    syscall

    bltz $v0 OuvrirFichierErreur
        j OuvrirFichierEpilogue
    OuvrirFichierErreur:
        la $a0 ERROPEN
        jal Erreur

    OuvrirFichierEpilogue:
# Epilogue
    lw $ra 0($sp)
    lw $a0 4($sp)
    lw $a1 8($sp)
    addiu $sp $sp 12
    jr $ra
#}}}
###############################################################################

###############################################################################
# LireFichier {{{
# Paramètres :
# a0 : Descripteur de fichier.
# a1 : Buffer.
# a2 : Nombre d'octets à lire.
#
# Retour:
# v0 : Nombre d'octets lus.

LireFichier:
# Prologue
    subiu $sp $sp 16
    sw $ra 0($sp)
    sw $a0 4($sp)
    sw $a1 8($sp)
    sw $a2 12($sp)

# Corps
    li $v0 14
    syscall

    bltz $v0 LireFichierErreur
        j LireFichierEpilogue
    LireFichierErreur:
        la $a0 ERRREAD
        jal Erreur

    LireFichierEpilogue:
# Epilogue
    lw $ra 0($sp)
    lw $a0 4($sp)
    lw $a1 8($sp)
    lw $a2 12($sp)
    addiu $sp $sp 16
    jr $ra
#}}}
###############################################################################

###############################################################################
# LireImage {{{
# Paramètres :
# a0 : Chemin vers l'image à ouvrir.
#
# Retour:
# v0 : Adresse du buffer contenant l'image.
# v1 : Adresse du buffer contenant l'image.

LireImage:
# Prologue
    subiu $sp $sp 28
    sw $ra 0($sp)
    sw $a0 4($sp)
    sw $s0 8($sp)
    sw $s1 8($sp)
    sw $s2 12($sp)
    sw $s3 16($sp)
    sw $s4 20($sp)
    sw $s5 24($sp)

# Corps
    move $s5 $a0
    li $a1 0            # Ouverture en lecture
    jal OuvrirFichier
    move $s0 $v0        # s0 : Descripteur du fichier

    # Allocation de 14 octets sur le tas
    li $a0 14           # Taille du buffer
    li $v0 9
    syscall
    move $s1 $v0        # s1 : Buffer pour l'entête du fichier

    # Lecture de l'entête du fichier
    move $a0 $s0        # Descripteur du fichier
    move $a1 $s1        # Adresse du buffer
    li $a2 14           # Nombre d'octets à lire
    jal LireFichier

    lwr $s2 2($s1)       # s2 : Taille totale du fichier
#
#    # Affichage taille
#    move $a0 $s2
#    jal AfficherInt
#

    # Allocation de la mémoire pour l'image sur le tas
    move $a0 $s2        # Taille du buffer
    li $v0 9
    syscall
    move $s3 $v0        # s3 : Buffer pour l'image

    # Allocation de la mémoire pour l'image sur le tas
    move $a0 $s2        # Taille du buffer
    li $v0 9
    syscall
    move $s4 $v0        # s4 : Buffer pour l'image

    # La lecture n'a pas l'air de fonctionner comme on le souhaite si
    # on tente de lire un fichier qu'on a déjà lu précédemment.

    # Fermeture du fichier
    move $a0 $s0        # Descripteur du fichier
    li $v0 16
    syscall

    # Réouverture du fichier
    move $a0 $s5
    li $a1 0            # Ouverture en lecture
    jal OuvrirFichier
    move $s0 $v0        # s0 : Descripteur du fichier

    # Lecture de l'image entière
    move $a0 $s0        # Descripteur du fichier
    move $a1 $s3        # Adresse du buffer
    move $a2 $s2        # Taille du fichier
    jal LireFichier

    # Fermeture du fichier
    move $a0 $s0        # Descripteur du fichier
    li $v0 16
    syscall

    # Réouverture du fichier
    move $a0 $s5
    li $a1 0            # Ouverture en lecture
    jal OuvrirFichier
    move $s0 $v0        # s0 : Descripteur du fichier

    # Lecture de l'image entière
    move $a0 $s0        # Descripteur du fichier
    move $a1 $s4        # Adresse du buffer
    move $a2 $s2        # Taille du fichier
    jal LireFichier

    # Fermeture du fichier
    move $a0 $s0        # Descripteur du fichier
    li $v0 16
    syscall

    # Retour des buffers contenant les copies en mémoire du fichier
    move $v0 $s3
    move $v1 $s4

    LireImageEpilogue:
# Epilogue
    lw $ra 0($sp)
    lw $a0 4($sp)
    lw $s0 8($sp)
    lw $s1 8($sp)
    lw $s2 12($sp)
    lw $s3 16($sp)
    lw $s4 20($sp)
    lw $s5 24($sp)
    addiu $sp $sp 28
    jr $ra
#}}}
###############################################################################

###############################################################################
# TraiterImage {{{
# Paramètres :
# a0 : Source
# a1 : Destination
#
# Retour :
# v0 : Destination

TraiterImage:
# Prologue
    subiu $sp $sp 20
    sw $ra 0($sp)
    sw $a0 4($sp)
    sw $a1 8($sp)
    sw $s0 12($sp)
    sw $s1 16($sp)
    sw $s2 20($sp)
    sw $s3 44($sp)
    sw $s4 28($sp)

# Corps
    lw $s0 10($a0)      # Offset des pixels
    lw $s2 18($a0)      # Largeur en pixels
    lw $s3 22($a0)      # Hauteur en pixels

    add $s3 $a1 $s0     # Adresse du premier pixel (Dest)
    add $s0 $a0 $s0     # Adresse du premier pixel (Source)

    # Buffer matrice 3x3
    li $a0 9            # Taille du buffer
    li $v0 9
    syscall
    move $s4 $v0

    # TODO:
    # Boucle tous les pixels
        # Copie Pixel + Voisinage
        # CalculG
        # Sauvegarde resultat dans Dest
   
# Epilogue
    lw $ra 0($sp)
    lw $a0 4($sp)
    lw $a1 8($sp)
    lw $s0 12($sp)
    lw $s1 16($sp)
    lw $s2 20($sp)
    lw $s3 44($sp)
    lw $s4 28($sp)
    addiu $sp $sp 20
    jr $ra
#}}}
###############################################################################

###############################################################################
# EcrireFichier {{{
# Paramètres :
# a0 : Chemin de destination
# a1 : Buffer
# a2 : Taille du fichier

EcrireFichier:
# Prologue
    subiu $sp $sp 24
    sw $ra 0($sp)
    sw $a0 4($sp)
    sw $a1 8($sp)
    sw $a2 12($sp)
    sw $s0 16($sp)
    sw $s1 20($sp)

# Corps
    move $s0 $a1
    move $s1 $a2

    # Ouverture en écriture du fichier
    li $a1 1
    jal OuvrirFichier

    # Ecriture dans le fichier
    move $a0 $v0
    move $a1 $s0
    move $a2 $s1
    li $v0 15
    syscall

    # Fermeture du fichier
    li $v0 16
    syscall

# Epilogue
    lw $ra 0($sp)
    lw $a0 4($sp)
    lw $a1 8($sp)
    lw $a2 12($sp)
    lw $s0 16($sp)
    lw $s1 20($sp)
    addiu $sp $sp 24
    jr $ra
#}}}
###############################################################################

###############################################################################
# AfficherInt {{{
# Paramètres :
# a0 : Entier à afficher

AfficherInt:
# Prologue
    subiu $sp $sp 8
    sw $ra 0($sp)
    sw $a0 4($sp)

# Corps
    li $v0 1
    syscall

# Epilogue
    lw $ra 0($sp)
    lw $a0 4($sp)
    addiu $sp $sp 8
    jr $ra
#}}}
###############################################################################

###############################################################################
# AfficherString {{{
# Paramètres :
# a0 : Chaîne à afficher.

AfficherString:
# Prologue
    subiu $sp $sp 8
    sw $ra 0($sp)
    sw $a0 4($sp)

# Corps
    li $v0 4
    syscall

# Epilogue
    lw $ra 0($sp)
    lw $a0 4($sp)
    addiu $sp $sp 8
    jr $ra
#}}}
###############################################################################

###############################################################################
# Erreur {{{
# Paramètres :
# a0 : Chaîne à afficher.

Erreur:
# Prologue
    subiu $sp $sp 8
    sw $ra 0($sp)
    sw $a0 4($sp)

# Corps
    jal AfficherString
    jal Exit

# Epilogue
    lw $ra 0($sp)
    lw $a0 4($sp)
    addiu $sp $sp 8
    jr $ra
#}}}
###############################################################################

# vim:ft=asm:fdm=marker:ff=unix:foldopen=all:foldclose=all 
