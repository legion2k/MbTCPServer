unit uMbBuf;

interface

type
  // ------------------------------------------------------------------------------------------------------------------
  TMBTable = (mb_4х, mb_3х, mb_1х, mb_0х);
  // ------------------------------------------------------------------------------------------------------------------
  TMBString = AnsiString;
  TMBChar   = AnsiChar;
  //
  TMBChars = array of TMBChar;
  TMBBytes = array of UInt8;
  //
  TMBReg = UInt16;
  TMBRegs = array of TMBReg;
  //
  TMBDiscret = Boolean;
  TMBDiscrets = array of TMBDiscret;
  // ------------------------------------------------------------------------------------------------------------------
  TMBBuf = record
    class operator Implicit(const Val: TMBBuf): TMBString;
    class operator Implicit(const Val: TMBBuf): TMBBytes;
    //
    class operator Implicit(const Val: Byte): TMBBuf;
    class operator Implicit(const Val: TMBChar): TMBBuf;
    class operator Implicit(const Val: TMBString): TMBBuf;
    class operator Implicit(const Val: TMBReg): TMBBuf;
    class operator Implicit(Val: TMBBytes): TMBBuf;
    class operator Implicit(const Val: TMBChars): TMBBuf;
    //
    class operator Implicit(const Val: TMBBuf): TMBRegs;
    class operator Implicit(const Val: TMBRegs): TMBBuf;
    //
    class operator Implicit(const Val: TMBDiscrets): TMBBuf;
    function AsDiscrets(Count: UInt16): TMBDiscrets;
    //
    class operator Add(const A: TMBBuf; const B: TMBBuf): TMBBuf;
  private
    Buf: TMBString;
    procedure SET_Item(Index: UInt16; const Val: UInt8);
    function GET_Item(Index: UInt16): UInt8;

    procedure SET_ItemC(Index: UInt16; const Val: TMBChar);
    function GET_ItemC(Index: UInt16): TMBChar;

    procedure SET_ItemW(Index: UInt16; const Val: TMBReg);
    function GET_ItemW(Index: UInt16): TMBReg;

    procedure SET_ItemF(Index: UInt32; const Val: Boolean);
    function GET_ItemF(Index: UInt32): Boolean;

    function GET_Count: UInt16;
    procedure SET_Count(Val: UInt16);
  public
    // property Data: TMbBuf.TBufString read Buf;
    //
    property Item [Index: UInt16]: UInt8   read GET_Item  write SET_Item;
    property ItemC[Index: UInt16]: TMBChar read GET_ItemC write SET_ItemC; default;
    property ItemW[Index: UInt16]: TMBReg  read GET_ItemW write SET_ItemW;
    property ItemB[Index: UInt32]: Boolean read GET_ItemF write SET_ItemF;
    property Count: UInt16                 read GET_Count write SET_Count;
    function Copy(Index: UInt16; Count: UInt16): TMBString;
  end;

  // ------------------------------------------------------------------------------------------------------------------
function CRC16(Data: AnsiString): UInt16;

implementation
uses System.SysUtils, uTools;

//----------------------------------------------------------------------------------------------------------------------
function CRC16(Data: AnsiString): UInt16;
const
  Polinominal = $A001;
var
  i, j, cnt: Integer;
begin
  Result := $FFFF;
  cnt := length(Data) + 1;
  i := 1;
  while i < cnt do
  begin
    Result := (Result and $FF00) or (Lo(Result) xor ord(Data[i]));
    for j := 1 to 8 do
    begin
      if (Result and $0001) <> 0 then Result := (Result shr 1) xor Polinominal
      else Result := Result shr 1;
    end;
    inc(i);
  end;
end;

//----------------------------------------------------------------------------------------------------------------------
//----------------------------------------------------------------------------------------------------------------------
{ TMbBuf }
//----------------------------------------------------------------------------------------------------------------------
//----------------------------------------------------------------------------------------------------------------------
// ---------------------------------------------------------------------
class operator TMBBuf.Implicit(const Val: TMBBuf): TMBString;
begin
  Result := Val.Buf;
end;
// ---------------------------------------------------------------------
class operator TMBBuf.Implicit(const Val: TMBBuf): TMBBytes;
begin
  Result := TMBBytes(BytesOf(Val.Buf))
  //Result := TMBBytes(Val.Buf)
end;
// ---------------------------------------------------------------------
class operator TMBBuf.Implicit(const Val: Byte): TMBBuf;
begin
  Result.Buf := TMBChar(Val);
end;

// ---------------------------------------------------------------------
class operator TMBBuf.Implicit(const Val: TMBChar): TMBBuf;
begin
  Result.Buf := Val;
end;

// ---------------------------------------------------------------------
class operator TMBBuf.Implicit(const Val: TMBString): TMBBuf;
begin
  Result.Buf := Val;
