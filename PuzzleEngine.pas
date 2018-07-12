{
  *************************************
  *       8-Puzzle game engine        *
  *-----------------------------------*
  * Version     : 1.3                 *
  * Coder       : David Eleazar       *
  * Prog. Lang  : Pascal              *
  * Compiler    : Free Pascal 3.0.4   *
  * Date Added  : 3rd February, 2018  *
  * Last Modif. : 12th July, 2018     *
  *************************************

  Changelog : 
  1.0 : Initial release
  1.1 : add manual input filter
        add delay to exit program
  1.2 : change delay mode
        change BFS structure to avoid recursion
  1.3 : add default final state option
}

unit PuzzleEngine;

interface
  uses
    CRT;

  type
    TMatrix = packed array [0..2,0..2] of char;   //array matrix berukuran 3x3
    TVertex = record  //record untuk menyimpan data tiap simpul
      itsPos,parentPos,depthLevel : integer; //memuat posisi array parent,dirinya sendiri dan tingkatan turunan
      content : TMatrix;  //isi matriks
      childPos : array of integer;  //menyimpan posisi anak dalam generated list
      isVisited : Boolean;  //penanda jika sudah dikunjungi
    end;
  
  var  //globar vars
  	errEnterBack : String = 'Tekan ENTER untuk kembali . . ';
	  strEnterContinue : String = 'Tekan ENTER untuk melanjutkan . . .';
    strAnyKeyExit : String = 'Tekan sembarang tombol untuk keluar . . .';
    generatedList : array of TVertex;  //array untuk menyimpan anakan hasil generate
    intInitState,intFinalState : TMatrix;  //initial state dan final state dari anakan yang dikirim dari program utama
    solutionFound : Boolean;  //jika solusi sudah ditemukan, maka bernilai TRUE
    solutionList : array of TMatrix;  //menyimpan solusi pergerakan dari initial state dan final state, jika solusi ditemukan
    
  //begin of procedure's prototypes
  procedure initModeSelect (s : String; var state : TMatrix);
	procedure manualStateInit (var x : TMatrix);
	procedure randomStateInit (var x : TMatrix);
  procedure defaultFinalState(var x : TMatrix);
	procedure viewState(x : TMatrix);
  procedure initFinalHorizontal (x,y : TMatrix);
	procedure findKPos (x : TMatrix; var a,b : integer);
	procedure copyMatrix (var origin,target : TMatrix);
  function isIdenticalMatrix(x, y : TMatrix):Boolean;
	procedure tMove(mvStep : char; var x : TMatrix);
	procedure exitConfirmation;
  procedure manualMove (init,final: TMatrix);
  procedure puzzle_prep (srcMethod : char;var init,final : TMatrix);
  procedure stepTracker (var x : array of TMatrix);
  procedure nodeGenerator (var node : TVertex);
  procedure puzzleBFS (numOfLevel : integer);
  procedure puzzleDFS (var node : TVertex; numOfLevel : integer);
  //end of procedure's protoypes

