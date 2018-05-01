@
@ Implementation by Ronny Van Keer, hereby denoted as "the implementer".
@
@ For more information, feedback or questions, please refer to our website:
@ https://keccak.team/
@
@ To the extent possible under law, the implementer has waived all copyright
@ and related or neighboring rights to the source code in this file.
@ http://creativecommons.org/publicdomain/zero/1.0/
@
@ ---
@
@ This file implements Keccak-p[1600]×2 in a PlSnP-compatible way.
@ Please refer to PlSnP-documentation.h for more details.
@
@ This implementation comes with KeccakP-1600-times2-SnP.h in the same folder.
@ Please refer to LowLevel.build for the exact list of other files it must be combined with.
@

@ WARNING: These functions work only on little endian CPU with@ ARMv7A + NEON architecture
@ WARNING: State must be 256 bit (32 bytes) aligned, best is 64-byte (cache alignment).

@ INFO: Tested on Cortex-A8 (BeagleBone Black), using gcc.
@ INFO: Parallel execution of Keccak-P permutation on 2 lane interleaved states.

@ INFO: KeccakP1600times2_PermuteAll_12rounds() execution time is 7690 cycles on a Cortex-A8 (BeagleBone Black)



.text

@----------------------------------------------------------------------------

@ --- offsets in state
.equ _ba    , 0*16
.equ _be    , 1*16
.equ _bi    , 2*16
.equ _bo    , 3*16
.equ _bu    , 4*16
.equ _ga    , 5*16
.equ _ge    , 6*16
.equ _gi    , 7*16
.equ _go    , 8*16
.equ _gu    , 9*16
.equ _ka    , 10*16
.equ _ke    , 11*16
.equ _ki    , 12*16
.equ _ko    , 13*16
.equ _ku    , 14*16
.equ _ma    , 15*16
.equ _me    , 16*16
.equ _mi    , 17*16
.equ _mo    , 18*16
.equ _mu    , 19*16
.equ _sa    , 20*16
.equ _se    , 21*16
.equ _si    , 22*16
.equ _so    , 23*16
.equ _su    , 24*16

@ --- macros for Parallel permutation

.macro    m_pls     start
    .if \start  != -1
    add         r3, r0, #\start
    .endif
    .endm

.macro    m_ld      qreg, next
    .if \next == 16
    vld1.64     { \qreg }, [r3:128]!
    .else
    vld1.64     { \qreg }, [r3:128], r4
    .endif
    .endm

.macro    m_st      qreg, next
    .if \next == 16
    vst1.64     { \qreg }, [r3:128]!
    .else
    vst1.64     { \qreg }, [r3:128], r4
    .endif
    .endm

