.data
    SEUIL:       .word   100                                    # Seuil
    FTAILLE:     .word   3                                      # Taille des matrices carrées Fx et Fy
    FX:          .word   1, 0, -1, 2, 0, -2, 1, 0, -1           # Fx utilisée dans la convolution de matrices
    FY:          .word   1, 2, 1, 0, 0, 0, -1, -2, -1           # Fy utilisée dans la convolution de matrices
    A:           .word   128, 3, 210, 5, 30, 78, 255, 0, 153

    FICHIER:    .asciiz "lena256.bmp"
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

# Test LireImage
#    la $a0 FICHIER
#    li $a1 0
#    jal LireImage
#
#    la $a0 DESTINA
#    move $a1 $v0
#    lwr $s2 2($a1)       # s2 : Taille totale du fichier
#    jal EcrireFichier

# Test TraiterImage
    la $a0 FICHIER
    li $a1 0
    jal LireImage

    move $a0 $v0
    move $a1 $v1
    jal TraiterImage

    la $a0 DESTINA
    move $a1 $v0
    lwl $s2 5($a1) ##
    lwr $s2 2($a1)       # s2 : Taille totale du fichier
    jal EcrireFichier

Exit:
    li $v0 10
    syscall

###############################################################################
# Valeur Absolue {{{
# Paramètres :
# a0 : Entier dont on veut la valeur absolue
#
# Retour:
# v0 : Valeur absolue de a0

ValeurAbsolue:
# Prologue
    subiu $sp $sp 8
    sw $ra 0($sp)
    sw $a0 4($sp)

# Corps
    bltz $a0 NegValeur
        move $v0 $a0                # a0 >= 0 : v0 = a0
        j ValeurAbsolueEpilogue
    NegValeur:
        negu $v0 $a0                # a0 < 0 : v0 = -a0
        j ValeurAbsolueEpilogue

    ValeurAbsolueEpilogue:
# Epilogue
    lw $ra 0($sp)
    lw $a0 4($sp)
    addiu $sp $sp 8
    jr $ra
# Fin Valeur Absolue
# }}}
###############################################################################

###############################################################################
# Seuillage255 {{{
# Paramètres :
# a0 : Entier à seuiller
#
# Retour :
# v0 : a0 seuillé

Seuillage255:
# Prologue
    subiu $sp $sp 8
    sw $ra 0($sp)
    sw $a0 4($sp)

# Corps
    li $t0 255
    bge $a0 $t0 SupSeuil255
        move $v0 $a0                # a0 < 255 : v0 = a0
        j Seuillage255Epilogue
    SupSeuil255:
        move $v0 $t0                # a0 >= 255 : v0 = 255
        j Seuillage255Epilogue

    Seuillage255Epilogue:
# Epilogue
    lw $ra 0($sp)
    lw $a0 4($sp)
    addiu $sp $sp 8
    jr $ra
# Fin Seuillage255
# }}}
###############################################################################

###############################################################################
# SeuillageInf {{{
# Paramètres :
# a0 : Entier à seuiller
# a1 : Seuil inférieur
#
# Retour :
# v0 : a0 seuillé
SeuillageInf:
    # Prologue
    subiu $sp $sp 12
    sw $ra 0($sp)
    sw $a0 4($sp)
    sw $a1 4($sp)

    # Corps
    ble $a0 $a1 InfSeuil
        move $v0 $a0                # a0 > a1 : v0 = a0
        j SeuillageInfEpilogue
    InfSeuil:
        move $v0 $0                 # a0 <= a1 : v0 = 0
        j SeuillageInfEpilogue

    SeuillageInfEpilogue:
    # Epilogue
    lw $ra 0($sp)
    lw $a0 4($sp)
    lw $a1 8($sp)
    addiu $sp $sp 12
    jr $ra
# Fin SeuillageInf
# }}}
###############################################################################

###############################################################################
# Convolution {{{
# Paramètres :
# a0 : taille des matrices
# a1 : matrice A
# a2 : matrice Fx ou Fy
#
# Retour :
# v0 : convolution de a1 par a2

Convolution:
# Prologue
    subiu $sp $sp 16
    sw $ra 0($sp)
    sw $a0 4($sp)
    sw $a1 8($sp)
    sw $a2 12($sp)

