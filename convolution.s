.data
    seuil:  .word   10
    Ft:     .word   3
    Fx:     .word   1, 0, -1, 2, 0, -2, 1, 0, -1
    Fy:     .word   1, 2, 1, 0, 0, 0, -1, -2, -1

.text

# Seuillage
Seuillage1:
    # Prologue
    subiu $sp $sp 8
    sw $ra 0($sp)
    sw $a0 4($sp)

    # Corps
    move $t0 $a0
    li $t1 255
    bge $t0 $t1 SupSeuil1
        move $v0 $t0
        j EpilogueSeuillage1
    SupSeuil1
        move $v0 $t1:
        j EpilogueSeuillage1

    EpilogueSeuillage1:

    # Epilogue
    lw $ra 0($sp)
    lw $a0 4($sp)
    addiu $sp $sp 8
    jr $ra
# Fin Seuillage

# Convolution
# a0 : taille des matrices
# a1 : matrice A
# a2 : matrice Fx ou Fy
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
    muli $t3 $t0 4      # Compteur en octets
    move $t4 $0         # V
    move $t5 $0
    move $t6 $0

    LoopConvolution:
    beq $t3 $t0 EndLoopConvolution
        addu $t1 $a1 $t3    # Adresse de A[$t0]
        addu $t2 $a2 $t3    # Adresse de F[$t0]
        lw $t5 0($t1)       # Chargement de A[$t0]
        lw $t6 O($t2)       # Chargement de F[$t0]
        mul $t5 $t5 $t6     # A[$t0] * F[$t0]
        add $t4 $t5         # $t4 += A[$t0] * F[$t0]
        addi $t0 $t0 1      # Incrémentation du compteur
        muli $t3 $t0 4      #
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
