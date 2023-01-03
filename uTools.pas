unit uTools;

interface

type
  Tools = class
  public
    class function iff<T>(Condition: Boolean; TrueVal: T; FalseVal: T): T; static;
  end;

Function BytesToHex(const Bytes: AnsiString; const HexFormat: string = '$%.2X '): string;
//
function BoolToStr(val: Boolean; sFalse: string; sTrue: string): string;
//
procedure SetBit(var Data: UInt8; Value: Boolean; BitIndex_0_7: Byte); overload;
procedure SetBit(var Data: UInt16; Value: Boolean; BitIndex_0_15: Byte); overload;
function GetBit(const Data: UInt8; BitIndex_0_7: Byte): Boolean; overload;
function GetBit(const Data: UInt16; BitIndex_0_15: Byte): Boolean; overload;
function WordToBin(const Data: UInt16): string;

function divCeil(x, y: Integer): Integer;

function WordToDWord(Lo: UInt16; Hi: UInt16): UInt32;

implementation

uses System.SysUtils;

{ Tools }

class function Tools.iff<T>(Condition: Boolean; TrueVal, FalseVal: T): T;
begin
  if Condition then
    Result := TrueVal
  else
    Result := FalseVal;
end;

// ------------------------------------------------------------------------------------------------------------------
function divCeil(x, y: Integer): Integer;
begin
  Result := x div y;
  if (x mod y)<>0 then
    Inc(Result);
end;

function BoolToStr(val: Boolean; sFalse: string; sTrue: string): string;
begin
  if val then
    Result := sTrue
  else
    Result := sFalse;
end;

// ------------------------------------------------------------------------------------------------------------------
Function BytesToHex;
var
  i, c: Integer;
begin
  c := length(Bytes);
  Result := '';
  i := 1;
  while i <= c do begin
    Result := Result + Format(HexFormat, [ord(Bytes[i])]);
    inc(i);
  end
end;
// ------------------------------------------------------------------------------------------------------------------

function GetBit(const Data: UInt8; BitIndex_0_7: Byte): Boolean;
var
  d: UInt16;
begin
  if BitIndex_0_7 > 7 then
    raise Exception.Create('Биты указываются в диапозоне от 0 до 7')
  else begin
    d := 1 shl BitIndex_0_7;
    Result := (Data and d) > 0;
  end;
end;
function GetBit(const Data: UInt16; BitIndex_0_15: Byte): Boolean;
var
  d: UInt16;
begin
  if BitIndex_0_15 > 15 then
    raise Exception.Create('Биты указываются в диапозоне от 0 до 15')
  else begin
    d := 1 shl BitIndex_0_15;
    Result := (Data and d) > 0;
  end;
end;
// ------------------------------------------------------------------------------------------------------------------

procedure SetBit(var Data: UInt8; Value: Boolean; BitIndex_0_7: Byte);
var
  d: UInt16;
begin
  if BitIndex_0_7 > 7 then
    raise Exception.Create('Биты указываются в диапозоне от 0 до 7')
  else begin
    d := 1 shl BitIndex_0_7;
    if Value then
      Data := Data or d
    else
      Data := Data and (not d);
  end;
end;
procedure SetBit(var Data: UInt16; Value: Boolean; BitIndex_0_15: Byte);
var
  d: UInt16;
begin
  if BitIndex_0_15 > 15 then
    raise Exception.Create('Биты указываются в диапозоне от 0 до 15')
  else begin
    d := 1 shl BitIndex_0_15;
    if Value then
      Data := Data or d
    else
      Data := Data and (not d);
  end;
end;
// ------------------------------------------------------------------------------------------------------------------

function WordToBin;
var
  i: Byte;
begin
  Result := '';
  for i := 0 to 15 do begin
    Result := IntToStr(Integer(GetBit(Data, i))) + Result;
    if (((i + 1) mod 4) = 0) and (not(i in [0, 15])) then
      Result := '_' + Result;
  end;
end;
// ------------------------------------------------------------------------------------------------------------------

function WordToDWord(Lo: UInt16; Hi: UInt16): UInt32;
begin
  Result := Lo + Hi * $10000;
end;

end.
