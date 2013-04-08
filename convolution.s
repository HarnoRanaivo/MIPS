.data
    SEUIL:       .word   10                                     # Seuil
    FTAILLE:     .word   3                                      # Taille des matrices carrées Fx et Fy
    FX:          .word   1, 0, -1, 2, 0, -2, 1, 0, -1           # Fx utilisée dans la convolution de matrices
    FY:          .word   1, 2, 1, 0, 0, 0, -1, -2, -1           # Fy utilisée dans la convolution de matrices
    A:           .word   128, 3, 210, 5, 30, 78, 255, 0, 153

.text
    la $a0 A
    jal CalculG

    move $a0 $v0
    li $v0 1
    syscall

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
        lw $t5 0($t1)       # Chargement de A[$t0]
        lw $t6 0($t2)       # Chargement de F[$t0]
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

# vim:ft=asm:fdm=marker:ff=unix:foldopen=all:foldclose=all 
