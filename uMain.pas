unit uMain;

interface

uses
  uModbusServer, uAddToLog,
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.TabControl, FMX.StdCtrls, FMX.Controls.Presentation,
  System.Rtti, FMX.Grid.Style, FMX.Grid, FMX.ScrollBox, uMapReg_Discretes, uMapReg_Registers, FMX.ListBox,
  FMX.Header, FMX.Ani, FMX.Objects, FMX.Layouts, uLog, uServerSettings;

type
  TfMain = class(TForm)
    TabControl: TTabControl;
    StatusBar: TStatusBar;
    ToolBar: TToolBar;
    TabItem1: TTabItem;
    TabItem2: TTabItem;
    TabItem3: TTabItem;
    TabItem4: TTabItem;
    BtnClose: TButton;
    StyleBook: TStyleBook;
    TabItem5: TTabItem;
    Rect_Work: TRectangle;
    Work_ColorAnimation: TColorAnimation;
    Work_Label: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label_CountConnection: TLabel;
    Line5: TLine;
    Line1: TLine;
    Splitter: TSplitter;
    BtnStartStop: TButton;
    ButtonFill: TButton;
    fmLog: TfmSimpleLog;
    frmMapReg_4x: TfrmMapReg_Registers;
    frmMapReg_3x: TfrmMapReg_Registers;
    frmMapReg_1x: TfrmMapReg_Descrites;
    frmMapReg_0x: TfrmMapReg_Descrites;
    fmServerSettings: TfmServerSettings;
    LayoutClient: TLayout;
    procedure FormCreate(Sender: TObject);
    procedure BtnCloseClick(Sender: TObject);
    procedure BtnStartStopClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure ButtonFillClick(Sender: TObject);
    procedure fmLogMesTypeListChange(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure fmServerSettingsEdit_SleepTimeChange(Sender: TObject);
  private
    { Private declarations }
    MbServer: TModbusServer;
    logThread: TThreadAddToLog;
    procedure OnMbServerTerminate(Sender: TObject);
    procedure setConnect(status: Boolean);
    procedure OnAnswerChange( const Answer: Byte; const Data: AnsiString );

  public
    { Public declarations }
     property ModbusServer: TModbusServer read MbServer;
  end;

var
  fMain: TfMain;

implementation

{$R *.fmx}

uses FMX.Styles, uTools, uFillForm, uMbRegs, System.IOUtils, FMX.DialogService, uIniJSON, uMbBuf;

function INIFileName(): string;
begin
  Result := System.IOUtils.TPath.Combine(System.IOUtils.TPath.GetHomePath, 'MBServer-EDC35E8C290D.json')
end;

procedure TfMain.FormCreate(Sender: TObject);
var inj: TIniJSONFile;
begin
  TStyleManager.TrySetStyleFromResource('win10style');// чтоб было одинакого на всех win

  logThread := TThreadAddToLog.Create;

  fmServerSettings.OnAnswerChange := OnAnswerChange;

  with frmMapReg_4x do begin
    FuncGetRegs := uMbRegs.getRegs4x;
    ProcSetRegs := uMbRegs.setRegs4x;
    FuncGetReg  := uMbRegs.getReg4x;
    ProcSetReg  := uMbRegs.setReg4x;
    fmMapRegs.RefreshCurrAddr();
    fmMapRegs.ColorCheck := TAlphaColor($ffB9E9FF);//BRIGHTESS 60%
    fmMapRegs.ColorSelect := TAlphaColor($ff6C9CFF);//BRIGHTESS 30%
    fmMapRegs.ColorCurrent := TAlphaColor($ff2050E0);//base //https://seochecker.it/color-palette-generator
  end;

  with frmMapReg_3x do begin
    FuncGetRegs := uMbRegs.getRegs3x;
    ProcSetRegs := uMbRegs.setRegs3x;
    FuncGetReg  := uMbRegs.getReg3x;
    ProcSetReg  := uMbRegs.setReg3x;
    fmMapRegs.RefreshCurrAddr();
    fmMapRegs.ColorCheck := TAlphaColor($ffFFB9FF);//BRIGHTESS 60%
    fmMapRegs.ColorSelect := TAlphaColor($ffEC7AD0);//DARKER 40%
    fmMapRegs.ColorCurrent := TAlphaColor($ff87136A);//DARKEN //E020B0-base
  end;

  with frmMapReg_1x do begin
    FuncGetDiscret  := uMbRegs.getReg1x;
    ProcSetDiscret  := uMbRegs.setReg1x;
    fmMapRegs.ColorCheck := TAlphaColor($ffB9FFE9);//BRIGHTESS 60%
    fmMapRegs.ColorSelect := TAlphaColor($ff20E050);//base
    fmMapRegs.ColorCurrent := TAlphaColor($ff138730);//DARKEN //20E050-base
  end;

  with frmMapReg_0x do begin
    FuncGetDiscret  := uMbRegs.getReg0x;
    ProcSetDiscret  := uMbRegs.setReg0x;
    fmMapRegs.ColorCheck := TAlphaColor($ffFFFFB9);//BRIGHTESS 60%
    fmMapRegs.ColorSelect := TAlphaColor($ffECD07A);//DARKER 40%
    fmMapRegs.ColorCurrent := TAlphaColor($ff876A13);//DARKEN //E0B020-base
  end;

  inj := TIniJSONFile.Create( INIFileName );
  try
    Height := inj.getValue<Integer>('w.h', Height);
    Width  := inj.getValue<Integer>('w.w', Width);
    Left   := inj.getValue<Integer>('w.x', Left);
    Top    := inj.getValue<Integer>('w.y', Top);
    if        inj.getValue<Boolean>('w.max', False) then WindowState := TWindowState.wsMaximized;
    fmLog.Height := inj.getValue<Single>('w.log', fmLog.Height);
    //
    with fmServerSettings do begin
      Edit_IP.Text           := inj.getValue<string> ('ss.ip', '0.0.0.0');
      Edit_Port.Value        := inj.getValue<UInt16> ('ss.port', 502);
      Edit_Addr.Value        := inj.getValue<UInt8>  ('ss.addr', 0);
      Edit_MaxConn.Value     := inj.getValue<UInt16> ('ss.maxCon', 0);
      Edit_TimeoutConn.Value := inj.getValue<Integer>('ss.timeout', 10_000);
      Edit_SleepTime.Value   := inj.getValue<UInt32> ('ss.sleep', 0);
      //
      Edit_Error.ItemIndex := inj.getValue<Integer>('ss.aError', 0);
      Edit_Data.Edit.Text  := inj.getValue<string> ('ss.aData', '');
      Edit_ADU.Edit.Text   := inj.getValue<string> ('ss.aADU',  '');
      Edit_Full.Edit.Text  := inj.getValue<string> ('ss.aFull', '');
    end;
    frmMapReg_4x.fmMapRegs.CheckRegs.AddRange( inj.getValue<TArray<UInt16>>('4x.check', []) );
    frmMapReg_3x.fmMapRegs.CheckRegs.AddRange( inj.getValue<TArray<UInt16>>('3x.check', []) );
    frmMapReg_1x.fmMapRegs.CheckRegs.AddRange( inj.getValue<TArray<UInt16>>('1x.check', []) );
    frmMapReg_0x.fmMapRegs.CheckRegs.AddRange( inj.getValue<TArray<UInt16>>('0x.check', []) );
    //
    setRegs4x( inj.getValue<TMBRegs>('4x.data', []), 0 );
    setRegs3x( inj.getValue<TMBRegs>('3x.data', []), 0 );
    setRegs1x( inj.getValue<TMBDiscrets>('1x.data', []), 0 );
    setRegs0x( inj.getValue<TMBDiscrets>('0x.data', []), 0 );
  finally
    FreeAndNil(inj);
  end;

end;

procedure TfMain.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
var inj: TIniJSONFile;
begin
  if Assigned(MbServer) then begin
    MbServer.OnTerminate := nil;
    MbServer.Terminate;
  end;
  logThread.Terminate;

  inj := TIniJSONFile.Create( INIFileName );
  //ini := TIniFile.Create( 'ComPort.ini');
  try
    inj.setValue('w.max', WindowState=TWindowState.wsMaximized);
    if WindowState<>TWindowState.wsMaximized then begin
      inj.setValue('w.h', Height);
      inj.setValue('w.w', Width);
      inj.setValue('w.x', Left);
      inj.setValue('w.y', Top);
    end;
    inj.setValue('w.log', fmLog.Height);
    //
    with fmServerSettings do begin
      inj.setValue('ss.ip',          Edit_IP.Text);
      inj.setValue('ss.port',        round(Edit_Port.Value));
      inj.setValue('ss.addr',        round(Edit_Addr.Value));
      inj.setValue('ss.maxCon',     round(Edit_MaxConn.Value));
      inj.setValue('ss.timeout', round(Edit_TimeoutConn.Value));
      inj.setValue('ss.sleep',   round(Edit_SleepTime.Value));
      //
      inj.setValue('ss.aError', Edit_Error.ItemIndex);
      inj.setValue('ss.aData',  Edit_Data.Edit.Text);
      inj.setValue('ss.aADU',   Edit_ADU.Edit.Text);
      inj.setValue('ss.aFull',  Edit_Full.Edit.Text);
    end;
    inj.setValue('4x.check', frmMapReg_4x.fmMapRegs.CheckRegs.ToArray);
    inj.setValue('3x.check', frmMapReg_3x.fmMapRegs.CheckRegs.ToArray);
    inj.setValue('1x.check', frmMapReg_1x.fmMapRegs.CheckRegs.ToArray);
    inj.setValue('0x.check', frmMapReg_0x.fmMapRegs.CheckRegs.ToArray);
    //
    inj.setValue('4x.data', TArray<UInt16>(getRegs4x(0, $10_000)));
    inj.setValue('3x.data', TArray<UInt16>(getRegs3x(0, $10_000)));
    inj.setValue('1x.data', TArray<Boolean>(getRegs1x(0, $10_000)));
    inj.setValue('0x.data', TArray<Boolean>(getRegs0x(0, $10_000)));
  except
    on e: Exception do
      TDialogService.MessageDialog('При сохранении настроек произошла ошибка:'#13+e.Message,
        TMsgDlgType.mtError, [TMsgDlgBtn.mbClose], TMsgDlgBtn.mbClose, e.HelpContext, nil);
  end;
  FreeAndNil(inj);
end;

procedure TfMain.BtnCloseClick(Sender: TObject);
begin
  Close;
end;

procedure TfMain.FormResize(Sender: TObject);
begin
  fmLog.FrameResized(Self);
end;

procedure TfMain.setConnect(status: Boolean);
begin
  Work_ColorAnimation.Enabled := status;
  Work_Label.text := Tools.iff<string>(status, 'ЗАПУЩЕН', 'НЕ ЗАПУЩЕН');
  fmServerSettings.Edit_IP.Enabled := not status;
  fmServerSettings.Edit_Port.Enabled := not status;
  fmServerSettings.Edit_Addr.Enabled := not status;
  fmServerSettings.Edit_MaxConn.Enabled := not status;
  fmServerSettings.Edit_TimeoutConn.Enabled := not status;
  //fmServerSettings.Edit_SleepTime.Enabled := not status;
end;

procedure TfMain.BtnStartStopClick(Sender: TObject);
var AnswerType: Byte;
  AnswerData: AnsiString;
begin
  if not Assigned(MbServer) then begin
    with fmServerSettings do begin
      getAnswerSets(AnswerType, AnswerData);
      MbServer := TModbusServer.Create(
        logThread,
        fmLog.AllowedMes,
        Edit_IP.Text,
        Round(Edit_Port.Value),
        Round(Edit_Addr.Value),
        Round(Edit_MaxConn.Value),
        Round(Edit_TimeoutConn.Value),
        Round(Edit_SleepTime.Value),
        AnswerType,
        AnswerData
      );
      MbServer.OnTerminate := OnMbServerTerminate;
      MbServer.Start();
      setConnect(True);
    end;
  end else
    MbServer.Terminate;
end;

procedure TfMain.OnMbServerTerminate(Sender: TObject);
begin
  MbServer := nil;
  setConnect(False);
end;

procedure TfMain.ButtonFillClick(Sender: TObject);
begin
  //fFillForm.ShowModal;
  fFillForm.Show;
end;

procedure TfMain.fmLogMesTypeListChange(Sender: TObject);
begin
  fmLog.MesTypeListChange(Sender);
  if Assigned(MbServer) then
    MbServer.SetAllowedMes(fmLog.AllowedMes);
end;

procedure TfMain.fmServerSettingsEdit_SleepTimeChange(Sender: TObject);
begin
  if Assigned(MbServer) then
    MbServer.setAnswerSleepTime(Round(fmServerSettings.Edit_SleepTime.Value))
end;

procedure TfMain.OnAnswerChange(const Answer: Byte; const Data: AnsiString);
begin
  if Assigned(MbServer) then
    MbServer.setAnswerTypeAndData(Answer, Data);
end;

end.
