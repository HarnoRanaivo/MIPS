###############################################################################
# MIPS : Maltraitons des Images Par Sobel
#
# Projet de l'UE « Architecture des Ordinateurs », L2S4, Université de
# Strasbourg.
# Implémentation du filtre de Sobel en assembleur MIPS.
#
# Auteurs :
# MEYER Jérémy <jeremy.meyer@etu.unistra.fr>
# RAZANAJATO Harenome <razanajato@etu.unistra.fr>
#
# Ce projet est libre. Vous pouvez le redistribuer ou le modifier selon les
# termes de la license « Do What The Fuck You Want To Public License »,
# Version 2, comme publiée par Sam Hocevar. Pour de plus amples informations,
# veuillez vous référer au fichier COPYING, ou bien http://www.wtfpl.net/
###############################################################################

# Section .data {{{
.data
    BUFFER:      .word   128                           # Taille des buffers
    SEUIL:       .word   254                           # Seuil.
    FTAILLE:     .word   3                             # Taille de Fx et Fy.

    # Matrices pour le filtre de Sobel.
    SX:          .byte   1, 0, -1, 2, 0, -2, 1, 0, -1
    SY:          .byte   1, 2, 1, 0, 0, 0, -1, -2, -1
    # Matrices pour le filtre de Prewitt.
    PX:          .byte   -1, 0, 1, -1, 0, 1, -1, 0, 1
    PY:          .byte   1, 1, 1, 0, 0, 0, -1, -1, -1
    # Matrices pour le filtre de Roberts.
    RX:          .byte   0, 0, 0, 0, 0, 1, 0, -1, 0
    RY:          .byte   0, 0, 0, 0, -1, 0, 0, 0, 1
    # Matrices pour le filtre de Kirsch.
    KX:          .byte   -3, -3, 5, -3, 0, 5, -3, -3, 5
    KY:          .byte   -3, -3, -3, -3, 0, -3, 5, 5, 5


    ERROPEN:    .asciiz "\nErreur lors de l'ouverture du fichier.\n"
    ERRREAD:    .asciiz "\nErreur lors de la lecture du fichier.\n"
    ERRFILTR:   .asciiz "\nErreur : Entrez un nombre compris entre 0 et 3.\n"
    DEMANDE:    .asciiz "\nVeuillez entrer le chemin du fichier à traiter :\n> "
    SERASAUV:   .asciiz "\nLe résultat sera sauvegardé dans le fichier :\n"
    QUELFILTR:  .asciiz "\nQuel filtre voulez-vous utiliser ?\n"
    FIL0:       .asciiz "0 : Filtre de Sobel\n"
    FIL1:       .asciiz "1 : Filtre de Prewitt\n"
    FIL2:       .asciiz "2 : Filtre de Roberts\n"
    FIL3:       .asciiz "3 : Filtre de Kirsch\n"
    PROMPT:     .asciiz "> "
#}}}

# Section .text {{{
.text
Main:
    # Demande du filtre à utiliser.
    jal ChoixFiltre
    move $s0 $v0

    bltz $v0 ErreurFiltre
        li $t0 4
    bge $s0 $t0 ErreurFiltre
        j Suite
    ErreurFiltre:
        la $a0 ERRFILTR
        jal Erreur
    j Suite

    Suite:
    # Demande du chemin du fichier.
    la $a0 DEMANDE
    jal AfficherString

    # Lecture du chemin du fichier.
    lw $a0 BUFFER
    jal Entree

    # Traitement du chemin du fichier (suppression de '\n' superflus).
    move $a0 $v0
    jal ChercheBSlashN

    # Lecture de l'image.
    move $a0 $v0
    li $a1 0
    jal LireImage

    # Sauvegarde de l'adresse du chemin du fichier.
    move $s1 $a0            # s1 : Chemin du fichier.

    # Traitement de l'image.
    move $a0 $v0
    move $a1 $v1
    move $a2 $s0
    jal TraiterImage

    # Sauvegarde du buffer de l'image.
    move $s2 $v0            # s2 : Buffer de l'image.

    # Affichage du nouveau chemin.
    la $a0 SERASAUV
    jal AfficherString

    # Nom du nouveau chemin.
    move $a0 $s1
    jal CherchePoint
    move $a0 $v0
    jal RajouteBMP
    jal AfficherString

    # Écriture du nouveau fichier.
    move $a1 $s2
    lwl $a2 5($a1)       # a2 : Taille totale du fichier (partie gauche).
    lwr $a2 2($a1)       # a2 : Taille totale du fichier (partie droite).
    jal EcrireFichier

