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

uses FMX.Styles, uTools, uFillForm, uMbRegs, IniFiles, System.IOUtils, FMX.DialogService;

function INIFileName(): string;
begin
  Result := System.IOUtils.TPath.Combine(System.IOUtils.TPath.GetHomePath, 'MBTCPServer2.ini')
end;

procedure TfMain.FormCreate(Sender: TObject);
var ini: TIniFile;
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

  ini := TIniFile.Create( INIFileName );
  try
    Height := ini.ReadInteger('0', 'h', Height);
    Width := ini.ReadInteger('0', 'w', Width);
    Left := ini.ReadInteger('0', 'x', Left);
    Top := ini.ReadInteger('0', 'y', Top);
    if ini.ReadBool('0', 'max', False) then WindowState := TWindowState.wsMaximized;
    fmLog.Height := ini.ReadFloat('0', 'log', fmLog.Height);
    //
    with fmServerSettings do begin
      Edit_IP.Text := ini.ReadString('ss','ip', Edit_IP.Text);
      Edit_Port.Value := ini.ReadInteger('ss','Port', round(Edit_Port.Value));
      Edit_Addr.Value := ini.ReadInteger('ss','Addr', round(Edit_Addr.Value));
      Edit_MaxConn.Value := ini.ReadInteger('ss','MaxConn', round(Edit_MaxConn.Value));
      Edit_TimeoutConn.Value := ini.ReadInteger('ss','TimeoutConn', round(Edit_TimeoutConn.Value));
      Edit_SleepTime.Value := ini.ReadInteger('ss','SleepTime', round(Edit_SleepTime.Value));

      Edit_Error.ItemIndex := ini.ReadInteger('ss','sError', Edit_Error.ItemIndex);
      Edit_Data.Edit.Text  := ini.ReadString('ss','sData', Edit_Data.Edit.Text);
      Edit_ADU.Edit.Text   := ini.ReadString('ss','sADU',  Edit_ADU.Edit.Text);
      Edit_Full.Edit.Text  := ini.ReadString('ss','sFull', Edit_Full.Edit.Text);
    end;
  finally
    FreeAndNil(ini);
  end;

end;

procedure TfMain.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
var ini: TIniFile;
begin
  if Assigned(MbServer) then begin
    MbServer.OnTerminate := nil;
    MbServer.Terminate;
  end;
  logThread.Terminate;

  ini := TIniFile.Create( INIFileName );
  //ini := TIniFile.Create( 'ComPort.ini');
  try
    ini.WriteBool   ('0', 'max', WindowState=TWindowState.wsMaximized);
    if WindowState<>TWindowState.wsMaximized then begin
      ini.WriteInteger('0', 'h', Height);
      ini.WriteInteger('0', 'w', Width);
      ini.WriteInteger('0', 'x', Left);
      ini.WriteInteger('0', 'y', Top);
    end;
    ini.WriteFloat('0', 'log', fmLog.Height);

    with fmServerSettings do begin
      ini.WriteString('ss','ip', Edit_IP.Text);
      ini.WriteInteger('ss','Port', round(Edit_Port.Value));
      ini.WriteInteger('ss','Addr', round(Edit_Addr.Value));
      ini.WriteInteger('ss','MaxConn', round(Edit_MaxConn.Value));
      ini.WriteInteger('ss','TimeoutConn', round(Edit_TimeoutConn.Value));
      ini.WriteInteger('ss','SleepTime', round(Edit_SleepTime.Value));

      ini.WriteInteger('ss','sError', Edit_Error.ItemIndex);
      ini.WriteString('ss','sData', Edit_Data.Edit.Text);
      ini.WriteString('ss','sADU',  Edit_ADU.Edit.Text);
      ini.WriteString('ss','sFull', Edit_Full.Edit.Text);
    end;

  except
    on e: Exception do
      TDialogService.MessageDialog('При сохранении настроек произошла ошибка:'#13+e.Message,
        TMsgDlgType.mtError, [TMsgDlgBtn.mbClose], TMsgDlgBtn.mbClose, e.HelpContext, nil);
  end;
  FreeAndNil(ini);
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
