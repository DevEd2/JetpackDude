; ================================================================
; Jetpack Dude - a Game Boy game by DevEd
; ================================================================

; Debug flag
; If set to 1, enable debugging features.

DebugFlag	set	1

; ================================================================
; Project includes
; ================================================================

include	"Variables.asm"
include	"Constants.asm"
include	"Macros.asm"
include	"hardware.inc"

; ================================================================
; Reset vectors (actual ROM starts here)
; ================================================================

SECTION	"Reset $00",HOME[$00]
Reset00:	ret

SECTION	"Reset $08",HOME[$08]
Reset08:	ret

SECTION	"Reset $10",HOME[$10]
Reset10:	ret

SECTION	"Reset $18",HOME[$18]
Reset18:	ret

SECTION	"Reset $20",HOME[$20]
Reset20:	ret

SECTION	"Reset $28",HOME[$28]
Reset28:	ret

SECTION	"Reset $30",HOME[$30]
Reset30:	ret

SECTION	"Reset $38",HOME[$38]
Reset38:	jp	ErrorHandler

; ================================================================
; Interrupt vectors
; ================================================================

SECTION	"VBlank interrupt",HOME[$40]
IRQ_VBlank:
	call	DoVBlank
	reti

SECTION	"LCD STAT interrupt",HOME[$48]
IRQ_STAT:
	reti

SECTION	"Timer interrupt",HOME[$50]
IRQ_Timer:
	reti

SECTION	"Serial interrupt",HOME[$58]
IRQ_Serial:
	reti

SECTION	"Joypad interrupt",Home[$60]
IRQ_Joypad:
	reti
	
; ================================================================
; System routines
; ================================================================

include	"SystemRoutines.asm"

; ================================================================
; ROM header
; ================================================================

SECTION	"ROM header",HOME[$100]

EntryPoint:
	nop
	jp	ProgramStart

NintendoLogo:	; DO NOT MODIFY!!!
	db	$ce,$ed,$66,$66,$cc,$0d,$00,$0b,$03,$73,$00,$83,$00,$0c,$00,$0d
	db	$00,$08,$11,$1f,$88,$89,$00,$0e,$dc,$cc,$6e,$e6,$dd,$dd,$d9,$99
	db	$bb,$bb,$67,$63,$6e,$0e,$ec,$cc,$dd,$dc,$99,$9f,$bb,$b9,$33,$3e

ROMTitle:		db	"JETPACKDUDE"	; ROM title (11 bytes)
ProductCode:	db	"AJDE"			; Product code (4 bytes)
GBCSupport:		db	0				; GBC support (0 = DMG only, $80 = DMG/GBC, $C0 = GBC only)
NewLicenseCode:	dw	0				; new license code (2 bytes)
SGBSupport:		db	0				; SGB support
CartType:		db	$19				; Cart type, see hardware.inc for a list of values
ROMSize:		ds	1				; ROM size (handled by post-linking tool)
RAMSize:		db	0				; RAM size
DestCode:		db	1				; Destination code (0 = Japan, 1 = All others)
OldLicenseCode:	db	$33				; Old license code (if $33, check new license code)
ROMVersion:		db	0				; ROM version
HeaderChecksum:	ds	1				; Header checksum (handled by post-linking tool)
ROMChecksum:	ds	2				; ROM checksum (2 bytes) (handled by post-linking tool)
	
; ================================================================
; Start of program code
; ================================================================

ProgramStart:
	di						; disable interrupts
	push	af
	and	a					; same as cp 0
	jr	z,.dontCheckGBType	; if GBType check has already run, don't do it again

	ld	a,IEF_VBLANK
	ldh	[rIE],a				; set VBlank interrupt flag
	call	ClearWRAM
	ld	a,%11100100
	ldh	[rBGP],a
	
	ei
	call	PalFadeOut
	ld	a,%00000000
	ldh	[rBGP],a
	halt
	xor	a
	ld	[rLCDC],a			; disable LCD

	di
	
	call	ClearVRAM
	
	; clear HRAM
	ld	a,0
	ld	bc,$6060
.loop
	ld	[c],a
	inc	c
	
	dec	b
	jr	nz,.loop
	
	ld	a,%11100100
	ldh	[rBGP],a			; set background palette
	
	; Routine to check which Game Boy model we're running on
	pop	af
	ld	hl,GBType
	cp	$11					; check for GBC
	jr	z,.gbc				; if on GBC, jump
	cp	$FF					; check for GBP
	jr	z,.gbp				; if on GBP, jump
.dmg						; if not on GBC or GBP, assume DMG
;	call	TestSGB			; check for SGB (NYI)
;	jr	z,.sgb				; if on SGB, jump (NYI)
	xor	a					; GBType = 0 (DMG)
	jr	.setSystem
.gbp
;	call	TestSGB			; check for SGB2 (NYI)
;	jr	z,.sgb2				; if on SGB2, jump (NYI)
	ld	a,1					; GBType = 1 (GBP)
	jr	.setSystem
.gbc
	bit	0,b					; check for GBA
	ld	a,2					; GBType = 2 (GBC)
	jr	z,.setSystem		; if not on GBA, jump
	inc	a					; GBType = 3 (GBA)
.setSystem
	ld	[hl+],a
	ld	a,1
	ld	[hl],a
.dontCheckGBType
	
	call	CopyOAMDMARoutine
	
	if	DebugFlag==1
		xor	a			; set game mode to 0 (debug menu)
	else
		ld	a,GM_SplashScreen
	endc
		
	call	SetGameMode

;	call	InitPlayer
;	call	StartMusic

	ei					; enable interrupts

; ================================================================
; Main game loop
; ================================================================

MainLoop:
;	call	UpdateMusic
	ld	a,[GameMode]
	cp	7
	jr	c,.continue		; if current game mode is less than 7, jump
	jp	MainLoop_end
.continue
	add	a
	add	a,GameModeProcTable%256
	ld	l,a
	adc	a,GameModeProcTable/256
	sub	l
	ld	h,a
	ld	a,[hl+]
	ld	h,[hl]
	ld	l,a
	jp	[hl]			; jump to main program processing routine

MainLoop_end:	
	halt
	jp	MainLoop

; ================================================================
; Game mode initialization
; ================================================================