# Corps
    # Initialisations
    move $t0 $0         # Compteur
    move $t1 $a1        # Adresse de A
    move $t2 $a2        # Adresse de F
    li $t7 4
    mul $t3 $t0 $t7     # Compteur en octets
    move $t4 $0         # V
    move $t5 $0
    move $t6 $0
    mul $a0 $a0 $a0

    LoopConvolution:
    beq $t0 $a0 EndLoopConvolution
        addu $t1 $a1 $t3    # Adresse de A[$t0]
        addu $t2 $a2 $t3    # Adresse de F[$t0]
        lb $t5 0($t1)       # Chargement de A[$t0]
        lb $t6 0($t2)       # Chargement de F[$t0]
        mul $t5 $t5 $t6     # A[$t0] * F[$t0]
        add $t4 $t4 $t5     # $t4 += A[$t0] * F[$t0]
        addi $t0 $t0 1      # Incrémentation du compteur
        mul $t3 $t0 $t7
        j LoopConvolution
    EndLoopConvolution:

    move $v0 $t4

# Epilogue
    lw $ra 0($sp)
    lw $a0 4($sp)
    lw $a1 8($sp)
    lw $a2 12($sp)
    addiu $sp $sp 16
    jr $ra
#Fin Convolution
#}}}
###############################################################################

###############################################################################
# CalculGxy {{{
# Calcul de la convolution de a0 par a1, et seuillage.
# Paramètres :
# a0 : Adresse du pixel et de ses pixels environnants
# a1 : Adresse de Fx ou Fy
#
# Retour :
# v0 : Fx(a0) ou Fy(a0) (valeur absolue seuillée)

CalculGxy:
# Prologue
    subiu $sp $sp 12
    sw $ra 0($sp)
    sw $a0 4($sp)
    sw $a1 8($sp)

# Corps
    move $a2 $a1
    move $a1 $a0
    lw $a0 FTAILLE
    jal Convolution         # Convolution de a0 par Fx ou Fy

    move $a0 $v0            # v0 : retour de Convolution
    jal ValeurAbsolue       # Valeur absolue de Gx(a0) (resp. Gy(a0))

    move $a0 $v0            # v0 : retour de ValeurAbsolue
    jal Seuillage255        # Seuillage de Gx(a0) (resp. Gy(a0))

    move $a0 $v0            # v0 : retour de Seuillage255
    lw $a1 SEUIL
    jal SeuillageInf        # Seuillage inf de Gx(a0) (resp. Gy(a0))

    # v0 : retour de SeuillageInf(Seuillage255(Convolution(FTAILLE, a0, a1)))

# Prologue
    lw $ra 0($sp)
    lw $a0 4($sp)
    lw $a1 8($sp)
    addiu $sp $sp 12
    jr $ra
# }}}
###############################################################################

###############################################################################
# CalculG {{{
# Paramètres :
# a0 : Adresse du pixel et de ses pixels environnants
#
# Retour :
# v0 : G(a0)

CalculG:
# Prologue
    subiu $sp $sp 8
    sw $ra 0($sp)
    sw $a0 4($sp)

# Corps
    # Calcul de Gx
    la $a1 FX
    jal CalculGxy       # a0 n'a pas été modifié : a0 de l'appel de CalculG
    move $s0 $v0        # v0 : retour de CalculGxy(a0, FX)

    # Calcul de Gy
    la $a1 FY
    jal CalculGxy       # a0 n'a pas été modifié : a0 de l'appel de CalculG

    # Gx + Gy et nouveau seuillage
    add $s0 $s0 $v0     # CalculGxy(a0, FX) + CalculGxy(a0, FY)
    move $a0 $s0
    jal Seuillage255

# Epilogue
    lw $ra 0($sp)
    lw $a0 4($sp)
    addiu $sp $sp 8
    jr $ra
# }}}
###############################################################################

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
    move $s0 $a0
    li $a1 0            # Ouverture en lecture
    jal OuvrirFichier
    move $s1 $v0        # s1 : Descripteur du fichier

    # Allocation de 14 octets sur le tas
    li $a0 14           # Taille du buffer
    li $v0 9
    syscall
    move $s2 $v0        # s2 : Buffer pour l'entête du fichier

    # Lecture de l'entête du fichier
    move $a0 $s1        # Descripteur du fichier
    move $a1 $s2        # Adresse du buffer
    li $a2 14           # Nombre d'octets à lire
    jal LireFichier

    lwl $s3 5($s2)
    lwr $s3 2($s2)       # s3 : Taille totale du fichier
#
    # Affichage taille
    move $a0 $s3
    jal AfficherInt
