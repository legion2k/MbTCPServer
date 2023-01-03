unit uEditReg;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Controls.Presentation, FMX.StdCtrls, FMX.Layouts,
  FMX.Edit, FMX.EditBox, FMX.SpinBox, FMX.NumberBox, uEditHex, uEditFloat;

type
  TfEditReg = class(TForm)
    Panel1: TPanel;
    SpeedButton1: TSpeedButton;
    SpeedButton2: TSpeedButton;
    SpeedButton3: TSpeedButton;
    SpeedButton4: TSpeedButton;
    SpeedButton5: TSpeedButton;
    SpeedButton6: TSpeedButton;
    SpeedButton7: TSpeedButton;
    SpeedButton8: TSpeedButton;
    SpeedButton9: TSpeedButton;
    SpeedButton10: TSpeedButton;
    SpeedButton11: TSpeedButton;
    SpeedButton12: TSpeedButton;
    SpeedButton13: TSpeedButton;
    SpeedButton14: TSpeedButton;
    SpeedButton15: TSpeedButton;
    SpeedButton16: TSpeedButton;
    Layout1: TLayout;
    ButtonOk: TButton;
    ButtonCancel: TButton;
    Layout_Hex: TLayout;
    Label1: TLabel;
    Layout_Int: TLayout;
    Label3: TLabel;
    Layout_UInt: TLayout;
    Label4: TLabel;
    Layout_Float: TLayout;
    Label_Float: TLabel;
    Layout_DInt: TLayout;
    Label_DInt: TLabel;
    Layout_DUInt: TLayout;
    Label_DUInt: TLabel;
    Edit_Int: TSpinBox;
    Edit_UInt: TSpinBox;
    Edit_DInt: TSpinBox;
    Edit_DUInt: TSpinBox;
    Edit_Hex: TfmEditHex;
    Edit_Float: TfmEditFloat;
    procedure ClickOnBit(Sender: TObject);
    procedure Edit_UIntChange(Sender: TObject);
    procedure Edit_IntChange(Sender: TObject);
    procedure Edit_DUIntChange(Sender: TObject);
    procedure Edit_DIntChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
    Value: UInt16;
    fValueHi: Boolean;
    ValueHi: UInt16;
    fUpdating: Boolean;
    procedure UpdateVal(Sender:TObject=nil);
    procedure Edit_HexChange(Sender: TObject);
    procedure Edit_FloatChange(Sender: TObject);
  public
    { Public declarations }
    function ShowModal(SetActive: UInt8; Index: string; var Value: UInt16; fValueHi: Boolean; var ValueHi: UInt16): Boolean; overload;
  end;

var
  fEditReg: TfEditReg;

implementation

{$R *.fmx}

uses uMain, uTools;

{ TfEditReg }

procedure TfEditReg.FormCreate(Sender: TObject);
begin
  Edit_Hex.OnChange := Edit_HexChange;
  Edit_Hex.Min := 0;
  Edit_Hex.Max := $FFFF;
  Edit_Float.OnChange := Edit_FloatChange;
  Edit_Float.Min := 0;
  Edit_Float.Max := 0;
end;

function TfEditReg.ShowModal(SetActive: UInt8; Index: string; var Value: UInt16; fValueHi: Boolean; var ValueHi: UInt16): Boolean;
begin
  Self.Value := Value;
  Self.fValueHi := fValueHi;
  Self.ValueHi := ValueHi;
  Caption := Format('Адресс регистра %s', [Index]);
  Edit_DUInt.Enabled := fValueHi;
  Edit_DInt.Enabled := fValueHi;
  Edit_float.Enabled := fValueHi;
  Label_DUInt.Enabled := fValueHi;
  Label_DInt.Enabled := fValueHi;
  Label_Float.Enabled := fValueHi;
  Layout_DUInt.Enabled := fValueHi;
  Layout_DInt.Enabled := fValueHi;
  Layout_Float.Enabled := fValueHi;
  UpdateVal;
  case SetActive of
    //0: Edit_UInt.SetFocus;
    1: Edit_Int.SetFocus;
    2: Edit_Hex.Edit.SetFocus;
    //3: Edit_UInt.SetFocus;
    4: Edit_DUInt.SetFocus;
    5: Edit_DInt.SetFocus;
    6: Edit_Float.Edit.SetFocus;
  else
    Edit_UInt.SetFocus;
  end;
  Result := inherited ShowModal = mrOk;
  if Result then begin
    Value := Self.Value;
    ValueHi := Self.ValueHi;
  end;
