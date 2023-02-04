program MbTCPServer;

uses
  System.StartUpCopy,
  FMX.Forms,
  uMain in 'uMain.pas' {fMain},
  uGrid in 'Grid\uGrid.pas' {fmGrid: TFrame},
  uServerSettings in 'uServerSettings.pas' {fmServerSettings: TFrame},
  uEditHex in 'Edit\uEditHex.pas' {fmEditHex: TFrame},
  uEditFloat in 'Edit\uEditFloat.pas' {fmEditFloat: TFrame},
  uEditSendData in 'Edit\uEditSendData.pas' {fmEditSendData: TFrame},
  uLog in 'uLog.pas' {fmSimpleLog: TFrame},
  uFillForm in 'uFillForm.pas' {fFillForm},
  uEditReg in 'Edit\uEditReg.pas' {fEditReg},
  uMbDecode in 'Modbus\uMbDecode.pas',
  uMbBuf in 'Modbus\uMbBuf.pas',
  uMbRegs in 'Modbus\uMbRegs.pas',
  uAddToLog in 'Modbus\uAddToLog.pas',
  uModbusServer in 'Modbus\uModbusServer.pas',
  uModbusSrvClient in 'Modbus\uModbusSrvClient.pas',
  uThreadModbus in 'Modbus\uThreadModbus.pas',
  uTools in 'uTools.pas',
  uMapReg_Discretes in 'Grid\uMapReg_Discretes.pas' {frmMapReg_Descrites: TFrame},
  uMapReg_Registers in 'Grid\uMapReg_Registers.pas' {frmMapReg_Registers: TFrame},
  uMapRegs in 'Grid\uMapRegs.pas' {fmMapRegs: TFrame},
  uIniJSON in 'uIniJSON.pas';

{$R *.res}

begin
  Application.Initialize;
  //Application.ShowHint := true;
  Application.CreateForm(TfMain, fMain);
  Application.CreateForm(TfFillForm, fFillForm);
  Application.CreateForm(TfEditReg, fEditReg);
  Application.Run;
end.