Exit:
    li $v0 10
    syscall
#}}}

# Fonctions {{{

###############################################################################
# Valeur Absolue {{{
# Paramètres :
# a0 : Entier dont on veut la valeur absolue.
#
# Retour:
# v0 : Valeur absolue de a0.

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
# }}}
###############################################################################

###############################################################################
# SeuillageInf {{{
# Paramètres :
# a0 : Entier à seuiller.
# a1 : Seuil inférieur.
#
# Retour :
# v0 : a0 seuillé.
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
# }}}
###############################################################################

###############################################################################
# Convolution {{{
# Paramètres :
# a0 : Taille des matrices.
# a1 : Matrice A.
# a2 : Matrice Fx ou Fy.
#
# Retour :
# v0 : convolution de a1 par a2.

Convolution:
# Prologue
    subiu $sp $sp 16
    sw $ra 0($sp)
    sw $a0 4($sp)
    sw $a1 8($sp)
    sw $a2 12($sp)

# Corps
    # Initialisations
    move $t0 $0         # t0 : Compteur.
    move $t1 $a1        # t1 : Adresse de A.
    move $t2 $a2        # t2 : Adresse de F.
    move $t4 $0         # t4 : Résultat.
    move $t5 $0         # t5 : Sera utilisé pour A[$t0].
    move $t6 $0         # t6 : Sera utilisé pour F[$t0].
    mul $a0 $a0 $a0     # a0 : Taille²

    LoopConvolution:
    beq $t0 $a0 EndLoopConvolution
        addu $t1 $a1 $t0    # Adresse de A[$t0]
        addu $t2 $a2 $t0    # Adresse de F[$t0]
        lb $t5 0($t1)       # Chargement de A[$t0]
        lb $t6 0($t2)       # Chargement de F[$t0]
        mul $t5 $t5 $t6     # A[$t0] * F[$t0]
        add $t4 $t4 $t5     # $t4 += A[$t0] * F[$t0]
        # Incrémentation du compteur.
        addi $t0 $t0 1
        j LoopConvolution
    EndLoopConvolution:
    move $v0 $t4        # v0 : Résultat

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
    move $a2 $a1            # Attention, important : a2 <- a1 avant a1 <- a0.
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
    li $a2 0        # 0 : Ignorer le mode
    li $v0 13
    syscall

    # Erreur d'ouverture du fichier si v0 < 0.
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

    # Erreur de lecture du fichier si v0 < 0.
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
# v0 : Adresse du 1er buffer contenant l'image.
# v1 : Adresse du 2ème buffer contenant l'image.
#
# L'image est copiée deux fois en mémoire : le filtre nécessite l'image
# d'origine pour le calcul de chaque pixel, on doit écrire ailleurs.
# L'image est copiée dans sa totalité pour faciliter l'écriture.

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

    # 1ère Allocation de la mémoire pour l'image sur le tas
    move $a0 $s3        # Taille du buffer
    li $v0 9
    syscall
    move $s4 $v0        # s4 : Buffer pour l'image

    # 2ème Allocation de la mémoire pour l'image sur le tas
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

    # 1ère Lecture de l'image entière
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

    # 2ème Lecture de l'image entière
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
# a2 : Filtre à utiliser
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
    move $s0 $a2
    move $s1 $a1

    lwr $s2 10($a0)      # Offset des pixels
    lwr $s3 18($a0)      # Largeur en pixels
    lwr $s4 22($a0)      # Hauteur en pixels

    add $s5 $a0 $s2      # Adresse du premier pixel (Source)
    add $s6 $a1 $s2      # Adresse du premier pixel (Dest)

    # Buffer matrice 3x3
    li $a0 9            # Taille du buffer
    li $v0 9
    syscall
    move $s7 $v0        # s7 : Adresse du buffer

    # Initialisation boucle sur tous les pixels
    move $t0 $0           # t0 : Compteur lignes
    move $t1 $0           # t1 : Compteur colonnes
    # Ne pas oublier de sauvegarder/charger ces deux $ti à chaque
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
                # Sauvegarde des $ti importants avant appel de fonction
                subiu $sp $sp 8
                sw $t0 0($sp)
                sw $t1 4($sp)

                # Calcul de l'adresse du coin gauche de la matrice 3x3
                # (ligne - 1) * nombre colonnes + (colonne - 1)
                # t3 = t0 - 1
                # t4 = t1 - 1
                # t2 = t3 * s3 + t4
                subi $t3 $t0 1
                subi $t4 $t1 1
                mul $t2 $t3 $s3
                add $t2 $s5 $t2
                add $t2 $t2 $t4
                move $a0 $t2         # Adresse du coin gauche de la matrice 3x3
                move $a1 $s7         # Buffer 3x3
                move $a2 $s3         # Nombre de colonnes
                jal CopieVoisinage

                move $a0 $v0
                move $a1 $s0
                jal AppliquerFiltre

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
                sb $v0 0($t2)           # Copie résultat FiltreSobel

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
    li $s1 0            # s1 : Compteur lignes.
    li $s2 0            # s2 : Compteur colonnes.
    move $s3 $a1        # Adresse buffer.
    CopieVoisinageBoucleLignes:
    beq $s1 $s0 CopieVoisinageFinBoucleLignes
        li $s2 0
        CopieVoisinageBoucleColonnes:
        beq $s2 $s0 CopieVoisinageFinBoucleColonnes
            # Adresse du pixel =
            # adresse coin + ligne courante * colonnes + colonne courante 
            mul $s4 $s1 $a2
            add $s4 $s4 $s2
            add $s4 $a0 $s4     # s4 : Adresse du pixel courant.
            lb $s4 0($s4)       # s4 : Chargement du pixel.
            sb $s4 0($s3)       # Sauvegarde du pixel dans le buffer.
            # Incrémentations
            addi $s3 $s3 1      # Adresse du pixel suivant dans le buffer.
            addi $s2 $s2 1      # Incrémentation compteur colonnes.
            j CopieVoisinageBoucleColonnes
        CopieVoisinageFinBoucleColonnes:
        # Incrémentation compteur lignes
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