SetGameMode:
	ld	[GameMode],a	; store current game mode
	cp	7
	jr	c,.init			; if current game mode is less than 7, jump
	ret					; else, return

.init
	ld	a,[rLCDC]
	or	a
	jr	z,.continue
	xor	a
	ldh	[rLCDC],a
	
.continue
	call	ClearScreen

	ld	a,[GameMode]
	add	a
	add	a,GameModeInitTable%256
	ld	l,a
	adc	a,GameModeInitTable/256
	sub	l
	ld	h,a
	ld	a,[hl+]
	ld	h,[hl]
	ld	l,a
	jp	[hl]

GameModeInitTable:
	dw	InitDebugMenu
	dw	InitSplashScreen
	dw	InitTestScreen
	dw	InitSoundTest
	dw	InitTitleScreen
	dw	InitLevelSelect
	dw	InitOptionsMenu
	dw	InitPasswordMenu
	dw	InitLevel

InitDebugMenu:
	call	StopMusic
	xor	a
	ldh	[rSCY],a
	ldh	[rSCX],a
	ld	[CurrentMenuItem],a
	or	%11100100
	ldh	[rBGP],a	; set palette
	call	ClearScreen
	CopyTileset1BPP	Font,0,(Font_End-Font)/8
	ld	hl,DebugMenuText
	call	LoadMapText	
	jp	InitDone

InitSplashScreen:
	call	StopSound
	xor	a
	ldh	[rSCY],a
	ldh	[rSCX],a
	ldh	[rBGP],a	; clear palette
	ld	[FadeState],a
	call	ClearScreen
	CopyTileset	SplashScreenGFX,0,79
	ld	hl,SplashScreenTilemap
	call	LoadMap
	ld	a,$f0
	ld	[ScreenTimer],a
	ld	a,6
	ld	[FadeTimer],a
	jp	InitDone

InitTestScreen:
	call	StopSound
	ld	a,$70
	ldh	[rSCX],a
	ldh	[rSCY],a
	ld	a,%11100100
	ldh	[rBGP],a	; set palette
	call	ClearScreen
	ld	a,1
	ld	[rROMB0],a
	CopyTileset	TestTileset,0,30
	ld	hl,TestTilemap
	call	LoadMapFull
	call	ParTile_Init
	jp	InitDone

InitSoundTest:
	call	StopSound
	
	xor	a
	ldh	[rSCY],a
	ldh	[rSCX],a
	ld	[CurrentMenuItem],a
	or	%11100100
	ldh	[rBGP],a	; set palette
	call	ClearScreen
	CopyTileset1BPP	Font,0,97
	ld	hl,SoundTestTilemap
	call	LoadMapText
	jp	InitDone

InitTitleScreen:
	call	StopSound
	xor	a
	ldh	[rSCY],a
	ldh	[rSCX],a
	or	%11100100
	ldh	[rBGP],a	; set palette
	call	ClearScreen
	CopyTileset1BPP	Font,0,97
	ld	hl,TitleScreenTilemap
	call	LoadMapText
	jp	InitDone

InitLevelSelect:
	call	StopSound
	xor	a
	ldh	[rSCY],a
	ldh	[rSCX],a
	ld	[CurrentMenuItem],a
	or	%11100100
	ldh	[rBGP],a	; set palette
	call	ClearScreen
	CopyTileset1BPP	Font,0,97
	ld	hl,LevelSelectTilemap
	call	LoadMapText
	jp	InitDone
	
InitOptionsMenu:
	call	StopSound
	xor	a
	ldh	[rSCY],a
	ldh	[rSCX],a
	ld	[CurrentMenuItem],a
	or	%11100100
	ldh	[rBGP],a	; set palette
	call	ClearScreen
	CopyTileset1BPP	Font,0,97
	ld	hl,OptionsMenuTilemap
	call	LoadMapText
	jp	InitDone
	
InitPasswordMenu:
	call	StopSound
	xor	a
	ldh	[rSCY],a
	ldh	[rSCX],a
	or	%11100100
	ldh	[rBGP],a	; set palette
	call	ClearScreen
	CopyTileset1BPP	Font,0,97
	ld	hl,PasswordMenuTilemap
	call	LoadMapText
	jp	InitDone
	
InitLevel:
	call	StopSound
	xor	a
	ldh	[rSCY],a
	ldh	[rSCX],a
	or	%11100100
	ldh	[rBGP],a	; set palette
	call	ClearScreen
	CopyTileset1BPP	Font,0,97
	ld	hl,LevelErrorTilemap
	call	LoadMapText
	
InitDone:
	ld	a,%10010001
	ldh	[rLCDC],a
	ret
	
; ================================================================
; Game mode processing table
; ================================================================
	
GameModeProcTable:
	dw	ProcessDebugMenu
	dw	ProcessSplashScreen
	dw	ProcessTestScreen
	dw	ProcessSoundTest
	dw	ProcessTitleScreen
	dw	ProcessLevelSelect
	dw	ProcessOptionsMenu
	dw	ProcessPasswordMenu
	dw	ProcessLevel

; ================================================================
; Process debug menu
; ================================================================

ProcessDebugMenu:
	call	CheckInput
	ld	a,[sys_btnPress]
	bit	btnUp,a
	jp	nz,.prevItem
	bit	btnDown,a
	jp	nz,.nextItem
	bit	btnA,a
	jp	nz,.selectItem
	bit	btnB,a
	jp	nz,.exit
	bit	btnStart,a
	jp	nz,.selectItem
	bit	btnSelect,a
	jp	nz,.nextItem
	jp	.continue
	
.prevItem
	ld	a,[CurrentMenuItem]
	ld	[OldMenuItem],a
	or	a
	jr	z,.iszero
	dec	a
	jr	.setitem
.iszero
	ld	a,4
	jr	.setitem
.nextItem
	ld	a,[CurrentMenuItem]
	ld	[OldMenuItem],a
	cp	4
	jr	z,.ismax
	inc	a
	jr	.setitem
.ismax
	xor	a
.setitem
	ld	[CurrentMenuItem],a
	jr	.continue