end;

// ---------------------------------------------------------------------
class operator TMBBuf.Implicit(const Val: TMBReg): TMBBuf;
begin
  Result.Count := 2;
  Result.ItemW[0] := Val;
end;

class operator TMBBuf.Implicit(const Val: TMBRegs): TMBBuf;
var lng: Integer;
  //buf: TMBBytes;
begin
  lng := Length(Val);
//  buf := TMBBytes(Val);
//  buf := System.Copy(buf, 0, lng*2);
  Result.Count := lng*2;
  while lng>0 do begin
    Dec(lng);
    Result.ItemW[lng*2] := Val[lng];
  end;
end;

class operator TMBBuf.Implicit(const Val: TMBBuf): TMBRegs;
var lng: Integer;
  //buf: TMBRegs;
begin
  lng := Length(Val.Buf);
//  buf := TMBRegs(TMBBytes(Val.Buf));
//  buf := System.Copy(buf, 0, lng div 2);
  lng := lng div 2;
  SetLength(Result, lng);
  while lng>0 do begin
    Dec(lng);
    Result[lng] := Val.ItemW[lng*2];
  end;
end;

// ---------------------------------------------------------------------
class operator TMBBuf.Implicit(const Val: TMBDiscrets): TMBBuf;
var l: Integer;
begin
  l := Length(Val);
  Result.Count := divCeil(l, 8);
  while l>0 do begin
    Dec(l);
    Result.ItemB[l] := Val[l]
  end;
end;

function TMBBuf.AsDiscrets(Count: UInt16): TMBDiscrets;
begin
  SetLength(Result, Count);
  while count>0 do begin
    Dec(Count);
    Result[Count] := ItemB[Count];
  end;
end;

// ---------------------------------------------------------------------
class operator TMBBuf.Implicit(const Val: TMBChars): TMBBuf;
begin
  Result := TMBBytes(Val);
end;

class operator TMBBuf.Implicit(Val: TMBBytes): TMBBuf;
begin
  Result.buf := TMBString(StringOf(TBytes(val)));
end;

//----------------------------------------------------------------------------------------------------------------------
class operator TMBBuf.Add(const A: TMBBuf; const B: TMBBuf): TMBBuf;
begin
  Result := A.Buf + B.Buf;
end;
//----------------------------------------------------------------------------------------------------------------------
//----------------------------------------------------------------------------------------------------------------------
//----------------------------------------------------------------------------------------------------------------------
function TMBBuf.GET_Count: UInt16;
begin
  Result := length(Buf);
end;

procedure TMBBuf.SET_Count(Val: UInt16);
begin
  SetLength(Buf, Val);
  FillChar(Buf[1], Val, #0);
end;

// ---------------------------------------------------------------------
function TMBBuf.GET_ItemC(Index: UInt16): TMBChar;
begin
  Result := Buf[integer(Index) + 1];
end;

procedure TMBBuf.SET_ItemC(Index: UInt16; const Val: TMBChar);
begin
  Buf[integer(Index) + 1] := Val;
end;

// ---------------------------------------------------------------------
function TMBBuf.GET_Item(Index: UInt16): UInt8;
begin
  Result := UInt8(Buf[integer(Index) + 1]);
end;

procedure TMBBuf.SET_Item(Index: UInt16; const Val: UInt8);
begin
  Buf[integer(Index) + 1] := TMBChar(Val);
end;

// ---------------------------------------------------------------------
function TMBBuf.GET_ItemW(Index: UInt16): TMBReg;
var v: array[0..1] of TMBChar absolute Result;
begin
  //Result := Item[Index] * $100 + Item[Index + 1];
  // сначала старший потом младший
  v[1] := ItemC[Index    ];
  v[0] := ItemC[Index + 1];
end;

procedure TMBBuf.SET_ItemW(Index: UInt16; const Val: TMBReg);
var v: array[0..1] of TMBChar absolute Val;
begin
  // сначала старший потом младший
  ItemC[Index    ] := v[1];
  ItemC[Index + 1] := v[0];
end;

// ---------------------------------------------------------------------
function TMBBuf.GET_ItemF(Index: UInt32): Boolean;
begin
  Result := GetBit(Item[Index div 8], Index mod 8);
end;

procedure TMBBuf.SET_ItemF(Index: UInt32; const Val: Boolean);
var b: Byte;
  i: UInt16;
begin
  i := Index div 8;
  b := Item[i];
  SetBit(b, Val, Index mod 8);
  Item[i] := b;
end;

//----------------------------------------------------------------------------------------------------------------------
function TMBBuf.Copy(Index, Count: UInt16): TMBString;
begin
  Result := TMBBuf(system.copy(TMBBytes(Buf), integer(Index), Count))
end;

//----------------------------------------------------------------------------------------------------------------------
end.