.macro    KeccakP_ThetaRhoPiChiIota ofs1, ofs2, ofs3, ofs4, ofs5, next, ofsn1

    @ De = Ca ^ ROL64(Ci, 1)
    @ Di = Ce ^ ROL64(Co, 1)
    @ Do = Ci ^ ROL64(Cu, 1)
    @ Du = Co ^ ROL64(Ca, 1)
    @ Da = Cu ^ ROL64(Ce, 1)
    vadd.u64    q6, q2,  q2
    vadd.u64    q7, q3,  q3
    vadd.u64    q8, q4,  q4
    vadd.u64    q9, q0,  q0
    vadd.u64    q5, q1,  q1

    vsri.64     q6, q2, #63
    vsri.64     q7, q3, #63
    vsri.64     q8, q4, #63
    vsri.64     q9, q0, #63
    vsri.64     q5, q1, #63

    veor.64     q6, q6,  q0
    veor.64     q7, q7,  q1
    veor.64     q8, q8,  q2
    .if  \next != 16
    mov     r4, #\next
    .endif
    veor.64     q9, q9,  q3
    veor.64     q5, q5,  q4

    @ Ba = argA1^Da
    @ Be = ROL64(argA2^De, 44)
    @ Bi = ROL64(argA3^Di, 43)
    @ Bo = ROL64(argA4^Do, 21)
    @ Bu = ROL64(argA5^Du, 14)
    m_ld    q10, \next
    m_pls   \ofs2
    m_ld    q1, \next
    m_pls   \ofs3
    veor.64 q10,    q10,    q5
    m_ld    q2, \next
    m_pls   \ofs4
    veor.64 q1, q1, q6
    m_ld    q3, \next
    m_pls   \ofs5
    veor.64 q2, q2, q7
    m_ld    q4, \next
    veor.64 q3, q3, q8
    mov     r6, r5
    veor.64 q4, q4, q9

    vst1.64 { q6 }, [r6:128]!
    vshl.u64    q11,    q1, #44
    vshl.u64    q12,    q2, #43
    vst1.64 { q7 }, [r6:128]!
    vshl.u64    q13,    q3, #21
    vshl.u64    q14,    q4, #14
    vst1.64 { q8 }, [r6:128]!
    vsri.64 q11,    q1, #64-44
    vsri.64 q12,    q2, #64-43
    vst1.64 { q9 }, [r6:128]!
    vsri.64 q13,    q3, #64-21
    vsri.64 q14,    q4, #64-14

    @ argA1 = Ba ^(~Be & Bi) ^ KeccakP1600RoundConstants[round]
    @ argA2 = Be ^(~Bi & Bo)
    @ argA3 = Bi ^(~Bo & Bu)
    @ argA4 = Bo ^(~Bu & Ba)
    @ argA5 = Bu ^(~Ba & Be)
    vld1.64     { d30 },    [r1:64]
    vbic.64     q0, q12,    q11
    vbic.64     q1, q13,    q12
    vld1.64     { d31 },    [r1:64]!
    veor.64     q0, q10
    vbic.64     q4, q11,    q10
    veor.64     q0, q15
    vbic.64     q2, q14,    q13
    vbic.64     q3, q10,    q14

    m_pls   \ofs1
    veor.64 q1, q11
    m_st    q0, \next
    m_pls   \ofs2
    veor.64 q2, q12
    m_st    q1, \next
    m_pls   \ofs3
    veor.64 q3, q13
    m_st    q2, \next
    m_pls   \ofs4
    veor.64 q4, q14
    m_st    q3, \next
    m_pls   \ofs5
    m_st    q4, \next
    m_pls   \ofsn1
    .endm

.macro    KeccakP_ThetaRhoPiChi  ofs1, ofs2, ofs3, ofs4, ofs5, next, ofsn1, Bb1, Bb2, Bb3, Bb4, Bb5, Rr1, Rr2, Rr3, Rr4, Rr5

    @ Bb1 = ROL64((argA1^Da), Rr1)
    @ Bb2 = ROL64((argA2^De), Rr2)
    @ Bb3 = ROL64((argA3^Di), Rr3)
    @ Bb4 = ROL64((argA4^Do), Rr4)
    @ Bb5 = ROL64((argA5^Du), Rr5)

    .if  \next != 16
    mov     r4, #\next
    .endif

    m_ld    \Bb1, \next
    m_pls   \ofs2
    m_ld    \Bb2, \next
    m_pls   \ofs3
    veor.64 q15,   q5,  \Bb1
    m_ld    \Bb3, \next
    m_pls   \ofs4
    veor.64 q6,  q6,  \Bb2
    m_ld    \Bb4, \next
    m_pls   \ofs5
    veor.64 q7,  q7,  \Bb3
    m_ld    \Bb5, \next
    veor.64 q8,  q8,  \Bb4
    veor.64 q9,  q9,  \Bb5

    vshl.u64    \Bb1,  q15,   #\Rr1
    vshl.u64    \Bb2,  q6,  #\Rr2
    vshl.u64    \Bb3,  q7,  #\Rr3
    vshl.u64    \Bb4,  q8,  #\Rr4
    vshl.u64    \Bb5,  q9,  #\Rr5

    vsri.64 \Bb1,  q15,   #64-\Rr1
    vsri.64 \Bb2,  q6,  #64-\Rr2
    vsri.64 \Bb3,  q7,  #64-\Rr3
    vsri.64 \Bb4,  q8,  #64-\Rr4
    vsri.64 \Bb5,  q9,  #64-\Rr5

    @ argA1 = Ba ^((~Be)&  Bi ), Ca ^= argA1
    @ argA2 = Be ^((~Bi)&  Bo ), Ce ^= argA2
    @ argA3 = Bi ^((~Bo)&  Bu ), Ci ^= argA3
    @ argA4 = Bo ^((~Bu)&  Ba ), Co ^= argA4
    @ argA5 = Bu ^((~Ba)&  Be ), Cu ^= argA5
    vbic.64 q15,    q12,  q11
    mov     r6, r5
    vbic.64 q6,   q13,  q12
    m_pls   \ofs1
    vbic.64 q7,   q14,  q13
    vbic.64 q8,   q10,  q14
    vbic.64 q9,   q11,  q10

    veor.64 q15,    q15,    q10
    veor.64 q6,   q6,   q11

    m_st    q15, \next
    m_pls   \ofs2
    veor.64 q7,   q7,   q12

    m_st    q6, \next
    m_pls   \ofs3
    veor.64 q1,   q1,  q6
    vld1.64 { q6 }, [r6:128]!
    veor.64 q8,   q8,   q13

    m_st    q7, \next
    m_pls   \ofs4
    veor.64 q2,   q2,  q7
    vld1.64 { q7 }, [r6:128]!
    veor.64 q9,   q9,   q14

    m_st    q8,  \next
    m_pls   \ofs5
    veor.64 q3,  q3,  q8

    m_st    q9,  \next

    vld1.64 { q8 }, [r6:128]!
    veor.64 q4,  q4,  q9
    m_pls   \ofsn1
    vld1.64 { q9 }, [r6:128]!
    veor.64 q0,  q0,  q15
    .endm