.selectItem
	ld	a,[CurrentMenuItem]
	add	a,a
	add	a,DebugMenuItemList%256
	ld	l,a
	adc	a,DebugMenuItemList/256
	sub	l
	ld	h,a
	ld	a,[hl]
	inc	hl
	ld	h,[hl]
	ld	l,a
	call	.executeItem
	jr	.continue
.executeItem
	jp	[hl]
.exit
	; TODO
	
.continue
	ld	a,[GameMode]
	or	a
	jr	z,.debug
	jp	MainLoop_end
.debug
	ld	hl,$9880
	call	ClearCursor
	ld	hl,$9880
	call	DrawCursor
	ld	a,[DebugEnabled]
	ld	hl,$9912
	call	DrawCheckbox
	jp	MainLoop_end
	
DebugMenuItemList:
	dw	.startGame
	dw	.testScreen
	dw	.levelSelect
	dw	.soundTest
	dw	.toggleDebug
.startGame
	call	PalFadeOut
	ld	a,GM_SplashScreen
	call	SetGameMode
	ret
.testScreen
	ld	a,GM_TestScreen
	call	SetGameMode
	ret
.levelSelect
	call	PalFadeOut
	ld	a,GM_LevelSelect
	call	SetGameMode
	ret
.soundTest
	call	PalFadeOut
	ld	a,GM_SoundTest
	call	SetGameMode
	ret
.toggleDebug
	ld	a,[DebugEnabled]
	xor	1
	ld	[DebugEnabled],a
	ret

; ================================================================
; Process splash screen
; ================================================================

ProcessSplashScreen:
	call	PalFadeIn
	
Splash_Wait:
	halt
	call	CheckInput
	ld	a,[sys_btnPress]
	bit	btnStart,a
	jr	nz,.fadeOut
	ld	a,[ScreenTimer]
	dec	a
	ld	[ScreenTimer],a
	and	a
	jr	nz,Splash_Wait
.fadeOut
	call	PalFadeOut

.exit
	ld	a,GM_TitleScreen
	call	SetGameMode
.continue
	jp	MainLoop_end

; ================================================================
; Process test screen
; ================================================================

ProcessTestScreen:
	call	CheckInput
	ld	a,[sys_btnPress]
	bit	btnB,a
	jr	nz,.exit			; if user presses B, return to debug menu
	
; Update the ParallaxTile.
; For every two pixels the camera moves, shift the tile one pixel in the
; opposite direction. Note that this implmentation is pretty much hardcoded
; so it will only work if the camera moves two pixels per frame.
; TODO: Modify this so the camera can move at any arbitrary speed and it will
; still work properly.
	
	ld	a,rSCY-$ff00
	ld	c,a					; c = SCY
	
	ld	a,[sys_btnHold]
	bit	btnUp,a
	call	nz,.decSCY
	bit	btnDown,a
	call	nz,.incSCY
	inc	c					; c = SCX
	bit	btnLeft,a
	call	nz,.decSCX
	bit	btnRight,a
	call	nz,.incSCX
	jr	.continue
.decSCY
	ld	a,[c]
	sub	2
	ld	[c],a
	call	ParTile_ShiftUp		
	ld	a,[sys_btnHold]
	ret
.incSCY
	ld	a,[c]
	add	2
	ld	[c],a
	call	ParTile_ShiftDown
	ld	a,[sys_btnHold]
	ret
.decSCX
	ld	a,[c]
	sub	2
	ld	[c],a
	call	ParTile_ShiftLeft
	ld	a,[sys_btnHold]
	ret
.incSCX
	ld	a,[c]
	add	2
	ld	[c],a
	call	ParTile_ShiftRight
	ld	a,[sys_btnHold]
	ret
.exit
	ld	a,GM_DebugMenu
	call	SetGameMode
.continue
	jp	MainLoop_end
	
; ================================================================
; Process sound test menu
; ================================================================	
	
ProcessSoundTest:
	call	CheckInput
	ld	a,[sys_btnPress]
	bit	btnUp,a
	jp	nz,.prevItem
	bit	btnDown,a
	jp	nz,.nextItem
	bit	btnLeft,a
	jp	nz,.prevSound
	bit	btnRight,a
	jp	nz,.nextSound
	bit	btnA,a
	jp	nz,.selectItem
	bit	btnB,a
	jp	nz,.stopSound
	bit	btnStart,a
	jp	nz,.exit
	bit	btnSelect,a
	jp	nz,.nextItem
	jp	.continue
	
.prevItem
	ld	a,[CurrentMenuItem]
	ld	[OldMenuItem],a
	or	a
	jr	z,.iszero
	dec	a
	jr	.setitem
.iszero
	ld	a,2
	jr	.setitem
.nextItem
	ld	a,[CurrentMenuItem]
	ld	[OldMenuItem],a
	cp	2
	jr	z,.ismax
	inc	a
	jr	.setitem
.ismax
	xor	a
.setitem
	ld	[CurrentMenuItem],a
	jr	.continue
	
.nextSound
	ld	a,[CurrentMenuItem]
	and	a
	jr	z,.nextSong
	dec	a
	jr	z,.nextSFX
	dec	a
	jr	z,.continue
.nextSong
	ld	a,[SoundTestMusicID]
	inc	a
	ld	[SoundTestMusicID],a
	jr	.continue
.nextSFX
	ld	a,[SoundTestSFXID]
	inc	a
	ld	[SoundTestSFXID],a
	jr	.continue

.prevSound
	ld	a,[CurrentMenuItem]
	and	a
	jr	z,.prevSong
	dec	a
	jr	z,.prevSFX
	dec	a
	jr	z,.continue
.prevSong
	ld	a,[SoundTestMusicID]
	dec	a
	ld	[SoundTestMusicID],a
	jr	.continue
.prevSFX
	ld	a,[SoundTestSFXID]
	dec	a
	ld	[SoundTestSFXID],a
	jr	.continue

.selectItem
	ld	a,[CurrentMenuItem]
	add	a,a
	add	a,SoundTestItemList%256
	ld	l,a
	adc	a,SoundTestItemList/256
	sub	l
	ld	h,a
	ld	a,[hl]
	inc	hl
	ld	h,[hl]
	ld	l,a
	call	.executeItem
	jr	.continue
.stopSound
	call	StopSound
	jr	.continue
.executeItem
	jp	[hl]