###############################################################################
# Entree {{{
# Paramètres :
# a0 : Taille buffer.
#
# Retour :
# v0 : Buffer de la chaîne de caratères.
Entree:
# Prologue
    subiu $sp $sp 8
    sw $a0 4($sp)
    sw $ra 0($sp)

# Corps
    # Allocation de a0 octets.
    li $v0 9
    syscall

    # Lecture d'une string de taille a0 au maximum.
    move $a1 $a0    # a1 : Taille du buffer.
    move $a0 $v0    # a0 : Adresse du buffer. 
    li $v0 8        # read string
    syscall
    move $v0 $a0

# Epilogue
    lw $a0 4($sp)
    lw $ra 0($sp)
    addiu $sp $sp 8
    jr $ra
#}}}
###############################################################################

###############################################################################
# ChercheBSlashN {{{
# Paramètres :
# a0 : Chaîne de caractères.
#
# Retour :
# v0 : Chaîne de caractères.
#
# Supprime les '\n' en trop dans une chaîne de caractères.

ChercheBSlashN:
# Prologue
    subiu $sp $sp 8
    sw $a0 4($sp)
    sw $ra 0($sp)

# Corps de la fonction
    move $t0 $a0
    li $t1 10       # t1 : Valeur ASCII de '\n'
    li $t2 0        # t2 : Valeur ASCII de '\0'
    LoopCherche:
        lb $t3 0($t0)
        beqz $t3 FinLoopCherche # Teste si $t3 = '\0'
        beq $t3 $t1 SupprimerChariot
            addi $t0 $t0 1      # Incrément $t0
            j LoopCherche
        SupprimerChariot:
            sb $t2 0($t0)
            j FinLoopCherche
    FinLoopCherche:
    move $v0 $a0

