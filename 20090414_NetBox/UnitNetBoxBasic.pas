unit UnitNetBoxBasic;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, IniFiles,
  ShellApi, AppEvnts, TLHelp32, Dialogs, Printers;




type
  TNetBoxBasic = class(TObject)
  private

  public
    procedure Print(sl: TStrings; bPrintDialog: Boolean);
    procedure GetProcessList(const aProcessList: TStrings);
    function IsExeRunning(const AExeName: string): boolean;
    function KillTask(const AExeName: string): boolean;
    function TaskBarAddIcon(Sender: TForm):Boolean;
    function TaskBarRemoveIcon(Sender: TForm):Boolean;
    procedure SetStartBtnEnabled(const AEnabled: Boolean);
    function CheckoutTan(sTan, sTanFile: String): Integer;
    function GenerateTan(iChars: integer): String;
    function IsTanExist( sTan, sTanFile : String  ):Integer;
    function IsTanExistInStringlist(sTan: String;aStringlist: TStringList): Integer;
    function EinfacheCodierung(aString: String): String;
    function EinfacheDeCodierung(aString: String): String;
    procedure LoadIniFile;
    constructor Create();
    destructor Destroy();
  end;


var sTanlistsDir : String;
var sTanlist1 : String;
var sTanlist2 : String;
var sTanlist3 : String;
var sTanlist4 : String;
var sTanlist5 : String;
var sTanlist6 : String;
var iTanRefesherInterval : integer;
var sAdminPass : String;
var sCodeCharakterPool : String;
var iBeep1 : Integer;
var iBeep2 : Integer;



implementation


{ TNetBoxBasic }

procedure TNetBoxBasic.GetProcessList(const aProcessList: TStrings);
var
  Snap: THandle;
  ProcessE: TProcessEntry32;
begin
  aProcessList.Clear;
  Snap := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  try
    ProcessE.dwSize := SizeOf(ProcessE);
    if Process32First(Snap, ProcessE) then
      Repeat
        aProcessList.Add(ProcessE.szExeFile);
      Until not Process32Next(Snap, ProcessE)
    else
      showmessage('L444');
      //RaiseLastOSError;
  finally
    CloseHandle(Snap);
  end;
end;




function TNetBoxBasic.IsExeRunning(const AExeName: string): boolean;
var
  h: THandle;
  p: TProcessEntry32;
begin
  Result := False;

  p.dwSize := SizeOf(p);
  h := CreateToolHelp32Snapshot(TH32CS_SnapProcess, 0);
  try
    Process32First(h, p);
    repeat
      Result := AnsiUpperCase(AExeName) = AnsiUpperCase(p.szExeFile);
    until Result or (not Process32Next(h, p));
  finally
    CloseHandle(h);
  end;
end;



function TNetBoxBasic.KillTask(const AExeName: string): boolean;
var
  p: TProcessEntry32;
  h: THandle;
begin
  Result := false;
  p.dwSize := SizeOf(p);
  h := CreateToolHelp32Snapshot(TH32CS_SnapProcess, 0);
  try
    if Process32First(h, p) then
      repeat
        if AnsiLowerCase(p.szExeFile) = AnsiLowerCase(AExeName) then
          Result := TerminateProcess(OpenProcess(Process_Terminate,
                                                 false,
                                                 p.th32ProcessID),
                                     0);
      until (not Process32Next(h, p)) or Result;
  finally
    CloseHandle(h);
  end;
end;



procedure TNetBoxBasic.LoadIniFile();
var
  Ini : TIniFile;
begin
  try
    Ini := TIniFile.Create('.\settings.ini');
    sTanlistsDir := Ini.ReadString('MainSettings','TanlistsDir','kein Wert');
    sTanlist1 := Ini.ReadString('MainSettings','Tanlist1','kein Wert');
    sTanlist2 := Ini.ReadString('MainSettings','Tanlist2','kein Wert');
    sTanlist3 := Ini.ReadString('MainSettings','Tanlist3','kein Wert');
    sTanlist4 := Ini.ReadString('MainSettings','Tanlist4','kein Wert');
    sTanlist5 := Ini.ReadString('MainSettings','Tanlist5','kein Wert');
    sTanlist6 := Ini.ReadString('MainSettings','Tanlist6','kein Wert');
    if Ini.ReadString('MainSettings','AdminPass','kein Wert') <> '...start' then
    begin
      sAdminPass:= EinfacheDeCodierung( Ini.ReadString('MainSettings','AdminPass','kein Wert') );
    end
    else
    begin
      sAdminPass:= Ini.ReadString('MainSettings','AdminPass','kein Wert');
    end;   
    sCodeCharakterPool := Ini.ReadString('MainSettings','CodeCharakterPool','kein Wert');
    iTanRefesherInterval := Ini.ReadInteger('MainSettings','TanRefesherInterval',10000);
    iBeep1 := Ini.ReadInteger('MainSettings','Beep1',900);
    iBeep2 := Ini.ReadInteger('MainSettings','Beep2',200);
  finally
    Ini.Free;
  end;