.exit
	call	PalFadeOut
	ld	a,GM_DebugMenu
	call	SetGameMode
	
.continue
	ld	a,[GameMode]
	cp	GM_SoundTest
	jr	z,.isSoundTest
	jp	MainLoop_end
.isSoundTest
	ld	a,[SoundTestMusicID]
	ld	hl,$9849
	call	DrawHex
	ld	a,[SoundTestSFXID]
	ld	hl,$9869
	call	DrawHex
	
	ld	hl,$9840
	call	ClearCursor
	ld	hl,$9840
	call	DrawCursor
	
	call	PrintSongName
	call	PrintAuthorName

	jp	MainLoop_end
	
SoundTestItemList:
	dw	.playSong
	dw	.playSFX
	dw	.exit
.playSong
	ld	a,[SoundTestMusicID]
	call	PlaySong
	ret
.playSFX
	ld	a,[SoundTestSFXID]
	call	PlaySFX
	ret
.exit
	call	PalFadeOut
	ld	a,GM_DebugMenu
	call	SetGameMode
	ret

PrintSongName:
	ld	a,[SoundTestMusicID]
	add	a,a
	add	a,SongNameTable%256
	ld	l,a
	adc	a,SongNameTable/256
	sub	l
	ld	h,a
	ld	a,[hl]
	inc	hl
	ld	h,[hl]
	ld	l,a
	ld	de,$9900
	call	PrintLine
	ret
	
PrintAuthorName:
	ld	a,[SoundTestMusicID]
	add	a,a
	add	a,AuthorNameTable%256
	ld	l,a
	adc	a,AuthorNameTable/256
	sub	l
	ld	h,a
	ld	a,[hl]
	inc	hl
	ld	h,[hl]
	ld	l,a
	ld	de,$9920
	call	PrintLine
	ret

SongNameTable:
	dw	SongName_Introtune
	dw	SongName_MenuTheme
	dw	SongName_Fruitless
	dw	SongName_Soundcheck
	dw	SongName_Train
	dw	SongName_Oldschool
	dw	SongName_Fruitful
	dw	SongName_FishFiles
	dw	SongName_LoOp
	dw	SongName_20y
	dw	SongName_Gejmbaj
	dw	SongName_Oh
	dw	SongName_Pocket
	dw	SongName_Demotronic
	
SongName_Introtune:		db	"Introtune",0
SongName_MenuTheme:		db	"Menu theme",0
SongName_Fruitless:		db	"Fruitless",0
SongName_Soundcheck:	db	"Soundcheck",0
SongName_Train:			db	"Train",0
SongName_Oldschool:		db	"Oldschool",0
SongName_Fruitful:		db	"Fruitful",0
SongName_FishFiles:		db	"The Fish Files",0
SongName_LoOp:			db	"LoOp",0
SongName_20y:			db	"20y",0
SongName_Gejmbaj:		db	"Gejmbaj",0
SongName_Oh:			db	"Oh!",0
SongName_Pocket:		db	"Demo in Pocket?",0
SongName_Demotronic:	db	"Demotronic",0

AuthorNameTable:
	dw	AuthorName_DevEd
	dw	AuthorName_DevEd
	dw	AuthorName_Heatbeat
	dw	AuthorName_Heatbeat
	dw	AuthorName_Heatbeat
	dw	AuthorName_Heatbeat
	dw	AuthorName_Heatbeat
	dw	AuthorName_SimoneC
	dw	AuthorName_Piksi
	dw	AuthorName_Nordloef
	dw	AuthorName_Nordloef
	dw	AuthorName_Nordloef
	dw	AuthorName_Nordloef
	dw	AuthorName_Unknown
	
AuthorName_DevEd:		db	"Ed Whalen (DevEd)",0
AuthorName_Heatbeat:	db	"Aleksi Eeben",0
AuthorName_SimoneC:		db	"Simone Cicconi",0
AuthorName_Piksi:		db	"Piksi",0
AuthorName_Nordloef:	db	"Nordloef",0
AuthorName_Unknown:		db	"Unknown",0

; ================================================================
; Process title screen
; ================================================================

ProcessTitleScreen:
	call	CheckInput
	ld	a,[sys_btnPress]
	bit	btnB,a
	jr	nz,.exit
	jr	.continue
.exit
	ld	a,GM_DebugMenu
	call	SetGameMode
.continue
	jp	MainLoop_end

; ================================================================
; Process level select menu
; ================================================================	
	
ProcessLevelSelect:
	call	CheckInput
	ld	a,[sys_btnPress]
	bit	btnB,a
	jr	nz,.exit
	jr	.continue
.exit
	ld	a,GM_DebugMenu
	call	SetGameMode
.continue
	jp	MainLoop_end

; ================================================================
; Process options menu
; ================================================================

ProcessOptionsMenu:
	call	CheckInput
	ld	a,[sys_btnPress]
	bit	btnB,a
	jr	nz,.exit
	jr	.continue
.exit
	ld	a,GM_DebugMenu
	call	SetGameMode
.continue
	jp	MainLoop_end

; ================================================================
; Process password menu
; ================================================================

ProcessPasswordMenu:
	call	CheckInput
	ld	a,[sys_btnPress]
	bit	btnB,a
	jr	nz,.exit
	jr	.continue
.exit
	ld	a,GM_DebugMenu
	call	SetGameMode
.continue
	jp	MainLoop_end

; ================================================================
; Level processing
; ================================================================

ProcessLevel:
	call	CheckInput
	ld	a,[sys_btnPress]
	bit	btnB,a
	jr	nz,.exit
	jr	.continue
.exit
	ld	a,GM_DebugMenu
	call	SetGameMode
.continue
	jp	MainLoop_end
	
SECTION	"Other routines",HOME	
	
; ================================================================
; Other routines
; ================================================================

; ================================================================
; Fade in from white
; ================================================================

PalFadeIn:
	xor	a
	ldh	[rBGP],a	; clear palette
	ld	[FadeState],a
	add	6
	ld	[FadeTimer],a
.loop
	halt						; wait for VBlank
	ld	a,[FadeTimer]
	dec	a
	ld	[FadeTimer],a
	and	a
	jr	nz,.loop
	ld	a,6
	ld	[FadeTimer],a
	ld	a,[FadeState]
	inc	a
	ld	[FadeState],a
	cp	1
	jr	z,.state0
	cp	2
	jr	z,.state1
	cp	3
	jr	z,.state2
	ret
