unit uAddToLog;

interface

uses
  System.Classes, uLog, System.Generics.Collections, System.SyncObjs;

type

  TThreadAddToLog = class(TThread)
  private type
    TMes = record
      tip: TLogType;
      Source: string;
      Mes: string;
      time: TDateTime;
    end;
    TMesArr = System.Generics.Collections.TList<TMes>;
  private
    msg : TMesArr;
    timer: System.SyncObjs.TLightweightEvent;
    //fastTerm: Boolean;
  protected
    procedure Execute; override;
    procedure DoTerminate; override;
  public
    constructor Create;
    destructor Destroy; override;
    procedure  AddToLog(MesType: TLogType; Source, Mes: string; Time: TDateTime);
    //procedure FastTerminate();
  end;

var
  ThreadAddToLog: TThreadAddToLog; // create in AppData

implementation
uses System.SysUtils, uMain;

{ ThreadPushToLog }

constructor TThreadAddToLog.Create;
begin
  inherited Create;
  msg := TMesArr.Create;
  //timer := TEvent.Create(nil, True, True, '');
  timer := TLightweightEvent.Create;
end;

destructor TThreadAddToLog.Destroy;
begin
  FreeAndNil(msg);
  FreeAndNil(timer);
  inherited;
end;

procedure TThreadAddToLog.Execute;
var m: TMes;
  r: TWaitResult;
begin
  FreeOnTerminate := True;
  while not Terminated do begin
    timer.ResetEvent;
    r := timer.WaitFor(200);
    if not Terminated and (msg.Count>0) and ( (r=TWaitResult.wrTimeout) or (r=TWaitResult.wrSignaled)and(msg.Count>10) ) then begin
      while (msg.Count>0) and not Terminated do begin
        Synchronize(procedure
          var cnt: NativeUInt;
        begin
          cnt := 0;
          fMain.fmLog.UpdateBegin;
          try
            while not Terminated and (msg.Count>0) do begin
              m := msg.ExtractAt(0);
              fMain.fmLog.AddLog(m.tip, m.Source, m.Mes, m.Time);
              if cnt>30 then Break; // ограничиваем добавление записей за один Synchronize
              Inc(cnt);
            end;
          finally
            fMain.fmLog.UpdateEnd;
          end;
        end);
      end;
    end;
  end;
end;

procedure TThreadAddToLog.DoTerminate;
begin
  inherited;
  timer.SetEvent;
end;

procedure TThreadAddToLog.AddToLog(MesType: TLogType; Source, Mes: string; Time: TDateTime);
var m: TMes;
begin
  Synchronize( Self, procedure begin
    m.tip := MesType;
    m.Source := Source;
    m.Mes := Mes;
    m.Time := Time;
    msg.Add(m);
    timer.SetEvent;
  end);
end;

end.
