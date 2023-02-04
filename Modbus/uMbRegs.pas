unit uMbRegs;

interface
uses uMbBuf;

procedure MBReg(Write: Boolean; MBTable: TMBTable; RegAdr, RegCnt: UInt16; var Buf: TMBBuf);

function getRegs4x(RegAdr, RegCnt: UInt32): TMBRegs;
function getRegs3x(RegAdr, RegCnt: UInt32): TMBRegs;
function getRegs1x(RegAdr, RegCnt: UInt32): TMBDiscrets;
function getRegs0x(RegAdr, RegCnt: UInt32): TMBDiscrets;

procedure setRegs4x(const Data: TMBRegs; RegAdr: UInt16);
procedure setRegs3x(const Data: TMBRegs; RegAdr: UInt16);
procedure setRegs1x(const Data: TMBDiscrets; RegAdr: UInt16);
procedure setRegs0x(const Data: TMBDiscrets; RegAdr: UInt16);

function getReg4x(RegAdr: UInt16): TMBReg;
function getReg3x(RegAdr: UInt16): TMBReg;
function getReg1x(RegAdr: UInt16): TMBDiscret;
function getReg0x(RegAdr: UInt16): TMBDiscret;

procedure setReg4x(Data: TMBReg; RegAdr: UInt16);
procedure setReg3x(Data: TMBReg; RegAdr: UInt16);
procedure setReg1x(Data: TMBDiscret; RegAdr: UInt16);
procedure setReg0x(Data: TMBDiscret; RegAdr: UInt16);


type
  //TMBRegs = uMbBuf.TMBRegs;
  TFuncGetRegs = reference to function (RegAdr, RegCnt: UInt32): TMBRegs;
  TProcSetRegs = reference to procedure(const Data: TMBRegs; RegAdr: UInt16);

  TFuncGetReg = reference to function (RegAdr: UInt16): TMBReg;
  TProcSetReg = reference to procedure(Data: TMBReg; RegAdr: UInt16);

  TFuncGetDiscrets = reference to function (RegAdr, RegCnt: UInt32): TMBDiscrets;
  TProcSetDiscrets = reference to procedure(const Data: TMBDiscrets; RegAdr: UInt16);

  TFuncGetDiscret = reference to function (RegAdr: UInt16): TMBDiscret;
  TProcSetDiscret = reference to procedure(Data: TMBDiscret; RegAdr: UInt16);
implementation
uses System.SyncObjs, System.Classes, System.SysUtils, uMain;

const
  SizeOF_TMBReg = SizeOf(TMBReg);
  SizeOF_TMBDiscret = SizeOf(TMBDiscret);

var
  lock4x, lock3x, lock1x, lock0x: TCriticalSection;
  reg4x: TMBRegs;
  reg3x: TMBRegs;
  reg1x: TMBDiscrets;
  reg0x: TMBDiscrets;

//----------------------------------------------------------------------------------------------------------------------
function getRegs4x(RegAdr, RegCnt: UInt32): TMBRegs;
begin
  if RegCnt>$10_000 then raise EArgumentOutOfRangeException.Create('RegCnt Argument Out Of Range ');
  lock4x.Acquire;
  Result := copy(reg4x, RegAdr, RegCnt);
  lock4x.Release;
end;
function getRegs3x(RegAdr, RegCnt: UInt32): TMBRegs;
begin
  if RegCnt>$10_000 then raise EArgumentOutOfRangeException.Create('RegCnt Argument Out Of Range ');
  lock3x.Acquire;
  Result := copy(reg3x, RegAdr, RegCnt);
  lock3x.Release;
end;
function getRegs1x(RegAdr, RegCnt: UInt32): TMBDiscrets;
begin
  if RegCnt>$10_000 then raise EArgumentOutOfRangeException.Create('RegCnt Argument Out Of Range ');
  lock1x.Acquire;
  Result := copy(reg1x, RegAdr, RegCnt);
  lock1x.Release;
end;
function getRegs0x(RegAdr, RegCnt: UInt32): TMBDiscrets;
begin
  if RegCnt>$10_000 then raise EArgumentOutOfRangeException.Create('RegCnt Argument Out Of Range ');
  lock0x.Acquire;
  Result := copy(reg0x, RegAdr, RegCnt);
  lock0x.Release;
end;

//----------------------------------------------------------------------------------------------------------------------
function getReg4x(RegAdr: UInt16): TMBReg;
begin
  lock4x.Acquire;
  Result := reg4x[RegAdr];
  lock4x.Release;
end;
function getReg3x(RegAdr: UInt16): TMBReg;
begin
  lock3x.Acquire;
  Result := reg3x[RegAdr];
  lock3x.Release;
end;
function getReg1x(RegAdr: UInt16): TMBDiscret;
begin
  lock1x.Acquire;
  Result := reg1x[RegAdr];
  lock1x.Release;
end;
function getReg0x(RegAdr: UInt16): TMBDiscret;
begin
  lock0x.Acquire;
  Result := reg0x[RegAdr];
  lock0x.Release;
end;

//----------------------------------------------------------------------------------------------------------------------

