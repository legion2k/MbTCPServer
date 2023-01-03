unit uEditHex;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, 
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls, FMX.Edit, FMX.Controls.Presentation;

type
  TfmEditHex = class(TFrame)
    Edit: TEdit;
    EditButtonUp: TEditButton;
    EditButtonDown: TEditButton;
    procedure EditButtonUpClick(Sender: TObject);
    procedure EditButtonDownClick(Sender: TObject);
    procedure EditChangeTracking(Sender: TObject);
    procedure EditUpdateText(Sender: TObject);
  private
    { Private declarations }
    update: Boolean;
    Val: NativeUInt;
    ValMin: NativeUInt;
    ValMax: NativeUInt;
    ValInc: NativeUInt;
    eonChange: TNotifyEvent;
    procedure set_Max(const v: NativeUInt);
    procedure set_Min(const v: NativeUInt);
    procedure set_Val(const v: NativeUInt);
    procedure set_Inc(const v: NativeUInt);
    procedure _check(v: NativeUInt);
  public
    { Public declarations }
    property Min: NativeUInt read ValMin write set_Min;
    property Max: NativeUInt read ValMax write set_Max;
    property Value: NativeUInt read Val write set_Val;
    property Increment: NativeUInt read Val write set_Inc;
    constructor Create(AOwner: TComponent); override;
  published
    property OnChange: TNotifyEvent read eonChange write eonChange;
  end;

implementation
uses System.RegularExpressions;
{$R *.fmx}

constructor TfmEditHex.Create(AOwner: TComponent);
begin
  inherited;
  Val := 0;
  ValMin := NativeUInt.MinValue;
  ValMax := NativeUInt.MaxValue;
  ValInc := 1;
  update := False;
end;

procedure TfmEditHex._check(v: NativeUInt);
begin
  if Max>Min then
    if Max<v then
      v := Max
    else if Min>v then
      v := Min;
  if v<>Val then begin
    Val := v;
    EditUpdateText(nil);
    if Assigned(eonChange) then
      eonChange(Self);
  end;
end;

procedure TfmEditHex.set_Inc(const v: NativeUInt);
begin
  ValInc := Val
end;

procedure TfmEditHex.set_Max(const v: NativeUInt);
begin
  ValMax := v;
  if ValMin>v then ValMin := v;
  _check(Val);
end;

procedure TfmEditHex.set_Min(const v: NativeUInt);
begin
  ValMin := v;
  if ValMax<v then ValMax := v;
  _check(Val);
end;

procedure TfmEditHex.set_Val(const v: NativeUInt);
begin
  _check(v);
end;

procedure TfmEditHex.EditButtonDownClick(Sender: TObject);
begin
  {$Q-}
  if Val>Min then
    _check(Val - ValInc);
  {$Q+}
end;

procedure TfmEditHex.EditButtonUpClick(Sender: TObject);
begin
  {$Q-}
  if Val<Max then
    _check(Val + ValInc);
  {$Q+}
end;

procedure TfmEditHex.EditChangeTracking(Sender: TObject);
var s: string;
  e: Integer;
  v: NativeUInt;
begin
  if update then exit;
  s := Edit.Text;
  if s='' then exit;
  s := TRegEx.Replace(s, '(?si)[^A-F\d]', '');
  System.Val('$' + s, v, e);
  if e=0 then
    _check(v);
  EditUpdateText(nil);
end;

procedure TfmEditHex.EditUpdateText(Sender: TObject);
begin
  update := True;
  Edit.Text := IntToHex(Val, 1);
  update := False;
end;

end.
