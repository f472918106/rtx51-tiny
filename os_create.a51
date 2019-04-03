;------------------------------------------------------------------------------
;  This file is part of the RTX-51 TINY Real-Time Operating System Package
;  Copyright KEIL ELEKTRONIK GmbH and Keil Software, Inc.  1991 - 2002
;------------------------------------------------------------------------------
;
;  OS_CREATE.A51:  This module contains the OS_CREATE_TASK function call.
;
;  RTX51 TINY VERSION 2
;
;------------------------------------------------------------------------------

NAME	?RTX51_TINY_OS_CREATE

$include (os_defines.inc)

PUBLIC	_os_create_task


?RTX?CODE	SEGMENT	CODE
		RSEG	?RTX?CODE
		USING	0		; Registerbank 0 for following code


;  uchar os_create_task (uchar no)  {
;    uchar i;
;    uchar p1, p2;
;---- Variable 'p1'  assigned to Register 'R1' ----
;---- Variable 'p2'  assigned to Register 'R5' ----
;---- Variable 'no'  assigned to Register 'R7' ----
;---- Variable 'i'   assigned to Register 'R6' ----
;
; Returns 0xFF if the task number is too large
;         0xFF if the task is already active
;         0x00 if the task was inserted into the task list
;
;
;    if (no > MAXTASKN)  return (0xff);
_os_create_task:
		MOV     A,R7
		SETB    C
		SUBB    A,#?RTX_MAXTASKN
		JC      ?C0010
?C0012_:	MOV     R7,#0FFH
		RET     
?C0010:
;    if (STATE[no].st & K_ACTIVE)  return (0xff);
		MOV	A,#?RTX?TASKSTATE?S+1
		ADD	A,R7
		ADD	A,R7
		MOV     R0,A
		MOV     A,@R0
		JB      ACC.B_ACTIVE,?C0012_

;    STATE[no].st |= K_ACTIVE + K_READY;
		CLR	EA
		MOV	A,@R0
		ORL	A,#K_ACTIVE+K_READY
		MOV     @R0,A
		SETB	EA
;
;    i = current;
		MOV	R6,?RTX_CURRENTTASK

?C0013_:
;    while (i < no)  {
		MOV     A,R6
		CLR	C
		SUBB    A,R7
		JNC     ?C0014
;      i++;
		INC	R6

;      p1 = STKP[i];
		MOV     A,#?RTX?TASKSP?S
		ADD     A,R6
		MOV     R0,A
		MOV     A,@R0
		MOV     R1,A

;      p2 = i == MAXTASKN ? RAMTOP : STKP[i+1];
		INC	R0
		MOV	A,@R0
		DEC	R0
		CJNE    R6,#?RTX_MAXTASKN,?C0015_
		MOV	A,#?RTX_RAMTOP
?C0015_:
		MOV	R5,A

?C0017:
                MOV     A,R5
                XRL     A,R1
                JZ      ?C0018
;      while (p1 != p2)  {
;        p1++;
;        DBYTE[p1-2] = DBYTE[p1];
;      }
		INC	R1
		MOV     A,@R1
		DEC	R1
		DEC	R1
$IF (CODE_BANKING)
		DEC	R1
$ENDIF
		MOV	@R1,A
$IF (CODE_BANKING)
		INC	R1
$ENDIF
		INC	R1
		INC	R1
		SJMP	?C0017
?C0018:
;      STKP[i] -= 2;
$IF (CODE_BANKING)
		DEC	@R0
$ENDIF
		DEC     @R0
		DEC     @R0
;    }    
		SJMP    ?C0013_
?C0014:
;    if (i > no)  SP += 2;
		MOV     A,R6
		SETB    C
		SUBB    A,R7
		JC      ?C0020
$IF (CODE_BANKING)
		INC	SP
$ENDIF
		INC     SP
		INC     SP
?C0020:
;    while (i > no)  {
		MOV     A,R6
		SETB    C
		SUBB    A,R7
		JC      ?C0021
;      p1 = i == current ? SP : STKP[i+1];
		MOV     A,#?RTX?TASKSP?S
		ADD     A,R6
		MOV     R0,A
		INC	R0
		MOV     A,@R0
		MOV     R1,A
		MOV     A,R6
		CJNE    A,?RTX_CURRENTTASK,?C0022
		MOV	R1,SP
?C0022:
;      STKP[i] += 2;
		DEC	R0
		INC	@R0
		INC	@R0
$IF (CODE_BANKING)
		INC	@R0
$ENDIF
;      p2 = STKP[i];
		MOV	A,@R0
		MOV	R5,A
?C0024:
;      while (p1 != p2)  {
		MOV     A,R5
		XRL     A,R1
		JZ      ?C0025
;        DBYTE[p1] = DBYTE[p1-2];
		DEC	R1
		DEC	R1
$IF (CODE_BANKING)
		DEC	R1
$ENDIF
		MOV	A,@R1
$IF (CODE_BANKING)
		INC	R1
$ENDIF
		INC	R1
		INC	R1
		MOV	@R1,A
;        p1--;
		DEC	R1
;      }
		SJMP    ?C0024
?C0025:
;      i--;
		DEC	R6
;    }
		SJMP	?C0020

?C0021:
;
;    DWORD[STKP[no]] = ENTRY[no];
;
; Copy the entry point address of a task onto the stack.
;
		MOV	A,R7
		ADD     A,#?RTX?TASKSP?S
		MOV	R0,A
		MOV	A,@R0
		INC	A
		MOV	R0,A
		MOV	A,R7
		ADD	A,R7
		INC	A
		MOV	DPTR,#?RTX?TASKENT?S
		MOVC	A,@A+DPTR
		MOV	@R0,A
		INC	R0
		MOV	A,R7
		ADD	A,R7
		MOVC	A,@A+DPTR
		MOV	@R0,A
;    return (0);
		MOV	R7,#0
$IF (CODE_BANKING)
EXTRN	DATA	(?B_CURRENTBANK)
		INC	R0
		MOV	A,?B_CURRENTBANK     ; Set the initial code bank
		MOV	@R0,A
$ENDIF
;  }
		RET

		END