end;


procedure TNetBoxBasic.Print(sl: TStrings; bPrintDialog:Boolean);
var zeile, x, y: integer;
    hoehe, randlinks, randoben: integer;
    PrintDialog1 : TPrintDialog;
begin
  If ( bPrintDialog ) then
  begin
    PrintDialog1 := TPrintDialog.Create(nil);
    try
      if PrintDialog1.Execute then
      begin
        Printer.BeginDoc; //Druckjob beginnen
        //Blattgröße in 1/10 mm ermitteln:
        //breite := GetDeviceCaps(Printer.Canvas.Handle, HORZSIZE)*10;
        hoehe := GetDeviceCaps(Printer.Canvas.Handle, VERTSIZE)*10;
        randlinks := 300; //1 cm
        randoben := 100; //1 cm
        x := randlinks;
        y := randoben*-1;
        for zeile :=0 to sl.Count-1 do
        begin
          if -y > (hoehe-2 * randoben) then
          begin
            y := randoben*-1;
            Printer.NewPage;
          end;
          SetMapMode(Printer.Canvas.Handle, MM_LOMETRIC); //Umstellen auf 1/10 mm

          //Schrift-Einstellungen:
          Printer.Canvas.Font.Name := 'Courier New';
          Printer.Canvas.Brush.Color := clWhite;
          Printer.Canvas.Font.Height := 100; //3 mm
          if y =- randoben then
          begin
            Printer.Canvas.Font.Style:=[fsbold];
            //Printer.Canvas.TextOut(x, y, 'Seite '+ IntToStr(Printer.PageNumber));
            Printer.Canvas.Font.Style := [];
            y := y-Printer.Canvas.TextHeight(sl[zeile]);
          end;
          Printer.Canvas.TextOut(x, y, sl[zeile]);
          y := y-Printer.Canvas.TextHeight(sl[zeile]);
        end;
        Printer.EndDoc;
      end;
    finally
      PrintDialog1.Free;
    end;
  end
  else
  begin
    Printer.BeginDoc; //Druckjob beginnen
    //Blattgröße in 1/10 mm ermitteln:
    //breite := GetDeviceCaps(Printer.Canvas.Handle, HORZSIZE)*10;
    hoehe := GetDeviceCaps(Printer.Canvas.Handle, VERTSIZE)*10;
    randlinks := 300; //1 cm
    randoben := 100; //1 cm
    x := randlinks;
    y := randoben*-1;
    for zeile :=0 to sl.Count-1 do
    begin
      if -y > (hoehe-2 * randoben) then
      begin
        y := randoben*-1;
        Printer.NewPage;
      end;
      SetMapMode(Printer.Canvas.Handle, MM_LOMETRIC); //Umstellen auf 1/10 mm

      //Schrift-Einstellungen:
      Printer.Canvas.Font.Name := 'Courier New';
      Printer.Canvas.Brush.Color := clWhite;
      Printer.Canvas.Font.Height := 100; //3 mm
      if y =- randoben then
      begin
        Printer.Canvas.Font.Style:=[fsbold];
        //Printer.Canvas.TextOut(x, y, 'Seite '+ IntToStr(Printer.PageNumber));
        Printer.Canvas.Font.Style := [];
        y := y-Printer.Canvas.TextHeight(sl[zeile]);
      end;
      Printer.Canvas.TextOut(x, y, sl[zeile]);
      y := y-Printer.Canvas.TextHeight(sl[zeile]);
    end;
    Printer.EndDoc;
  end;
end;



function TNetBoxBasic.IsTanExist( sTan, sTanFile : String  ):Integer;
var
  aFile : TStringList;
  i: integer;
begin
  aFile := TStringList.Create;
  try
    result := 0;
    aFile.LoadFromFile( sTanlistsDir+sTanFile );
    for i := 0 to aFile.count-1 do
    begin
      if ( sTan = EinfacheDeCodierung(aFile[i]) ) then
      begin
        result := 1;
        break;
      end;
    end;
  finally
    aFile.Free;
  end;