# Epilogue
    lw $a0 4($sp)
    lw $ra 0($sp)
    addiu $sp $sp 8
    jr $ra
#}}}
###############################################################################

###############################################################################
# CherchePoint {{{
# Paramètre :
# a0 : Chaîne de caractères.
#
# Retour :
# v0 : Chaîne de caractères.
#
# Remplace le .bmp par ".Contour" dans la chaîne a0.
CherchePoint:
#Prologue
    subiu $sp $sp 16
    sw $s0 12($sp)
    sw $a1 8($sp)
    sw $a0 4($sp)
    sw $ra 0($sp)

#Corps de la fonction
    move $s0 $a0    # s0 : Adresse de la chaîne.
    li $t1 46       # t1 : Valeur ASCII de '.'
    li $t2 67       # t2 : Valeur ASCII de 'C'
    li $t3 111      # t3 : Valeur ASCII de 'o'
    li $t4 110      # t4 : Valeur ASCII de 'n'
    li $t5 116      # t5 : Valeur ASCII de 't'
    li $t6 111      # t6 : Valeur ASCII de 'o'
    li $t7 117      # t7 : Valeur ASCII de 'u'
    li $t8 114      # t8 : Valeur ASCII de 'r'
    li $t9 46       # t9 : Valeur ASCII de '.'
    LoopCherchePoint:
        lb $t0 0($s0)
        beq $t0 $t1 RemplacePoint
            addiu $s0 $s0 1     # Incrément $s0
            j LoopCherchePoint
        RemplacePoint:
            sb $t2 0($s0)
            addiu $s0 $s0 1
            sb $t3 0($s0)
            addiu $s0 $s0 1
            sb $t4 0($s0)
            addiu $s0 $s0 1
            sb $t5 0($s0)
            addiu $s0 $s0 1
            sb $t6 0($s0)
            addiu $s0 $s0 1
            sb $t7 0($s0)
            addiu $s0 $s0 1
            sb $t8 0($s0)
            addiu $s0 $s0 1
            sb $t9 0($s0)
            j FinLoopCherchePoint
    FinLoopCherchePoint:
    move $v0 $a0

#Epilogue
    #lb $t9 0($a0)
    #move $v0 $t9
    lw $s0 12($sp)
    lw $a1 8($sp)
    lw $a0 4($sp)
    lw $ra 0($sp)
    addiu $sp $sp 16
    jr $ra
#}}}
###############################################################################

###############################################################################
# RajouteBMP {{{
# Paramètre :
# a0 : Chaîne de caractères.
#
# Retour :
# v0 : Chaîne de caractères.
#
# Rajoute ".bmp" à la fin de la chaîne de caractères.
RajouteBMP:
#Prologue
    subiu $sp $sp 16
    sw $s0 12($sp)
    sw $a1 8($sp)
    sw $a0 4($sp)
    sw $ra 0($sp)

#Corps de la fonction
    move $s0 $a0    # s0 : Adresse de la chaîne.
    li $t1 46       # t1 : Valeur ASCII de '.'
    li $t2 98       # t2 : Valeur ASCII de 'b'
    li $t3 109      # t3 : Valeur ASCII de 'm'
    li $t4 112      # t4 : Valeur ASCII de 'p'
    LoopCherchePointBIS:
        lb $t0 0($s0)
        beq $t0 $t1 ajoutBMP
            addiu $s0 $s0 1     # Incrément $s0
            j LoopCherchePointBIS
        ajoutBMP:
            sb $t1 0($s0)
            addiu $s0 $s0 1
            sb $t2 0($s0)
            addiu $s0 $s0 1
            sb $t3 0($s0)
            addiu $s0 $s0 1
            sb $t4 0($s0)
            j FinLoopCherchePointBMP
    FinLoopCherchePointBMP:
    move $v0 $a0

#Epilogue
    lw $s0 12($sp)
    lw $a1 8($sp)
    lw $a0 4($sp)
    lw $ra 0($sp)
    addiu $sp $sp 16
    jr $ra
#}}}
###############################################################################

###############################################################################
# ChoixFiltre {{{
# Paramètres :
# Aucun
#
# Retour :
# v0 : Numéro du filtre
# Choix du filtre