.macro    KeccakP_ThetaRhoPiChi1 ofs1, ofs2, ofs3, ofs4, ofs5, next, ofsn1
    KeccakP_ThetaRhoPiChi  \ofs1, \ofs2, \ofs3, \ofs4, \ofs5, \next, \ofsn1, q12, q13, q14, q10, q11,  3, 45, 61, 28, 20
    .endm

.macro    KeccakP_ThetaRhoPiChi2 ofs1, ofs2, ofs3, ofs4, ofs5, next, ofsn1
    KeccakP_ThetaRhoPiChi  \ofs1, \ofs2, \ofs3, \ofs4, \ofs5, \next, \ofsn1, q14, q10, q11, q12, q13, 18,  1,  6, 25,  8
    .endm

.macro    KeccakP_ThetaRhoPiChi3 ofs1, ofs2, ofs3, ofs4, ofs5, next, ofsn1
    KeccakP_ThetaRhoPiChi  \ofs1, \ofs2, \ofs3, \ofs4, \ofs5, \next, \ofsn1, q11, q12, q13, q14, q10, 36, 10, 15, 56, 27
    .endm

.macro    KeccakP_ThetaRhoPiChi4 ofs1, ofs2, ofs3, ofs4, ofs5, next, ofsn1

    @ Bo = ROL64((argA1^Da), 41)
    @ Bu = ROL64((argA2^De), 2)
    @ Ba = ROL64((argA3^Di), 62)
    @ Be = ROL64((argA4^Do), 55)
    @ Bi = ROL64((argA5^Du), 39)
    @ KeccakChi

    .if  \next != 16
    mov     r4, #\next
    .endif

    m_ld    q13, \next
    m_pls   \ofs2
    m_ld    q14, \next
    m_pls   \ofs3
    veor.64 q5,  q5,  q13
    m_ld    q10, \next
    m_pls   \ofs4
    veor.64 q6,  q6,  q14
    m_ld    q11, \next
    m_pls   \ofs5
    veor.64 q7,  q7,  q10
    m_ld    q12, \next
    veor.64 q8,  q8,  q11
    veor.64 q9,  q9,  q12

    vshl.u64    q13,  q5,  #41
    vshl.u64    q14,  q6,  #2
    vshl.u64    q10,  q7,  #62
    vshl.u64    q11,  q8,  #55
    vshl.u64    q12,  q9,  #39

    vsri.64 q13,  q5,  #64-41
    vsri.64 q14,  q6,  #64-2
    vsri.64 q11,  q8,  #64-55
    vsri.64 q12,  q9,  #64-39
    vsri.64 q10,  q7,  #64-62

    vbic.64 q5,   q12,  q11
    vbic.64 q6,   q13,  q12
    vbic.64 q7,   q14,  q13
    vbic.64 q8,   q10,  q14
    vbic.64 q9,   q11,  q10
    veor.64 q5,   q5,  q10
    veor.64 q6,   q6,  q11
    veor.64 q7,   q7,  q12
    veor.64 q8,   q8,  q13
    m_pls   \ofs1
    veor.64 q9,   q9,  q14
    m_st    q5,  \next
    m_pls   \ofs2
    veor.64 q0,   q0,  q5
    m_st    q6,  \next
    m_pls   \ofs3
    veor.64 q1,   q1,  q6
    m_st    q7,  \next
    m_pls   \ofs4
    veor.64 q2,   q2,  q7
    m_st    q8,  \next
    m_pls   \ofs5
    veor.64 q3,   q3,  q8
    m_st    q9,  \next
    m_pls   \ofsn1
    veor.64 q4,   q4,  q9
    .endm


