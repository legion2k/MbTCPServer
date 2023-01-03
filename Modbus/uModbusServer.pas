{
  Если запускать в Debug-e приложения (F9),
  то при тесте на большом количестве (например 100) подключений,
  может сильно зависать в момент подключения - это нормально!
}

unit uModbusServer;

interface
uses
  uThreadModbus, uAddToLog, System.Net.Socket, uModbusSrvClient, System.Generics.Collections,
  System.SyncObjs, uLog;

type
  //TClientsInfo = System.Generics.Collections.TList<TClientInfo>;
  TClientsInfo = System.Generics.Collections.TDictionary<UInt64,TClientInfo>;

type
  TModbusServer = class(TThreadModbus)
  private
    type
     TClients = System.Generics.Collections.TList<TModbusSrvClient>;
    var
    lockClients: TCriticalSection;
    sName: string;
    //----------------
    _ip: string;
    _port: UInt16;
    _addr: UInt8;
    _cnctMax: UInt16;
    _cnctTimeout: Integer;
    _answerSleep: UInt32;
    _answerType: Byte;
    _answerData: AnsiString;
    //----------------
    _srvSckt: TSocket;
    _clients: TClients;
  protected
    procedure Execute; override;
    procedure OnClienTerminate(Sender: TObject);
    procedure TerminatedSet; override;
  public
    constructor Create(logThread: TThreadAddToLog; AllowedMes: TLogTypes;
          IP: string; Port: UInt16; Addr: UInt8; ConnectionMax: UInt16; ConnectionTimeout: Integer;
          AnswerSleep: UInt32; AnswerType: Byte; AnswerData: AnsiString);
    destructor Destroy; override;
    //---
    procedure setAnswerTypeAndData(AnswerType: Byte; AnswerData:AnsiString);
    procedure setAnswerSleepTime(AnswerSleep: UInt32);
    //---
    function GetInfo(): TClientsInfo;
    //---
    procedure SetAllowedMes(AAllowedMes: TLogTypes); override;
  end;

implementation

uses System.SysUtils;

constructor TModbusServer.Create;
begin
  inherited Create(logThread, AllowedMes, True);
  _ip := IP;
  _port := Port;
  _addr :=  Addr;
  _cnctMax := ConnectionMax;
  _cnctTimeout := ConnectionTimeout;
  _answerSleep := AnswerSleep;
  _answerType := AnswerType;
  _answerData := AnswerData;
  _clients := TClients.Create;
  sName := 'Сервер: ';
  lockClients := TCriticalSection.Create;
end;

destructor TModbusServer.Destroy;
begin
  FreeAndNil(_clients);
  FreeAndNil(lockClients);
  inherited;
end;

procedure TModbusServer.Execute;
var i: Integer;
  cnctSckt: TSocket;
  client: TModbusSrvClient;
begin
  //--------------------------------------------------------------
  FreeOnTerminate := True;
  //--------------------------------------------------------------
  _srvSckt := TSocket.Create(TSocketType.TCP, TEncoding.ANSI);
  //_srvSckt.SendTimeout := 1;
  //_srvSckt.ReceiveTimeout := 1;
  //--------------------------------------------------------------
  try
    _srvSckt.Listen(_ip, '', _port );
    while not Terminated do
      try
        { https://en.delphipraxis.net/topic/2858-systemnetsocket-tsocketaccept-not-behaving-correctly-in-linux/ }
        cnctSckt := _srvSckt.Accept();
        //cnctSckt := _srvSckt.EndAccept( _srvSckt.BeginAccept());
        if Assigned(cnctSckt) and not Terminated then begin
          if (_cnctMax=0)or(_clients.Count<_cnctMax) then begin
            cnctSckt.SendTimeout := 1000;
            cnctSckt.ReceiveTimeout := _cnctTimeout;
            client := TModbusSrvClient.Create(cnctSckt, log, AllowedMes, _addr, _answerSleep, _answerType, _answerData);
            client.OnTerminate := OnClienTerminate;
            lockClients.Acquire;
            try
              _clients.Add(client);
            finally
              lockClients.Leave;
            end;
            client.Start();
          end else begin
           cnctSckt.Close(True);
           AddLog(ltInfo, sName, 'Превышено количество допустимых соединений');
          end;
        end;
      except
        on e: Exception do AddLog(ltError, sName, e.Message);
      end;
  except
    on e: Exception do AddLog(ltError, sName, e.Message);
  end;
  //--------------------------------------------------------------
  i := _clients.Count;
  lockClients.Acquire;
  try
    while i>0 do begin
      Dec(i);
        _clients[i].OnTerminate := nil;
        _clients[i].Terminate();
    end;
  finally
    lockClients.Release;
  end;
  if TSocketState.Connected in _srvSckt.State then
    _srvSckt.Close(True);
  //--------------------------------------------------------------
  FreeAndNil(_srvSckt);
end;

procedure TModbusServer.TerminatedSet;
begin
  inherited;
  if Assigned(_srvSckt) then begin
    _srvSckt.Close(True);
  end;
end;

procedure TModbusServer.OnClienTerminate(Sender: TObject);
begin
  if not Terminated then begin
    lockClients.Acquire;
    try
      _clients.Remove(Sender as TModbusSrvClient)
    finally
      lockClients.Release;
    end;
  end;
end;

procedure TModbusServer.SetAllowedMes(AAllowedMes: TLogTypes);
var c: TModbusSrvClient;
begin
  inherited;
  lockClients.Acquire;
  for c in _clients do
    c.SetAllowedMes(AAllowedMes);
  lockClients.Release;
end;

procedure TModbusServer.setAnswerSleepTime(AnswerSleep: UInt32);
var c: TModbusSrvClient;
begin
  Synchronize( self, procedure begin
    _answerSleep := AnswerSleep;
  end);
    lockClients.Acquire;
    try
      for c in _clients do
        c.setAnswerSleepTime(AnswerSleep);
    finally
      lockClients.Release;
    end;
end;

procedure TModbusServer.setAnswerTypeAndData(AnswerType: Byte; AnswerData: AnsiString);
var c: TModbusSrvClient;
begin
  Synchronize( self, procedure begin
    _answerType := AnswerType;
    _answerData := AnswerData;
  end);
    lockClients.Acquire;
    try
      for c in _clients do
        c.setAnswerTypeAndData(AnswerType, AnswerData);
    finally
      lockClients.Release;
    end;
end;

function TModbusServer.GetInfo(): TClientsInfo;
var inf: TClientInfo;
  c: TModbusSrvClient;
begin
//  r := TClientsInfo.Create;
//  Synchronize( self, procedure
//    var c: TModbusSrvClient;
//      inf: TClientInfo;
//  begin
    Result := TClientsInfo.Create;
    lockClients.Acquire;
    try
      for c in _clients do begin
        c.getInfo(inf);
        Result.Add(inf.ID, inf);
      end;
    finally
      lockClients.Release;
    end;
//  end);
//  Result := r;
end;

end.