.state0
	ld	a,%01000000
	jr	.setpal
.state1
	ld	a,%10010000
	jr	.setpal
.state2
	ld	a,%11100100
.setpal
	ldh	[rBGP],a
	jr	.loop

; ================================================================
; Fade out to white
; ================================================================
	
PalFadeOut:
	ld	a,3
	ld	[FadeState],a
	add	a
	ld	[FadeTimer],a
	ld	a,%11100100
	ldh	[rBGP],a
.loop
	halt						; wait for VBlank
	ld	a,[FadeTimer]
	dec	a
	ld	[FadeTimer],a
	and	a
	jr	nz,.loop
	ld	a,6
	ld	[FadeTimer],a
	ld	a,[FadeState]
	dec	a
	ld	[FadeState],a
	and	a
	jr	z,.state0
	cp	1
	jr	z,.state1
	cp	2
	jr	z,.state2
	cp	$ff
	jr	z,.endfade
	jr	.loop
.state0
	ld	a,%00010001
	ldh	[rNR50],a
	ld	a,%00000000
	jr	.setpal
.state1
	ld	a,%00110011
	ldh	[rNR50],a
	ld	a,%01000000
	jr	.setpal
.state2
	ld	a,%01010101
	ldh	[rNR50],a
	ld	a,%10010000
.setpal
	ldh	[rBGP],a
	jr	.loop
.endfade
	ldh	[rBGP],a
	ret
	
; ================================================================
; Fade in from black
; ================================================================

PalFadeInBlack:
	ld	a,$ff
	ldh	[rBGP],a	; clear palette
	inc	a
	ld	[FadeState],a
	add	6
	ld	[FadeTimer],a
.loop
	halt						; wait for VBlank
	ld	a,[FadeTimer]
	dec	a
	ld	[FadeTimer],a
	and	a
	jr	nz,.loop
	ld	a,6
	ld	[FadeTimer],a
	ld	a,[FadeState]
	inc	a
	ld	[FadeState],a
	cp	1
	jr	z,.state0
	cp	2
	jr	z,.state1
	cp	3
	jr	z,.state2
	ret
.state0
	ld	a,%11111110
	jr	.setpal
.state1
	ld	a,%11111001
	jr	.setpal
.state2
	ld	a,%11100100
.setpal
	ldh	[rBGP],a
	jr	.loop
	
; ================================================================
; Fade out to black
; ================================================================
	
PalFadeOutBlack:
	ld	a,3
	ld	[FadeState],a
	add	a
	ld	[FadeTimer],a
	ld	a,%11100100
	ldh	[rBGP],a
.loop
	halt						; wait for VBlank
	ld	a,[FadeTimer]
	dec	a
	ld	[FadeTimer],a
	and	a
	jr	nz,.loop
	ld	a,6
	ld	[FadeTimer],a
	ld	a,[FadeState]
	dec	a
	ld	[FadeState],a
	and	a
	jr	z,.state0
	cp	1
	jr	z,.state1
	cp	2
	jr	z,.state2
	cp	$ff
	jr	z,.endfade
	jr	.loop
.state0
	ld	a,%00010001
	ldh	[rNR50],a
	ld	a,%11111111
	jr	.setpal
.state1
	ld	a,%00110011
	ldh	[rNR50],a
	ld	a,%11111110
	jr	.setpal
.state2
	ld	a,%01010101
	ldh	[rNR50],a
	ld	a,%11111001
.setpal
	ldh	[rBGP],a
	jr	.loop
.endfade
	ldh	[rBGP],a
	ret

; ================================================================
; Load a text tilemap
; ================================================================

LoadMapText:
	ld	de,_SCRN0
	ld	b,$12
	ld	c,$14
.loop
	ld	a,[hl+]
	sub 32	
	ld	[de],a
	inc	de
	dec	c
	jr	nz,.loop
	ld	c,$14
	rept	12
	inc	de
	endr
	dec	b
	jr	nz,.loop
	ret


; ================================================================
; Draw a menu cursor starting at address HL
; ================================================================

DrawCursor:
	ld	a,[CurrentMenuItem]
	swap	a	
	rl	a
	add	l
	ld	l,a
	jr	nc,.nocarry
	inc	h
	ld	a,h
.nocarry
	ld	a,">" - 32
	ld	[hl],a
	ret
	
; ================================================================
; Clear a menu cursor
; ================================================================

ClearCursor:
	ld	a,[OldMenuItem]
	swap	a
	rl	a
	add	l
	ld	l,a
	jr	nc,.nocarry
	inc	h
	ld	a,h
.nocarry
	ld	a," " - 32
	ld	[hl],a
	ret
	
; ================================================================
; Draw a checkbox at HL with value A
; ================================================================

DrawCheckbox:
	bit	0,a
	ld	a,$5f
	jr	nz,.checked
	jr	.draw
.checked
	inc	a
.draw
	ld	[hl],a
	ret
	
; ================================================================
; Do VBlank stuff
; ================================================================

DoVBlank:
	push	af	
	ld	a,2
	ld	[rROMB0],a
	call	$4006		; update SFX
	ld	a,[PlayMusic]
	and	a
	jr	z,.incFrame
	ld	a,[MusicBank]
	ld	[rROMB0],a
	call	$4100		; update music
.incFrame:
	ld	a,[CurrentFrame]
	inc	a
	ld	[CurrentFrame],a
.updateParTile
	ld	a,[GameMode]
	cp	GM_TestScreen
	jr	nz,.dontUpdate
	call	ParTile_CopyToVRAM
.dontUpdate
	pop	af
	ret
	
; ================================================================
; Print a line of text
; INPUT: hl = address of text, de = destination address
; ================================================================

PrintLine:
	ld	a,20
	ld	b,a
.loop
	ld	a,[hl+]
	and	a
	jr	z,.endOfString
	sub	32
	ld	[de],a
	inc	de
	dec	b
	jr	nz,.loop
.endOfString
	xor	a
.loop2
	ld	[de],a
	inc	de
	dec	b
	jr	nz,.loop2
	ret
	