.macro  KeccakRound
    KeccakP_ThetaRhoPiChiIota  _ba,  -1,  -1,  -1,  -1, _ge-_ba, _ka @ _ba, _ge, _ki, _mo, _su
    KeccakP_ThetaRhoPiChi1     _ka,  -1,  -1,  _bo, -1, _me-_ka, _sa @ _ka, _me, _si, _bo, _gu
    KeccakP_ThetaRhoPiChi2     _sa, _be,  -1,  -1,  -1, _gi-_be, _ga @ _sa, _be, _gi, _ko, _mu
    KeccakP_ThetaRhoPiChi3     _ga,  -1,  -1,  -1, _bu, _ke-_ga, _ma @ _ga, _ke, _mi, _so, _bu
    KeccakP_ThetaRhoPiChi4     _ma,  -1, _bi,  -1,  -1, _se-_ma, _ba @ _ma, _se, _bi, _go, _ku

    KeccakP_ThetaRhoPiChiIota  _ba,  -1, _gi,  -1, _ku, _me-_ba, _sa @ _ba, _me, _gi, _so, _ku
    KeccakP_ThetaRhoPiChi1     _sa, _ke, _bi,  -1, _gu, _mo-_bi, _ma @ _sa, _ke, _bi, _mo, _gu
    KeccakP_ThetaRhoPiChi2     _ma, _ge,  -1, _ko, _bu, _si-_ge, _ka @ _ma, _ge, _si, _ko, _bu
    KeccakP_ThetaRhoPiChi3     _ka, _be,  -1, _go,  -1, _mi-_be, _ga @ _ka, _be, _mi, _go, _su
    KeccakP_ThetaRhoPiChi4     _ga,  -1, _ki, _bo,  -1, _se-_ga, _ba @ _ga, _se, _ki, _bo, _mu

    KeccakP_ThetaRhoPiChiIota  _ba,  -1,  -1, _go,  -1, _ke-_ba, _ma @ _ba, _ke, _si, _go, _mu
    KeccakP_ThetaRhoPiChi1     _ma, _be,  -1,  -1, _gu, _ki-_be, _ga @ _ma, _be, _ki, _so, _gu
    KeccakP_ThetaRhoPiChi2     _ga,  -1, _bi,  -1,  -1, _me-_ga, _sa @ _ga, _me, _bi, _ko, _su
    KeccakP_ThetaRhoPiChi3     _sa, _ge,  -1, _bo,  -1, _mi-_ge, _ka @ _sa, _ge, _mi, _bo, _ku
    KeccakP_ThetaRhoPiChi4     _ka,  -1, _gi,  -1, _bu, _se-_ka, _ba @ _ka, _se, _gi, _mo, _bu

    KeccakP_ThetaRhoPiChiIota  _ba,  -1,  -1,  -1,  -1, _be-_ba, _ga @ _ba, _be, _bi, _bo, _bu
    KeccakP_ThetaRhoPiChi1     _ga,  -1,  -1,  -1,  -1, _ge-_ga, _ka @ _ga, _ge, _gi, _go, _gu
    KeccakP_ThetaRhoPiChi2     _ka,  -1,  -1,  -1,  -1, _ke-_ka, _ma @ _ka, _ke, _ki, _ko, _ku
    KeccakP_ThetaRhoPiChi3     _ma,  -1,  -1,  -1,  -1, _me-_ma, _sa @ _ma, _me, _mi, _mo, _mu
    @ do we need to handle r2 here?
    KeccakP_ThetaRhoPiChi4     _sa,  -1,  -1,  -1,  -1, _se-_sa, _ba @ _sa, _se, _si, _so, _su
    .endm



