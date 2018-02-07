program puzzle8UAS;
uses
	CRT,PuzzleEngine; //CRT for modifying screen, and PuzzleEngine is the core module

var
	globalInpChar : char;
	initState,finalState : TMatrix;  //deklarasi matriks untuk menyimpan initial state dan final state

//the main program starts here
begin
	clrscr;
	writeln ('Selamat datang di kuis 8-puzzle!');
	write (strEnterContinue);
	readln;
	initModeSelect('Initial',initState);
	initModeSelect('Final',finalState);
	clrscr;
	repeat
		TextColor (11);
		writeln ('Silakan pilih metode permainan : ');
		writeln ('1. Auto -> Depth-first search');
		writeln ('2. Auto -> Breadth-first search');
		writeln ('3. Manual');
		write ('Masukkan angka pilihan : ');
		globalInpChar:=readkey;
		case globalInpChar of 
			'1' : puzzle_prep('D',initState,finalState);
			'2' : puzzle_prep('B',initState,finalState);
			'3' : manualMove(initState,finalState);
		end;
	until ((globalInpChar='1') or (globalInpChar='2') or (globalInpChar='3'));
end.