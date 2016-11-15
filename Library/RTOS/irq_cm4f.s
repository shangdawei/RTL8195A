;/*
; * Copyright (c) 2013-2016 ARM Limited. All rights reserved.
; *
; * SPDX-License-Identifier: Apache-2.0
; *
; * Licensed under the Apache License, Version 2.0 (the License); you may
; * not use this file except in compliance with the License.
; * You may obtain a copy of the License at
; *
; * http://www.apache.org/licenses/LICENSE-2.0
; *
; * Unless required by applicable law or agreed to in writing, software
; * distributed under the License is distributed on an AS IS BASIS, WITHOUT
; * WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
; * See the License for the specific language governing permissions and
; * limitations under the License.
; *
; * -----------------------------------------------------------------------------
; *
; * Project:     CMSIS-RTOS RTX
; * Title:       Cortex-M4F Exception handlers
; *
; * -----------------------------------------------------------------------------
; */


I_T_RUN_OFS     EQU      28                     ; osInfo.thread.run offset
TCB_SP_OFS      EQU      56                     ; TCB.SP offset
TCB_SF_OFS      EQU      34                     ; TCB.stack_frame offset


                MODULE  ?irq_cm4


                SECTION .constdata:CONST:REORDER:NOROOT(2)
                PUBLIC   os_irq_cm
os_irq_cm       DCB      0                      ; Non weak library reference


                PUBLIC   SVC_Handler
                EXTERN   os_UserSVC_Table
                EXTERN   os_Info

                SECTION .text:CODE:REORDER:NOROOT(2)
                THUMB
SVC_Handler
                MRS      R0,PSP                 ; Get PSP
                LDR      R1,[R0,#24]            ; Load saved PC from stack
                LDRB     R1,[R1,#-2]            ; Load SVC number
                CBNZ     R1,SVC_User            ; Branch if not SVC 0

                PUSH     {R0,LR}                ; Save PSP and EXC_RETURN
                LDM      R0,{R0-R3,R12}         ; Load function parameters and address from stack
                BLX      R12                    ; Call service function
                POP      {R12,LR}               ; Restore PSP and EXC_RETURN
                STM      R12,{R0-R1}            ; Store function return values

SVC_Context
                LDR      R3,=os_Info+I_T_RUN_OFS; Load address of os_Info.run
                LDM      R3,{R1,R2}             ; Load os_Info.thread.run: curr & next
                CMP      R1,R2                  ; Check if thread switch is required
                BNE      SVC_Next               ;
                BX       LR                     ; Exit when threads are the same
SVC_Next
                CBNZ     R1,SVC_ContextSave     ; Branch if running thread is not deleted
                TST      LR,#0x10               ; Check if extended stack frame
                BNE      SVC_ContextSwitch
                LDR      R1,=0xE000EF34         ; FPCCR Address
                LDR      R0,[R1]                ; Load FPCCR
                BIC      R0, R0, #1             ; Clear LSPACT (Lazy state)
                STR      R0,[R1]                ; Store FPCCR
                B        SVC_ContextSwitch

SVC_ContextSave
                STMDB    R12!,{R4-R11}          ; Save R4..R11
                TST      LR,#0x10               ; Check if extended stack frame
                BNE      SVC_Skip
                VSTMDB   R12!,{S16-S31}         ;  Save VFP S16.S31
SVC_Skip
                STR      R12,[R1,#TCB_SP_OFS]   ; Store SP
                STRB     LR, [R1,#TCB_SF_OFS]   ; Store stack frame information

SVC_ContextSwitch
                STR      R2,[R3]                ; os_Info.thread.run: curr = next

SVC_ContextRestore
                LDRB     R1,[R2,#TCB_SF_OFS]    ; Load stack frame information
                LDR      R0,[R2,#TCB_SP_OFS]    ; Load SP
                ORR      LR,R1,#0xFFFFFF00      ; Set EXC_RETURN

                TST      LR,#0x10               ; Check if extended stack frame
                BNE      SVC_Skip2
                VLDMIA   R0!,{S16-S31}          ;  Restore VFP S16..S31
SVC_Skip2
                LDMIA    R0!,{R4-R11}           ; Restore R4..R11
                MSR      PSP,R0                 ; Set PSP

SVC_Exit
                BX       LR                     ; Exit from handler

SVC_User
                PUSH     {R4,LR}                ; Save registers
                LDR      R2,=os_UserSVC_Table   ; Load address of SVC table
                LDR      R3,[R2]                ; Load SVC maximum number
                CMP      R1,R3                  ; Check SVC number range
                BHI      SVC_Done               ; Branch if out of range

                LDR      R4,[R2,R1,LSL #2]      ; Load address of SVC function

                LDM      R0,{R0-R3}             ; Load function parameters from stack
                BLX      R4                     ; Call service function
                MRS      R4,PSP                 ; Get PSP
                STR      R0,[R4]                ; Store function return value

SVC_Done
                POP      {R4,PC}                ; Return from handler

                PUBLIC   PendSV_Handler
                EXTERN   os_PendSV_Handler

PendSV_Handler

                PUSH     {R4,LR}                ; Save EXC_RETURN
                BL       os_PendSV_Handler
                POP      {R4,LR}                ; Restore EXC_RETURN
                MRS      R12,PSP
                B        SVC_Context

                PUBLIC   SysTick_Handler
                EXTERN   os_Tick_Handler
SysTick_Handler
                PUSH     {R4,LR}                ; Save EXC_RETURN
                BL       os_Tick_Handler
                POP      {R4,LR}                ; Restore EXC_RETURN
                MRS      R12,PSP
                B        SVC_Context


                END