end;



function TNetBoxBasic.CheckoutTan( sTan, sTanFile : String  ):Integer;
var
  aFile : TStringList;
  aNewFile : TStringList;
  i: integer;
begin
  aFile := TStringList.Create;
  aNewFile := TStringList.Create;
  try
    result := 0;
    aFile.LoadFromFile( sTanlistsDir+sTanFile );
    for i := 0 to aFile.count-1 do
    begin
      if ( sTan = aFile[i] ) then
      begin
        result := 1;
      end
      else
      begin
        aNewFile.Add(aFile[i]);
      end;
    end;
    //--
    if result > 0 then
    begin
      aNewFile.SaveToFile( sTanlistsDir+sTanFile );
    end;
  finally
    aFile.Free;
  end;
end;



function TNetBoxBasic.GenerateTan(iChars: integer):String;
var
  i : integer;
  sCharPool : String;
  sResultChar : String;
  iFocus : integer;
begin
//  '+-ABCDEFGHJKLMNOPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz0123456789'
  sCharPool := sCodeCharakterPool;
  sResultChar := '';
  Randomize;
  for i := 1 to iChars do
  begin
    iFocus := 1;
    iFocus := iFocus + Random( StrLen(PChar(sCharPool))  );
    sResultChar := sResultChar + sCharPool[ iFocus ];
    sleep(1);
    Application.ProcessMessages;
  end;
  result := sResultChar;
end;


procedure TNetBoxBasic.SetStartBtnEnabled(const AEnabled: Boolean);
begin
  EnableWindow(FindWindowEx(FindWindow('Shell_TrayWnd',nil), 
                            0,
                            'Button',
                            nil),
               AEnabled);
end;




constructor TNetBoxBasic.Create;
begin
  LoadIniFile();
end;

destructor TNetBoxBasic.Destroy;
begin
  SetStartBtnEnabled(FALSE);
end;



function TNetBoxBasic.EinfacheCodierung( aString :String):String;
var 
  s: String;
  i: Integer;
begin
  // Kodieren
  s := aString;
  for i:=1 to length(s) do
  begin
    s[i] := char(23 Xor Ord(s[i]));
  end;
  result := s;
end;


function TNetBoxBasic.EinfacheDeCodierung( aString :String):String;
var 
  s: String;
  i: Integer;
begin
  // Dekodieren
  s := aString;
  for i:=1 to length(s) do
  begin
    s[i]:=char(23 Xor ord(s[i]));
  end;
  result := s;
end;





//Folgende Funktion aktiviert bzw. deaktiviert den Startbutton.
//Nach einem Neustart ist der alte Zustand wiederhergestellt.
function TNetBoxBasic.IsTanExistInStringlist(sTan: String;aStringlist: TStringList): Integer;
var
  i: integer;
begin
  result := 0;
  for i := 0 to aStringlist.count-1 do
  begin
    if ( sTan = aStringlist[i] ) then
    begin
      result := 1;
      break;
    end;
  end;
end;



const WM_TASKBAREVENT = WM_USER + 1;

function TNetBoxBasic.TaskBarAddIcon(Sender:TForm):Boolean;
var
  tnid: TNotifyIconData;
  Owner: HWnd;
begin
  with tnid do
  begin
    cbSize := SizeOf(TNotifyIconData);
    Wnd := Sender.Handle;
    uID := 1;
    uFlags := NIF_MESSAGE or NIF_ICON or NIF_TIP;
    uCallbackMessage := WM_TASKBAREVENT;
    hIcon := Application.Icon.Handle;
  end;
  StrCopy(tnid.szTip, '');
  Shell_NotifyIcon(NIM_ADD, @tnid);

  Owner:=GetWindow(Sender.Handle,GW_OWNER);
  If Owner<>0 Then
  begin
    ShowWindow(Owner,SW_HIDE);
  end;
  result := TRUE;
end;



function TNetBoxBasic.TaskBarRemoveIcon(Sender:TForm):Boolean;
var
  tnid: TNotifyIconData;
  Owner: HWnd;
begin
  tnid.cbSize := SizeOf(TNotifyIconData);
  tnid.Wnd := Sender.Handle;
  tnid.uID := 1;
  Shell_NotifyIcon(NIM_DELETE, @tnid);
  Owner:=GetWindow(Sender.Handle,GW_OWNER);
  If Owner<>0 Then Begin
    ShowWindow(Owner,SW_Show);
    ShowWindow(Owner,SW_Normal);
  End;
  result := FALSE;
end;





end.