#

    # Allocation de la mémoire pour l'image sur le tas
    move $a0 $s3        # Taille du buffer
    li $v0 9
    syscall
    move $s4 $v0        # s4 : Buffer pour l'image

    # Allocation de la mémoire pour l'image sur le tas
    move $a0 $s3        # Taille du buffer
    li $v0 9
    syscall
    move $s5 $v0        # s5 : Buffer pour l'image

    # La lecture n'a pas l'air de fonctionner comme on le souhaite si
    # on tente de lire un fichier qu'on a déjà lu précédemment.

    # Fermeture du fichier
    move $a0 $s1        # Descripteur du fichier
    li $v0 16
    syscall

    # Réouverture du fichier
    move $a0 $s0
    li $a1 0            # Ouverture en lecture
    jal OuvrirFichier
    move $s1 $v0        # s1 : Descripteur du fichier

    # Lecture de l'image entière
    move $a0 $s1        # Descripteur du fichier
    move $a1 $s4        # Adresse du buffer
    move $a2 $s3        # Taille du fichier
    jal LireFichier

    # Fermeture du fichier
    move $a0 $s1        # Descripteur du fichier
    li $v0 16
    syscall

    # Réouverture du fichier
    move $a0 $s0
    li $a1 0            # Ouverture en lecture
    jal OuvrirFichier
    move $s1 $v0        # s1 : Descripteur du fichier

    # Lecture de l'image entière
    move $a0 $s1        # Descripteur du fichier
    move $a1 $s5        # Adresse du buffer
    move $a2 $s3        # Taille du fichier
    jal LireFichier

    # Fermeture du fichier
    move $a0 $s1        # Descripteur du fichier
    li $v0 16
    syscall

    # Retour des buffers contenant les copies en mémoire du fichier
    move $v0 $s4
    move $v1 $s5

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
    subiu $sp $sp 44
    sw $ra 0($sp)
    sw $a0 4($sp)
    sw $a1 8($sp)
    sw $a2 12($sp)
    sw $s0 16($sp)
    sw $s1 20($sp)
    sw $s2 24($sp)
    sw $s3 28($sp)
    sw $s4 32($sp)
    sw $s6 36($sp)
    sw $s7 40($sp)

# Corps
    move $s0 $a0
    move $s1 $a1

    lwr $s2 10($a0)      # Offset des pixels
    lwr $s3 18($a0)      # Largeur en pixels
    lwr $s4 22($a0)      # Hauteur en pixels

    add $s5 $a0 $s2      # Adresse du premier pixel (Source)
    add $s6 $a1 $s2      # Adresse du premier pixel (Dest)

####
    # Vérification lecture correcte de la taille
    # move $a0 $s2
    # jal AfficherInt
    # move $a0 $s3
    # jal AfficherInt
    # move $a0 $s4
    # jal AfficherInt
####

    # Buffer matrice 3x3
    li $a0 9            # Taille du buffer
    li $v0 9
    syscall
    move $s7 $v0        # s7 : Adresse du buffer

    # TODO:
    # Initialisation boucle sur tous les pixels
    move $t0 $0           # t0 : Compteur lignes
    move $t1 $0           # t1 : Compteur colonnes
    # Ne pas oublier de sauvegarder/charger les $ti à chaque
    # appel de fonction !

    # Boucle sur tous les pixels restants
    TraiterImageBoucleLignes:
    beq $t0 $s3 TraiterImageBoucleLignesFin
        move $t1 $0
        TraiterImageBoucleColonnes:
        beq $t1 $s4 TraiterImageBoucleColonnesFin

            # Si on est sur les bords, mettre à 0
            subi $t2 $s3 1
            beq $t0 $0 TraiterImageBoucleColonnesZero
            beq $t0 $t2 TraiterImageBoucleColonnesZero
            subi $t2 $s4 1
            beq $t1 $0 TraiterImageBoucleColonnesZero
            beq $t1 $t2 TraiterImageBoucleColonnesZero
            # Si on est pas sur les bords :
####
                # Premier test, soyons fou fou
                # mul $t2 $t0 $s3         # t2 : t0 * s3
                # add $t2 $s6 $t2         # t2 : t2 + t6
                # add $t2 $t2 $t1         # t2 : t2 + t1
                # sb $0 0($t2)