; ================================================================
; Play a song
; INPUT: a = song ID
; ================================================================

PlaySong:
	add	3
	ld	[MusicBank],a
	ld	[rROMB0],a
	call	$4003
	ld	a,1
	ld	[PlayMusic],a
	ld	a,%01110111
	ldh	[rNR50],a
	ret
	
; ================================================================
; Stop playing a song
; ================================================================

StopSong:
	ld	a,[MusicBank]
	ld	[rROMB0],a
	call	$4006
	xor	a
	ld	[PlayMusic],a
	ret

; ================================================================
; Play a sound effect
; INPUT: a = SFX ID
; ================================================================

PlaySFX:
	push	af
	ld	a,2
	ld	[rROMB0],a
	pop	af
	call	$4000	; play sound effect
	ld	a,%01110111
	ldh	[rNR50],a
	ret
	
; ================================================================
; Stop playing a sound effect
; ================================================================

StopSFX:
	ld	a,2
	ld	[rROMB0],a
	call	$4003	; stop sound effect
	ret
	
; ================================================================
; Stop all sound
; ================================================================

StopSound:	
	xor	a
	ld	[PlayMusic],a
	ld	a,3
	ld	[rROMB0],a
	call	$4006
	ld	a,2
	ld	[rROMB0],a
	call	$4003	
	ret	

; ================================================================
; Main font
; ================================================================

Font:				incbin	"Data/Font_1BPP.bin"
Font_End:
SplashScreenGFX:	incbin	"Data/SplashScreenGFX.bin"

; ================================================================
; Tilemaps
; ================================================================

SECTION	"Tilemaps",HOME

DebugMenuText:
;		 ####################
	db	" Jetpack Dude v0.1  "
	db	"     by DevEd       "
	db	"  deved8@gmail.com  "
	db	"                    "
	db	" Start game         "
	db	" Test screen        "
	db	" Level select       "
	db	" Sound test         "
	db	" Debug mode       ? "	; "?" is replaced with check box graphic
	db	"                    "
	db	"                    "
	db	"                    "
	db	"                    "
	db	"                    "
	db	"                    "
	db	"                    "
	db	"                    "
	db	"                    "
;		 ####################

SplashScreenTilemap:
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	db $00,$00,$01,$02,$05,$00,$00,$00,$00,$00,$00,$26,$29,$2a,$00,$00,$43,$00,$00,$00
	db $00,$00,$03,$04,$06,$07,$00,$00,$00,$00,$27,$28,$00,$00,$00,$3b,$44,$00,$00,$00
	db $00,$00,$08,$09,$0b,$0c,$17,$18,$00,$1f,$2b,$2c,$2f,$30,$00,$3c,$45,$00,$00,$00
	db $00,$00,$0a,$00,$0d,$0e,$19,$1a,$20,$21,$2d,$2e,$31,$32,$3d,$3e,$46,$00,$00,$00
	db $00,$00,$0f,$10,$13,$14,$1b,$1c,$22,$23,$33,$34,$37,$38,$3f,$40,$47,$00,$00,$00
	db $00,$00,$11,$12,$15,$16,$1d,$1e,$24,$25,$35,$36,$39,$3a,$41,$42,$48,$00,$00,$00
	db $00,$00,$00,$00,$00,$00,$49,$4a,$4b,$4c,$4b,$4d,$4e,$4c,$00,$00,$00,$00,$00,$00
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

TestScreenTilemap:
;		 ####################
	db	"Placeholder for     "
	db	"test screen.        "
	db	"                    "
	db	"Press B to return to"
	db	"the debug menu.     "
	db	"                    "
	db	"                    "
	db	"                    "
	db	"                    "
	db	"                    "
	db	"                    "
	db	"                    "
	db	"                    "
	db	"                    "
	db	"                    "
	db	"                    "
	db	"                    "
	db	"                    "
;		 ####################	

SoundTestTilemap:
;		 ####################
	db	"Sound test          "
	db	"                    "
	db	" Music  $??         "	; ?? is replaced with music ID
	db	" SFX    $??         "	; ?? is replaced with SFX ID
	db	" Exit               "
	db	"                    "
	db	"                    "
	db	"Now playing:        "
	db	"                    "	; song name goes here
	db	"                    "	; author goes here
	db	"                    "
	db	"                    "
	db	"                    "
	db	"                    "
	db	"                    "
	db	"                    "
	db	"                    "
	db	"                    "
;		 ####################

TitleScreenTilemap:	
;		 ####################
	db	"Placeholder for     "
	db	"title screen.       "
	db	"                    "
	db	"Press B to return to"
	db	"the debug menu.     "
	db	"                    "
	db	"                    "
	db	"                    "
	db	"                    "
	db	"                    "
	db	"                    "
	db	"                    "
	db	"                    "
	db	"                    "
	db	"                    "
	db	"                    "
	db	"                    "
	db	"                    "
;		 ####################

LevelSelectTilemap:
;		 ####################
	db	"Placeholder for     "
	db	"level select screen."
	db	"                    "
	db	"Press B to return to"
	db	"the debug menu.     "
	db	"                    "
	db	"                    "
	db	"                    "
	db	"                    "
	db	"                    "
	db	"                    "
	db	"                    "
	db	"                    "
	db	"                    "
	db	"                    "
	db	"                    "
	db	"                    "
	db	"                    "
;		 ####################

OptionsMenuTilemap:
;		 ####################
	db	"Placeholder for     "
	db	"options menu.       "
	db	"                    "
	db	"Press B to return to"
	db	"the debug menu.     "
	db	"                    "
	db	"                    "
	db	"                    "
	db	"                    "
	db	"                    "
	db	"                    "
	db	"                    "
	db	"                    "
	db	"                    "
	db	"                    "
	db	"                    "
	db	"                    "
	db	"                    "
;		 ####################

PasswordMenuTilemap:
;		 ####################
	db	"Placeholder for     "
	db	"password screen.    "
	db	"                    "
	db	"Press B to return to"
	db	"the debug menu.     "
	db	"                    "
	db	"                    "
	db	"                    "
	db	"                    "
	db	"                    "
	db	"                    "
	db	"                    "
	db	"                    "
	db	"                    "
	db	"                    "
	db	"                    "
	db	"                    "
	db	"                    "
