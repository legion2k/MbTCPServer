unit uThreadModbus;

interface

uses
  System.Classes, uAddToLog, uLog;

type
  TThreadModbus = class(TThread)
  private
    _allowedMes: TLogTypes;
    _threadAddLog: TThreadAddToLog;
  protected
    property AllowedMes: TLogTypes read _allowedMes;
    property log: TThreadAddToLog read _threadAddLog;
    constructor Create(AThreadAddLog: TThreadAddToLog; AAllowedMes: TLogTypes; ACreateSuspended: Boolean = False);
    procedure AddLog(const MesType: TLogType; const Source, Mes: string);
  public
    procedure SetAllowedMes(AAllowedMes: TLogTypes); virtual;
  end;

implementation
uses System.SysUtils;

{ TThreadModbus }

constructor TThreadModbus.Create(AThreadAddLog: TThreadAddToLog; AAllowedMes: TLogTypes; ACreateSuspended: Boolean = False);
begin
  inherited Create(ACreateSuspended);
  _threadAddLog := AThreadAddLog;
  _allowedMes := AAllowedMes;
end;

procedure TThreadModbus.SetAllowedMes(AAllowedMes: TLogTypes);
begin
  Synchronize(Self, procedure begin
    _allowedMes := AAllowedMes;
  end);
end;

procedure TThreadModbus.AddLog(const MesType: TLogType; const Source, Mes: string);
begin
  if not Terminated then
    if MesType in _allowedMes then
      _threadAddLog.AddToLog(MesType, Source, Mes, Now());
//  var dt:=Now();
//  TThread.Synchronize(threadAddLog, procedure begin
//    threadAddLog.AddToLog(Mes, MesType, dt);
//  end)
end;

end.