@----------------------------------------------------------------------------
@
@ void KeccakF1600( void *states, void *constants )
@
.align 8
.global     KeccakF1600
.type   KeccakF1600, %function;
KeccakF1600:
    @ sp+4 is taken as the start of the state array
    @ sp+8 is taken as the start of the constants
    ldr     r0, [sp, #4]
    ldr     r1, [sp, #8]
    vpush   {q4-q7}
    push    {r4-r7}
    sub     sp, #4*2*8+8    @allocate 4 D double lanes (plus 8bytes to allow alignment on 16 bytes)
    mov     r3, r0
    add     r5, sp, #8

    @PrepareTheta
    @ Ca = ba ^ ga ^ ka ^ ma ^ sa
    @ Ce = be ^ ge ^ ke ^ me ^ se
    @ Ci = bi ^ gi ^ ki ^ mi ^ si
    @ Co = bo ^ go ^ ko ^ mo ^ so
    @ Cu = bu ^ gu ^ ku ^ mu ^ su
    vld1.64 { d0, d1, d2, d3 }, [r3:256]!   @ _ba _be
    bic     r5, #15
    vld1.64 { d4, d5, d6, d7 }, [r3:256]!   @ _bi _bo
    vld1.64 { d8, d9, d10, d11 }, [r3:256]! @ _bu _ga
    vld1.64 { d12, d13 }, [r3:128]! @ _ge
    veor.64 q0, q0, q5
    vld1.64 { d14, d15 }, [r3:128]! @ _gi
    veor.64 q1, q1, q6
    vld1.64 { d16, d17 }, [r3:128]! @ _go
    veor.64 q2, q2, q7
    vld1.64 { d18, d19 }, [r3:128]! @ _gu
    veor.64 q3, q3, q8
    vld1.64 { d10, d11 }, [r3:128]! @ _ka
    veor.64 q4, q4, q9
    vld1.64 { d12, d13 }, [r3:128]! @ _ke
    veor.64 q0, q0, q5
    vld1.64 { d14, d15 }, [r3:128]! @ _ki
    veor.64 q1, q1, q6
    vld1.64 { d16, d17 }, [r3:128]! @ _ko
    veor.64 q2, q2, q7
    vld1.64 { d18, d19 }, [r3:128]! @ _ku
    veor.64 q3, q3, q8
    vld1.64 { d10, d11 }, [r3:128]! @ _ma
    veor.64 q4, q4, q9
    vld1.64 { d12, d13 }, [r3:128]! @ _me
    veor.64 q0, q0, q5
    vld1.64 { d14, d15 }, [r3:128]! @ _mi
    veor.64 q1, q1, q6
    vld1.64 { d16, d17 }, [r3:128]! @ _mo
    veor.64 q2, q2, q7
    vld1.64 { d18, d19 }, [r3:128]! @ _mu
    veor.64 q3, q3, q8
    vld1.64 { d10, d11 }, [r3:128]! @ _sa
    veor.64 q4, q4, q9
    vld1.64 { d12, d13 }, [r3:128]! @ _se
    veor.64 q0, q0, q5
    vld1.64 { d14, d15 }, [r3:128]! @ _si
    veor.64 q1, q1, q6
    vld1.64 { d16, d17 }, [r3:128]! @ _so
    veor.64 q2, q2, q7
    vld1.64 { d18, d19 }, [r3:128]! @ _su
    mov     r3, r0
    veor.64 q3, q3, q8
    veor.64 q4, q4, q9

    KeccakRound
    KeccakRound
    KeccakRound
    KeccakRound
    KeccakRound
    KeccakRound


    add     sp, #4*2*8+8    @ free 4.5 D lanes
    pop     {r4-r7}
    vpop    {q4-q7}
    bx      lr