;		 ####################
	
LevelErrorTilemap:
;		 ####################
	db	"     - ERROR -      "
	db	"                    "
	db	"Level ?? does not   "	; ?? is replaced with level number
	db	"exist.              "
	db	"                    "
	db	"Press B to return to"
	db	"the debug menu.     "
	db	"                    "
	db	"                    "
	db	"                    "
	db	"                    "
	db	"                    "
	db	"                    "
	db	"                    "
	db	"                    "
	db	"                    "
	db	"                    "
	db	"                    "
;		 ####################

; ================================================================
; Error handler
; ================================================================

SECTION	"Error handler",HOME

ErrorHandler:

	; store stack pointer
	ld	[tempSP],sp
	
	push	hl
	push	af
	
	; store AF
	pop	hl
	ld	a,h
	ldh	[tempAF],a
	ld	a,l
	ldh	[tempAF+1],a
	
	; store BC
	ld	a,b
	ldh	[tempBC],a
	ld	a,c
	ldh	[tempBC+1],a
	
	; store DE
	ld	a,d
	ldh	[tempDE],a
	ld	a,e
	ldh	[tempDE+1],a
	
	; store HL
	pop	hl
	ld	a,h
	ldh	[tempHL],a
	ld	a,l
	ldh	[tempHL+1],a
	
	; store PC
	pop	hl				; hl = old program counter
	ld	a,h
	ldh	[tempPC],a
	ld	a,l
	ldh	[tempPC+1],a
	
	; store IF
	ldh	a,[rIF]
	ldh	[tempIF],a
	
	; store IE
	ldh	a,[rIE]
	ldh	[tempIE],a
	
.wait					; wait for VBlank before disabling the LCD
	ldh	a,[rLY]
	cp	$90
	jr	nz,.wait
	; Note that it probably isn't a good idea to use halt to wait for VBlank
	; because interrupts may not be enabled when an error occurs.
	
	xor	a
	ldh	[rLCDC],a		; disable LCD
	
	call	ClearVRAM
	
	CopyTileset1BPP	Font,0,97
	ld	hl,ErrorHandlerTilemap
	call	LoadMapText
	
DrawRegisterValues:
	ld	de,tempAF
	
	ld	hl,$9965
	ld	a,[de]
	inc	de
	call	DrawHex
	ld	a,[de]
	inc	de
	call	DrawHex
	ld	hl,$996f
	ld	a,[de]
	inc	de
	call	DrawHex
	ld	a,[de]
	inc	de
	call	DrawHex
	ld	hl,$9985
	ld	a,[de]
	inc	de
	call	DrawHex
	ld	a,[de]
	inc	de
	call	DrawHex
	ld	hl,$998f
	ld	a,[de]
	inc	de
	call	DrawHex
	ld	a,[de]
	inc	de
	call	DrawHex
	inc	de
	inc	de
	ld	hl,$99af
	ld	a,[de]
	inc	de
	call	DrawHex
	ld	a,[de]
	inc	de
	call	DrawHex
	
	ld	hl,$99a5
	ld	a,[tempSP+1]
	call	DrawHex
	ld	a,[tempSP]
	call	DrawHex
	
	; TODO: Draw IF and IE
	
	ld	a,[rIF]
	ld	b,a
	ld	hl,$99c8
	call	DrawBin
	
	ld	a,[rIE]
	ld	b,a
	ld	hl,$99e8
	call	DrawBin

	ld	a,%10010001
	ldh	[rLCDC],a
	
	call	StopSound

ErrorHandler_loop:
	call	CheckInput
	ld	a,[sys_btnPress]
	bit	btnStart,a
	jr	z,.continue
	jp	ProgramStart
.continue
	halt
	jr	ErrorHandler_loop
	
DrawBin:
	bit	7,b
	call	nz,.draw1
	call	z,.draw0
	bit	6,b
	call	nz,.draw1
	call	z,.draw0
	bit	5,b
	call	nz,.draw1
	call	z,.draw0
	bit	4,b
	call	nz,.draw1
	call	z,.draw0
	bit	3,b
	call	nz,.draw1
	call	z,.draw0
	bit	2,b
	call	nz,.draw1
	call	z,.draw0
	bit	1,b
	call	nz,.draw1
	call	z,.draw0
	bit	0,b
	call	nz,.draw1
	ret	nz
.draw0
	ld	a,"0" - 32
	ld	[hl+],a
	ret
.draw1
	ld	a,"1" - 32
	ld	[hl+],a
	ret
	
ErrorHandlerTilemap:
;		 ####################
	db	"     - ERROR -      "
	db	"                    "
	db	"An error has occured"
	db	"and the game cannot "
	db	"continue. Contact   "
	db	"the following email "
	db	"address to report   "
	db	"this error:         "
	db	"  deved8@gmail.com  "	; you can replace this with your own email address
	db	"                    "
	db	"Registers:          "
	db	" AF=$????  BC=$???? "
	db	" DE=$????  HL=$???? "
	db	" SP=$????  PC=$???? "
	db	"    IF=%XXXXXXXX    "
	db	"    IE=%XXXXXXXX    "
	db	"                    "
	db	"Press Start to exit."
;		 ####################

; ================================================================
; Load a map which takes up the entire tilemap area rather than
; just the visible screen area
; ================================================================

LoadMapFull:
	ld	de,_SCRN0
	ld	bc,$2020
.loop
	ld	a,[hl+]	
	ld	[de],a
	inc	de
	dec	c
	jr	nz,.loop
	ld	c,$20
	dec	b
	jr	nz,.loop
	ret

; ================================================================
; Parallax tile functions
; ================================================================

ParTileID	equ	1	
	
ParTile_Init:
	ld	a,1
	ld	[rROMB0],a
	ld	hl,TestTileset+(ParTileID*$10)
	ld	de,ParTileBuffer
	call	ParTile_CopyLoop
	ld	hl,TestTileset+$10
	call	ParTile_CopyLoop
	ret
	
ParTile_CopyToVRAM:
	; normal parallax tile
	ld	hl,ParTileBuffer
	ld	de,$8010
	call	ParTile_CopyLoop
	; dark parallax tile 
	ld	hl,ParTileBuffer
	ld	de,$8120
	ld	a,$10
	ld	b,a
