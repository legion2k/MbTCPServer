unit uFillForm;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.StdCtrls, FMX.Controls.Presentation, FMX.Edit,
  FMX.EditBox, FMX.SpinBox;

type
  TfFillForm = class(TForm)
    GroupBox1: TGroupBox;
    CheckBox_4x: TCheckBox;
    CheckBox_3x: TCheckBox;
    CheckBox_0x: TCheckBox;
    CheckBox_1x: TCheckBox;
    GroupBox2: TGroupBox;
    RadioButton_Rnd: TRadioButton;
    RadioButton_Val: TRadioButton;
    RadioButton_Inc: TRadioButton;
    Edit_Val: TSpinBox;
    RadioButton4: TRadioButton;
    BtnFill: TButton;
    Button2: TButton;
    procedure BtnFillClick(Sender: TObject);
    procedure Button2Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  fFillForm: TfFillForm;

implementation

{$R *.fmx}

uses uMain, uMbBuf, uMbRegs;

procedure TfFillForm.BtnFillClick(Sender: TObject);
  function fillW(): TMBRegs;
  var i: UInt16;
  begin
    SetLength(Result, $10_000);
    if RadioButton_Rnd.isChecked then begin
      for i := 0 to $FFFF do
        Result[i] := Random($10000);
    end else
    if RadioButton_Inc.isChecked then begin
      for i := 0 to $FFFF do
        Result[i] := i;
    end else begin
    // if RadioButton_Val.isChecked then
      for i := 0 to $FFFF do
        Result[i] := Round(Edit_Val.Value);
    end;
  end;
  function fillB(): TMBDiscrets;
  var i: UInt16;
  begin
    SetLength(Result, $10_000);
    if RadioButton_Rnd.isChecked then begin
      for i := 0 to $FFFF do
        Result[i] := Odd(Random($10000));
    end else
    if RadioButton_Inc.isChecked then begin
      for i := 0 to $FFFF do
        Result[i] := Odd(i);
    end else begin
    // if RadioButton_Val.isChecked then
      for i := 0 to $FFFF do
        Result[i] := Odd(Round(Edit_Val.Value));
    end;
  end;
begin
  if CheckBox_4x.isChecked then
    with fMain.frmMapReg_4x do begin
      setRegs4x( fillW(), 0);
      fmMapRegs.fmGrid.Grid.repaint;
      fmMapRegs.RefreshCurrAddr();
    end;
  if CheckBox_3x.isChecked then
    with fMain.frmMapReg_3x do begin
      setRegs3x( fillW(), 0);
      fmMapRegs.fmGrid.Grid.repaint;
      fmMapRegs.RefreshCurrAddr();
    end;
  if CheckBox_1x.isChecked then
    with fMain.frmMapReg_1x do begin
      setRegs1x( fillB(), 0);
      fmMapRegs.fmGrid.Grid.repaint;
    end;
  if CheckBox_0x.isChecked then
    with fMain.frmMapReg_0x do begin
      setRegs0x( fillB(), 0);
      fmMapRegs.fmGrid.Grid.repaint;
    end;
end;

procedure TfFillForm.Button2Click(Sender: TObject);
begin
  Close;
end;

end.
