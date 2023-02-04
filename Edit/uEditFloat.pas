unit uEditFloat;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls, FMX.Edit, FMX.Controls.Presentation;

type
  TfmEditFloat = class(TFrame)
    Edit: TEdit;
    EditButtonUp: TEditButton;
    EditButtonDown: TEditButton;
    procedure EditButtonUpClick(Sender: TObject);
    procedure EditButtonDownClick(Sender: TObject);
    procedure EditChangeTracking(Sender: TObject);
    procedure EditUpdateText(Sender: TObject);
  private
    { Private declarations }
    type
    TType = Real;
    var
    update: Boolean;
    Val: TType;
    ValMin: TType;
    ValMax: TType;
    ValInc: TType;
    eonChange: TNotifyEvent;
    procedure set_Max(const v: TType);
    procedure set_Min(const v: TType);
    procedure set_Val(const v: TType);
    procedure set_Inc(const v: TType);
    procedure _check(v: TType);
  public
    { Public declarations }
    property Min: TType read ValMin write set_Min;
    property Max: TType read ValMax write set_Max;
    property Value: TType read Val write set_Val;
    property Increment: TType read Val write set_Inc;
    constructor Create(AOwner: TComponent); override;
  published
    property OnChange: TNotifyEvent read eonChange write eonChange;
  end;

implementation
uses System.RegularExpressions;
{$R *.fmx}

constructor TfmEditFloat.Create(AOwner: TComponent);
begin
  inherited;
  Val := 0;
  ValMin := 0;
  ValMax := 0;
  ValInc := 1;
  update := False;
end;

procedure TfmEditFloat._check(v: TType);
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

procedure TfmEditFloat.set_Inc(const v: TType);
begin
  ValInc := Val
end;

procedure TfmEditFloat.set_Max(const v: TType);
begin
  ValMax := v;
  if ValMin>v then ValMin := v;
  _check(Val);
end;

procedure TfmEditFloat.set_Min(const v: TType);
begin
  ValMin := v;
  if ValMax<v then ValMax := v;
  _check(Val);
end;

procedure TfmEditFloat.set_Val(const v: TType);
begin
  _check(v);
end;

procedure TfmEditFloat.EditButtonDownClick(Sender: TObject);
begin
  _check(Val - ValInc);
end;

procedure TfmEditFloat.EditButtonUpClick(Sender: TObject);
begin
  _check(Val + ValInc);
end;

procedure TfmEditFloat.EditChangeTracking(Sender: TObject);
var
  m: TMatch;
  s,ss: string;
  e: Integer;
  v: TType;
  notEnd: Boolean;// признак не законченного ввода
begin
  if update then exit;
  s := (Sender as TEdit).Text;
  if s='' then exit;
  s := s.Replace(',','.');
  ss := s;
  //s := s.Trim;
  notEnd := False;
  // full Match '[+-]?((\d+(\.\d*)?)|(\.\d+))([eE][+-]?\d+)?')
  // с экспнициальной частью
  m := TRegEx.Match(s, '^[+-]?((\d+(\.\d*)?)|(\.\d+))[eE][+-]?\d+');
  if m.Success then
    s := m.Value
  else begin
    // не дописанная экспнициальная часть
    m := TRegEx.Match(s, '^[+-]?((\d+(\.\d*)?)|(\.\d+))[eE][+-]?');
    notEnd := m.Success;
    if m.Success then
      s := m.Value
    else begin
      // без экспнициальной части
      m := TRegEx.Match(s, '^[+-]?((\d+\.\d+)|(\.\d+))');
      if m.Success then
        s := m.Value
      else begin
        // число c точкой
        m := TRegEx.Match(s, '^[+-]?\d+\.');
        notEnd := m.Success;
        if m.Success then
          s := m.Value
        else begin
          // число
          m := TRegEx.Match(s, '^[+-]?\d+');
          if m.Success then
            s := m.Value
          else begin
            notEnd := True;
            // просто точка
            m := TRegEx.Match(s, '^[+-]?\.');
            if m.Success then
              s := m.Value
            else begin
              // пустая строка или + или -
              m := TRegEx.Match(s, '^[+-]?');
              s := m.Value
            end;
          end;
        end;
      end;
    end;
  end;
  if s <> ss then begin
    Edit.Text := s;
  end else if notEnd then begin //если не законченный ввод, то просто обновляем текст
    if s <> ss then begin
      update := True;
      Edit.Text := s;
      update := False;
    end
  end else begin //если нашли число, обновляем число
    System.Val(s, v, e);
    if e=0 then
      _check(v)
    else
      EditUpdateText(nil);
  end;
end;

procedure TfmEditFloat.EditUpdateText(Sender: TObject);
begin
  update := True;
  Edit.Text := FloatToStr(Val);
  update := False;
end;

initialization
  System.SysUtils.FormatSettings.DecimalSeparator := '.';
end.