procedure setRegs4x(const Data: TMBRegs; RegAdr: UInt16);
var i: Integer;
begin
  i := Length(Data);
  if i>0 then begin
    lock4x.Acquire;
    try
      Move(Data[0], reg4x[ RegAdr ], i*SizeOF_TMBReg);
    finally
      lock4x.Release;
    end;
  end;
end;

procedure setRegs3x(const Data: TMBRegs; RegAdr: UInt16);
var i: Integer;
begin
  i := Length(Data);
  if i>0 then begin
    lock3x.Acquire;
    try
      Move(Data[0], reg3x[ RegAdr ], i*SizeOF_TMBReg);
    finally
      lock3x.Release;
    end;
  end;
end;

procedure setRegs1x(const Data: TMBDiscrets; RegAdr: UInt16);
var i: Integer;
begin
  i := Length(Data);
  if i>0 then begin
    lock1x.Acquire;
    try
      Move(Data[0], reg1x[ RegAdr ], i*SizeOF_TMBDiscret);
    finally
      lock1x.Release;
    end;
  end;
end;

procedure setRegs0x(const Data: TMBDiscrets; RegAdr: UInt16);
var i: Integer;
begin
  i := Length(Data);
  if i>0 then begin
    lock0x.Acquire;
    try
      Move(Data[0], reg0x[ RegAdr ], i*SizeOF_TMBDiscret);
    finally
      lock0x.Release;
    end;
  end;
end;

//----------------------------------------------------------------------------------------------------------------------
procedure setReg4x(Data: TMBReg; RegAdr: UInt16);
begin
  lock4x.Acquire;
  reg4x[ RegAdr ] := Data;
  lock4x.Release;
end;
procedure setReg3x(Data: TMBReg; RegAdr: UInt16);
begin
  lock3x.Acquire;
  reg3x[ RegAdr ] := Data;
  lock3x.Release;
end;
procedure setReg1x(Data: TMBDiscret; RegAdr: UInt16);
begin
  lock1x.Acquire;
  reg1x[ RegAdr ] := Data;
  lock1x.Release;
end;
procedure setReg0x(Data: TMBDiscret; RegAdr: UInt16);
begin
  lock0x.Acquire;
  reg0x[ RegAdr ] := Data;
  lock0x.Release;
end;

//----------------------------------------------------------------------------------------------------------------------
procedure MBReg(Write: Boolean; MBTable: TMBTable; RegAdr, RegCnt: UInt16; var Buf: TMBBuf);
begin
  case MBTable of
    //--------------------------
    mb_4х: begin
      if not Write then begin
        Buf := TMBBuf(getRegs4x(RegAdr, RegCnt));
      end else begin
        var b := TMBRegs(Buf);
        setRegs4x( b, RegAdr);
        TThread.Synchronize( TThread.CurrentThread , procedure begin
          with fMain.frmMapReg_4x do begin
            fmMapRegs.fmGrid.Grid.Repaint;
            fmMapRegs.RefreshCurrAddr;
          end;
        end);
      end;
    end;
    // --------------------------
    mb_3х: begin
      if not Write then begin
        Buf := TMBBuf(getRegs3x(RegAdr, RegCnt));
      end else begin
        var b := TMBRegs(Buf);
        setRegs3x( b, RegAdr);
        TThread.Synchronize( TThread.CurrentThread , procedure begin
          with fMain.frmMapReg_3x do begin
            fmMapRegs.fmGrid.Grid.Repaint;
            fmMapRegs.RefreshCurrAddr;
          end;
        end);
      end;
    end;
    // --------------------------
    mb_1х: begin
      if not Write then begin
        Buf := TMBBuf(getRegs1x(RegAdr, RegCnt));
      end else begin
        var b := Buf.AsDiscrets(RegCnt); //TMBDiscrets(Buf);
        setRegs1x( b, RegAdr);
        TThread.Synchronize( TThread.CurrentThread , procedure begin
          fMain.frmMapReg_1x.fmMapRegs.fmGrid.Grid.Repaint;
        end);

      end;
    end;
    // --------------------------
    mb_0х: begin
      if not Write then begin
        Buf := TMBBuf(getRegs0x(RegAdr, RegCnt));
      end else begin
        var b := Buf.AsDiscrets(RegCnt); //TMBDiscrets(Buf);
        setRegs0x( b, RegAdr);
        TThread.Synchronize( TThread.CurrentThread , procedure begin
          fMain.frmMapReg_0x.fmMapRegs.fmGrid.Grid.Repaint;
        end);
      end;
    end;
    // --------------------------
  end;
end;

initialization
  SetLength(reg4x, $10_000);
  SetLength(reg3x, $10_000);
  SetLength(reg1x, $10_000);
  SetLength(reg0x, $10_000);
  lock4x := TCriticalSection.Create;
  lock3x := TCriticalSection.Create;
  lock1x := TCriticalSection.Create;
  lock0x := TCriticalSection.Create;
finalization
  lock4x.Free;
  lock3x.Free;
  lock1x.Free;
  lock0x.Free;
end.
