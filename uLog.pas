unit uLog;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls, FMX.Memo.Types,
  FMX.Controls.Presentation, FMX.ScrollBox, FMX.Memo, FMX.ListBox;

type
  TLogType = (ltInfo, ltError, ltWarning, ltRx, ltTx);
  TLogTypes = set of TLogType;
  TOnChangeMesType = procedure(const AllowedTypes: TLogTypes) of object;

  TfmSimpleLog = class(TFrame)
    LogList: TMemo;
    MesTypeList: TComboBox;
    ListBoxItem_Simple: TListBoxItem;
    ListBoxItem_All: TListBoxItem;
    TimerChechSize: TTimer;
    procedure MesTypeListChange(Sender: TObject);
    procedure FrameResized(Sender: TObject);
    procedure TimerChechSizeTimer(Sender: TObject);
  private
    FOnChangeMesType: TOnChangeMesType;
    _allowedMes: TLogTypes;
    procedure App_OnException(Sender: TObject; E: Exception);
  public
    constructor Create(AOwner: TComponent); override;
    procedure AddLog(const LType: TLogType; const Source: string; const Mes: string; const MesTime: TDateTime);
    procedure UpdateBegin;
    procedure UpdateEnd;
    property OnChangeMesType: TOnChangeMesType read FOnChangeMesType write FOnChangeMesType;
    property AllowedMes: TLogTypes read _allowedMes;
  end;

implementation
uses {Warnings}FMX.Text;

{$R *.fmx}

{ TFrame1 }

constructor TfmSimpleLog.Create(AOwner: TComponent);
begin
  inherited;
  Application.OnException := App_OnException;
  MesTypeListChange(nil);
end;

procedure TfmSimpleLog.App_OnException(Sender: TObject; E: Exception);
begin
  AddLog(ltError, 'Система', e.Message, Now);
end;

procedure TfmSimpleLog.AddLog(const LType: TLogType; const Source: string; const Mes: string; const MesTime: TDateTime);
var //color: TAlphaColor;
  inf, dt: string;
begin
//  if MesTypeList.Selected=ListBoxItem_Simple then
//    case LType of
//      ltRx, ltTx: Exit;
//    end;
  if not (LType in AllowedMes) then exit;
  if LogList.Lines.Count>4000 then begin
    LogList.Lines.BeginUpdate;
    try
    //while LogList.Lines.Count>3000 do begin
    //  LogList.Lines.Delete(LogList.Lines.Count-1)
    //
    //end;
    var pos := TCaretPosition.Create(3000,0);
    var pot := LogList.PosToTextPos(pos);
    LogList.DeleteFrom(pos, Length(LogList.Lines.Text)-pot, []);
    finally
      LogList.Lines.EndUpdate;
    end;
  end;
  case LType of
    ltInfo: begin
      //Color := TAlphaColors.Blue;
      inf := 'Инфо';
    end;
    ltError: begin
      //Color := TAlphaColors.Red;
      inf := 'Ошибка';
    end;
    ltWarning: begin
      //Color := TAlphaColors.Orange;
      inf := 'Внимание';
    end;
    ltRx: begin
      //Color := TAlphaColors.Green;
      inf := 'Rx<<<';
    end;
    ltTx: begin
      //Color := TAlphaColors.Fuchsia;
      inf := 'Tx>>>';
    end;
  end;
  DateTimeToString(dt,'dd.mm.yyyy hh:nn:ss.zzz', MesTime);
  LogList.Lines.Insert(0,Format('%s %.15s %.10s %s',[ dt, Source, inf, Mes]));
  LogList.CaretPosition := TCaretPosition.Zero;
  //LogList.ScrollToTop()
end;

procedure TfmSimpleLog.UpdateBegin;
begin
  //Self.BeginUpdate;
  LogList.BeginUpdate;
end;

procedure TfmSimpleLog.UpdateEnd;
begin
  LogList.EndUpdate;
  //Self.EndUpdate;
  //LogList.ScrollToTop()
end;

procedure TfmSimpleLog.MesTypeListChange(Sender: TObject);
begin
  case MesTypeList.ItemIndex of
    0: _allowedMes := [ ltInfo, ltError, ltWarning ];
  else
   {1:}_allowedMes := [ ltInfo, ltError, ltWarning, ltRx, ltTx ];
  end;
  if Assigned(FOnChangeMesType) then
    FOnChangeMesType(_allowedMes);
end;

procedure TfmSimpleLog.TimerChechSizeTimer(Sender: TObject);
var h: Single;
begin
  //AddLog(ltWarning, 'Resize',  'timer', Now);
  TimerChechSize.Enabled := False;
  if Assigned(ParentControl) then begin
    //AddLog(ltWarning, '1',  format('%f %f',[ParentControl.Height, Height]), Now);
    if Height+100>=ParentControl.Height  then begin
      //AddLog(ltWarning, '2',  format('%f %f',[Height+100, ParentControl.Height]), Now);
      h := ParentControl.Height - 110;
      //AddLog(ltWarning, '3',  format('%f' ,[h]), Now);
      if (h<Height) then begin
        if (h<50) then h := 50;
        Height := h
      end;
    end;
  end;
end;

procedure TfmSimpleLog.FrameResized(Sender: TObject);
begin
  //так же вызвать эту функцию в fMain.FormResize
  TimerChechSize.Enabled := False;
  TimerChechSize.Enabled := True;
end;

end.