####
                # Sauvegarde des $ti importants avant appel de fonction
                subiu $sp $sp 8
                sw $t0 0($sp)
                sw $t1 4($sp)

                subi $t3 $t0 1
                subi $t4 $t1 1
                mul $t2 $t3 $s3
                add $t2 $s5 $t2
                add $t2 $t2 $t4
                move $a0 $t2            # Adresse du coin gauche de la matrice 3x3
                move $a1 $s7            # Buffer 3x3
                move $a2 $s3            # Nombre de colonnes
                jal CopieVoisinage

                move $a0 $v0
                jal CalculG

                ## Restauration des $ti précédemment sauvegardés
                lw $t0 0($sp)
                lw $t1 4($sp)
                addiu $sp $sp 8

                # Adresse du pixel =
                # ligne courante * nombre de colonnes + colonne courante
                # t2 = t0 * s3 + t1
                mul $t2 $t0 $s3         # t2 : t0 * s3
                add $t2 $s6 $t2         # t2 : t2 + t6
                add $t2 $t2 $t1         # t2 : t2 + t1
                sb $v0 0($t2)           # Copie résultat CalculG
####
                #li $t7 128
                #sb $t7 0($t2)
####

            j TraiterImageBoucleColonnesIncrementation

            # Mise à 0
            TraiterImageBoucleColonnesZero:
                mul $t2 $t0 $s3             # t2 : t0 * s3
                add $t2 $s6 $t2             # t2 : t2 + t6
                add $t2 $t2 $t1             # t2 : t2 + t1
                sb $0 0($t2)
            j TraiterImageBoucleColonnesIncrementation

            # Incrémentation compteur colonnes, boucle sur les colonnes
            TraiterImageBoucleColonnesIncrementation:
            addi $t1 $t1 1
            j TraiterImageBoucleColonnes

        TraiterImageBoucleColonnesFin:
        # Incrémentation compteur lignes, boucle sur les lignes
        addi $t0 $t0 1
        j TraiterImageBoucleLignes
    TraiterImageBoucleLignesFin:

    move $v0 $s1

# Epilogue
    lw $ra 0($sp)
    lw $a0 4($sp)
    lw $a1 8($sp)
    lw $a2 12($sp)
    lw $s0 16($sp)
    lw $s1 20($sp)
    lw $s2 24($sp)
    lw $s3 28($sp)
    lw $s4 32($sp)
    lw $s6 36($sp)
    lw $s7 40($sp)
    addiu $sp $sp 44
    jr $ra
#}}}
###############################################################################

###############################################################################
# CopieVoisinage {{{
# Paramètres :
# a0 : Adresse coin gauche
# a1 : Buffer 3x3
# a2 : Nombre de colonnes de l'image
#
# Retour :
# v0 : Buffer

CopieVoisinage:
# Prologue
    subiu $sp $sp 48
    sw $ra 0($sp)
    sw $a0 4($sp)
    sw $a1 8($sp)
    sw $a2 12($sp)
    sw $a3 16($sp)
    sw $s0 20($sp)
    sw $s1 24($sp)
    sw $s2 28($sp)
    sw $s3 32($sp)
    sw $s4 36($sp)
    sw $s5 40($sp)
    sw $s6 44($sp)

# Corps
    li $s0 3            # Limite
    li $s1 0            # s1 : Compteur lignes
    li $s2 0            # s2 : Compteur colonnes
    move $s3 $a1        # Adresse buffer
    CopieVoisinageBoucleLignes:
    beq $s1 $s0 CopieVoisinageFinBoucleLignes
        li $s2 0
        CopieVoisinageBoucleColonnes:
        beq $s2 $s0 CopieVoisinageFinBoucleColonnes
            # Adresse du pixel =
            # adresse coin + ligne courante * colonnes + colonne courante 
            mul $s4 $s1 $a2
            add $s4 $s4 $s2
            add $s4 $a0 $s4
            lb $s4 0($s4)
            sb $s4 0($s3)

            addi $s2 $s2 1
            addi $s3 $s3 1      # buffer++
            j CopieVoisinageBoucleColonnes
        CopieVoisinageFinBoucleColonnes:
        addi $s1 $s1 1
        j CopieVoisinageBoucleLignes
    CopieVoisinageFinBoucleLignes:
    move $v0 $a1
# Epilogue
    lw $ra 0($sp)
    lw $a0 4($sp)
    lw $a1 8($sp)
    lw $a2 12($sp)
    lw $a3 16($sp)
    lw $s0 20($sp)
    lw $s1 24($sp)
    lw $s2 28($sp)
    lw $s3 32($sp)
    lw $s4 36($sp)
    lw $s5 40($sp)
    lw $s6 44($sp)
    addiu $sp $sp 48
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

# vim:ft=asm:fdm=marker:ff=unix:foldopen=all:foldclose=all:colorcolumn=72,80