end;

procedure TfEditReg.UpdateVal(Sender:TObject=nil);
var
  u: UInt16;
  i: Int16 absolute u;
  dw: UInt32;
  di: Int32 absolute dw;
  f: Single absolute dw;
begin
  fUpdating := True;
  u := Value;
  Edit_UInt.Value := u;
  Edit_Int.Value := i;
  Edit_Hex.Value := Value;
  if fValueHi then begin
    dw := WordToDWord(Value, ValueHi);
    Edit_DUInt.Value := dw;
    Edit_DInt.Value := di;
    if Edit_Float<>Sender then
      Edit_Float.Value := f;
  end else begin
    Edit_DUInt.Value := 0;
    Edit_DInt.Value := 0;
    Edit_Float.Value := 0;
  end;
  SpeedButton1.Text := BoolToStr(GetBit(Value, 0), '0', '1');
  SpeedButton2.Text := BoolToStr(GetBit(Value, 1), '0', '1');
  SpeedButton3.Text := BoolToStr(GetBit(Value, 2), '0', '1');
  SpeedButton4.Text := BoolToStr(GetBit(Value, 3), '0', '1');
  SpeedButton5.Text := BoolToStr(GetBit(Value, 4), '0', '1');
  SpeedButton6.Text := BoolToStr(GetBit(Value, 5), '0', '1');
  SpeedButton7.Text := BoolToStr(GetBit(Value, 6), '0', '1');
  SpeedButton8.Text := BoolToStr(GetBit(Value, 7), '0', '1');
  SpeedButton9.Text := BoolToStr(GetBit(Value, 8), '0', '1');
  SpeedButton10.Text := BoolToStr(GetBit(Value, 9), '0', '1');
  SpeedButton11.Text := BoolToStr(GetBit(Value, 10), '0', '1');
  SpeedButton12.Text := BoolToStr(GetBit(Value, 11), '0', '1');
  SpeedButton13.Text := BoolToStr(GetBit(Value, 12), '0', '1');
  SpeedButton14.Text := BoolToStr(GetBit(Value, 13), '0', '1');
  SpeedButton15.Text := BoolToStr(GetBit(Value, 14), '0', '1');
  SpeedButton16.Text := BoolToStr(GetBit(Value, 15), '0', '1');
  fUpdating := False;
end;

// ----------------------------------------------------------------------------------------------------------------------
procedure TfEditReg.ClickOnBit(Sender: TObject);
begin
  SetBit(Value, not GetBit(Value, (Sender as TSpeedButton).Tag), (Sender as TSpeedButton).Tag);
  UpdateVal;
end;

procedure TfEditReg.Edit_UIntChange(Sender: TObject);
begin
  if fUpdating then
    exit;
  Value := Round(Edit_UInt.Value);
  UpdateVal;

end;

procedure TfEditReg.Edit_IntChange(Sender: TObject);
var
  i: Int16;
  u: UInt16 absolute i;
begin
  if fUpdating then
    exit;
  i := Round(Edit_Int.Value);
  Value := u;
  UpdateVal;
end;

procedure TfEditReg.Edit_HexChange(Sender: TObject);
begin
  if fUpdating then
    exit;
  Value := Edit_Hex.Value;
  UpdateVal;
end;

procedure TfEditReg.Edit_DUIntChange(Sender: TObject);
var
  dw: UInt32;
begin
  if not fValueHi or fUpdating then
    exit;
  dw := Round(Edit_DUInt.Value);
  Value := dw and $FFFF;
  ValueHi := (dw shr 16) and $FFFF;
  UpdateVal;
end;

procedure TfEditReg.Edit_DIntChange(Sender: TObject);
var
  dw: UInt32;
  di: Int32 absolute dw;
begin
  if not fValueHi or fUpdating then
    exit;
  di := Round(Edit_DInt.Value);
  Value := dw and $FFFF;
  ValueHi := (dw shr 16) and $FFFF;
  UpdateVal;
end;

procedure TfEditReg.Edit_FloatChange(Sender: TObject);
var
  dw: UInt32;
  f: Single absolute dw;
begin
  if not fValueHi or fUpdating then
    exit;
  f := (Edit_Float.Value);
  Value := dw and $FFFF;
  ValueHi := (dw shr 16) and $FFFF;
  UpdateVal(Sender);
end;

end.