.loop
	ld	a,[hl+]
	xor	%11111111
	ld	[de],a
	inc	de
	dec	b
	jr	nz,.loop
	ret

ParTile_CopyToFirstBuffer:
	ld	hl,ParTileBuffer+$10
	ld	de,ParTileBuffer
	call	ParTile_CopyLoop
	ret

ParTile_CopyToSecondBuffer:
	ld	hl,ParTileBuffer
	ld	de,ParTileBuffer+$10
	call	ParTile_CopyLoop
	ret

ParTile_ShiftUp:
	push	bc
	push	hl
	push	de
	ld	hl,ParTileBuffer+$10	; parallax tile source
	ld	de,ParTileBuffer		; parallax tile destination
	
	push	hl
	inc	hl
	inc	hl
	ld	a,14
	ld	b,a
.loop
	ld	a,[hl+]
	ld	[de],a
	inc	de
	dec	b
	jr	nz,.loop
	pop	hl
	ld	a,2
	ld	b,a
.loop2
	ld	a,[hl+]
	ld	[de],a
	inc	de
	dec	b
	jr	nz,.loop2
	call	ParTile_CopyToSecondBuffer
	pop	de
	pop	hl
	pop	bc
	ret

ParTile_ShiftDown:
	push	bc
	push	hl
	push	de
	ld	hl,ParTileBuffer+$10	; parallax tile source
	ld	de,ParTileBuffer		; parallax tile destination
	
	push	hl
	ld	a,14
	add	l
	ld	l,a
	jr	nc,.nocarry
	inc	h
.nocarry
	ld	a,2
	ld	b,a
.loop
	ld	a,[hl+]
	ld	[de],a
	inc	de
	dec	b
	jr	nz,.loop
	pop	hl
	ld	a,14
	ld	b,a
.loop2
	ld	a,[hl+]
	ld	[de],a
	inc	de
	dec	b
	jr	nz,.loop2
	call	ParTile_CopyToSecondBuffer
	pop	de
	pop	hl
	pop	bc
	ret

ParTile_ShiftLeft:
	push	bc
	push	hl
	push	de
	ld	hl,ParTileBuffer	; parallax tile source
	ld	de,ParTileBuffer	; parallax tile destination
	
	ld	a,16
	ld	b,a
.loop
	ld	a,[hl+]
	rlc	a
	jr	nc,.nocarry
	set	0,a
.nocarry
	ld	[de],a
	inc	de
	dec	b
	jr	nz,.loop
	call	ParTile_CopyToSecondBuffer
	pop	de
	pop	hl
	pop	bc
	ret
	
ParTile_ShiftRight:
	push	bc
	push	hl
	push	de
	ld	hl,ParTileBuffer	; parallax tile source
	ld	de,ParTileBuffer	; parallax tile destination
	
	ld	a,16
	ld	b,a
.loop
	ld	a,[hl+]
	rrc	a
	jr	nc,.nocarry
	set	7,a
.nocarry
	ld	[de],a
	inc	de
	dec	b
	jr	nz,.loop
	call	ParTile_CopyToSecondBuffer
	pop	de
	pop	hl
	pop	bc
	ret

ParTile_CopyLoop:
	ld	a,$10
	ld	b,a
.loop
	ld	a,[hl+]
	ld	[de],a
	inc	de
	dec	b
	jr	nz,.loop
	ret

; ================================================================
; OAM DMA routine
; ================================================================

CopyOAMDMARoutine:
	ld	hl,_OAM_DMA
	ld	de,OAM_DMA
	ld	a,_OAM_DMA_End-_OAM_DMA
	ld	b,a
.loop
	ld	a,[hl+]
	ld	[de],a
	inc	de
	dec	b
	jr	nz,.loop
	ret

_OAM_DMA:
	ldh	[rDMA],a
	ld	a,$28
.loop
	dec	a
	jr	nz,.loop
	ret	
_OAM_DMA_End:

; ================================================================
; Graphics data
; ================================================================

SECTION	"Graphics data",ROMX,BANK[1]

TestTileset:	incbin	"Data/TestTileset.bin"

TestTilemap:	incbin	"Data/TestTilemap.bin"

; ================================================================
; SFX data
; ================================================================

SECTION "SFX data",ROMX,BANK[2]
SFXData:			incbin	"SFXData.bin"

; ================================================================
; Music data
; ================================================================

SECTION	"Introtune",ROMX,BANK[3]
Music_Introtune:	incbin	"Music/Introtune.bin"

SECTION	"Menu Theme",ROMX,BANK[4]
Music_MenuTheme:	incbin	"Music/MenuTheme.bin"

SECTION "Fruitless",ROMX,BANK[5]
Music_Fruitless:	incbin	"Music/Fruitless.bin"

SECTION	"Soundcheck",ROMX,BANK[6]
Music_Soundcheck:	incbin	"Music/Soundcheck.bin"

SECTION	"Train",ROMX,BANK[7]
Music_Train:		incbin	"Music/Train.bin"

SECTION	"Oldschool",ROMX,BANK[8]
Music_Oldschool:	incbin	"Music/Oldschool.bin"

SECTION	"Fruitful",ROMX,BANK[9]
Music_Fruitful:		incbin	"Music/Fruitful.bin"

SECTION	"The Fish Files",ROMX,BANK[$a]
Music_FishFiles:	incbin	"Music/FishFiles.bin"

SECTION	"LoOp",ROMX,BANK[$b]
Music_LoOp:			incbin	"Music/LoOp.bin"

SECTION	"20y",ROMX,BANK[$c]
Music_20y:			incbin	"Music/20y.bin"

SECTION	"Gejmbaj",ROMX,BANK[$d]
Music_Gejmbaj:		incbin	"Music/Gejmbaj.bin"

SECTION	"Oh!",ROMX,BANK[$e]
Music_Oh:			incbin	"Music/Oh.bin"

SECTION	"Is That A Demo In Your Pocket?",ROMX,BANK[$f]
Music_Pocket:		incbin	"Music/Pocket.bin"

SECTION	"Demotronic",ROMX,BANK[$10]
Music_Demotronic:	incbin	"Music/Demotronic.bin"
