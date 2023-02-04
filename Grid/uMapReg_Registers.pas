unit uMapReg_Registers;

interface

uses
  uMbRegs,
  //System.Generics.Collections,
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, 
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls, FMX.Layouts, FMX.Edit, FMX.ListBox,
  FMX.Controls.Presentation, uMapRegs;

type
  TfrmMapReg_Registers = class(TFrame)
    PanelLeft: TPanel;
    Splitter1: TSplitter;
    LayoutRmLevel: TLayout;
    Edit_RegViewStyle: TComboBox;
    ListBoxItem1: TListBoxItem;
    ListBoxItem2: TListBoxItem;
    ListBoxItem3: TListBoxItem;
    ListBoxItem4: TListBoxItem;
    Label16: TLabel;
    Layout1: TLayout;
    Label1: TLabel;
    Edit_ViewHex: TEdit;
    ScrollBox: TScrollBox;
    Layout2: TLayout;
    Label2: TLabel;
    Edit_ViewBin: TEdit;
    Layout3: TLayout;
    Label3: TLabel;
    Edit_ViewInt: TEdit;
    Layout4: TLayout;
    Label4: TLabel;
    Edit_ViewUInt: TEdit;
    Layout5: TLayout;
    Label5: TLabel;
    Edit_ViewFloat: TEdit;
    Layout6: TLayout;
    Label6: TLabel;
    Edit_ViewDInt: TEdit;
    Layout7: TLayout;
    Label7: TLabel;
    Edit_ViewDUInt: TEdit;
    ListBoxItem5: TListBoxItem;
    ListBoxItem6: TListBoxItem;
    ListBoxItem7: TListBoxItem;
    fmMapRegs: TfmMapRegs;
    procedure Edit_RegViewStyleChange(Sender: TObject);
  private
    getRegs: TFuncGetRegs;
    setRegs: TProcSetRegs;
    getReg:  TFuncGetReg;
    setReg:  TProcSetReg;
    procedure OnChangeRegAddr(const ARegAddr: UInt16);
    procedure OnGetRegText(const ARegAddr: UInt16; out Text: string);
    procedure OnEditReg(const ARegAddr: UInt16; const sRegAddr: string);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    property FuncGetRegs: TFuncGetRegs read getRegs write getRegs;
    property ProcSetRegs: TProcSetRegs read setRegs write setRegs;
    property FuncGetReg : TFuncGetReg  read getReg  write getReg;
    property ProcSetReg : TProcSetReg  read setReg  write setReg;
  end;

implementation

{$R *.fmx}

uses uTools, uEditReg, uMbBuf;

{ TfrmMapReg_Registers }

constructor TfrmMapReg_Registers.Create(AOwner: TComponent);
begin
  inherited;
  fmMapRegs.OnChangeRegAddr := OnChangeRegAddr;
  fmMapRegs.OnGetRegText := OnGetRegText;
  fmMapRegs.OnEditReg := OnEditReg;
end;

destructor TfrmMapReg_Registers.Destroy;
begin
  inherited;
end;

procedure TfrmMapReg_Registers.OnGetRegText(const ARegAddr: UInt16; out Text: string);
var i: Byte;
  u16: UInt16;
  i16: Int16 absolute u16;
  u16x2: array[1..2] of UInt16;
  u32: UInt32 absolute u16x2;
  i32: Int32 absolute u32;
  f32: Single absolute u32;
begin
  u16 := getReg(ARegAddr);
  case Edit_RegViewStyle.ItemIndex of
    0: // UInt
      begin
        Text := u16.ToString;
      end;
    1: // Int
      begin
        Text := i16.ToString;
      end;
    2: // HEX
      begin
        Text := u16.ToHexString(4);
      end;
    3: // BIN
      begin
        Text := '';
        for i:=0 to 15 do begin
          Text := Tools.iff<string>((u16 and ( 1 shl i ))>0, '1', '0') + Text;
          if(i<15)and((i mod 4)=3)then
            Text := '_' + Text;
        end;
      end;
  else
    begin
      Text := '-';
      if ARegAddr<$FFFF then begin
        u16x2[1] := u16;
        u16x2[2] := getReg(ARegAddr+1);
        case Edit_RegViewStyle.ItemIndex of
          4: //DUInt
            begin
              Text := u32.ToString;
            end;
          5: //DInt
            begin
              Text := i32.ToString;
            end;
          6: //FLOAT
            begin
              Text := f32.ToString;
            end;
        end;
      end;
    end
  end
end;

procedure TfrmMapReg_Registers.Edit_RegViewStyleChange(Sender: TObject);
begin
  fmMapRegs.fmGrid.Grid.repaint;
end;

procedure TfrmMapReg_Registers.OnChangeRegAddr(const ARegAddr: UInt16);
var
  u16: UInt16;
  i16: Int16 absolute u16;
  u16x2: array[1..2] of UInt16;
  u32: UInt32 absolute u16x2;
  i32: Int32 absolute u32;
  f32: Single absolute u32;
  hiVal: Boolean;
begin
  hiVal := ARegAddr<$FFFF;
  if hiVal then begin
    var b := getRegs(ARegAddr, 2);
    u16 := b[0];
    u16x2[1] := b[0];
    u16x2[2] := b[1];
  end else
    u16 := getReg(ARegAddr);

  Edit_ViewHex.Text := '-';
  Edit_ViewBin.Text := '-';
  Edit_ViewInt.Text := '-';
  Edit_ViewUInt.Text := '-';
  Edit_ViewDInt.Text := '-';
  Edit_ViewDUInt.Text := '-';
  Edit_ViewFloat.Text := '-';
  Edit_ViewHex.Text := u16.ToHexString(4);
  Edit_ViewInt.Text := i16.ToString;
  Edit_ViewUInt.Text := u16.ToString;
  Edit_ViewBin.Text := '';
  Edit_ViewBin.Text := uTools.WordToBin(u16);
  if hiVal then begin
    Edit_ViewDInt.Text := i32.ToString;
    Edit_ViewDUInt.Text := u32.ToString;
    Edit_ViewFloat.Text := f32.ToString;
  end;
end;

procedure TfrmMapReg_Registers.OnEditReg(const ARegAddr: UInt16; const sRegAddr: string);
var u1,u2: UInt16;
  hiVal: Boolean;
begin
  hiVal := ARegAddr<$FFFF;
  if hiVal then begin
    var b := getRegs(ARegAddr, 2);
    u1 := b[0];
    u2 := b[1];
  end else
    u1 := getReg(ARegAddr);
  if fEditReg.ShowModal(Edit_RegViewStyle.ItemIndex, sRegAddr, u1, hiVal, u2) then begin
    if hiVal then begin
      var b: TMBRegs;
      SetLength(b, 2);
      b[0] := u1;
      b[1] := u2;
      setRegs(b, ARegAddr);
    end else
      setReg(u1, ARegAddr);
    fmMapRegs.fmGrid.Grid.Repaint;
    fmMapRegs.RefreshCurrAddr;
  end;

end;

end.
