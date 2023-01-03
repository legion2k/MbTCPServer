unit uMbDecode;

interface

uses uMbBuf;
type
  TMbProcGetSetReg = reference to procedure(Write: Boolean; MBTable: TMBTable; RegAdr: UInt16; RegCnt: UInt16; var Buf: TMBBuf);

function ModbusServerParse(const PDU_in: TMBBuf; const MbProcGetSetReg: TMbProcGetSetReg; out PDU_out: TMBBuf): Boolean;

implementation

uses System.SysUtils, uTools;

function ModbusServerParse(const PDU_in: TMBBuf; const MbProcGetSetReg: TMbProcGetSetReg; out PDU_out: TMBBuf): Boolean;
var
  RegAdr, RegCnt, RegAdr2, RegCnt2, Mask_AND, Mask_OR: UInt16;
  N, ln: Integer;
  Buf: TMBBuf;
  ILLEGAL_DATA_ADDRESS: Boolean;
  ILLEGAL_DATA_VALUE: Boolean;
begin
  ILLEGAL_DATA_ADDRESS := False;
  ILLEGAL_DATA_VALUE := False;
  Result := False;
  PDU_out := '';
  Buf := '';
  ln := PDU_in.Count;
  if ln < 1 then
    Exit;

  case PDU_in.Item[0] of

    $01: begin // Read Coils
      ILLEGAL_DATA_VALUE := ln <> 5;
      if not ILLEGAL_DATA_VALUE then begin

        RegAdr := PDU_in.ItemW[1];
        RegCnt := PDU_in.ItemW[3];
        ILLEGAL_DATA_VALUE := (RegCnt = 0) or (RegCnt > 2000);
        if not ILLEGAL_DATA_VALUE then begin

          ILLEGAL_DATA_ADDRESS := (Uint32(RegAdr) + Uint32(RegCnt))>$FFFF;
          if not ILLEGAL_DATA_ADDRESS then begin

            MbProcGetSetReg(False, mb_0х, RegAdr, RegCnt, Buf);
            ln := divCeil(RegCnt, 8);
            PDU_out := PDU_in[0] + TMBChar(ln) + Buf;
            Result := true;
          end
        end
      end
    end;

    $02: begin // Read Discrete Inputs
      ILLEGAL_DATA_VALUE := ln <> 5;
      if not ILLEGAL_DATA_VALUE then begin

        RegAdr := PDU_in.ItemW[1];
        RegCnt := PDU_in.ItemW[3];
        ILLEGAL_DATA_ADDRESS := (RegCnt = 0) or (RegCnt > 2000);
        if not ILLEGAL_DATA_VALUE then begin

          ILLEGAL_DATA_ADDRESS := (Uint32(RegAdr) + Uint32(RegCnt))>$FFFF;
          if not ILLEGAL_DATA_ADDRESS then begin

            MbProcGetSetReg(False, mb_1х, RegAdr, RegCnt, Buf);
            ln := divCeil(RegCnt, 8);
            PDU_out := PDU_in[0] + TMBChar(ln) + Buf;
            Result := true;
          end
        end;
      end
    end;

    $03: begin // Read Holding Registers
      ILLEGAL_DATA_VALUE := ln <> 5;
      if not ILLEGAL_DATA_VALUE then begin

        RegAdr := PDU_in.ItemW[1];
        RegCnt := PDU_in.ItemW[3];
        ILLEGAL_DATA_ADDRESS := (RegCnt = 0) or (RegCnt > 125);
        if not ILLEGAL_DATA_VALUE then begin

          ILLEGAL_DATA_ADDRESS := (Uint32(RegAdr) + Uint32(RegCnt))>$FFFF;
          if not ILLEGAL_DATA_ADDRESS then begin

            MbProcGetSetReg(False, mb_4х, RegAdr, RegCnt, Buf);
            PDU_out := PDU_in[0] + TMBChar(RegCnt * 2) + Buf;
            Result := true;
          end
        end
      end
    end;

    $04: begin // Read Input Registers
      ILLEGAL_DATA_VALUE := ln <> 5;
      if not ILLEGAL_DATA_VALUE then begin

        RegAdr := PDU_in.ItemW[1];
        RegCnt := PDU_in.ItemW[3];
        ILLEGAL_DATA_ADDRESS := (RegCnt = 0) or (RegCnt > 125);
        if not ILLEGAL_DATA_VALUE then begin

          ILLEGAL_DATA_ADDRESS := (Uint32(RegAdr) + Uint32(RegCnt))>$FFFF;
          if not ILLEGAL_DATA_ADDRESS then begin

            MbProcGetSetReg(False, mb_3х, RegAdr, RegCnt, Buf);
            PDU_out := PDU_in[0] + TMBChar(RegCnt * 2) + Buf;
            Result := true;
          end;
        end;
      end;
    end;

    $05: begin // Write Single Coil
      ILLEGAL_DATA_VALUE := ln <> 5;
      if not ILLEGAL_DATA_VALUE then begin
        Mask_AND := PDU_in.ItemW[3];
        ILLEGAL_DATA_VALUE  := not((Mask_AND=0) or (Mask_AND=$FF00));
        if not ILLEGAL_DATA_VALUE then begin
          RegAdr := PDU_in.ItemW[1];
          RegCnt := 1;
          Buf.Count := 1;
          Buf.ItemB[0] := Mask_AND <> 0;

          MbProcGetSetReg(true, mb_0х, RegAdr, RegCnt, Buf);
          PDU_out := PDU_in;
          Result := true;
        end;
      end;
    end;

    $06: begin // Write Single Register
      ILLEGAL_DATA_VALUE := ln <> 5;
      if not ILLEGAL_DATA_VALUE then begin
        RegAdr := PDU_in.ItemW[1];
        RegCnt := 1;
        Buf := PDU_in.Copy(3,2);

        MbProcGetSetReg(true, mb_4х, RegAdr, RegCnt, Buf);
        PDU_out := PDU_in;
        Result := true;
      end;
    end;

    // #$07:
    // #$08:
    // #$0B:
    // #$0C:

    $0F: begin // Write Multiple Coils
      ILLEGAL_DATA_VALUE := ln < 7;
      if not ILLEGAL_DATA_VALUE then begin

        N := PDU_in.Item[5];// колтчесто байт
        RegCnt := PDU_in.ItemW[3]; // количество Coli-ов
        ILLEGAL_DATA_VALUE := (ln <> N + 6) or (divCeil(RegCnt, 8)<>N);
        if not ILLEGAL_DATA_VALUE then begin

          RegAdr := PDU_in.ItemW[1];
          ILLEGAL_DATA_ADDRESS := (Uint32(RegAdr) + Uint32(RegCnt))>$FFFF;
          if not ILLEGAL_DATA_ADDRESS then begin

            Buf := PDU_in.Copy(6, N);
            MbProcGetSetReg(true, mb_0х, RegAdr, RegCnt, Buf);
            PDU_out := PDU_in.copy(0, 5);//PDU_in[0] + PDU_in[1] + PDU_in[2] + PDU_in[3] + PDU_in[4];
            Result := true;
          end;
        end;
      end;
    end;

    $10: begin // Write Multiple registers
      ILLEGAL_DATA_VALUE := ln < 8;
      if not ILLEGAL_DATA_VALUE then begin

        N := PDU_in.Item[5];// колтчесто байт
        RegCnt := PDU_in.ItemW[3]; // количество регистров
        ILLEGAL_DATA_VALUE := (ln <> N + 6) or ((RegCnt*2)<>N);
        if not ILLEGAL_DATA_VALUE then begin

          RegAdr := PDU_in.ItemW[1];
          ILLEGAL_DATA_ADDRESS := (Uint32(RegAdr) + Uint32(RegCnt))>$FFFF;
          if not ILLEGAL_DATA_ADDRESS then begin

            Buf := PDU_in.Copy(6, N);
            MbProcGetSetReg(true, mb_4х, RegAdr, RegCnt, Buf);
            PDU_out := PDU_in.copy(0, 5);//PDU_in[0] + PDU_in[1] + PDU_in[2] + PDU_in[3] + PDU_in[4];
            Result := true;
          end;
        end;
      end;
    end;

    // #$11:
    // #$14:
    // #$15:

    $16: begin // Mask Write Register
      ILLEGAL_DATA_VALUE := ln <> 7;
      if not ILLEGAL_DATA_VALUE then begin
        RegAdr := PDU_in.ItemW[1];
        MbProcGetSetReg(False, mb_4х, RegAdr, 1, Buf);

        Mask_AND := PDU_in.ItemW[3];
        Mask_OR :=  PDU_in.ItemW[5];

        Buf.ItemW[0] := (Buf.ItemW[0] and Mask_AND) OR (Mask_OR and (not Mask_AND));

        MbProcGetSetReg(true, mb_4х, RegAdr, 1, Buf);
        PDU_out := PDU_in;
        Result := true;
      end;
    end;

    $17: begin // Read/Write Multiple registers
      ILLEGAL_DATA_VALUE := ln < 12;
      if not ILLEGAL_DATA_VALUE then begin

        // Операция записи выполняется перед чтением.
        RegAdr  := PDU_in.ItemW[1];
        RegCnt  := PDU_in.ItemW[3];
        RegAdr2 := PDU_in.ItemW[5];
        RegCnt2 := PDU_in.ItemW[7];
        N       := PDU_in.Item [9];
        ILLEGAL_DATA_VALUE := (ln <> N + 10) or (RegCnt = 0) or (RegCnt > 125) or (RegCnt2 = 0) or (RegCnt2 > 125);
        if not ILLEGAL_DATA_VALUE then begin

          ILLEGAL_DATA_ADDRESS := ((Uint32(RegAdr) + Uint32(RegCnt))>$FFFF) or ((Uint32(RegAdr2) + Uint32(RegCnt2))>$FFFF);
          // Операция записи выполняется перед чтением.
          if not ILLEGAL_DATA_VALUE then begin

            // write
            buf := PDU_in.Copy(10,N);
            MbProcGetSetReg(true, mb_4х, RegAdr2, RegCnt2, Buf);

            // read
            MbProcGetSetReg(False, mb_4х, RegAdr, RegCnt, Buf);
            PDU_out := PDU_in[0] + TMBChar(RegCnt * 2) + Buf;

            Result := true;
          end;
        end;
      end;
    end;

    // #$18:
    // #$2B:

  else
    PDU_out := TMBChar(PDU_in.Item[0] or $80) + TMBChar(#$01); // ILLEGAL FUNCTION
  end;

  if ILLEGAL_DATA_ADDRESS then
    PDU_out := TMBChar(PDU_in.Item[0] or $80) + TMBChar(#$02) // ILLEGAL DATA ADDRESS
  else
  if ILLEGAL_DATA_VALUE then
    PDU_out := TMBChar(PDU_in.Item[0] or $80) + TMBChar(#$03) // ILLEGAL DATA VALUE
end;

end.