implementation
  {
    prosedur initModeSelect digunakan untuk memilih inisialisasi data, apakah ingin manual atau random
  }
  procedure initModeSelect (s : String; var state : TMatrix); //s : [Initial] atau [Final]
  var
    inpChar : char;
    enableDefault : Boolean;
  begin
    if (s='Initial') then begin
      TextColor (13);
      enableDefault:=FALSE;
    end else begin
      TextColor (10);
      enableDefault:=TRUE;
    end;
    if enableDefault then begin
      repeat
        clrscr;
        writeln;
        writeln ('--> ',s,' state initialization');
        writeln ('Silakan pilih metode inisialisasi data');
        writeln (' 1. Manual');
        writeln (' 2. Random');
        WriteLn (' 3. Default');
        write ('Masukkan angka pilihan : ');
        inpChar:=readkey;
        case inpChar of 
        '1' : manualStateInit(state);
        '2' : randomStateInit(state);
        '3' : defaultFinalState(state);
        end;
      until ((inpChar='1') or (inpChar='2') or (inpChar='3'));
    end else begin
      repeat
        clrscr;
        writeln;
        writeln ('--> ',s,' state initialization');
        writeln ('Silakan pilih metode inisialisasi data');
        writeln (' 1. Manual');
        writeln (' 2. Random');
        write ('Masukkan angka pilihan : ');
        inpChar:=readkey;
        case inpChar of 
        '1' : manualStateInit(state);
        '2' : randomStateInit(state);
        end;
      until ((inpChar='1') or (inpChar='2'));
    end;
  end;
  {
    prosedur manualStateInit
    prosedur ini digunakan untuk inisialisasi data dari state yang digunakan secara manual
    alias diinput manual oleh user dalam tampilan interaktif
    Dilengkapi filter untuk mencegah input karakter yang tidak seharusnya
  }
  procedure manualStateInit (var x : TMatrix);  //now with filtering
  var
    i,j,k,arrayPos : integer;
    tmp : char;
    foundOnMatrix,foreignChar : Boolean;  //jika data yang ingin diinput berada pada matriks, maka nilainya TRUE
    contentList : array [0..8] of char = ('1','2','3','4','5','6','7','8','k'); //berfungsi sebagai penanda array
    mirrorList : array [0..8] of Boolean; //bernilai FALSE jika belum dipakai, sebaliknya TRUE
  begin
    arrayPos := 0;  //init
    writeln;
    writeln ('Hanya diizinkan untuk memasukkan karakter 1,2,3,4,5,6,7,8 dan k');
    for i:=Low(mirrorList) to High(mirrorList) do mirrorList[i] := FALSE;  //buat mirror untuk check posisi
    for i:=0 to 2 do
      for j:=0 to 2 do begin
        repeat
        foreignChar :=TRUE;  //karakter tidak ditemukan pada content list
        foundOnMatrix := FALSE;
          write ('Masukkan isi untuk posisi ',i+1,'-',j+1,' : ');
          readln(tmp);
          //input filter
          for k:=Low(contentList) to High(contentList) do begin
            if (contentList[k]=tmp) then begin  //cek apakah karakter diizinkan
              foreignChar:=FALSE;
              arrayPos:=k; //kopikan posisi array tempat ditemukannya karakter
              break;
            end;
          end;
          if foreignChar then writeln ('Karakter tidak diizinkan !') else begin
            if mirrorList[arrayPos] then begin
              foundOnMatrix:=TRUE;  //data sudah ada pada matriks
              writeln ('Karakter sudah berada dalam matriks !');
            end else begin
              x[i,j]:=tmp; //masukkan kedalam matriks
              mirrorList[arrayPos]:=TRUE;  //sudah ada dalam matriks
              foundOnMatrix:=FALSE;
            end;
          end;
          //pesan exception
          if foundOnMatrix or foreignChar then begin
            WriteLn (errEnterBack);
            ReadLn;
          end;
        until ((not foundOnMatrix) and (not foreignChar));
      end;
  end;

  {
    prosedur randomStateInit
    prosedur ini digunakan untuk inisialisasi data dari state yang digunakan secara random
    alias diacak oleh sistem
  }
  procedure randomStateInit (var x : TMatrix);
  var
    i,j,k,randValue : integer;
    contentList : array [0..8] of char = ('1','2','3','4','5','6','7','8','k'); //berfungsi sebagai penanda array
    randomNumberList : array [0..8] of integer;
    positionFound : Boolean;
  begin
    positionFound:=FALSE;
    for i:=0 to 8 do randomNumberList[i]:=i+1;  //mengisi array dengan nomor 1-9, sebagai penanda posisi array contentList
    for i:=0 to 2 do begin
      for j:=0 to 2 do begin
        repeat
          randomize;  //acak-acak angka
          randValue := random(9);  //pilih angka acak dari 0-8
          for k:=0 to 8 do if (randValue+1=randomNumberList[k]) then begin
            x[i,j] := contentList[k];
            randomNumberList[k]:=0;
            positionFound:=TRUE;
          end;
        until positionFound;
        positionFound:=FALSE; 
      end;
    end;

  end;

  {
    prosedur defaultFinalState
    prosedur ini akan membuat final state default ('1','2','3','4','5','6','7','8','k')
  }
  procedure defaultFinalState (var x : TMatrix);
  var
    contentList : array [0..8] of char = ('1','2','3','4','5','6','7','8','k');
    i,j,cListPos : integer;
  begin
    cListPos:=0;
    for i:=0 to 2 do begin
      for j:=0 to 2 do begin
        x[i,j]:=contentList[cListPos];
        inc(cListPos);
      end;
    end;
  end;

  {
    prosedur viewState digunakan untuk melihat isi matriks
    silakan modifikasi seperlunya
  }
  procedure viewState(x : TMatrix);
  var
    i,j : integer;
  begin
    for i:=0 to 2 do begin
      write ('  ');
      for j:=0 to 2 do begin
        write (x[i,j],' ');
      end;
      writeln;
    end;
  end;

  {
    prosedur initFinalHorizontal hanya digunakan untuk menampilkan initial state dan final state dalam susunan horizontal
  }
  procedure initFinalHorizontal (x,y : TMatrix); //x = initState, y = finalState
  var
    i,j : integer;
  begin
    writeln ('#################################');
    writeln ('# Initial State  |  Final State #');
    for i:=0 to 2 do begin
      write ('#     ');
      for j:=0 to 2 do	write (x[i,j],' ');
      write ('     |     ');
      for j:=0 to 2 do	write (y[i,j],' ');
      writeln ('   #');
    end;
    writeln ('#################################');
    writeln;
  end;

  {
    prosedur findKPos digunakan untuk mencari posisi 'k' dalam matriks
    dan mengembalikan nilai berupa nilai posisi relatif x dan y
  }
  procedure findKPos (x : TMatrix; var a,b : integer); //a = i = ypos, b = j = xpos
  var
    i,j : integer;
  begin
    for i:= 0 to 2 do begin
      for j:= 0 to 2 do begin
        if (x[i,j]='k') then begin
          a := i;
          b := j;
        end;
      end;
    end;
  end;

  {
    prosedur copyMatrix digunakan untuk menyalin isi dari satu matriks ke matriks lain
  }
  procedure copyMatrix (var origin,target : TMatrix);
  var
    i,j : integer;
  begin
    for i:= 0 to 2 do begin
      for j:= 0 to 2 do target[i,j] := origin[i,j];
    end;
  end;

  {
    prosedur tMove adalah prosedur untuk memindahkan posisi 'k' dalam matriks
    untuk menghemat kode, digunakan parameter untuk mengatur perpindahan
  }
  procedure tMove(mvStep : char; var x : TMatrix); //mvStep : U=up,D=down,L=left,R=right
  var
    xpos,ypos,xmove,ymove : integer; //xpos ypos adalah posisi 'k', sedangkan xmove ymove adalah offset step perpindahan 'k'
    tmp : char;  //variabel bantu untuk simpan karakter sementara
    errorFlag : Boolean; //flag penanda error saat pindah posisi, bernilai TRUE jika tidak bisa pindah, sebaliknya FALSE
    errString : String = 'Error! Tidak dapat pindah ke ';  //string yang akan ditampilkan jika posisi 'k' pada array sudah paling tepi
  begin
    errorFlag := FALSE; //inisialisasi error state
    findKPos(x,ypos,xpos); //cari posisi 'k' dalam matriks
    //inisialisasi nilai offset perpindahan dengan 0
    xmove := 0;
    ymove := 0;
    case mvStep of
      'L' : if (xpos>0) then xmove := -1 else begin
        errorFlag := TRUE;
        errString += 'kiri';
      end;
      'R' : if (xpos<2) then xmove := 1 else begin
        errorFlag := TRUE;
        errString += 'kanan';
      end;
      'U' : if (ypos>0) then ymove := -1 else begin
        errorFlag := TRUE;
        errString += 'atas';
      end;
      'D' : if (ypos<2) then ymove := 1 else begin
        errorFlag := TRUE;
        errString += 'bawah';
      end;
    end;
    //mulai perpindahan berdasarkan parameter
    if (errorFlag=FALSE) then begin
      tmp :=x[ypos,xpos];
      x[ypos,xpos] := x[ypos+ymove,xpos+xmove];
      x[ypos+ymove,xpos+xmove] := tmp;
    end else begin
      writeln (errString);
      writeln (errEnterBack);
      readln;
    end;
  end;

  {
    fungsi isIdenticalMatrix digunakan untuk membandingkan dua buah matriks
    dan mengembalikan nilai boolean TRUE atau FALSE
    jika TRUE, maka matriks identik, sebaliknya tidak identik
  }
  function isIdenticalMatrix(x, y : TMatrix):Boolean;
  var
    i,j : Integer;
  begin
    isIdenticalMatrix := TRUE;
    for i:=0 to 2 do begin
    for j:=0 to 2 do begin
      if (x[i,j]<>y[i,j]) then isIdenticalMatrix:=FALSE; //ada isi yang berbeda
    end;
    end;
  end;

  procedure exitConfirmation; //call when you need to exit the game
  var
    conf_char : char;
    sec_left : integer;
  begin
    sec_left := 3; //tiga detik hitung mundur
    repeat
      TextColor (11);
      clrscr;
      writeln;
      writeln ('Apakah Anda yakin ingin keluar ?');
      writeln ('Y=Ya, N=Tidak');
      write ('Pilihan Anda : ');
      conf_char := upCase(readkey);
    until ((conf_char='Y') or (conf_char='N'));
    case conf_char of 
      'Y' : begin
        writeln ('Sampai jumpa kembali !');
        write ('Program akan keluar otomatis dalam ');
        while sec_left>0 do begin
          write (sec_left,'..');
          dec(sec_left);
          delay (1000);  //delay biar WOW
        end;
        halt;  //keluar dari keseluruhan program
      end;
      'N' : exit;  //keluar dari prosedur ini dan kembali ke prosedur sebelumnya
    end;
  end;

  {
    prosedur manualMove digunakan untuk memindahkan posisi 'k' secara manual
  }
  procedure manualMove (init,final: TMatrix); //pindahkan matriks secara manual
  var
    char_inp : char;
    currentState : TMatrix;
    finishPlaying : Boolean;
  begin
    //local init
    copyMatrix(init,currentState);
    finishPlaying:=FALSE;
    clrscr;
    while not finishPlaying do begin
      repeat
        TextColor (15);
        initFinalHorizontal(init,final);  //menampilkan init dan final state
        writeln ('----Manual puzzle move----');
        writeln ('Current state');
        writeln;
        TextColor(14);viewState(currentState);
        writeln;
        TextColor (15);writeln ('Silakan pilih pergerakan');
        writeln;
        TextColor (10);
        writeln ('     W');
        writeln ('  A     D');
        writeln ('     S');
        TextColor (11);
        gotoXY (15,17);writeln ('-> W = Atas');
        gotoXY (15,18);writeln ('-> A = Kiri | D = Kanan');
        gotoXY (15,19);writeln ('-> S = Bawah');
        TextColor (15);
        writeln;
        writeln ('Tekan 0 untuk keluar');
        write ('Silakan masukkan pilihan : ');
        char_inp:=upCase(readkey);
        if ((char_inp<>'A') and (char_inp<>'D') and (char_inp<>'W') and (char_inp<>'S') and (char_inp<>'0')) then begin
          writeln ('ERROR! Pilihan invalid!');
          write (errEnterBack);
          readln;
        end;
        clrscr;
      until ((char_inp='A') or (char_inp='D') or (char_inp='W') or (char_inp='S') or (char_inp='0'));
      case char_inp of
        'A' : tMove('L',currentState);  //pindah kiri
        'D' : tMove('R',currentState);  //pindah kanan
        'W' : tMove('U',currentState);  //pindah atas
        'S' : tMove('D',currentState);  //pindah bawah
        '0' : exitConfirmation;  //keluar
      end;
      writeln;
      clrscr;
      finishPlaying:=isIdenticalMatrix(currentState,final); //if return TRUE, then game over
    end;
    if finishPlaying then begin
      writeln ('Permainan selesai !');
      writeln (strEnterContinue);
      readln;
    end;
  end;

  procedure puzzle_prep (srcMethod : char;var init,final : TMatrix);  //scrMethod : "[B]readth FS" atau "[D]epth FS"
  var
    maxLevel : integer;
    strText : String = 'Anda memilih menggunakan metode ';
  begin
    //copy init state dan final state ke variabel global
    copyMatrix(init,intInitState);
    copyMatrix(final,intFinalState);
    maxLevel := 0;
    SetLength(generatedList,1);  //siapkan tempat pertama untuk root parent
    copyMatrix(init,generatedList[0].content);  //posisi 0 sebagai root parent
    //set attribute
    generatedList[0].parentPos:=0;
    generatedList[0].itsPos :=0;
    generatedList[0].depthLevel:=0;
    generatedList[0].isVisited:=FALSE;
    clrscr;
    TextColor (11);
    initFinalHorizontal(intInitState,intFinalState);
    writeln;
    case srcMethod of 
      'D' : strText += 'Depth-first Search';
      'B' : strText += 'Breadth-first Search';
    end;
    writeln (strText);
    writeln;
    write ('Masukkan batasan level kedalaman : ');
    readln (maxLevel);
    writeln ('Anda memilih ',maxLevel,' level kedalaman pencarian');
    writeln (strEnterContinue);
    readln;
    clrscr;
    if (srcMethod='B') then begin
      puzzleBFS(maxLevel);
    end else begin
      puzzleDFS(generatedList[0],maxLevel);
    end;
    if solutionFound=FALSE then begin
      TextColor (12);
      writeln ('Mohon maaf, solusi tidak ditemukan');
      writeln (strAnyKeyExit);
      repeat
      until keypressed;  //menunggu hingga sebuah tombol ditekan
    end;
  end;

  {
    prosedur stepTracker berguna untuk menarik garis dari posisi final state di array hasil generate hingga ke initial state dari program
  }
  procedure stepTracker (var x : array of TMatrix);
  var
    i,locParent : integer;
  begin
    locParent:=generatedList[High(generatedList)].itsPos;  //kopikan posisi diri sendiri terlebih dahulu
    for i:=High(x) downto Low(x) do begin
      copyMatrix(generatedList[locParent].content,x[i]);
      locParent:=generatedList[locParent].parentPos;  //kemudian untuk tiap loop, ganti posisi parent
    end;
  end;

  {
    prosedur nodeGenerator berfungsi untuk membangkitan child dari suatu node masukan,
    dan menyimpannya dalam variabel global bertipe array dinamis
  }
  procedure nodeGenerator (var node : TVertex);
  var
    i,j,k,xpos,ypos,tmpNodeLevel : integer;
    allowedRule : array [0..3] of Boolean; //0 = left, 1 = right, 2 = up, 3 = down
    moveCode : array [0..3] of char = ('L','R','U','D');  //array untuk memanggil prosedur tMove
    tmpMatrixStorage : TMatrix;
    isIdentic,reachedFinal : Boolean; //cek kesamaan isi matriks dan finalisasi
  begin
    clrscr;  //bersihkan layar
    tmpNodeLevel:=0;
    writeln ('Parent position : ',node.itsPos);
    isIdentic := FALSE;
    reachedFinal:=FALSE;
    //begin ruler init
    for i:=low(allowedRule) to high(allowedRule) do allowedRule[i]:=TRUE; //pada awalnya, boleh bergerak kemanapun
    findKPos(node.content,ypos,xpos);  //cari posisi k di matriks dan kembalikan hasil dalam xpos ypos 
    if (xpos-1<0) then allowedRule[0] := FALSE;  //tidak bisa kekiri jika sudah paling kiri
    if (xpos+1>2) then allowedRule[1] := FALSE;  //tidak bisa kekanan jika sudah paling kanan
    if (ypos-1<0) then allowedRule[2] := FALSE;  //tidak bisa keatas jika sudah paling atas
    if (ypos+1>2) then allowedRule[3] := FALSE;  //tidak bisa kebawah jika sudah paling bawah
    //end ruler init
    tmpNodeLevel:=node.depthLevel;
    inc(tmpNodeLevel);
    for i:=low(allowedRule) to high(allowedRule) do begin
      copyMatrix(node.content,tmpMatrixStorage);  //kopi konten node ke temp
      if allowedRule[i] then tMove(moveCode[i],tmpMatrixStorage); //jika boleh pindah, maka pindahkan
      for j:=low(generatedList) to high(generatedList) do begin
        isIdentic:=isIdenticalMatrix(tmpMatrixStorage,generatedList[j].content);
        if isIdentic=TRUE then break;  //jika terdeteksi ada yang identik, hentikan looping
      end;
      if (isIdentic=FALSE and allowedRule[i]) then begin  //jika tidak ada yang identik, kopikan hasil generate ke generatedList
        SetLength (generatedList,length(generatedList)+1);  //siapkan tempat untuk generated matrix
        SetLength(node.childPos,length(node.childPos)+1);  //siapkan tempat untuk posisi child pada array
        node.childPos[length(node.childPos)-1] := length(generatedList)-1;  //masukkan posisi child pada array childPos
        copyMatrix (tmpMatrixStorage,generatedList[length(generatedList)-1].content); //kopikan isi ke generated list
        generatedList[length(generatedList)-1].parentPos := node.itsPos; //posisi parent pada array
        generatedList[length(generatedList)-1].itsPos := length(generatedList)-1;  //posisi node yang baru digenerate berada pada posisi terakhir array yang baru diset
        generatedList[length(generatedList)-1].depthLevel := tmpNodeLevel;  //kedalaman level = level node aktif + 1
        generatedList[length(generatedList)-1].isVisited := FALSE;  //set status node yang belum digenerate dengan FALSE
        reachedFinal:=isIdenticalMatrix(generatedList[length(generatedList)-1].content,intFinalState);
        if reachedFinal then begin  //jika sudah ketemu final state
          SetLength(solutionList,generatedList[length(generatedList)-1].depthLevel+1);  //menyiapkan array untuk menyimpan posisi langkah
          stepTracker(solutionList);  //panggil prosedur tracker 
          TextColor(14);
          clrscr;
          writeln ('Solusi ditemukan!');
          solutionFound:=TRUE;
        end;
        writeln ('Current node position : ',node.childPos[high(node.childPos)]);
        writeln ('Child level : ',tmpNodeLevel);
        viewState(generatedList[length(generatedList)-1].content);   //tampilkan node yang baru digenerate
        if solutionFound then begin
          writeln ('Posisi final state berada pada array ke-',High(generatedList));
          writeln ('Langkah yang diperlukan dari initial state adalah ',generatedList[High(generatedList)].depthLevel,' langkah');
          writeln ('Langkah langkahnya adalah : ');
          writeln;
          TextColor (10);
          for k:=Low(solutionList) to High(solutionList) do begin
            if k=Low(solutionList) then writeln ('Initial State')
              else if k=High(solutionList) then writeln ('Final State')
                else writeln ('Langkah ke-',k);
            viewState(solutionList[k]);
            readln;
          end;
          writeln ('Permainan selesai');
          writeln (strAnyKeyExit);
          repeat
          until keypressed;  //menunggu hingga sebuah tombol ditekan
          halt;  //keluar dari program
        end;
        writeln;
      end;
    end;
    node.isVisited := TRUE;  //tandai node yang sudah digenerate sebagai TRUE
    //delay(500);  //just for debugging
    //readln;  //just for debugging
  end;