ChoixFiltre:
# Prologue
    subiu $sp $sp 8
    sw $ra 0($sp)
    sw $a0 4($sp)

# Corps
    la $a0 QUELFILTR
    jal AfficherString

    la $a0 FIL0
    jal AfficherString

    la $a0 FIL1
    jal AfficherString

    la $a0 FIL2
    jal AfficherString

    la $a0 FIL3
    jal AfficherString

    la $a0 PROMPT
    jal AfficherString

    li $v0 5
    syscall

# Epilogue
    lw $ra 0($sp)
    lw $a0 4($sp)
    addiu $sp $sp 8
    jr $ra
#}}}
###############################################################################

###############################################################################
# AppliquerFiltre {{{
# Paramètres
# a0 : Adresse du pixel et de son voisinage
# a1 : Numéro du filtre
#
# Retour :
# v0 : pixel
AppliquerFiltre:
# Prologue
    subiu $sp $sp 12
    sw $ra 0($sp)
    sw $a0 4($sp)
    sw $a1 8($sp)

# Corps
    li $t0 0
    li $t1 1
    li $t2 2
    li $t3 3
    beq $a1 $t0 AppliquerSobel
    beq $a1 $t1 AppliquerPrewitt
    beq $a1 $t2 AppliquerRoberts
    beq $a1 $t3 AppliquerKirsch
        j AppliquerFiltreFin
        AppliquerSobel:
            la $a1 SX
            la $a2 SY
            jal Filtre
            j AppliquerFiltreFin
        AppliquerPrewitt:
            la $a1 PX
            la $a2 PY
            jal Filtre
            j AppliquerFiltreFin
        AppliquerRoberts:
            la $a1 RX
            la $a2 RY
            jal Filtre
            j AppliquerFiltreFin
        AppliquerKirsch:
            la $a1 KX
            la $a2 KY
            jal Filtre
            j AppliquerFiltreFin

    AppliquerFiltreFin:

# Epilogue
    lw $ra 0($sp)
    lw $a0 4($sp)
    lw $a1 8($sp)
    addiu $sp $sp 12
    jr $ra
#}}}
###############################################################################

###############################################################################
# Filtre{{{
# Paramètres :
# a0 : Adresse du pixel et de ses pixels environnants
# a1 : Matrice 1
# a2 : Matrice 2
#
# Retour :
# v0 : G(a0)

Filtre:
# Prologue
    subiu $sp $sp 20
    sw $ra 0($sp)
    sw $a0 4($sp)
    sw $s0 8($sp)
    sw $s1 12($sp)
    sw $s2 16($sp)

# Corps
    move $s0 $a1
    move $s1 $a2
    # Calcul de Gx
    move $a1 $s0
    jal CalculGxy       # a0 n'a pas été modifié : a0 de l'appel
    move $s2 $v0        # s2 : retour de CalculGxy(a0, KX)

    # Calcul de Gy
    move $a1 $s1
    jal CalculGxy       # a0 n'a pas été modifié : a0 de l'appel

    # Gx + Gy et nouveau seuillage
    # Seuillage Inf non nécessaire :
    # Gx > SEUIL ou Gx = 0, idem pour Gy.
    # Donc Gx + Gy = 0 ou Gx + Gy > SEUIL
    add $s2 $s2 $v0     # s2 : CalculGxy(a0, KX) + CalculGxy(a0, KY)
    move $a0 $s2
    jal Seuillage255

    # v0 : Seuillage255(Gx + Gy)

# Epilogue
    lw $ra 0($sp)
    lw $a0 4($sp)
    lw $s0 8($sp)
    lw $s1 12($sp)
    lw $s2 16($sp)
    addiu $sp $sp 20
    jr $ra
# }}}
###############################################################################

#}}}

# Config spéciale pour vim {{{
# * 'za' pour ouvrir/fermer tous les replis.
# * `:set fdm=indent` ou `:set fdm=marker` pour changer le style de replis.
# * `:set colorcolumn=""` pour cacher les colonnes limites.
#
# vim: ft=asm:fdm=marker:ff=unix:foldopen=all:foldclose=all:colorcolumn=72,80
#}}}