//deprecated procedure
{
  procedure puzzleBFS (var node : TVertex; numOfLevel : integer);  //this is old BFS procedure, using recursive
  begin
    if ((node.isVisited=FALSE) and (solutionFound=FALSE)) then begin
      if node.depthLevel<numOfLevel then begin
        nodeGenerator(node);  //generate hasil
        inc(bfsPosition);  //generator akan bergerak secara mendatar
        puzzleBFS(generatedList[bfsPosition],numOfLevel);
      end;
    end else exit;
  end;
}
  procedure puzzleBFS (numOfLevel : integer);  //this is new BFS procedure, no recursive
  var
    bfsPosition : integer;
  begin
    bfsPosition := 0;  //posisi awal BFS pada root parent
    while ((generatedList[bfsPosition].isVisited=FALSE) and (solutionFound=FALSE)) do begin
      if generatedList[bfsPosition].depthLevel<numOfLevel then begin
        nodeGenerator(generatedList[bfsPosition]);  //generate hasil
        inc(bfsPosition);  //generator akan bergerak secara mendatar
      end else exit;
    end;
  end;

  procedure puzzleDFS (var node : TVertex; numOfLevel : integer);  //this is DFS
  var
    i : integer;
  begin
    if (node.isVisited=FALSE) then begin
      if node.depthLevel<numOfLevel then begin
        nodeGenerator(node);
        for i:=low(node.childPos) to high(node.childPos) do //generator akan melakukan pembangkitan anakan terlebih dahulu
          puzzleDFS(generatedList[node.childPos[i]],numOfLevel);
      end;
    end else exit;
  end;
end.